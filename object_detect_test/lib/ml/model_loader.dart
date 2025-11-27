import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';

class ModelLoader {
  static Interpreter? _interpreter;
  static List<String>? _labels;
  
  static Future<void> loadModel({String modelPath = 'assets/models/trained_model.tflite'}) async {
    try {
      _interpreter = await Interpreter.fromAsset(modelPath);
      
      // Allocate tensors explicitly
      _interpreter!.allocateTensors();
      
      print('✓ Model loaded successfully');
      print('  Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('  Input type: ${_interpreter!.getInputTensor(0).type}');
      print('  Output shape: ${_interpreter!.getOutputTensor(0).shape}');
      print('  Output type: ${_interpreter!.getOutputTensor(0).type}');
      
      // Load labels
      _labels = await _loadLabels();
      print('✓ Labels loaded: ${_labels?.length} classes');
    } catch (e) {
      print('✗ Error loading model: $e');
      rethrow;
    }
  }
  
  static Future<List<String>> _loadLabels() async {
    try {
    final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      return labelsData.split('\n').where((line) => line.trim().isNotEmpty).toList();
    } catch (e) {
      print('✗ Error loading labels: $e');
      rethrow;
    }
  }
  
  static Interpreter get interpreter {
    if (_interpreter == null) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }
    return _interpreter!;
  }
  
  static List<String> get labels {
    if (_labels == null) {
      throw StateError('Labels not loaded. Call loadModel() first.');
    }
    return _labels!;
  }
  
  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
  }
}