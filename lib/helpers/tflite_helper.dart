import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TFLiteHelper {
  static final TFLiteHelper _instance = TFLiteHelper._internal();
  factory TFLiteHelper() => _instance;
  TFLiteHelper._internal();

  Interpreter? _interpreter;
  List _labels = [];

  bool get isLoaded => _interpreter != null;

  Future loadModel() async {
    try {
      print('Loading model...');

      // Load interpreter
      _interpreter = await Interpreter.fromAsset(
        'assets/models/best_float32.tflite',
        options: InterpreterOptions()..threads = 4, // Use 4 threads
      );

      print('Model loaded successfully!');
      print('Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('Output shape: ${_interpreter!.getOutputTensor(0).shape}');

      // Load labels
      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData
          .split('\n')
          .where((element) => element.trim().isNotEmpty)
          .toList();

      print(' Labels loaded: ${_labels.length} classes');
      print(' Classes: $_labels');
    } catch (e) {
      print('Error loading model: $e');
      rethrow;
    }
  }

  Future<Map> runModel(File imageFile) async {
    if (_interpreter == null) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    try {
      // Read and decode image
      final rawBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(rawBytes);
      if (image == null) throw Exception("Invalid image format");

      // Resize to model input size (224x224)
      final resized = img.copyResize(image, width: 224, height: 224);

      // Prepare input tensor [1, 224, 224, 3] normalized to [0, 1]
      var input = List.generate(
        1,
        (_) => List.generate(
          224,
          (_) => List.generate(224, (_) => List.filled(3, 0.0)),
        ),
      );

      // Fill input with normalized RGB values
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pixel = resized.getPixel(x, y);
          input[0][y][x][0] = pixel.r / 255.0;
          input[0][y][x][1] = pixel.g / 255.0;
          input[0][y][x][2] = pixel.b / 255.0;
        }
      }

      // Prepare output tensor
      var output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

      // Run inference
      final startTime = DateTime.now();
      _interpreter!.run(input, output);
      final inferenceTime = DateTime.now().difference(startTime).inMilliseconds;

      print('Inference completed in ${inferenceTime}ms');
      print('Raw output: ${output[0]}');

      // Get results
      final probabilities = List.from(output[0]);
      final maxIndex = probabilities.indexOf(
        probabilities.reduce((a, b) => a > b ? a : b),
      );

      return {
        'class': _labels[maxIndex],
        'confidence': probabilities[maxIndex] * 100,
        'allProbabilities': {
          for (int i = 0; i < _labels.length; i++)
            _labels[i]: probabilities[i] * 100,
        },
        'inferenceTime': inferenceTime,
      };
    } catch (e) {
      print(' Error during inference: $e');
      rethrow;
    }
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
    print('Model closed');
  }
}
