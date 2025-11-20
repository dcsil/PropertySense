"""
Price prediction for home repair defects
Maps detected defects to repair cost estimates
"""

# ============================================================
# HARDCODED REPAIR COSTS (min, max in USD)
# ============================================================
REPAIR_COSTS = {
    'algae': (300, 600),
    'major_crack': (1000, 2000),
    'minor_crack': (400, 800),
    'peeling': (300, 800),
    'spalling': (25, 50),
    'stain': (150, 300),
    'plain': (0, 0)  # No defect
}


class PricePredictor:
    """Predict repair costs for detected defects"""
    
    def __init__(self):
        self.costs = REPAIR_COSTS
    
    def predict_single(self, defect_class: str, confidence: float = 1.0) -> dict:
        """
        Predict cost for a single defect
        
        Args:
            defect_class: One of the 7 classes (algae, major_crack, etc.)
            confidence: Detection confidence (0-1), optional
            
        Returns:
            dict with min_cost, max_cost, avg_cost
        """
        if defect_class not in self.costs:
            raise ValueError(f"Unknown defect class: {defect_class}")
        
        min_cost, max_cost = self.costs[defect_class]
        avg_cost = (min_cost + max_cost) / 2
        
        return {
            'defect': defect_class,
            'min_cost': min_cost,
            'max_cost': max_cost,
            'avg_cost': avg_cost,
            'confidence': confidence
        }
    
    def predict_batch(self, detections: list) -> dict:
        """
        Predict costs for multiple detections
        
        Args:
            detections: List of dicts with 'class' and optional 'confidence'
            Example: [{'class': 'major_crack', 'confidence': 0.95}, ...]
            
        Returns:
            dict with detailed report and total cost estimate
        """
        results = []
        total_min = 0
        total_max = 0
        
        for detection in detections:
            defect_class = detection.get('class')
            confidence = detection.get('confidence', 1.0)
            
            # Skip 'plain' (no defect)
            if defect_class == 'plain':
                continue
            
            result = self.predict_single(defect_class, confidence)
            results.append(result)
            
            total_min += result['min_cost']
            total_max += result['max_cost']
        
        return {
            'detections': results,
            'total_min_cost': total_min,
            'total_max_cost': total_max,
            'total_avg_cost': (total_min + total_max) / 2,
            'defect_count': len(results),
            'summary': self._generate_summary(results, total_min, total_max)
        }
    
    def _generate_summary(self, results: list, total_min: float, total_max: float) -> str:
        """Generate human-readable summary"""
        if not results:
            return "No defects detected. Property appears to be in good condition."
        
        summary_lines = [
            f"Detected {len(results)} defect(s):",
            ""
        ]
        
        for r in results:
            summary_lines.append(
                f"- {r['defect'].replace('_', ' ').title()}: "
                f"${r['min_cost']:.0f} - ${r['max_cost']:.0f} "
                f"(confidence: {r['confidence']*100:.1f}%)"
            )
        
        summary_lines.append("")
        summary_lines.append(
            f"Estimated Total Repair Cost: ${total_min:.0f} - ${total_max:.0f}"
        )
        
        return "\n".join(summary_lines)


# ============================================================
# EXAMPLE USAGE
# ============================================================
if __name__ == "__main__":
    predictor = PricePredictor()
    
    # Example: Detections from YOLO model
    sample_detections = [
        {'class': 'major_crack', 'confidence': 0.95},
        {'class': 'minor_crack', 'confidence': 0.87},
        {'class': 'peeling', 'confidence': 0.92},
        {'class': 'algae', 'confidence': 0.78}
    ]
    
    print("=" * 60)
    print("🏠 Home Repair Cost Prediction")
    print("=" * 60)
    
    report = predictor.predict_batch(sample_detections)
    
    print(report['summary'])
    print("\n" + "=" * 60)
    print(f"Defect Count: {report['defect_count']}")
    print(f"Average Estimate: ${report['total_avg_cost']:.0f}")
    print("=" * 60)

