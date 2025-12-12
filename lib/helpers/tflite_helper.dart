import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Handles YOLO11m-seg model for urine analysis
class TFLiteHelper {
  static final TFLiteHelper _instance = TFLiteHelper._internal();
  factory TFLiteHelper() => _instance;
  TFLiteHelper._internal();

  Interpreter? _interpreter;
  List<String> _labels = [];

  bool get isLoaded => _interpreter != null;

  /// Load model and labels from assets
  Future loadModel() async {
    try {
      print('Loading model...');
      _interpreter = await Interpreter.fromAsset(
        'assets/models/best_float32.tflite',
        options: InterpreterOptions()..threads = 4,
      );

      print('Model loaded successfully');
      print('Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('Output 0 shape: ${_interpreter!.getOutputTensor(0).shape}');
      print('Output 1 shape: ${_interpreter!.getOutputTensor(1).shape}');

      // Load class names
      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData
          .split('\n')
          .where((element) => element.trim().isNotEmpty)
          .map((e) => e.trim())
          .toList();

      print('Labels loaded: $_labels');
    } catch (e) {
      print('Error loading model: $e');
      rethrow;
    }
  }

  /// Run model on image, returns detections with masks
  Future<Map<String, dynamic>> runModel(File imageFile) async {
    if (_interpreter == null) {
      throw Exception('Model not loaded');
    }

    try {
      final rawBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(rawBytes);
      if (image == null) throw Exception("Invalid image");

      final origWidth = image.width;
      final origHeight = image.height;
      print('Original image: ${origWidth}x$origHeight');

      // Resize to 640x640 for model input
      final resized = img.copyResize(image, width: 640, height: 640);

      // Prepare input: normalize pixels to 0-1
      var input = List.generate(
        1,
        (_) => List.generate(
          640,
          (y) => List.generate(640, (x) {
            final pixel = resized.getPixel(x, y);
            return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
          }),
        ),
      );

      // Prepare outputs
      // Output 0: [1, 39, 8400] - box coords + class scores + mask coeffs
      var output0 = List.generate(
        1,
        (_) => List.generate(39, (_) => List.filled(8400, 0.0)),
      );

      // Output 1: [1, 160, 160, 32] - mask prototypes
      var output1 = List.generate(
        1,
        (_) => List.generate(
          160,
          (_) => List.generate(160, (_) => List.filled(32, 0.0)),
        ),
      );

      Map<int, Object> outputs = {0: output0, 1: output1};

      // Run inference
      final startTime = DateTime.now();
      _interpreter!.runForMultipleInputs([input], outputs);
      final inferenceTime = DateTime.now().difference(startTime).inMilliseconds;

      print('Inference completed in ${inferenceTime}ms');

      // Reshape for easier processing: [1, 39, 8400] → [39, 8400]
      List<List<double>> transposedOutput = List.generate(
        39,
        (i) => List.generate(8400, (j) => output0[0][i][j]),
      );

      // Parse and filter detections
      final detections = _parseDetections(
        transposedOutput,
        output1[0],
        origWidth,
        origHeight,
      );

      print('Found ${detections.length} detections after filtering');

      return {
        'success': true,
        'detections': detections,
        'inferenceTime': inferenceTime,
        'imageSize': {'width': origWidth, 'height': origHeight},
      };
    } catch (e) {
      print('Error running model: $e');
      return {'success': false, 'error': e.toString(), 'detections': []};
    }
  }

  /// Parse detections and apply NMS filtering
  List<Map<String, dynamic>> _parseDetections(
    List<List<double>> detections,
    List<List<List<double>>> maskProtos,
    int origWidth,
    int origHeight,
  ) {
    List<Map<String, dynamic>> results = [];
    print('Parsing ${detections[0].length} raw detections...');

    for (int i = 0; i < detections[0].length; i++) {
      // Extract box: center x, center y, width, height (normalized 0-1)
      double cx = detections[0][i];
      double cy = detections[1][i];
      double w = detections[2][i];
      double h = detections[3][i];

      // Extract class scores
      List<double> scores = [
        detections[4][i],
        detections[5][i],
        detections[6][i],
      ];

      double maxScore = scores.reduce(max);
      int classIdx = scores.indexOf(maxScore);

      // Keep only confident detections (>50%)
      if (maxScore > 0.5) {
        // Extract 32 mask coefficients
        List<double> maskCoeffs = [];
        for (int j = 7; j < 39; j++) {
          maskCoeffs.add(detections[j][i]);
        }

        // Convert to pixel coordinates
        double x1 = ((cx - w / 2) * origWidth).clamp(0.0, origWidth.toDouble());
        double y1 = ((cy - h / 2) * origHeight).clamp(
          0.0,
          origHeight.toDouble(),
        );
        double x2 = ((cx + w / 2) * origWidth).clamp(0.0, origWidth.toDouble());
        double y2 = ((cy + h / 2) * origHeight).clamp(
          0.0,
          origHeight.toDouble(),
        );

        String className = classIdx < _labels.length
            ? _labels[classIdx]
            : 'Unknown';

        // Generate mask polygon
        final polygon = _generatePolygon(
          maskCoeffs,
          maskProtos,
          x1,
          y1,
          x2,
          y2,
          origWidth,
          origHeight,
        );

        results.add({
          'bbox': {
            'x1': x1,
            'y1': y1,
            'x2': x2,
            'y2': y2,
            'width': x2 - x1,
            'height': y2 - y1,
          },
          'class': className,
          'confidence': maxScore * 100,
          'classIndex': classIdx,
          'polygon': polygon,
          'hasMask': true,
        });
      }
    }

    // Remove overlapping detections (NMS)
    results.sort(
      (a, b) =>
          (b['confidence'] as double).compareTo(a['confidence'] as double),
    );
    List<Map<String, dynamic>> kept = [];

    while (results.isNotEmpty) {
      kept.add(results.removeAt(0));
      results.removeWhere((det) {
        final iou = _calculateIoU(kept.last['bbox'], det['bbox']);
        return iou > 0.4 && kept.last['class'] == det['class'];
      });
    }

    return kept;
  }

  /// Generate polygon from mask coefficients
  List<Map<String, double>> _generatePolygon(
    List<double> coeffs,
    List<List<List<double>>> protos,
    double x1,
    double y1,
    double x2,
    double y2,
    int imgW,
    int imgH,
  ) {
    const int maskSize = 160;

    // Create mask by combining coefficients with prototypes
    List<List<double>> mask = List.generate(
      maskSize,
      (_) => List.filled(maskSize, 0.0),
    );

    for (int y = 0; y < maskSize; y++) {
      for (int x = 0; x < maskSize; x++) {
        double sum = 0.0;
        for (int c = 0; c < 32; c++) {
          sum += coeffs[c] * protos[y][x][c];
        }
        mask[y][x] = 1.0 / (1.0 + exp(-sum)); // sigmoid
      }
    }

    // Map bbox to mask region
    int mx1 = ((x1 / imgW) * maskSize).round().clamp(0, maskSize - 1);
    int my1 = ((y1 / imgH) * maskSize).round().clamp(0, maskSize - 1);
    int mx2 = ((x2 / imgW) * maskSize).round().clamp(0, maskSize - 1);
    int my2 = ((y2 / imgH) * maskSize).round().clamp(0, maskSize - 1);

    // Add padding
    mx1 = (mx1 - 5).clamp(0, maskSize - 1);
    my1 = (my1 - 5).clamp(0, maskSize - 1);
    mx2 = (mx2 + 5).clamp(0, maskSize - 1);
    my2 = (my2 + 5).clamp(0, maskSize - 1);

    if (mx2 <= mx1) mx2 = min(mx1 + 1, maskSize - 1);
    if (my2 <= my1) my2 = min(my1 + 1, maskSize - 1);

    // Calculate threshold
    double maxMask = 0.0;
    double avgMask = 0.0;
    int count = 0;

    for (int y = my1; y <= my2; y++) {
      for (int x = mx1; x <= mx2; x++) {
        maxMask = max(maxMask, mask[y][x]);
        avgMask += mask[y][x];
        count++;
      }
    }
    avgMask = count > 0 ? avgMask / count : 0.0;

    double threshold = min(maxMask * 0.3, 0.3);
    if (avgMask > 0.5) threshold = min(threshold, 0.2);

    // Find edge pixels
    List<Map<String, int>> maskPixels = [];

    for (int y = my1; y <= my2; y++) {
      for (int x = mx1; x <= mx2; x++) {
        if (mask[y][x] > threshold) {
          bool isEdge = false;

          // Check neighbors
          for (int dy = -1; dy <= 1 && !isEdge; dy++) {
            for (int dx = -1; dx <= 1 && !isEdge; dx++) {
              if (dx == 0 && dy == 0) continue;

              int ny = y + dy;
              int nx = x + dx;

              if (ny < 0 ||
                  ny >= maskSize ||
                  nx < 0 ||
                  nx >= maskSize ||
                  mask[ny][nx] <= threshold) {
                isEdge = true;
              }
            }
          }

          if (isEdge) maskPixels.add({'x': x, 'y': y});
        }
      }
    }

    // Fallback if too few edge pixels
    if (maskPixels.length < 8) {
      List<Map<String, int>> allPixels = [];
      for (int y = my1; y <= my2; y++) {
        for (int x = mx1; x <= mx2; x++) {
          if (mask[y][x] > threshold) {
            allPixels.add({'x': x, 'y': y});
          }
        }
      }

      if (allPixels.isNotEmpty) {
        maskPixels = _extractBoundary(allPixels);
      }
    }

    // Convert to image coordinates
    List<Map<String, double>> polygon = [];

    if (maskPixels.length < 4) {
      // Use bbox as fallback
      polygon = [
        {'x': x1, 'y': y1},
        {'x': x2, 'y': y1},
        {'x': x2, 'y': y2},
        {'x': x1, 'y': y2},
      ];
    } else {
      maskPixels = _sortPointsClockwise(maskPixels);

      for (var e in maskPixels) {
        double px = ((e['x']! / maskSize) * imgW).clamp(0.0, imgW.toDouble());
        double py = ((e['y']! / maskSize) * imgH).clamp(0.0, imgH.toDouble());
        polygon.add({'x': px, 'y': py});
      }

      // Simplify if too many points
      if (polygon.length > 100) {
        int step = (polygon.length / 100).ceil();
        List<Map<String, double>> simplified = [];
        for (int i = 0; i < polygon.length; i += step) {
          simplified.add(polygon[i]);
        }
        polygon = simplified;
      }
    }

    return polygon;
  }

  /// Find boundary pixels
  List<Map<String, int>> _extractBoundary(List<Map<String, int>> pixels) {
    if (pixels.isEmpty) return [];

    Set<String> pixelSet = {};
    for (var p in pixels) {
      pixelSet.add('${p['x']},${p['y']}');
    }

    List<Map<String, int>> boundary = [];

    for (var p in pixels) {
      int x = p['x']!;
      int y = p['y']!;

      bool isBoundary = false;
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;

          if (!pixelSet.contains('${x + dx},${y + dy}')) {
            isBoundary = true;
            break;
          }
        }
        if (isBoundary) break;
      }

      if (isBoundary) boundary.add({'x': x, 'y': y});
    }

