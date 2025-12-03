import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';

class ModelLoader {
  static Interpreter? _interpreter;
  static List<String>? _labels;
  static String? _loadedModelPath;
  
  static Future<void> loadModel({String modelPath = 'assets/models/classifier_model.tflite'}) async {
    try {
      print('🔄 Loading model from: $modelPath');
      
      // Load model bytes to check size
      final modelData = await rootBundle.load(modelPath);
      final modelBytes = modelData.buffer.asUint8List();
      print('📦 Model size: ${(modelBytes.length / 1024 / 1024).toStringAsFixed(2)} MB');
      
      _interpreter = await Interpreter.fromAsset(modelPath);
      _loadedModelPath = modelPath;
      
      // Allocate tensors explicitly
      _interpreter!.allocateTensors();
      
      print('✓ Model loaded successfully');
      print('  Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('  Input type: ${_interpreter!.getInputTensor(0).type}');
      print('  Output shape: ${_interpreter!.getOutputTensor(0).shape}');
      print('  Output type: ${_interpreter!.getOutputTensor(0).type}');
      
      // Quick validation: run dummy inference
      await _validateModel();
      
      // Load labels
      _labels = await _loadLabels();
      print('✓ Labels loaded: ${_labels?.length} classes');
    } catch (e) {
      print('✗ Error loading model: $e');
      rethrow;
    }
  }
  
  /// Check if model is a classification model (2D output) vs detection (3D output)
  static bool get isClassificationModel {
    if (_interpreter == null) return false;
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    // Classification: [1, numClasses], Detection: [1, features, predictions]
    return outputShape.length == 2;
  }
  
  /// Run a quick validation inference on the loaded model
  static Future<void> _validateModel() async {
    if (_interpreter == null) return;
    
    try {
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      
      // Create dummy input
      final inputSize = inputShape.reduce((a, b) => a * b);
      final dummyInput = Float32List(inputSize);
      // Fill with mid-gray values (0.5)
      for (int i = 0; i < inputSize; i++) {
        dummyInput[i] = 0.5;
      }
      
      final input = dummyInput.reshape(inputShape);
      
      // Create output buffer based on output shape dimensions
      dynamic output;
      if (outputShape.length == 2) {
        // Classification model: [1, numClasses]
        output = List.generate(
          outputShape[0],
          (i) => List.filled(outputShape[1], 0.0),
        );
      } else if (outputShape.length == 3) {
        // Detection model: [1, features, predictions]
        output = List.generate(
          outputShape[0],
          (i) => List.generate(
            outputShape[1],
            (j) => List.filled(outputShape[2], 0.0),
          ),
        );
      } else {
        print('⚠️ Unexpected output shape: $outputShape');
        return;
      }
      
      final Map<int, Object> outputs = {0: output};
      
      // Run inference
      _interpreter!.runForMultipleInputs([input], outputs);

      print('🧪 Model Validation:');
      
      if (outputShape.length == 2) {
        // Classification model: [1, numClasses]
        final result = outputs[0] as List<List<double>>;
        final classScores = result[0];
        
        double maxScore = double.negativeInfinity;
        double minScore = double.infinity;
        int maxIndex = 0;
        
        for (int i = 0; i < classScores.length; i++) {
          if (classScores[i] > maxScore) {
            maxScore = classScores[i];
            maxIndex = i;
          }
          if (classScores[i] < minScore) minScore = classScores[i];
        }
        
        print('   📊 Classification model detected');
        print('   Class logits: min=${minScore.toStringAsFixed(4)}, max=${maxScore.toStringAsFixed(4)}');
        print('   Predicted class: $maxIndex');
        print('   ✅ Model outputs valid logits');
      } else {
        // Detection model: [1, features, predictions]
        final result = outputs[0] as List<List<List<double>>>;
        final features = result[0];
        
        double maxClassScore = double.negativeInfinity;
        double minClassScore = double.infinity;
        
        for (int row = 4; row < features.length; row++) {
          final classRow = features[row];
          for (final val in classRow) {
            if (val > maxClassScore) maxClassScore = val;
            if (val < minClassScore) minClassScore = val;
          }
        }
        
        print('   🎯 Detection model detected');
        print('   Class scores: min=${minClassScore.toStringAsFixed(4)}, max=${maxClassScore.toStringAsFixed(4)}');
        
        if (maxClassScore > 0.5) {
          print('   ✅ Model outputs meaningful predictions');
        } else if (maxClassScore > 0.1) {
          print('   ⚠️ Model outputs weak predictions (may need retraining)');
        } else {
          print('   ❌ Model outputs near-zero predictions (export may be broken)');
        }
      }
    } catch (e) {
      print('⚠️ Model validation failed: $e');
    }
  }
  
  static String? get loadedModelPath => _loadedModelPath;
  
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