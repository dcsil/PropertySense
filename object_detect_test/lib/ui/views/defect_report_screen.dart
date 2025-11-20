import 'package:flutter/material.dart';
import '../../domain/models/defect_detection.dart';
import '../../domain/services/price_predictor.dart';

class DefectReportScreen extends StatelessWidget {
  final List<DefectDetection> detections;

  const DefectReportScreen({
    super.key,
    required this.detections,
  });

  @override
  Widget build(BuildContext context) {
    final pricePredictor = PricePredictor();
    final (totalMin, totalMax) = pricePredictor.calculateTotal(detections);
    final avgTotal = ((totalMin + totalMax) / 2).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Defect Report'),
        backgroundColor: Colors.blue,
      ),
      body: detections.isEmpty
          ? _buildNoDefectsView()
          : Column(
              children: [
                // Total cost summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: Column(
                    children: [
                      Text(
                        'Total Repair Estimate',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$$totalMin - \$$totalMax',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Average: \$$avgTotal',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${detections.length} defect(s) detected',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
                // List of defects
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: detections.length,
                    itemBuilder: (context, index) {
                      return _buildDefectCard(context, detections[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNoDefectsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade300),
          const SizedBox(height: 16),
          const Text(
            'No Defects Detected',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Property appears to be in good condition',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildDefectCard(BuildContext context, DefectDetection detection) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder for defect image (can be replaced with actual image later)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 40,
                color: _getDefectColor(detection.className),
              ),
            ),
            const SizedBox(width: 16),
            // Defect details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detection.displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      detection.costRange,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Avg: \$${detection.avgCost}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDefectColor(String className) {
    switch (className) {
      case 'major_crack':
        return Colors.red;
      case 'minor_crack':
        return Colors.orange;
      case 'spalling':
        return Colors.deepOrange;
      case 'peeling':
        return Colors.amber;
      case 'algae':
        return Colors.green;
      case 'stain':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}

