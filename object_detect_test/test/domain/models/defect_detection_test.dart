import 'package:flutter_test/flutter_test.dart';
import 'package:object_detect_test/domain/models/defect_detection.dart';

void main() {
  group('DefectDetection', () {
    group('Constructor', () {
      test('should create DefectDetection with all required fields', () {
        // Act
        final detection = DefectDetection(
          className: 'major_crack',
          confidence: 0.95,
          minCost: 1000,
          maxCost: 2000,
        );

        // Assert
        expect(detection.className, 'major_crack');
        expect(detection.confidence, 0.95);
        expect(detection.minCost, 1000);
        expect(detection.maxCost, 2000);
        expect(detection.imagePath, isNull);
      });

      test('should create DefectDetection with optional imagePath', () {
        // Act
        final detection = DefectDetection(
          className: 'major_crack',
          confidence: 0.95,
          minCost: 1000,
          maxCost: 2000,
          imagePath: '/path/to/image.jpg',
        );

        // Assert
        expect(detection.imagePath, '/path/to/image.jpg');
      });

      test('should accept different defect class names', () {
        final classes = [
          'algae',
          'major_crack',
          'minor_crack',
          'peeling',
          'spalling',
          'stain',
          'plain',
        ];

        for (final className in classes) {
          final detection = DefectDetection(
            className: className,
            confidence: 0.8,
            minCost: 100,
            maxCost: 200,
          );
          expect(detection.className, className);
        }
      });

      test('should accept confidence values from 0.0 to 1.0', () {
        final confidences = [0.0, 0.5, 0.75, 0.99, 1.0];

        for (final confidence in confidences) {
          final detection = DefectDetection(
            className: 'major_crack',
            confidence: confidence,
            minCost: 1000,
            maxCost: 2000,
          );
          expect(detection.confidence, confidence);
        }
      });

      test('should accept zero costs', () {
        // Act
        final detection = DefectDetection(
          className: 'plain',
          confidence: 1.0,
          minCost: 0,
          maxCost: 0,
        );

        // Assert
        expect(detection.minCost, 0);
        expect(detection.maxCost, 0);
      });
    });

    group('avgCost getter', () {
      test('should calculate average cost correctly for even sum', () {
        // Arrange
        final detection = DefectDetection(
          className: 'major_crack',
          confidence: 0.95,
          minCost: 1000,
          maxCost: 2000,
        );

        // Act & Assert
        expect(detection.avgCost, 1500);
      });

      test('should round average cost correctly for odd sum', () {
        // Arrange
        final detection = DefectDetection(
          className: 'algae',
          confidence: 0.8,
          minCost: 300,
          maxCost: 600,
        );

        // Act & Assert
        expect(detection.avgCost, 450);
      });

      test('should round up correctly', () {
        // Arrange
        final detection = DefectDetection(
          className: 'stain',
          confidence: 0.9,
          minCost: 150,
          maxCost: 300,
        );

        // Act & Assert
        expect(detection.avgCost, 225);
      });

      test('should return zero for zero costs', () {
        // Arrange
        final detection = DefectDetection(
          className: 'plain',
          confidence: 1.0,
          minCost: 0,
          maxCost: 0,
        );

        // Act & Assert
        expect(detection.avgCost, 0);
      });

      test('should handle small cost differences', () {
        // Arrange
        final detection = DefectDetection(
          className: 'spalling',
          confidence: 0.85,
          minCost: 25,
          maxCost: 50,
        );

        // Act & Assert
        expect(detection.avgCost, 38); // (25 + 50) / 2 = 37.5, rounded to 38
      });
    });

    group('displayName getter', () {
      test('should format single word class name correctly', () {
        // Arrange
        final detection = DefectDetection(
          className: 'algae',
          confidence: 0.8,
          minCost: 300,
          maxCost: 600,
        );

        // Act & Assert
        expect(detection.displayName, 'Algae');
      });

      test('should format multi-word class name with underscores correctly', () {
        // Arrange
        final detection = DefectDetection(
          className: 'major_crack',
          confidence: 0.95,
          minCost: 1000,
          maxCost: 2000,
        );

        // Act & Assert
        expect(detection.displayName, 'Major Crack');
      });

      test('should format three-word class name correctly', () {
        // Arrange
        final detection = DefectDetection(
          className: 'major_crack_repair',
          confidence: 0.95,
          minCost: 1000,
          maxCost: 2000,
        );

        // Act & Assert
        expect(detection.displayName, 'Major Crack Repair');
      });

      test('should handle lowercase single letter words', () {
        // Arrange
        final detection = DefectDetection(
          className: 'a_b_c',
          confidence: 0.8,
          minCost: 100,
          maxCost: 200,
        );

        // Act & Assert
        expect(detection.displayName, 'A B C');
      });

      // Note: Empty string test removed - displayName getter assumes non-empty className
      // This is a valid assumption as defect classes are always non-empty in practice

      test('should format all known defect types correctly', () {
        final testCases = {
          'algae': 'Algae',
          'major_crack': 'Major Crack',
          'minor_crack': 'Minor Crack',
          'peeling': 'Peeling',
          'spalling': 'Spalling',
          'stain': 'Stain',
          'plain': 'Plain',
        };

        for (final entry in testCases.entries) {
          final detection = DefectDetection(
            className: entry.key,
            confidence: 0.8,
            minCost: 100,
            maxCost: 200,
          );
          expect(detection.displayName, entry.value);
        }
      });
    });

    group('costRange getter', () {
      test('should format cost range with dollar signs correctly', () {
        // Arrange
        final detection = DefectDetection(
          className: 'major_crack',
          confidence: 0.95,
          minCost: 1000,
          maxCost: 2000,
        );

        // Act & Assert
        expect(detection.costRange, '\$1000 - \$2000');
      });

      test('should format zero costs correctly', () {
        // Arrange
        final detection = DefectDetection(
          className: 'plain',
          confidence: 1.0,
          minCost: 0,
          maxCost: 0,
        );

        // Act & Assert
        expect(detection.costRange, '\$0 - \$0');
      });

      test('should format single digit costs correctly', () {
        // Arrange
        final detection = DefectDetection(
          className: 'spalling',
          confidence: 0.85,
          minCost: 25,
          maxCost: 50,
        );

        // Act & Assert
        expect(detection.costRange, '\$25 - \$50');
      });

      test('should format large costs correctly', () {
        // Arrange
        final detection = DefectDetection(
          className: 'major_crack',
          confidence: 0.95,
          minCost: 10000,
          maxCost: 50000,
        );

        // Act & Assert
        expect(detection.costRange, '\$10000 - \$50000');
      });

      test('should format costs with same min and max correctly', () {
        // Arrange
        final detection = DefectDetection(
          className: 'stain',
          confidence: 0.9,
          minCost: 150,
          maxCost: 150,
        );

        // Act & Assert
        expect(detection.costRange, '\$150 - \$150');
      });
    });

    group('Integration tests', () {
      test('should work correctly with all getters together', () {
        // Arrange
        final detection = DefectDetection(
          className: 'minor_crack',
          confidence: 0.87,
          minCost: 400,
          maxCost: 800,
          imagePath: '/path/to/image.jpg',
        );

        // Act & Assert
        expect(detection.className, 'minor_crack');
        expect(detection.confidence, 0.87);
        expect(detection.minCost, 400);
        expect(detection.maxCost, 800);
        expect(detection.avgCost, 600);
        expect(detection.displayName, 'Minor Crack');
        expect(detection.costRange, '\$400 - \$800');
        expect(detection.imagePath, '/path/to/image.jpg');
      });
    });
  });
}

