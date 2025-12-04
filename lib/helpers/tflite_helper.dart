import 'dart:io';
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

  Future<void> loadModel() async {
    try {
      print('Loading model...');
      _interpreter = await Interpreter.fromAsset('assets/models/best_head_quant.tflite');
      print('Model loaded!');

      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData
          .split('\n')
          .where((element) => element.trim().isNotEmpty)
          .toList();
      print('Labels loaded: ${_labels.length}');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<List<double>> runModel(File imageFile) async {
    if (_interpreter == null) {
      print('Interpreter not initialized!');
      return [];
    }

    try {
      final rawBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(rawBytes);
      if (image == null) throw Exception("Invalid image");

      final resized = img.copyResize(image, width: 224, height: 224);

      var input = List.generate(
          1, (_) => List.generate(224, (_) => List.generate(224, (_) => List.filled(3, 0.0))));

      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pixel = resized.getPixel(x, y); // Pixel object
          input[0][y][x][0] = pixel.r / 255.0;
          input[0][y][x][1] = pixel.g / 255.0;
          input[0][y][x][2] = pixel.b / 255.0;
        }
      }

      var output = List.generate(1, (_) => List.filled(_labels.length, 0.0));
      _interpreter!.run(input, output);

      print('Inference done! Output: $output');
      return List<double>.from(output[0]);
    } catch (e) {
      print('Error running inference: $e');
      return [];
    }
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
  }
}
