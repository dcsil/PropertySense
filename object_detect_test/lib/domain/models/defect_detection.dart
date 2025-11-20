/// Model for a detected defect with its cost estimate
class DefectDetection {
  final String className;
  final double confidence;
  final int minCost;
  final int maxCost;
  final String? imagePath; // Path to cropped defect image (optional)

  DefectDetection({
    required this.className,
    required this.confidence,
    required this.minCost,
    required this.maxCost,
    this.imagePath,
  });

  int get avgCost => ((minCost + maxCost) / 2).round();

  String get displayName {
    return className
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String get costRange => '\$$minCost - \$$maxCost';
}

