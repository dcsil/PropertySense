from ultralytics import YOLO
import torch
import shutil
from pathlib import Path

# ============================================================
# HYPERPARAMETERS - Modify these to tune training
# ============================================================
EPOCHS = 10             # Number of training epochs
IMG_SIZE = 640          # Input image size
BATCH_SIZE = 16         # Batch size
LEARNING_RATE = 0.001   # Initial learning rate
# ============================================================

class HomeRepairYOLOTrainer:
    """Fine-tune YOLO for home repair detection"""
    
    def __init__(self, base_model: str = "yolov8n.pt"):
        self.model = YOLO(base_model)
        
    def train(self,
              data_yaml: str,
              epochs: int = EPOCHS,
              img_size: int = IMG_SIZE,
              batch_size: int = BATCH_SIZE):
        """Fine-tune YOLO on home repair dataset"""
        print("=" * 60)
        print("🚀 Training Model")
        print("=" * 60)
        print(f"Epochs: {epochs}, Image size: {img_size}, Batch: {batch_size}")
        print(f"Learning rate: {LEARNING_RATE}")
        print(f"Device: {'CUDA' if torch.cuda.is_available() else 'CPU'}")
        print("=" * 60)
        
        # Add callback to print clear accuracy metrics
        def on_fit_epoch_end(trainer):
            metrics = trainer.metrics
            epoch = trainer.epoch + 1
            map50 = metrics.get('metrics/mAP50(B)', 0)
            map50_95 = metrics.get('metrics/mAP50-95(B)', 0)
            box_loss = metrics.get('train/box_loss', 0)
            cls_loss = metrics.get('train/cls_loss', 0)
            
            print(f"\n📊 Epoch {epoch}/{epochs}: Accuracy={map50*100:.1f}% | mAP50-95={map50_95*100:.1f}% | BoxLoss={box_loss:.4f} | ClsLoss={cls_loss:.4f}\n")
        
        self.model.add_callback('on_fit_epoch_end', on_fit_epoch_end)
        
        results = self.model.train(
            data=data_yaml,
            epochs=epochs,
            imgsz=img_size,
            batch=batch_size,
            name="home_repair_detector",
            project="runs/train",
            optimizer="Adam",
            lr0=LEARNING_RATE,
            hsv_h=0.015,
            hsv_s=0.7,
            hsv_v=0.4,
            degrees=10.0,
            translate=0.1,
            scale=0.5,
            device=0 if torch.cuda.is_available() else "cpu",
            verbose=True
        )
        
        print("\n✅ Training complete!")
        final_acc = results.results_dict.get('metrics/mAP50(B)', 0)
        print(f"🎯 Final Accuracy: {final_acc*100:.1f}%")
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
    
    # Train (uses HYPERPARAMETERS from top of file)
    trainer.train(
        data_yaml=str(data_yaml),
        epochs=EPOCHS,
        img_size=IMG_SIZE,
        batch_size=BATCH_SIZE
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