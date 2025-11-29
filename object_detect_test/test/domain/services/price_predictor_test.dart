import 'package:flutter_test/flutter_test.dart';
import 'package:object_detect_test/domain/models/defect_detection.dart';
import 'package:object_detect_test/domain/services/price_predictor.dart';

void main() {
  late PricePredictor pricePredictor;

  setUp(() {
    pricePredictor = PricePredictor();
  });

  group('PricePredictor', () {
    group('predictSingle', () {
      test('should return DefectDetection with correct costs for known defect', () {
        // Act
        final result = pricePredictor.predictSingle(
          className: 'major_crack',
          confidence: 0.95,
        );

        // Assert
        expect(result, isA<DefectDetection>());
        expect(result.className, 'major_crack');
        expect(result.confidence, 0.95);
        expect(result.minCost, 1000);
        expect(result.maxCost, 2000);
        expect(result.avgCost, 1500);
      });

      test('should return DefectDetection with correct costs for algae', () {
        // Act
        final result = pricePredictor.predictSingle(
          className: 'algae',
          confidence: 0.87,
        );

        // Assert
        expect(result.className, 'algae');
        expect(result.minCost, 300);
        expect(result.maxCost, 600);
        expect(result.avgCost, 450);
      });

      test('should return DefectDetection with correct costs for minor_crack', () {
        // Act
        final result = pricePredictor.predictSingle(
          className: 'minor_crack',
          confidence: 0.92,
        );

        // Assert
        expect(result.className, 'minor_crack');
        expect(result.minCost, 400);
        expect(result.maxCost, 800);
        expect(result.avgCost, 600);
      });

      test('should return DefectDetection with correct costs for peeling', () {
        // Act
        final result = pricePredictor.predictSingle(
          className: 'peeling',
          confidence: 0.78,
        );

        // Assert
        expect(result.className, 'peeling');
        expect(result.minCost, 300);
        expect(result.maxCost, 800);
        expect(result.avgCost, 550);
      });

      test('should return DefectDetection with correct costs for spalling', () {
        // Act
        final result = pricePredictor.predictSingle(
          className: 'spalling',
          confidence: 0.85,
        );

        // Assert
        expect(result.className, 'spalling');
        expect(result.minCost, 25);
        expect(result.maxCost, 50);
        expect(result.avgCost, 38);
      });

      test('should return DefectDetection with correct costs for stain', () {
        // Act
        final result = pricePredictor.predictSingle(
          className: 'stain',
          confidence: 0.90,
        );

        // Assert
        expect(result.className, 'stain');
        expect(result.minCost, 150);
        expect(result.maxCost, 300);
        expect(result.avgCost, 225);
      });

      test('should return DefectDetection with zero costs for plain', () {
        // Act
        final result = pricePredictor.predictSingle(
          className: 'plain',
          confidence: 1.0,
        );

        // Assert
        expect(result.className, 'plain');
        expect(result.minCost, 0);
        expect(result.maxCost, 0);
        expect(result.avgCost, 0);
      });

      test('should return DefectDetection with zero costs for unknown defect class', () {
        // Act
        final result = pricePredictor.predictSingle(
          className: 'unknown_defect',
          confidence: 0.75,
        );

        // Assert
        expect(result.className, 'unknown_defect');
        expect(result.minCost, 0);
        expect(result.maxCost, 0);
        expect(result.avgCost, 0);
      });

      test('should include imagePath when provided', () {
        // Act
        final result = pricePredictor.predictSingle(
          className: 'major_crack',
          confidence: 0.95,
          imagePath: '/path/to/image.jpg',
        );

        // Assert
        expect(result.imagePath, '/path/to/image.jpg');
      });

      test('should have null imagePath when not provided', () {
        // Act
        final result = pricePredictor.predictSingle(
          className: 'major_crack',
          confidence: 0.95,
        );

        // Assert
        expect(result.imagePath, isNull);
      });
    });

    group('predictBatch', () {
      test('should return list of DefectDetection for multiple defects', () {
        // Arrange
        final detections = [
          {'class': 'major_crack', 'confidence': 0.95},
          {'class': 'minor_crack', 'confidence': 0.87},
          {'class': 'stain', 'confidence': 0.92},
        ];

        // Act
        final results = pricePredictor.predictBatch(detections);

        // Assert
        expect(results.length, 3);
        expect(results[0].className, 'major_crack');
        expect(results[0].minCost, 1000);
        expect(results[1].className, 'minor_crack');
        expect(results[1].minCost, 400);
        expect(results[2].className, 'stain');
        expect(results[2].minCost, 150);
      });

      test('should filter out plain defects', () {
        // Arrange
        final detections = [
          {'class': 'major_crack', 'confidence': 0.95},
          {'class': 'plain', 'confidence': 1.0},
          {'class': 'stain', 'confidence': 0.92},
        ];

        // Act
        final results = pricePredictor.predictBatch(detections);

        // Assert
        expect(results.length, 2);
        expect(results.any((r) => r.className == 'plain'), isFalse);
        expect(results[0].className, 'major_crack');
        expect(results[1].className, 'stain');
      });

      test('should handle empty list', () {
        // Arrange
        final detections = <Map<String, dynamic>>[];

        // Act
        final results = pricePredictor.predictBatch(detections);

        // Assert
        expect(results, isEmpty);
      });

      test('should handle list with only plain defects', () {
        // Arrange
        final detections = [
          {'class': 'plain', 'confidence': 1.0},
          {'class': 'plain', 'confidence': 1.0},
        ];

        // Act
        final results = pricePredictor.predictBatch(detections);

        // Assert
        expect(results, isEmpty);
      });

      test('should preserve confidence values', () {
        // Arrange
        final detections = [
          {'class': 'major_crack', 'confidence': 0.95},
          {'class': 'minor_crack', 'confidence': 0.50},
        ];

        // Act
        final results = pricePredictor.predictBatch(detections);

        // Assert
        expect(results[0].confidence, 0.95);
        expect(results[1].confidence, 0.50);
      });

      test('should include imagePath when provided in detection', () {
        // Arrange
        final detections = [
          {
            'class': 'major_crack',
            'confidence': 0.95,
            'imagePath': '/path/to/crack.jpg',
          },
        ];

        // Act
        final results = pricePredictor.predictBatch(detections);

        // Assert
        expect(results[0].imagePath, '/path/to/crack.jpg');
      });

      test('should handle all known defect types', () {
        // Arrange
        final detections = [
          {'class': 'algae', 'confidence': 0.8},
          {'class': 'major_crack', 'confidence': 0.9},
          {'class': 'minor_crack', 'confidence': 0.85},
          {'class': 'peeling', 'confidence': 0.75},
          {'class': 'spalling', 'confidence': 0.88},
          {'class': 'stain', 'confidence': 0.92},
        ];

        // Act
        final results = pricePredictor.predictBatch(detections);

        // Assert
        expect(results.length, 6);
        expect(results.map((r) => r.className).toSet(), {
          'algae',
          'major_crack',
          'minor_crack',
          'peeling',
          'spalling',
          'stain',
        });
      });
    });

    group('calculateTotal', () {
      test('should calculate total cost for multiple defects', () {
        // Arrange
        final detections = [
          DefectDetection(
            className: 'major_crack',
            confidence: 0.95,
            minCost: 1000,
            maxCost: 2000,
          ),
          DefectDetection(
            className: 'minor_crack',
            confidence: 0.87,
            minCost: 400,
            maxCost: 800,
          ),
          DefectDetection(
            className: 'stain',
            confidence: 0.92,
            minCost: 150,
            maxCost: 300,
          ),
        ];

        // Act
        final (min, max) = pricePredictor.calculateTotal(detections);

        // Assert
        expect(min, 1550); // 1000 + 400 + 150
        expect(max, 3100); // 2000 + 800 + 300
      });

      test('should return zero for empty list', () {
        // Arrange
        final detections = <DefectDetection>[];

        // Act
        final (min, max) = pricePredictor.calculateTotal(detections);

        // Assert
        expect(min, 0);
        expect(max, 0);
      });

      test('should handle single defect', () {
        // Arrange
        final detections = [
          DefectDetection(
            className: 'major_crack',
            confidence: 0.95,
            minCost: 1000,
            maxCost: 2000,
          ),
        ];

        // Act
        final (min, max) = pricePredictor.calculateTotal(detections);

        // Assert
        expect(min, 1000);
        expect(max, 2000);
      });

      test('should handle defects with zero cost', () {
        // Arrange
        final detections = [
          DefectDetection(
            className: 'plain',
            confidence: 1.0,
            minCost: 0,
            maxCost: 0,
          ),
          DefectDetection(
            className: 'major_crack',
            confidence: 0.95,
            minCost: 1000,
            maxCost: 2000,
          ),
        ];

        // Act
        final (min, max) = pricePredictor.calculateTotal(detections);

        // Assert
        expect(min, 1000);
        expect(max, 2000);
      });

      test('should calculate large totals correctly', () {
        // Arrange
        final detections = List.generate(
          10,
          (index) => DefectDetection(
            className: 'major_crack',
            confidence: 0.95,
            minCost: 1000,
            maxCost: 2000,
          ),
        );

        // Act
        final (min, max) = pricePredictor.calculateTotal(detections);

        // Assert
        expect(min, 10000); // 10 * 1000
        expect(max, 20000); // 10 * 2000
      });
    });
  });
}

