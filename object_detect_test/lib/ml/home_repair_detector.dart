import 'dart:typed_data';
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
  
  /// Process model output into detections
  /// Returns list of detections with label, confidence, and bbox
  List<Map<String, dynamic>> processOutput(
    List<dynamic> output, {
    double confidenceThreshold = 0.5,
    int maxDetections = 10,
  }) {
    final List<Map<String, dynamic>> detections = [];
    
    if (output.isEmpty) return detections;
    
    try {
      final batch = output[0] as List;
      
      for (var detection in batch) {
        if ((detection as List).length < 5 + labels.length) continue;
        
        // Extract bbox (center format)
        final cx = detection[0] as double;
        final cy = detection[1] as double;
        final w = detection[2] as double;
        final h = detection[3] as double;
        final objectness = detection[4] as double;
        
        // Find best class
        double maxScore = 0.0;
        int maxIndex = 0;
        
        for (int i = 5; i < detection.length; i++) {
          final score = detection[i] as double;
          if (score > maxScore) {
            maxScore = score;
            maxIndex = i - 5;
          }
        }
        
        // Calculate confidence
        final confidence = objectness * maxScore;
        if (confidence < confidenceThreshold) continue;
        
        // Get label
        final label = maxIndex < labels.length ? labels[maxIndex] : 'Unknown';
        
        // Convert to corner format [x, y, width, height] normalized
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
      
      // Sort by confidence and limit
      detections.sort((a, b) => 
        (b['confidence'] as double).compareTo(a['confidence'] as double));
      
      return detections.length > maxDetections 
          ? detections.sublist(0, maxDetections) 
          : detections;
          
    } catch (e) {
      print('Detection processing error: $e');
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

