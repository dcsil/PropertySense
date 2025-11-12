from ultralytics import YOLO
import torch
from pathlib import Path

class HomeRepairYOLOTrainer:
    """Fine-tune YOLO for home repair detection"""
    
    def __init__(self, base_model: str = "yolov8n.pt"):
        self.model = YOLO(base_model)  # Start from pretrained YOLO
        
    def train(self,
              data_yaml: str,
              epochs: int = 100,
              img_size: int = 640,
              batch_size: int = 32):
        """
        Fine-tune YOLO on home repair dataset
        
        Args:
            data_yaml: Path to data.yaml defining dataset structure
            epochs: Number of training epochs
            img_size: Input image size
            batch_size: Batch size
        """
        results = self.model.train(
            data=data_yaml,
            epochs=epochs,
            imgsz=img_size,
            batch=batch_size,
            name="home_repair_detector",
            project="runs/train",
            optimizer="Adam",
            lr0=0.001,
            hsv_h=0.015,
            hsv_s=0.7,
            hsv_v=0.4,
            degrees=10.0,
            translate=0.1,
            scale=0.5,
            device=0 if torch.cuda.is_available() else "cpu"
        )
        
        return results
    
    def export_to_tflite(self, output_path: str):
        """Export trained model to TFLite format for Flutter"""
        self.model.export(
            format="tflite",
            imgsz=320,  # Smaller for mobile
            int8=True,   # Quantize for smaller size & faster inference
            save_dir=output_path
        )


def convert_to_tflite(saved_model_path: str, output_path: str, quantize: bool = True):
    """
    Convert existing model to TFLite format
    
    Args:
        saved_model_path: Path to saved TensorFlow model
        output_path: Where to save .tflite file
        quantize: Whether to apply int8 quantization
    """
    converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_path)
    
    if quantize:    # INT8 quantization - smaller size, faster inference
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_types = [tf.int8]
    
    tflite_model = converter.convert()
    
    output_file = Path(output_path)
    output_file.parent.mkdir(parents=True, exist_ok=True)
    output_file.write_bytes(tflite_model)