    return boundary.isEmpty ? pixels : boundary;
  }

  /// Sort points clockwise
  List<Map<String, int>> _sortPointsClockwise(List<Map<String, int>> points) {
    if (points.length < 3) return points;

    // Find center
    double cx = 0, cy = 0;
    for (var p in points) {
      cx += p['x']!;
      cy += p['y']!;
    }
    cx /= points.length;
    cy /= points.length;

    // Sort by angle
    points.sort((a, b) {
      double angleA = atan2(a['y']! - cy, a['x']! - cx);
      double angleB = atan2(b['y']! - cy, b['x']! - cx);
      return angleA.compareTo(angleB);
    });

    return points;
  }

  /// Calculate overlap between boxes
  double _calculateIoU(Map<String, dynamic> b1, Map<String, dynamic> b2) {
    final x1 = max(b1['x1'], b2['x1']);
    final y1 = max(b1['y1'], b2['y1']);
    final x2 = min(b1['x2'], b2['x2']);
    final y2 = min(b1['y2'], b2['y2']);

    final inter = max(0.0, x2 - x1) * max(0.0, y2 - y1);
    final union =
        b1['width'] * b1['height'] + b2['width'] * b2['height'] - inter;

    return union > 0 ? inter / union : 0.0;
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
  }
}
