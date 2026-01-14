import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Handles YOLO11 with Segmentation
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

  /// Image Preprocessing and Inference
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
      //  Resize to 640x640 (model requirement)
      final resized = img.copyResize(image, width: 640, height: 640);
      // Convert pixels to normalized format
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
      // Output 0: Detection results
      var output0 = List.generate(
        1,
        (_) => List.generate(39, (_) => List.filled(8400, 0.0)),
      );
      // Output 1: Segmentation masks
      var output1 = List.generate(
        1,
        (_) => List.generate(
          160,
          (_) => List.generate(160, (_) => List.filled(32, 0.0)),
        ),
      );

      Map<int, Object> outputs = {0: output0, 1: output1};

      final startTime = DateTime.now();
      // Run Inference
      _interpreter!.runForMultipleInputs([input], outputs);
      final inferenceTime = DateTime.now().difference(startTime).inMilliseconds;

      print('Inference completed in ${inferenceTime}ms');

      List<List<double>> transposedOutput = List.generate(
        39,
        (i) => List.generate(8400, (j) => output0[0][i][j]),
      );

      // Pass output1 for mask processing
      final detections = _parseDetections(
        transposedOutput,
        output1,
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

  /// Parse detections
  List<Map<String, dynamic>> _parseDetections(
    List<List<double>> detections,
    List<List<List<List<double>>>> maskProtos,
    int origWidth,
    int origHeight,
  ) {
    List<Map<String, dynamic>> results = [];
    print('Parsing ${detections[0].length} raw detections...');
    // Check each possible detection
    for (int i = 0; i < detections[0].length; i++) {
      double cx = detections[0][i];
      double cy = detections[1][i];
      double w = detections[2][i];
      double h = detections[3][i];
      // Extract confidence scores for each class
      List<double> scores = [
        detections[4][i],
        detections[5][i],
        detections[6][i],
      ];
      // Find highest confidence class
      double maxScore = scores.reduce(max);
      int classIdx = scores.indexOf(maxScore);

      if (maxScore > 0.5) {
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

        List<double> maskCoeffs = [];
        for (int j = 7; j < 39; j++) {
          maskCoeffs.add(detections[j][i]);
        }

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
          'maskCoeffs': maskCoeffs,
        });
      }
    }
    // Apply NMS to remove duplicates
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
    // Generate masks to keep only best detections
    for (var det in kept) {
      det['mask'] = _generateMask(
        det['maskCoeffs'],
        maskProtos[0],
        det['bbox'],
        origWidth,
        origHeight,
      );
    }

    return kept;
  }

  /// Generate segmentation mask
  List<List<double>> _generateMask(
    List<double> maskCoeffs,
    List<List<List<double>>> maskProtos,
    Map<String, dynamic> bbox,
    int origWidth,
    int origHeight,
  ) {
    // Create 160x160 mask
    List<List<double>> mask = List.generate(160, (_) => List.filled(160, 0.0));

    for (int y = 0; y < 160; y++) {
      for (int x = 0; x < 160; x++) {
        double sum = 0.0;
        for (int c = 0; c < 32; c++) {
          sum += maskProtos[y][x][c] * maskCoeffs[c];
        }
        mask[y][x] = 1.0 / (1.0 + exp(-sum));
      }
    }

    return _resizeAndCropMask(mask, bbox, origWidth, origHeight);
  }

  /// Resize mask to bbox region
  List<List<double>> _resizeAndCropMask(
    List<List<double>> mask,
    Map<String, dynamic> bbox,
    int origWidth,
    int origHeight,
  ) {
    int x1 = bbox['x1'].round();
    int y1 = bbox['y1'].round();
    int x2 = bbox['x2'].round();
    int y2 = bbox['y2'].round();

    int bboxWidth = (x2 - x1).clamp(1, origWidth);
    int bboxHeight = (y2 - y1).clamp(1, origHeight);

    List<List<double>> croppedMask = List.generate(
      bboxHeight,
      (y) => List.filled(bboxWidth, 0.0),
    );

    for (int y = 0; y < bboxHeight; y++) {
      for (int x = 0; x < bboxWidth; x++) {
        double maskX = ((x1 + x) / origWidth * 160).clamp(0.0, 159.0);
        double maskY = ((y1 + y) / origHeight * 160).clamp(0.0, 159.0);

        int mx = maskX.round();
        int my = maskY.round();

        croppedMask[y][x] = mask[my][mx] > 0.5 ? 1.0 : 0.0;
      }
    }

    return croppedMask;
  }

  /// Extract urine color from masks pixels only
  Future<Map<String, dynamic>> extractUrineColor(
    File imageFile,
    Map<String, dynamic> detection,
  ) async {
    //  Reload original image
    final rawBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(rawBytes);
    if (image == null) throw Exception("Invalid image");
    // Get mask and bbox from detection
    List<List<double>> mask = detection['mask'];
    Map<String, dynamic> bbox = detection['bbox'];

    int x1 = bbox['x1'].round();
    int y1 = bbox['y1'].round();

    List<int> reds = [], greens = [], blues = [];

    for (int y = 0; y < mask.length; y++) {
      for (int x = 0; x < mask[y].length; x++) {
        if (mask[y][x] > 0.5) {
          int imgX = (x1 + x).clamp(0, image.width - 1);
          int imgY = (y1 + y).clamp(0, image.height - 1);

          final pixel = image.getPixel(imgX, imgY);
          reds.add(pixel.r.toInt());
          greens.add(pixel.g.toInt());
          blues.add(pixel.b.toInt());
        }
      }
    }

    if (reds.isEmpty) {
      return {
        'avgColor': {'r': 0, 'g': 0, 'b': 0},
        'pixelCount': 0,
        'error': 'No masked pixels found',
      };
    }

    int avgR = reds.reduce((a, b) => a + b) ~/ reds.length;
    int avgG = greens.reduce((a, b) => a + b) ~/ greens.length;
    int avgB = blues.reduce((a, b) => a + b) ~/ blues.length;

    return {
      'avgColor': {'r': avgR, 'g': avgG, 'b': avgB},
      'pixelCount': reds.length,
    };
  }

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
