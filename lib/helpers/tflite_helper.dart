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

  /// Load tflite model and labels from assets
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

  /// Run model
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

      // normalize pixels to 0-1
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

      // Prepare output0 & output1
      var output0 = List.generate(
        1,
        (_) => List.generate(
          39,
          (_) => List.filled(8400, 0.0),
        ), // bbox + classes + mask coeffs
      );
      var output1 = List.generate(
        1,
        (_) => List.generate(
          160,
          (_) => List.generate(
            160,
            (_) => List.filled(32, 0.0),
          ), // mask prototypes
        ),
      );

      Map<int, Object> outputs = {0: output0, 1: output1};

      // Run inference
      final startTime = DateTime.now();
      _interpreter!.runForMultipleInputs([input], outputs);
      final inferenceTime = DateTime.now().difference(startTime).inMilliseconds;

      print('Inference completed in ${inferenceTime}ms');

      // Parse detection - Reshape for easier processing
      List<List<double>> transposedOutput = List.generate(
        39,
        (i) => List.generate(8400, (j) => output0[0][i][j]),
      );

      // Parse detections and generate polygons
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
    List<List<double>> detections, // from output 0
    List<List<List<double>>> maskProtos, // from output 1
    int origWidth,
    int origHeight,
  ) {
    List<Map<String, dynamic>> results = [];
    print('Parsing ${detections[0].length} raw detections...');

    for (int i = 0; i < detections[0].length; i++) {
      double cx = detections[0][i]; // Center X
      double cy = detections[1][i]; // Center Y
      double w = detections[2][i]; // Width
      double h = detections[3][i]; // Height

      List<double> scores = [
        detections[4][i],
        detections[5][i],
        detections[6][i],
      ];

      double maxScore = scores.reduce(max);
      int classIdx = scores.indexOf(maxScore);

      if (maxScore > 0.5) {
        List<double> maskCoeffs = [];
        for (int j = 7; j < 39; j++) {
          maskCoeffs.add(detections[j][i]);
        }
        // Convert normalized coords - pixel coords
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

        // Generate polygon mask
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
        // stored complete detection
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

    // Apply NMS (remove duplicates)
    results.sort(
      (a, b) =>
          (b['confidence'] as double).compareTo(a['confidence'] as double),
    );
    List<Map<String, dynamic>> kept = [];

    while (results.isNotEmpty) {
      kept.add(results.removeAt(0)); // Keep best one
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
        mask[y][x] = 1.0 / (1.0 + exp(-sum));
      }
    }

    // Map bbox to mask region
    int mx1 = ((x1 / imgW) * maskSize).round().clamp(0, maskSize - 1);
    int my1 = ((y1 / imgH) * maskSize).round().clamp(0, maskSize - 1);
    int mx2 = ((x2 / imgW) * maskSize).round().clamp(0, maskSize - 1);
    int my2 = ((y2 / imgH) * maskSize).round().clamp(0, maskSize - 1);

    if (mx2 <= mx1) mx2 = min(mx1 + 1, maskSize - 1);
    if (my2 <= my1) my2 = min(my1 + 1, maskSize - 1);

    // Calculate threshold
    double maxMask = 0.0;
    for (int y = my1; y <= my2; y++) {
      for (int x = mx1; x <= mx2; x++) {
        maxMask = max(maxMask, mask[y][x]);
      }
    }

    double threshold = max(0.5, maxMask * 0.5);

    // Find edge pixels
    List<Map<String, int>> edges = [];

    for (int y = my1; y <= my2; y++) {
      for (int x = mx1; x <= mx2; x++) {
        if (mask[y][x] > threshold) {
          bool isEdge = false;

          for (int dy = -1; dy <= 1 && !isEdge; dy++) {
            for (int dx = -1; dx <= 1 && !isEdge; dx++) {
              if (dx == 0 && dy == 0) continue;

              int ny = y + dy;
              int nx = x + dx;

              if (ny < my1 ||
                  ny > my2 ||
                  nx < mx1 ||
                  nx > mx2 ||
                  mask[ny][nx] <= threshold) {
                isEdge = true;
              }
            }
          }

          if (isEdge) edges.add({'x': x, 'y': y});
        }
      }
    }

    // Convert to image coordinates
    List<Map<String, double>> polygon = [];

    if (edges.length < 4) {
      polygon = [
        {'x': x1, 'y': y1},
        {'x': x2, 'y': y1},
        {'x': x2, 'y': y2},
        {'x': x1, 'y': y2},
      ];
    } else {
      edges = _sortPointsClockwise(edges);

      for (var e in edges) {
        double px = ((e['x']! / maskSize) * imgW).clamp(0.0, imgW.toDouble());
        double py = ((e['y']! / maskSize) * imgH).clamp(0.0, imgH.toDouble());
        polygon.add({'x': px, 'y': py});
      }

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

  /// Sort points clockwise
  List<Map<String, int>> _sortPointsClockwise(List<Map<String, int>> points) {
    if (points.length < 3) return points;

    double cx = 0, cy = 0;
    for (var p in points) {
      cx += p['x']!;
      cy += p['y']!;
    }
    cx /= points.length;
    cy /= points.length;

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
