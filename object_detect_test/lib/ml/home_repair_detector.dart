import 'dart:typed_data';
import 'dart:math' as math;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Home repair detector - handles both classification and detection models
class HomeRepairDetector {
  final Interpreter interpreter;
  final List<String> labels;
  final bool isClassificationModel;
  
  HomeRepairDetector({
    required this.interpreter,
    required this.labels,
    this.isClassificationModel = true,  // Default to classification
  });
  
  /// Process model output into detections/classifications
  /// 
  /// For CLASSIFICATION model: output is [1, numClasses] - class logits
  /// For DETECTION model: output is [1, 11, 2100] - bbox + class scores per anchor
  List<Map<String, dynamic>> processOutput(
    List<dynamic> output, {
    double confidenceThreshold = 0.25,
    int maxDetections = 10,
  }) {
    if (output.isEmpty) {
      print('⚠️ Output is empty');
      return [];
    }

    try {
      if (isClassificationModel) {
        return _processClassificationOutput(output, confidenceThreshold);
      } else {
        return _processDetectionOutput(output, confidenceThreshold, maxDetections);
      }
    } catch (e, stackTrace) {
      print('❌ Output processing error: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }
  
  /// Process classification model output [1, numClasses]
  List<Map<String, dynamic>> _processClassificationOutput(
    List<dynamic> output,
    double confidenceThreshold,
  ) {
    final classLogits = output[0] as List;
    final numClasses = classLogits.length;
    
    // Apply softmax to get probabilities
    final probabilities = _softmax(classLogits.cast<double>());
    
    // Find best class
    double maxProb = 0.0;
    int maxIndex = 0;
    
    for (int i = 0; i < numClasses; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        maxIndex = i;
      }
    }
    
    final label = maxIndex < labels.length ? labels[maxIndex] : 'class_$maxIndex';
    
    // Only return if above threshold
    if (maxProb < confidenceThreshold) {
      return [];
    }
    
    // Return single classification result with centered bbox
    // Using a smaller, centered box so label annotations are always visible
    // Bbox format: [x_min, y_min, width, height] in normalized coordinates
    return [{
      'label': label,
      'confidence': maxProb,
      'bbox': [0.0, 0.2, 1.0, 0.6],  // Centered 60% box
      'isClassification': true,
      'allProbabilities': Map.fromIterables(
        labels.take(numClasses),
        probabilities,
      ),
    }];
  }
  
  /// Apply softmax to convert logits to probabilities
  List<double> _softmax(List<double> logits) {
    // Find max for numerical stability
    final maxLogit = logits.reduce(math.max);
    
    // Compute exp(x - max) for each
    final expValues = logits.map((x) => math.exp(x - maxLogit)).toList();
    
    // Compute sum
    final sumExp = expValues.reduce((a, b) => a + b);
    
    // Normalize
    return expValues.map((x) => x / sumExp).toList();
  }
  
  /// Process detection model output [1, 11, 2100]
  List<Map<String, dynamic>> _processDetectionOutput(
    List<dynamic> output,
    double confidenceThreshold,
    int maxDetections,
  ) {
    final List<Map<String, dynamic>> detections = [];
    
    // Output shape: [1, 11, 2100] — transposed format
    final features = output[0] as List;
    final numFeatures = features.length;
    final numPredictions = (features[0] as List).length;
    
    final numClasses = numFeatures - 4;
    
    int belowThreshold = 0;
    
    for (int i = 0; i < numPredictions; i++) {
      final cx = (features[0] as List)[i] as double;
      final cy = (features[1] as List)[i] as double;
      final w = (features[2] as List)[i] as double;
      final h = (features[3] as List)[i] as double;
      
      double maxScore = 0.0;
      int maxIndex = 0;
      
      for (int c = 0; c < numClasses; c++) {
        final score = (features[4 + c] as List)[i] as double;
        if (score > maxScore) {
          maxScore = score;
          maxIndex = c;
        }
      }
      
      if (maxScore < confidenceThreshold) {
        belowThreshold++;
        continue;
      }
      
      final label = maxIndex < labels.length ? labels[maxIndex] : 'Unknown';
      
      detections.add({
        'label': label,
        'confidence': maxScore,
        'bbox': [
          (cx - w / 2).clamp(0.0, 1.0),
          (cy - h / 2).clamp(0.0, 1.0),
          w.clamp(0.0, 1.0),
          h.clamp(0.0, 1.0),
        ],
        'isClassification': false,
      });
    }

    detections.sort((a, b) =>
        (b['confidence'] as double).compareTo(a['confidence'] as double));

    return detections.length > maxDetections
        ? detections.sublist(0, maxDetections)
        : detections;
  }
  
  /// Preprocess image for model input
  Float32List preprocessImage(img.Image image, int inputSize) {
    // Resize to model input size
    final resized = img.copyResize(image, width: inputSize, height: inputSize);
    
    // Normalize [0-255] -> [0-1]
    final buffer = Float32List(1 * inputSize * inputSize * 3);
    int pixelIndex = 0;
    
    for (int h = 0; h < inputSize; h++) {
      for (int w = 0; w < inputSize; w++) {
        final pixel = resized.getPixel(w, h);
        buffer[pixelIndex++] = pixel.r / 255.0;
        buffer[pixelIndex++] = pixel.g / 255.0;
        buffer[pixelIndex++] = pixel.b / 255.0;
      }
    }
    
    return buffer;
  }
}

