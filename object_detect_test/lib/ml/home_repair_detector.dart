import 'dart:typed_data';
import 'dart:math' as math;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Minimal home repair detector - just processes model output
class HomeRepairDetector {
  final Interpreter interpreter;
  final List<String> labels;
  
  HomeRepairDetector({
    required this.interpreter,
    required this.labels,
  });
  
  /// Apply sigmoid activation to convert logits to probabilities
  double _sigmoid(double x) {
    return 1.0 / (1.0 + math.exp(-x));
  }
  
  /// Process model output into detections
  /// YOLOv8 TFLite output is TRANSPOSED: [1, 11, 2100] where:
  ///   - 11 = features (4 bbox + 7 class scores) — NO separate objectness in YOLOv8!
  ///   - 2100 = number of predictions
  /// Each column is one prediction, each row is one feature.
  List<Map<String, dynamic>> processOutput(
    List<dynamic> output, {
    double confidenceThreshold = 0.0,  // DEBUG: Set to 0 for debugging - show ALL detections
    int maxDetections = 10,
  }) {
    final List<Map<String, dynamic>> detections = [];

    if (output.isEmpty) {
      print('⚠️ Output is empty');
      return detections;
    }

    try {
      // Output shape: [1, 11, 2100] — transposed format
      final features = output[0] as List;  // 11 feature rows
      final numFeatures = features.length;  // Should be 11 (4 bbox + 7 classes)
      final numPredictions = (features[0] as List).length;  // Should be 2100
      
      print('🔍 DEBUG: Output shape [$numFeatures, $numPredictions] (transposed)');
      
      // YOLOv8 format: [cx, cy, w, h, class0, class1, ..., class6]
      // No separate objectness score — class scores ARE the confidence
      final numClasses = numFeatures - 4;  // 11 - 4 = 7 classes
      
      if (numClasses != labels.length) {
        print('⚠️ Class count mismatch: model has $numClasses, labels has ${labels.length}');
      }
      
      int belowThreshold = 0;
      
      // Iterate through each prediction (column)
      for (int i = 0; i < numPredictions; i++) {
        // Read features for prediction i (column i across all rows)
        final cx = (features[0] as List)[i] as double;
        final cy = (features[1] as List)[i] as double;
        final w = (features[2] as List)[i] as double;
        final h = (features[3] as List)[i] as double;
        
        // Find max class score (YOLOv8 outputs raw logits, need sigmoid!)
        double maxScore = 0.0;
        int maxIndex = 0;
        
        for (int c = 0; c < numClasses; c++) {
          final rawScore = (features[4 + c] as List)[i] as double;
          // Apply sigmoid to convert logits to probabilities
          final score = _sigmoid(rawScore);
          if (score > maxScore) {
            maxScore = score;
            maxIndex = c;
          }
        }
        
        // After sigmoid, this is the actual confidence
        final confidence = maxScore;
        
        // Debug first 3 predictions
        if (i < 3) {
          print('  Pred $i: cx=${cx.toStringAsFixed(3)}, cy=${cy.toStringAsFixed(3)}, w=${w.toStringAsFixed(3)}, h=${h.toStringAsFixed(3)}, conf=${confidence.toStringAsFixed(3)}, class=$maxIndex');
        }
        
        if (confidence < confidenceThreshold) {
          belowThreshold++;
          continue;
        }
        
        final label = maxIndex < labels.length ? labels[maxIndex] : 'Unknown';
        
        detections.add({
          'label': label,
          'confidence': confidence,
          'bbox': [
            (cx - w / 2).clamp(0.0, 1.0),
            (cy - h / 2).clamp(0.0, 1.0),
            w.clamp(0.0, 1.0),
            h.clamp(0.0, 1.0),
          ],
        });
      }
      
      print('📊 Processed $numPredictions predictions, $belowThreshold below threshold, ${detections.length} passed');

      // Sort by confidence and limit
      detections.sort((a, b) =>
          (b['confidence'] as double).compareTo(a['confidence'] as double));

      return detections.length > maxDetections
          ? detections.sublist(0, maxDetections)
          : detections;
    } catch (e, stackTrace) {
      print('❌ Detection processing error: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
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

