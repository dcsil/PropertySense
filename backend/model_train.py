from ultralytics import YOLO
import torch
import shutil
from pathlib import Path

class HomeRepairYOLOTrainer:
    """Fine-tune YOLO for home repair detection"""
    
    def __init__(self, base_model: str = "yolov8n.pt"):
        self.model = YOLO(base_model)
        
    def train(self,
              data_yaml: str,
              epochs: int = 50,
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
        print("=" * 60)
        print("🚀 Training Model")
        print("=" * 60)
        print(f"Epochs: {epochs}, Image size: {img_size}, Batch: {batch_size}")
        print(f"Device: {'CUDA' if torch.cuda.is_available() else 'CPU'}")
        print("=" * 60)
        
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
        
        print("\n✅ Training complete!")
        return results
    
    def deploy_to_flutter(self):
        """Export to TFLite and copy to Flutter assets"""
        print("\n" + "=" * 60)
        print("📦 Deploying to Flutter")
        print("=" * 60)
        
        # Export to TFLite
        print("Converting to TFLite...")
        export_path = self.model.export(
            format="tflite",
            imgsz=320,
            int8=False,  # Set True for smaller size
        )
        print(f"✅ TFLite created: {export_path}")
        
        # Copy to Flutter assets
        flutter_assets = Path(__file__).parent.parent / "object_detect_test" / "assets" / "models"
        flutter_assets.mkdir(parents=True, exist_ok=True)
        
        dest = flutter_assets / "trained_model.tflite"
        shutil.copy(export_path, dest)
        
        size_mb = dest.stat().st_size / 1024 / 1024
        print(f"✅ Deployed to: {dest}")
        print(f"📏 Size: {size_mb:.2f} MB")
        print("\n" + "=" * 60)
        print("✅ DONE! Update pubspec.yaml and restart Flutter app")
        print("=" * 60)


def train_and_deploy():
    """Main function: Train model and deploy to Flutter"""
    # Initialize trainer
    trainer = HomeRepairYOLOTrainer()
    
    # Train (requires data.yaml - see data_loading.py for dataset structure)
    data_yaml = Path(__file__).parent / "data.yaml"
    
    if not data_yaml.exists():
        print("⚠️  Creating placeholder data.yaml")
        create_data_yaml()
    
    # Train
    trainer.train(
        data_yaml=str(data_yaml),
        epochs=50,
        img_size=640,
        batch_size=16
    )
    
    # Deploy to Flutter
    trainer.deploy_to_flutter()


def create_data_yaml():
    """Create data.yaml for YOLO training"""
    data_dir = Path(__file__).parent / "data"
    yaml_content = f"""# Home Repair Dataset
path: {data_dir}
train: train/images
val: val/images

names:
  0: algae
  1: major_crack
  2: minor_crack
  3: peeling
  4: spalling
  5: stain
  6: plain

nc: 7
"""
    yaml_path = Path(__file__).parent / "data.yaml"
    yaml_path.write_text(yaml_content)
    print(f"Created: {yaml_path}")


if __name__ == "__main__":
    train_and_deploy()