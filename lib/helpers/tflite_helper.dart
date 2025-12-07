import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TFLiteHelper {
  static final TFLiteHelper _instance = TFLiteHelper._internal();
  factory TFLiteHelper() => _instance;
  TFLiteHelper._internal();

  Interpreter? _interpreter;
  List<String> _labels = [];

  bool get isLoaded => _interpreter != null;

  Future loadModel() async {
    try {
      print('Loading model...');

      _interpreter = await Interpreter.fromAsset(
        'assets/models/best_float32.tflite',
        options: InterpreterOptions()..threads = 4,
      );

      print('Model loaded successfully!');
      print('Number of outputs: ${_interpreter!.getOutputTensors().length}');
      for (int i = 0; i < _interpreter!.getOutputTensors().length; i++) {
        print('Output $i shape: ${_interpreter!.getOutputTensor(i).shape}');
      }
      print('Input shape: ${_interpreter!.getInputTensor(0).shape}');

      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData
          .split('\n')
          .where((element) => element.trim().isNotEmpty)
          .map((e) => e.trim())
          .toList();

      print('Labels loaded: ${_labels.length} classes');
      print('Classes: $_labels');
    } catch (e) {
      print('Error loading model: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> runModel(File imageFile) async {
    if (_interpreter == null) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    try {
      final rawBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(rawBytes);
      if (image == null) throw Exception("Invalid image format");

      // Store original dimensions for mask scaling
      final origWidth = image.width;
      final origHeight = image.height;

      // Resize to 640x640
      final resized = img.copyResize(image, width: 640, height: 640);

      // Prepare input [1, 640, 640, 3]
      var input = List.generate(
        1,
        (_) => List.generate(
          640,
          (_) => List.generate(640, (_) => List.filled(3, 0.0)),
        ),
      );

      for (int y = 0; y < 640; y++) {
        for (int x = 0; x < 640; x++) {
          final pixel = resized.getPixel(x, y);
          input[0][y][x][0] = pixel.r / 255.0;
          input[0][y][x][1] = pixel.g / 255.0;
          input[0][y][x][2] = pixel.b / 255.0;
        }
      }

      // Prepare outputs
      // Output 0: [1, 39, 8400] - detections (4 box + 3 classes + 32 mask coeffs)
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

      // Parse detections
      final detections = _parseYoloSegOutput(
        output0[0],
        output1[0],
        confidenceThreshold: 0.5,
        iouThreshold: 0.4,
        origWidth: origWidth,
        origHeight: origHeight,
      );

      return {
        'success': true,
        'detections': detections,
        'inferenceTime': inferenceTime,
        'imageSize': {'width': origWidth, 'height': origHeight},
      };
    } catch (e) {
      print('Error during inference: $e');
      return {'success': false, 'error': e.toString(), 'detections': []};
    }
  }

  List<Map<String, dynamic>> _parseYoloSegOutput(
    List<List<double>> detectionOutput,
    List<List<List<double>>> maskProtos, {
    required double confidenceThreshold,
    required double iouThreshold,
    required int origWidth,
    required int origHeight,
  }) {
    List<Map<String, dynamic>> detections = [];

    // detectionOutput is [39, 8400]
    // First 4: box (x, y, w, h)
    // Next 3: class scores
    // Last 32: mask coefficients

    final numPredictions = detectionOutput[0].length; // 8400

    for (int i = 0; i < numPredictions; i++) {
      // Extract box coordinates
      double cx = detectionOutput[0][i];
      double cy = detectionOutput[1][i];
      double w = detectionOutput[2][i];
      double h = detectionOutput[3][i];

      // Extract class scores (indices 4-6 for 3 classes)
      List<double> classScores = [
        detectionOutput[4][i],
        detectionOutput[5][i],
        detectionOutput[6][i],
      ];

      // Find best class
      double maxScore = classScores.reduce(max);
      int classIndex = classScores.indexOf(maxScore);

      if (maxScore > confidenceThreshold) {
        // Extract mask coefficients (indices 7-38 = 32 coeffs)
        List<double> maskCoeffs = [];
        for (int j = 7; j < 39; j++) {
          maskCoeffs.add(detectionOutput[j][i]);
        }

        // Convert from center format to corner format
        double x1 = (cx - w / 2) * origWidth / 640;
        double y1 = (cy - h / 2) * origHeight / 640;
        double x2 = (cx + w / 2) * origWidth / 640;
        double y2 = (cy + h / 2) * origHeight / 640;

        detections.add({
          'bbox': {
            'x1': x1,
            'y1': y1,
            'x2': x2,
            'y2': y2,
            'width': x2 - x1,
            'height': y2 - y1,
          },
          'class': classIndex < _labels.length
              ? _labels[classIndex]
              : 'Unknown',
          'confidence': (maxScore * 100).toDouble(),
          'classIndex': classIndex,
          'maskCoeffs': maskCoeffs,
        });
      }
    }

    print('Found ${detections.length} detections before NMS');

    // Apply NMS
    detections = _applyNMS(detections, iouThreshold);

    print('Final detections after NMS: ${detections.length}');

    // Generate masks for each detection
    for (var detection in detections) {
      detection['hasMask'] = true;
      // You can generate actual mask here by multiplying coeffs with protos
      // For now, we just flag that mask data is available
    }

    return detections;
  }

  List<Map<String, dynamic>> _applyNMS(
    List<Map<String, dynamic>> detections,
    double iouThreshold,
  ) {
    if (detections.isEmpty) return [];

    detections.sort(
      (a, b) =>
          (b['confidence'] as double).compareTo(a['confidence'] as double),
    );

    List<Map<String, dynamic>> kept = [];

    while (detections.isNotEmpty) {
      final best = detections.removeAt(0);
      kept.add(best);

      detections.removeWhere((detection) {
        final iou = _calculateIoU(best['bbox'], detection['bbox']);
        return iou > iouThreshold && best['class'] == detection['class'];
      });
    }

    return kept;
  }

  double _calculateIoU(Map<String, dynamic> box1, Map<String, dynamic> box2) {
    final x1 = max(box1['x1'], box2['x1']);
    final y1 = max(box1['y1'], box2['y1']);
    final x2 = min(box1['x2'], box2['x2']);
    final y2 = min(box1['y2'], box2['y2']);

    final intersectionArea = max(0.0, x2 - x1) * max(0.0, y2 - y1);
    final box1Area = box1['width'] * box1['height'];
    final box2Area = box2['width'] * box2['height'];
    final unionArea = box1Area + box2Area - intersectionArea;

    return unionArea > 0 ? intersectionArea / unionArea : 0.0;
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
    print('Model closed');
  }
}
