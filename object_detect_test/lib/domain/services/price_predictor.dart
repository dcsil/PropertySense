import '../models/defect_detection.dart';

/// Price prediction service for home repair defects
class PricePredictor {
  // Hardcoded repair costs (min, max in USD)
  static const Map<String, (int, int)> _repairCosts = {
    'algae': (300, 600),
    'major_crack': (1000, 2000),
    'minor_crack': (400, 800),
    'peeling': (300, 800),
    'spalling': (25, 50),
    'stain': (150, 300),
    'plain': (0, 0),
  };

  /// Predict cost for a single defect
  DefectDetection predictSingle({
    required String className,
    required double confidence,
    String? imagePath,
  }) {
    final costs = _repairCosts[className] ?? (0, 0);
    
    return DefectDetection(
      className: className,
      confidence: confidence,
      minCost: costs.$1,
      maxCost: costs.$2,
      imagePath: imagePath,
    );
  }

  /// Predict costs for multiple detections
  List<DefectDetection> predictBatch(List<Map<String, dynamic>> detections) {
    return detections
        .where((d) => d['class'] != 'plain') // Skip "plain" (no defect)
        .map((d) => predictSingle(
              className: d['class'] as String,
              confidence: d['confidence'] as double,
              imagePath: d['imagePath'] as String?,
            ))
        .toList();
  }

  /// Calculate total cost estimate
  (int min, int max) calculateTotal(List<DefectDetection> detections) {
    int totalMin = 0;
    int totalMax = 0;

    for (final detection in detections) {
      totalMin += detection.minCost;
      totalMax += detection.maxCost;
    }

    return (totalMin, totalMax);
  }
}

