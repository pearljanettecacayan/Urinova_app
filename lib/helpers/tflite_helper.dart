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

      // Load class labels (Possible Dehydrated, Normal, Possible UTI)
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

      // Prepare output
      var output0 = List.generate(
        1,
        (_) => List.generate(39, (_) => List.filled(8400, 0.0)),
      );

      var output1 = List.generate(
        1,
        (_) => List.generate(
          160,
          (_) => List.generate(160, (_) => List.filled(32, 0.0)),
        ),
      );

      Map<int, Object> outputs = {0: output0, 1: output1};

      // Run the model
      final startTime = DateTime.now();
      _interpreter!.runForMultipleInputs([input], outputs);
      final inferenceTime = DateTime.now().difference(startTime).inMilliseconds;

      print('Inference completed in ${inferenceTime}ms');

      // Parse detection - Reshape for easier processing
      List<List<double>> transposedOutput = List.generate(
        39,
        (i) => List.generate(8400, (j) => output0[0][i][j]),
      );

      // Parse detections
      final detections = _parseDetections(
        transposedOutput,
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
    int origWidth,
    int origHeight,
  ) {
    List<Map<String, dynamic>> results = [];
    print('Parsing ${detections[0].length} raw detections...');

    for (int i = 0; i < detections[0].length; i++) {
      // Extract bounding box
      double cx = detections[0][i]; // Center X
      double cy = detections[1][i]; // Center Y
      double w = detections[2][i]; // Width
      double h = detections[3][i]; // Height

      // Get class scores
      List<double> scores = [
        detections[4][i],
        detections[5][i],
        detections[6][i],
      ];
      // Find highest confidence
      double maxScore = scores.reduce(max);
      int classIdx = scores.indexOf(maxScore);

      /// Only keep detections above 50% confidence
      if (maxScore > 0.5) {
        // Convert normalized coords to pixel coords
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

        // Store detection
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
        });
      }
    }

    // Apply NMS (remove duplicates)
    results.sort(
      //Sort by confidence (highest first)
      (a, b) =>
          (b['confidence'] as double).compareTo(a['confidence'] as double),
    );

    List<Map<String, dynamic>> kept = [];

    while (results.isNotEmpty) {
      kept.add(results.removeAt(0)); // Keep best detection
      // Remove overlapping detections of same class
      results.removeWhere((det) {
        final iou = _calculateIoU(kept.last['bbox'], det['bbox']);
        return iou > 0.4 && kept.last['class'] == det['class'];
      });
    }

    return kept;
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
