from ultralytics import YOLO
import torch
import shutil
import numpy as np
from pathlib import Path

# ============================================================
# HYPERPARAMETERS
# ============================================================
EPOCHS = 10             # this takes like 2.5 hours
IMG_SIZE = 320          # Smaller images = objects appear larger at all scales
BATCH_SIZE = 16         # Batch size
LEARNING_RATE = 0.001   # Initial learning rate
LR_FINAL_RATIO = 0.1    # Final LR ratio
WARMUP_EPOCHS = 3       # Warmup epochs
WEIGHT_DECAY = 1e-5     # Low weight decay

# MODEL TYPE: "classify" or "detect"
# Use "classify" if your data has full-image bounding boxes (class labels only)
# Use "detect" if you have actual localized bounding boxes
MODEL_TYPE = "classify"  # <-- CHANGE THIS BASED ON YOUR DATA
# ============================================================

class HomeRepairClassifier:
    """Train YOLOv8 for IMAGE CLASSIFICATION (not detection)
    
    Use this when your data has class labels per image, not localized bounding boxes.
    This avoids the weight collapse issue entirely since classification models
    don't have multi-scale detection heads.
    """
    
    def __init__(self, base_model: str = "yolov8n-cls.pt"):
        """Initialize with classification model"""
        self.model = YOLO(base_model)
        print(f"📦 Loaded classification model: {base_model}")
    
    def prepare_classification_data(self):
        """Convert detection-format data to classification format
        
        Classification format expects:
        data/
          train/
            class_name/
              image1.jpg
              image2.jpg
          val/
            class_name/
              image1.jpg
        """
        data_dir = Path(__file__).parent / "data"
        cls_data_dir = Path(__file__).parent / "data_cls"
        
        if cls_data_dir.exists():
            print(f"📁 Classification data already exists at {cls_data_dir}")
            return cls_data_dir
        
        print("🔄 Converting detection data to classification format...")
        
        # Class names from data.yaml
        class_names = ['algae', 'major_crack', 'minor_crack', 'peeling', 'spalling', 'stain', 'plain']
        
        for split in ['train', 'val']:
            images_dir = data_dir / split / 'images'
            labels_dir = data_dir / split / 'labels'
            
            if not images_dir.exists():
                print(f"⚠️  {images_dir} not found")
                continue
            
            # Create class directories
            for class_name in class_names:
                (cls_data_dir / split / class_name).mkdir(parents=True, exist_ok=True)
            
            # Process each image
            for img_path in images_dir.glob('*.[jJ][pP][gG]'):
                label_path = labels_dir / f"{img_path.stem}.txt"
                
                if label_path.exists():
                    # Read class from label file
                    with open(label_path) as f:
                        line = f.readline().strip()
                        if line:
                            class_id = int(line.split()[0])
                            class_name = class_names[class_id]
                            
                            # Copy image to class directory
                            dest = cls_data_dir / split / class_name / img_path.name
                            shutil.copy(img_path, dest)
            
            # Count images per class
            print(f"\n📊 {split} split:")
            for class_name in class_names:
                count = len(list((cls_data_dir / split / class_name).glob('*')))
                print(f"   {class_name}: {count} images")
        
        print(f"\n✅ Classification data created at: {cls_data_dir}")
        return cls_data_dir
    
    def train(self, epochs: int = EPOCHS, img_size: int = IMG_SIZE, batch_size: int = BATCH_SIZE):
        """Train classification model"""
        print("=" * 60)
        print("🚀 Training IMAGE CLASSIFICATION Model")
        print("=" * 60)
        print("This model classifies entire images, not localized objects.")
        print("This avoids the multi-scale detection head weight collapse issue.")
        print("=" * 60)
        
        # Prepare data
        data_dir = self.prepare_classification_data()
        
        # Determine device
        if torch.cuda.is_available():
            device = 0
        elif torch.backends.mps.is_available():
            device = "mps"
        else:
            device = "cpu"
        
        print(f"\nDevice: {device}")
        print(f"Epochs: {epochs}, Image size: {img_size}, Batch: {batch_size}")
        
        results = self.model.train(
            data=str(data_dir),
            epochs=epochs,
            imgsz=img_size,
            batch=batch_size,
            name="home_repair_classifier",
            project="runs/classify",
            lr0=LEARNING_RATE,
            lrf=LR_FINAL_RATIO,
            warmup_epochs=WARMUP_EPOCHS,
            weight_decay=WEIGHT_DECAY,
            device=device,
            verbose=True,
            exist_ok=True,
        )
        
        print("\n✅ Classification training complete!")
        return results
    
    def deploy_to_flutter(self, weights_path: str = None):
        """Export classification model to TFLite"""
        print("\n" + "=" * 60)
        print("📦 Deploying Classification Model to Flutter")
        print("=" * 60)
        
        if weights_path is None:
            runs_dir = Path(__file__).parent / "runs" / "classify"
            detector_dirs = sorted(runs_dir.glob("home_repair_classifier*"), reverse=True)
            if detector_dirs:
                weights_path = detector_dirs[0] / "weights" / "best.pt"
        
        if weights_path and Path(weights_path).exists():
            print(f"📥 Loading weights: {weights_path}")
            self.model = YOLO(str(weights_path))
        
        # Export to TFLite
        print("\nConverting to TFLite...")
        export_path = self.model.export(
            format="tflite",
            imgsz=IMG_SIZE,
            int8=False,
        )
        print(f"✅ TFLite created: {export_path}")
        
        # Copy to Flutter assets
        export_path = Path(export_path)
        if export_path.is_dir():
            tflite_files = list(export_path.rglob("*.tflite"))
            if tflite_files:
                export_path = tflite_files[0]
        
        flutter_assets = Path(__file__).parent.parent / "object_detect_test" / "assets" / "models"
        flutter_assets.mkdir(parents=True, exist_ok=True)
        
        dest = flutter_assets / "classifier_model.tflite"
        shutil.copy(export_path, dest)
        
        print(f"✅ Deployed to: {dest}")
        print(f"📏 Size: {dest.stat().st_size / 1024 / 1024:.2f} MB")
        
        # Validate
        self._validate_tflite(dest)
    
    def _validate_tflite(self, tflite_path):
        """Validate classification TFLite model"""
        try:
            import tensorflow as tf
        except ImportError:
            print("⚠️  TensorFlow not installed, skipping validation")
            return
        
        try:
            interpreter = tf.lite.Interpreter(model_path=str(tflite_path))
            interpreter.allocate_tensors()
            
            input_details = interpreter.get_input_details()
            output_details = interpreter.get_output_details()
            
            print(f"\n📥 Input shape: {input_details[0]['shape']}")
            print(f"📤 Output shape: {output_details[0]['shape']}")
            
            # Test inference
            input_shape = input_details[0]['shape']
            test_input = np.random.rand(*input_shape).astype(np.float32)
            
            interpreter.set_tensor(input_details[0]['index'], test_input)
            interpreter.invoke()
            output = interpreter.get_tensor(output_details[0]['index'])
            
            print(f"\n🔍 Test Inference:")
            print(f"   Output shape: {output.shape}")
            print(f"   Output range: min={output.min():.4f}, max={output.max():.4f}")
            
            # Softmax to get probabilities
            exp_out = np.exp(output - output.max())
            probs = exp_out / exp_out.sum()
            
            print(f"   After softmax: min={probs.min():.4f}, max={probs.max():.4f}")
            
            if probs.max() > 0.2:
                print("\n✅ Classification model is working!")
            else:
                print("\n⚠️  Output probabilities seem uniform. Check model.")
                
        except Exception as e:
            print(f"❌ Validation failed: {e}")


class HomeRepairYOLOTrainer:
    """Fine-tune YOLO for home repair detection"""
    
    def __init__(self, base_model: str = "yolov8n.pt"):
        self.model = YOLO(base_model)
        
    def train(self,
              data_yaml: str,
              epochs: int = EPOCHS,
              img_size: int = IMG_SIZE,
              batch_size: int = BATCH_SIZE):
        """Fine-tune YOLO on home repair dataset
        
        IMPORTANT: This config is tuned to PREVENT WEIGHT COLLAPSE.
        See MODEL_DEBUG_LOG.md for why previous training failed.
        """
        print("=" * 60)
        print("🚀 Training Model")
        print("=" * 60)
        print(f"Epochs: {epochs}, Image size: {img_size}, Batch: {batch_size}")
        print(f"Learning rate: {LEARNING_RATE} → {LEARNING_RATE * LR_FINAL_RATIO} (final)")
        print(f"Weight decay: {WEIGHT_DECAY} (low to prevent collapse)")
        print(f"Multi-scale: {MULTI_SCALE}, Scale range: {SCALE_RANGE}")
        print(f"Warmup epochs: {WARMUP_EPOCHS}")
        print(f"Device: {'CUDA' if torch.cuda.is_available() else 'MPS' if torch.backends.mps.is_available() else 'CPU'}")
        print("=" * 60)
        
        # Add callback to print clear accuracy metrics AND monitor weight health
        def on_fit_epoch_end(trainer):
            metrics = trainer.metrics
            epoch = trainer.epoch + 1
            map50 = metrics.get('metrics/mAP50(B)', 0)
            map50_95 = metrics.get('metrics/mAP50-95(B)', 0)
            box_loss = metrics.get('train/box_loss', 0)
            cls_loss = metrics.get('train/cls_loss', 0)
            
            print(f"\n📊 Epoch {epoch}/{epochs}: Accuracy={map50*100:.1f}% | mAP50-95={map50_95*100:.1f}% | BoxLoss={box_loss:.4f} | ClsLoss={cls_loss:.4f}")
            
            # Check weight health every 10 epochs
            if epoch % 5 == 0 or epoch == epochs:
                self._check_weight_health(trainer.model, epoch)
            print()
        
        self.model.add_callback('on_fit_epoch_end', on_fit_epoch_end)
        
        # Determine device
        if torch.cuda.is_available():
            device = 0
        elif torch.backends.mps.is_available():
            device = "mps"
        else:
            device = "cpu"
        
        results = self.model.train(
            data=data_yaml,
            epochs=epochs,
            imgsz=img_size,
            batch=batch_size,
            name="home_repair_detector",
            project="runs/train",
            
            # Optimizer settings (CRITICAL for preventing weight collapse)
            optimizer="SGD",        # SGD more stable than Adam for fine-tuning
            lr0=LEARNING_RATE,      # Initial learning rate
            lrf=LR_FINAL_RATIO,     # Final LR ratio (prevents aggressive decay)
            momentum=0.9,           # Standard momentum
            weight_decay=WEIGHT_DECAY,  # LOW weight decay to prevent collapse
            warmup_epochs=WARMUP_EPOCHS,  # Warmup for stable gradients
            
            # Multi-scale training (CRITICAL for all detection heads)
            multi_scale=MULTI_SCALE,  # Vary image size during training
            
            # Data augmentation (aggressive scale to train all heads)
            hsv_h=0.015,
            hsv_s=0.7,
            hsv_v=0.4,
            degrees=15.0,           # Slight rotation
            translate=0.2,          # Translation
            scale=SCALE_RANGE,      # AGGRESSIVE scale augmentation
            fliplr=0.5,             # Horizontal flip
            mosaic=1.0,             # Mosaic augmentation (creates multi-scale objects)
            mixup=0.1,              # Light mixup for regularization
            copy_paste=0.1,         # Copy-paste augmentation
            
            # Training settings
            freeze=FREEZE_LAYERS,   # Don't freeze - train everything
            patience=10,            # Early stopping patience
            save_period=3,         # Save checkpoint every 3 epochs
            
            device=device,
            verbose=True,
            exist_ok=True,          # Overwrite existing run
        )
        
        print("\n✅ Training complete!")
        final_acc = results.results_dict.get('metrics/mAP50(B)', 0)
        print(f"🎯 Final Accuracy: {final_acc*100:.1f}%")
        
        # Final weight health check
        print("\n" + "=" * 60)
        print("🔬 Final Weight Health Check")
        print("=" * 60)
        self._check_weight_health_detailed()
        
        return results
    
    def _check_weight_health(self, model, epoch):
        """Quick weight health check during training"""
        try:
            detect = None
            for m in model.modules():
                if type(m).__name__ == 'Detect':
                    detect = m
                    break
            
            if detect is None:
                return
            
            # Check cv3 (classification head) weights
            cv3_healthy = True
            for i, cv3 in enumerate(detect.cv3):
                for j, block in enumerate(cv3):
                    if hasattr(block, 'conv') and hasattr(block.conv, 'weight'):
                        w = block.conv.weight.data
                        w_range = w.abs().max().item()
                        if w_range < 0.001:
                            cv3_healthy = False
                            print(f"   ⚠️  cv3.{i}.{j} weights near zero! (max={w_range:.6f})")
            
            if cv3_healthy:
                print(f"   ✅ All cv3 weights healthy at epoch {epoch}")
        except Exception as e:
            pass  # Don't interrupt training for monitoring errors
    
    def _check_weight_health_detailed(self):
        """Detailed weight health check after training"""
        try:
            # Load the best weights
            runs_dir = Path(__file__).parent / "runs" / "train"
            detector_dirs = sorted(runs_dir.glob("home_repair_detector*"), reverse=True)
            if not detector_dirs:
                print("   No training runs found")
                return
            
            weights_path = detector_dirs[0] / "weights" / "best.pt"
            if not weights_path.exists():
                print(f"   Weights not found: {weights_path}")
                return
            
            model = YOLO(str(weights_path))
            
            # Find Detect module
            detect = None
            for m in model.model.modules():
                if type(m).__name__ == 'Detect':
                    detect = m
                    break
            
            if detect is None:
                print("   Could not find Detect module")
                return
            
            print("Classification head (cv3) weight ranges:")
            all_healthy = True
            
            for i, cv3 in enumerate(detect.cv3):
                scale_name = ["small", "medium", "large"][i] if i < 3 else f"scale{i}"
                print(f"\n   Scale {i} ({scale_name} objects):")
                
                for j, block in enumerate(cv3):
                    if hasattr(block, 'conv') and hasattr(block.conv, 'weight'):
                        w = block.conv.weight.data
                        w_min, w_max = w.min().item(), w.max().item()
                        w_std = w.std().item()
                        
                        status = "✅" if abs(w_max - w_min) > 0.01 else "❌ COLLAPSED"
                        if abs(w_max - w_min) <= 0.01:
                            all_healthy = False
                        
                        print(f"      cv3.{i}.{j}: range=[{w_min:.4f}, {w_max:.4f}], std={w_std:.4f} {status}")
            
            print()
            if all_healthy:
                print("   ✅ All classification head weights are healthy!")
                print("   The model should export correctly to ONNX/TFLite.")
            else:
                print("   ❌ Some weights have collapsed! Export will likely fail.")
                print("   Try: longer training, more multi-scale data, or lower weight_decay")
                
        except Exception as e:
            print(f"   Weight check failed: {e}")
            import traceback
            traceback.print_exc()
    
    def deploy_to_flutter(self, weights_path: str = None):
        """Export to TFLite and copy to Flutter assets"""
        print("\n" + "=" * 60)
        print("📦 Deploying to Flutter")
        print("=" * 60)
        
        # Find and load best weights explicitly
        if weights_path is None:
            # Look for most recent training run
            runs_dir = Path(__file__).parent / "runs" / "train"
            if runs_dir.exists():
                # Find latest home_repair_detector folder
                detector_dirs = sorted(runs_dir.glob("home_repair_detector*"), reverse=True)
                if detector_dirs:
                    weights_path = detector_dirs[0] / "weights" / "best.pt"
        
        if weights_path and Path(weights_path).exists():
            print(f"📥 Loading best weights: {weights_path}")
            self.model = YOLO(str(weights_path))
            
            # Quick PyTorch validation before export
            print("🧪 Testing PyTorch model first...")
            test_img = np.random.randint(0, 255, (320, 320, 3), dtype=np.uint8)
            results = self.model(test_img, verbose=False)
            print(f"   PyTorch test: {len(results[0].boxes)} detections")
            if hasattr(results[0], 'boxes') and len(results[0].boxes) > 0:
                confs = results[0].boxes.conf.cpu().numpy()
                print(f"   Confidence range: {confs.min():.3f} - {confs.max():.3f}")
        else:
            print(f"⚠️ No weights file found, using model in memory")
        
        # Export to TFLite
        print("\nConverting to TFLite...")
        export_path = self.model.export(
            format="tflite",
            imgsz=320,
            int8=False,  # float32 for accuracy
        )
        print(f"✅ TFLite created: {export_path}")
        
        # Handle case where export_path is a directory
        export_path = Path(export_path)
        if export_path.is_dir():
            tflite_files = list(export_path.rglob("*.tflite"))
            if tflite_files:
                export_path = tflite_files[0]
                print(f"📄 Found TFLite in directory: {export_path}")
            else:
                print("❌ No TFLite file found in export directory!")
                return
        
        # Copy to Flutter assets
        flutter_assets = Path(__file__).parent.parent / "object_detect_test" / "assets" / "models"
        flutter_assets.mkdir(parents=True, exist_ok=True)
        
        dest = flutter_assets / "new_trained_model.tflite"
        shutil.copy(export_path, dest)
        
        size_mb = dest.stat().st_size / 1024 / 1024
        print(f"✅ Deployed to: {dest}")
        print(f"📏 Size: {size_mb:.2f} MB")
        
        # Run validation
        self._validate_tflite(dest)
        
        print("\n" + "=" * 60)
        print("✅ DONE! Update pubspec.yaml and restart Flutter app")
        print("=" * 60)
    
    def _validate_tflite(self, tflite_path):
        """Validate TFLite model by running test inference"""
        print("\n" + "=" * 60)
        print("🧪 Validating TFLite Export")
        print("=" * 60)
        
        try:
            import tensorflow as tf
        except ImportError:
            print("⚠️  TensorFlow not installed, skipping validation")
            print("   Install with: pip install tensorflow")
            return
        
        try:
            # Load TFLite model
            interpreter = tf.lite.Interpreter(model_path=str(tflite_path))
            interpreter.allocate_tensors()
            
            input_details = interpreter.get_input_details()
            output_details = interpreter.get_output_details()
            
            print(f"📥 Input shape: {input_details[0]['shape']}")
            print(f"📥 Input dtype: {input_details[0]['dtype']}")
            print(f"📤 Output shape: {output_details[0]['shape']}")
            print(f"📤 Output dtype: {output_details[0]['dtype']}")
            
            # Create test input (random image)
            input_shape = input_details[0]['shape']
            test_input = np.random.rand(*input_shape).astype(np.float32)
            
            # Run inference
            interpreter.set_tensor(input_details[0]['index'], test_input)
            interpreter.invoke()
            output = interpreter.get_tensor(output_details[0]['index'])
            
            print(f"\n🔍 Test Inference Results:")
            print(f"   Output shape: {output.shape}")
            print(f"   Output range: min={output.min():.6f}, max={output.max():.6f}")
            
            # Check class scores (rows 4-10 for 7 classes)
            if len(output.shape) == 3 and output.shape[1] >= 11:
                class_scores = output[0, 4:, :]  # Get class score rows
                print(f"   Class scores shape: {class_scores.shape}")
                print(f"   Class scores range: min={class_scores.min():.6f}, max={class_scores.max():.6f}")
                
                # Apply sigmoid to see actual probabilities
                def sigmoid(x):
                    return 1.0 / (1.0 + np.exp(-np.clip(x, -500, 500)))
                
                class_probs = sigmoid(class_scores)
                print(f"   After sigmoid: min={class_probs.min():.6f}, max={class_probs.max():.6f}")
                
                # Check if model is actually outputting meaningful values
                if class_probs.max() > 0.6:
                    print("\n✅ Model appears to be working! Class probabilities > 0.6 detected.")
                elif class_probs.max() > 0.52:
                    print("\n⚠️  Model outputs weak predictions (max prob ~0.5). May need retraining.")
                else:
                    print("\n❌ Model outputs near-zero class scores. Export may be broken!")
                    print("   All predictions have ~50% confidence (random). Check:")
                    print("   1. Training actually converged (check loss/accuracy)")
                    print("   2. Try different export settings")
                    print("   3. The trained weights file is being used")
            else:
                print(f"⚠️  Unexpected output shape: {output.shape}")
                
        except Exception as e:
            print(f"❌ Validation failed: {e}")
            import traceback
            traceback.print_exc()


def train_and_deploy():
    """Main function: Train model and deploy to Flutter
    
    Uses MODEL_TYPE setting to choose between:
    - "classify": Image classification (recommended for full-image labels)
    - "detect": Object detection (requires localized bounding boxes)
    """
    
    # First, check the annotation format
    print("\n" + "=" * 60)
    print("🔍 Checking Annotation Format")
    print("=" * 60)
    
    bbox_info = analyze_annotations()
    
    if MODEL_TYPE == "classify":
        print("\n" + "=" * 60)
        print("📸 TRAINING IMAGE CLASSIFICATION MODEL")
        print("=" * 60)
        print("Using YOLOv8-cls since your data has full-image labels.")
        print("This model classifies entire images into defect categories.")
        print("=" * 60 + "\n")
        
        trainer = HomeRepairClassifier()
        trainer.train(epochs=EPOCHS, img_size=IMG_SIZE, batch_size=BATCH_SIZE)
        trainer.deploy_to_flutter()
        
    else:  # detect
        if bbox_info and bbox_info.get('all_full_image', False):
            print("\n⚠️  WARNING: Your annotations are full-image bounding boxes!")
            print("This will cause weight collapse in detection models.")
            print("Consider setting MODEL_TYPE = 'classify' instead.")
            response = input("Continue with detection training anyway? (y/n): ").strip().lower()
            if response != 'y':
                print("Training cancelled. Set MODEL_TYPE = 'classify' in the script.")
                return
        
        print("\n" + "=" * 60)
        print("🎯 TRAINING OBJECT DETECTION MODEL")
        print("=" * 60 + "\n")
        
        trainer = HomeRepairYOLOTrainer()
        
        data_yaml = Path(__file__).parent / "data.yaml"
        if not data_yaml.exists():
            print("⚠️  Creating placeholder data.yaml")
            create_data_yaml()
        
        trainer.train(
            data_yaml=str(data_yaml),
            epochs=EPOCHS,
            img_size=IMG_SIZE,
            batch_size=BATCH_SIZE
        )
        
        # Check weight health
        print("\n" + "=" * 60)
        print("🔍 Pre-Export Weight Validation")
        print("=" * 60)
        
        if not check_model_weights():
            print("\n⚠️  WARNING: Weight health check found issues!")
            print("The exported model may not work correctly.")
            print("Consider using MODEL_TYPE = 'classify' instead.")
            response = input("Continue with export anyway? (y/n): ").strip().lower()
            if response != 'y':
                print("Export cancelled.")
                return
        
        trainer.deploy_to_flutter()


def analyze_annotations():
    """Analyze annotation files to detect full-image bboxes"""
    labels_dir = Path(__file__).parent / "data" / "train" / "labels"
    
    if not labels_dir.exists():
        print("   Labels directory not found")
        return None
    
    label_files = list(labels_dir.glob("*.txt"))[:100]  # Sample first 100
    
    full_image_count = 0
    localized_count = 0
    
    for label_file in label_files:
        try:
            with open(label_file) as f:
                for line in f:
                    parts = line.strip().split()
                    if len(parts) >= 5:
                        _, cx, cy, w, h = parts[:5]
                        w, h = float(w), float(h)
                        
                        # Check if bbox covers most of image
                        if w > 0.9 and h > 0.9:
                            full_image_count += 1
                        else:
                            localized_count += 1
        except:
            pass
    
    total = full_image_count + localized_count
    if total == 0:
        print("   No annotations found")
        return None
    
    pct_full = (full_image_count / total) * 100
    
    print(f"   Analyzed {total} annotations:")
    print(f"   - Full-image bboxes: {full_image_count} ({pct_full:.0f}%)")
    print(f"   - Localized bboxes: {localized_count} ({100-pct_full:.0f}%)")
    
    if pct_full > 90:
        print("\n   ⚠️  Your data has FULL-IMAGE labels (classification data).")
        print("   📌 RECOMMENDATION: Use MODEL_TYPE = 'classify'")
    elif pct_full > 50:
        print("\n   ⚠️  Mixed annotation sizes detected.")
    else:
        print("\n   ✅ Your data has localized bounding boxes (detection data).")
    
    return {
        'full_image_count': full_image_count,
        'localized_count': localized_count,
        'all_full_image': pct_full > 90
    }


def check_model_weights(weights_path: str = None) -> bool:
    """Check if model weights are healthy (not collapsed)
    
    Returns True if weights are healthy, False if collapsed weights detected.
    """
    print("=" * 60)
    print("🔬 Checking Model Weight Health")
    print("=" * 60)
    
    # Find weights file
    if weights_path is None:
        runs_dir = Path(__file__).parent / "runs" / "train"
        detector_dirs = sorted(runs_dir.glob("home_repair_detector*"), reverse=True)
        if not detector_dirs:
            print("❌ No training runs found!")
            return False
        weights_path = detector_dirs[0] / "weights" / "best.pt"
    
    weights_path = Path(weights_path)
    if not weights_path.exists():
        print(f"❌ Weights file not found: {weights_path}")
        return False
    
    print(f"📦 Loading: {weights_path}")
    
    try:
        model = YOLO(str(weights_path))
        
        # Find Detect module
        detect = None
        for m in model.model.modules():
            if type(m).__name__ == 'Detect':
                detect = m
                break
        
        if detect is None:
            print("❌ Could not find Detect module in model")
            return False
        
        print("\n📊 Classification Head (cv3) Analysis:")
        print("-" * 50)
        
        all_healthy = True
        scale_status = []
        
        for i, cv3 in enumerate(detect.cv3):
            scale_name = ["P3/8 (small)", "P4/16 (medium)", "P5/32 (large)"][i] if i < 3 else f"scale{i}"
            scale_healthy = True
            
            print(f"\n   Scale {i} - {scale_name}:")
            
            for j, block in enumerate(cv3):
                if hasattr(block, 'conv') and hasattr(block.conv, 'weight'):
                    w = block.conv.weight.data
                    w_min, w_max = w.min().item(), w.max().item()
                    w_std = w.std().item()
                    w_range = w_max - w_min
                    
                    # Weight is collapsed if range < 0.01
                    if w_range < 0.01:
                        status = "❌ COLLAPSED"
                        scale_healthy = False
                        all_healthy = False
                    elif w_range < 0.05:
                        status = "⚠️  WEAK"
                    else:
                        status = "✅ OK"
                    
                    print(f"      cv3.{i}.{j}.conv: [{w_min:+.4f}, {w_max:+.4f}] std={w_std:.4f} {status}")
            
            scale_status.append((scale_name, scale_healthy))
        
        print("\n" + "-" * 50)
        print("📋 Summary:")
        for name, healthy in scale_status:
            icon = "✅" if healthy else "❌"
            print(f"   {icon} {name}: {'Healthy' if healthy else 'COLLAPSED'}")
        
        print()
        if all_healthy:
            print("✅ All classification weights are healthy!")
            print("   Model should export correctly to ONNX/TFLite.")
        else:
            print("❌ WEIGHT COLLAPSE DETECTED!")
            print("   This model will NOT work when exported.")
            print("\n   Recommended fixes:")
            print("   1. Increase training epochs")
            print("   2. Add more training images with small/medium defects")
            print("   3. Reduce WEIGHT_DECAY even further")
            print("   4. Increase SCALE_RANGE for more scale augmentation")
        
        return all_healthy
        
    except Exception as e:
        print(f"❌ Error checking weights: {e}")
        import traceback
        traceback.print_exc()
        return False


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


def validate_deployed_model():
    """Validate the currently deployed TFLite model without retraining"""
    flutter_assets = Path(__file__).parent.parent / "object_detect_test" / "assets" / "models"
    tflite_path = flutter_assets / "trained_model.tflite"
    
    if not tflite_path.exists():
        print(f"❌ Model not found: {tflite_path}")
        return
    
    print(f"📄 Validating: {tflite_path}")
    print(f"📏 Size: {tflite_path.stat().st_size / 1024 / 1024:.2f} MB")
    
    # Create a dummy trainer just to use the validation method
    trainer = HomeRepairYOLOTrainer()
    trainer._validate_tflite(tflite_path)


def reexport_model(export_format="tflite"):
    """Re-export the trained model without retraining
    
    Args:
        export_format: "tflite", "onnx", or "coreml"
    """
    print("=" * 60)
    print(f"🔄 Re-exporting trained model to {export_format.upper()}")
    print("=" * 60)
    
    # Find best.pt from most recent training
    runs_dir = Path(__file__).parent / "runs" / "train"
    detector_dirs = sorted(runs_dir.glob("home_repair_detector*"), reverse=True)
    
    if not detector_dirs:
        print("❌ No training runs found!")
        return
    
    weights_path = detector_dirs[0] / "weights" / "best.pt"
    if not weights_path.exists():
        print(f"❌ Weights not found: {weights_path}")
        return
    
    print(f"📦 Found weights: {weights_path}")
    
    # Load model and test PyTorch inference first
    model = YOLO(str(weights_path))
    
    print("\n🧪 Testing PyTorch model...")
    test_img = np.ones((320, 320, 3), dtype=np.uint8) * 128
    results = model(test_img, verbose=False)
    print(f"   Gray image: {len(results[0].boxes)} detections")
    
    test_img2 = np.random.randint(0, 255, (320, 320, 3), dtype=np.uint8)
    results2 = model(test_img2, verbose=False)
    print(f"   Random image: {len(results2[0].boxes)} detections")
    
    if len(results[0].boxes) > 0:
        boxes = results[0].boxes
        print(f"   Confidence: {boxes.conf.cpu().numpy()}")
        print(f"   Classes: {boxes.cls.cpu().numpy()}")
        print(f"   Box xyxy: {boxes.xyxy[0].cpu().numpy()}")
    
    # Understand YOLO's actual output format
    print("\n🔬 Analyzing YOLO detection output format...")
    print("   YOLO internally processes raw output through postprocess().")
    print("   The 'results' object contains POST-PROCESSED detections.")
    print("   Raw model output needs decoding (DFL for boxes, sigmoid for classes).")
    
    # Check if we can access the pre-NMS predictions
    print("\n📊 Checking raw prediction tensor...")
    model.model.eval()
    with torch.no_grad():
        img_tensor = torch.from_numpy(test_img).permute(2, 0, 1).unsqueeze(0).float() / 255.0
        
        # Run through model to get raw output
        raw_output = model.model(img_tensor)
        if isinstance(raw_output, (list, tuple)):
            raw_output = raw_output[0]
        
        raw_np = raw_output.cpu().numpy()
        print(f"   Raw shape: {raw_np.shape}")
        
        # YOLOv8 output: [batch, 4+nc, num_anchors]
        # First 4 rows: box regression (DFL encoded, NOT cx/cy/w/h directly)
        # Remaining rows: class logits (need sigmoid)
        
        if raw_np.shape[1] == 11:  # 4 box + 7 classes
            box_preds = raw_np[0, :4, :]  # Box predictions (DFL encoded)
            cls_preds = raw_np[0, 4:, :]  # Class predictions (logits)
            
            print(f"   Box predictions range: {box_preds.min():.2f} to {box_preds.max():.2f}")
            print(f"   Class logits range: {cls_preds.min():.4f} to {cls_preds.max():.4f}")
            
            # The class predictions ARE the issue - they're near zero
            # This means the classification head isn't outputting meaningful values
            # But YOLO's inference gets 96% confidence...
            
            # Let's check what YOLO's postprocess actually returns
            print("\n🔍 Checking YOLO's internal postprocessing...")
            
            # Get the prediction before NMS but after decode
            pred = model.predictor.postprocess(
                [torch.from_numpy(raw_np)], 
                img_tensor, 
                [test_img]
            ) if hasattr(model, 'predictor') and model.predictor else None
            
            if pred:
                print(f"   Post-processed predictions available")
            else:
                print("   Predictor not initialized, using results object")
                
                # The key insight: YOLO's Results object shows 96% confidence
                # but raw output shows 0 class scores. 
                # This means postprocess is doing something special.
                
                # Check orig_shape vs processed
                if len(results[0].boxes) > 0:
                    # Get the raw data tensor that Results uses
                    raw_boxes = results[0].boxes.data.cpu().numpy()
                    print(f"   Results.boxes.data shape: {raw_boxes.shape}")
                    print(f"   Results.boxes.data: {raw_boxes[0] if len(raw_boxes) > 0 else 'empty'}")
    
    print("\n💡 CONCLUSION: YOLOv8 export format differs from inference format.")
    print("   The TFLite/ONNX export outputs RAW predictions that need decoding.")
    print("   We need to apply YOLO's postprocess logic in Flutter.")
    
    flutter_assets = Path(__file__).parent.parent / "object_detect_test" / "assets" / "models"
    flutter_assets.mkdir(parents=True, exist_ok=True)
    
    if export_format == "tflite":
        # Try multiple TFLite export configurations
        print("\n📤 Trying TFLite export with different settings...")
        
        # Method 1: Standard export
        print("\n   [Method 1] Standard TFLite export...")
        export_path = model.export(format="tflite", imgsz=320, int8=False)
        _deploy_and_validate(export_path, flutter_assets / "trained_model.tflite")
        
    elif export_format == "onnx":
        # ONNX export (can use with onnx_runtime_flutter package)
        print("\n📤 Exporting to ONNX...")
        export_path = model.export(
            format="onnx",
            imgsz=320,
            simplify=True,
            dynamic=False,
        )
        dest = flutter_assets / "trained_model.onnx"
        shutil.copy(export_path, dest)
        print(f"✅ ONNX deployed to: {dest}")
        print(f"📏 Size: {dest.stat().st_size / 1024 / 1024:.2f} MB")
        print("\nTo use ONNX in Flutter, add 'onnxruntime_flutter' package")
        
        # Validate ONNX
        _validate_onnx(dest)
        
    elif export_format == "coreml":
        # CoreML export (iOS native, typically works better)
        print("\n📤 Exporting to CoreML...")
        export_path = model.export(
            format="coreml",
            imgsz=320,
            nms=True,  # Include NMS in CoreML
        )
        dest = flutter_assets / "trained_model.mlpackage"
        if Path(export_path).is_dir():
            shutil.copytree(export_path, dest, dirs_exist_ok=True)
        else:
            shutil.copy(export_path, dest)
        print(f"✅ CoreML deployed to: {dest}")
        print("\nCoreML can be used via platform channels in Flutter iOS")


def _deploy_and_validate(export_path, dest):
    """Copy TFLite and validate it"""
    export_path = Path(export_path)
    if export_path.is_dir():
        tflite_files = list(export_path.rglob("*float32.tflite"))
        if not tflite_files:
            tflite_files = list(export_path.rglob("*.tflite"))
        if tflite_files:
            export_path = tflite_files[0]
    
    shutil.copy(export_path, dest)
    print(f"   ✅ Deployed to: {dest}")
    print(f"   📏 Size: {dest.stat().st_size / 1024 / 1024:.2f} MB")
    
    trainer = HomeRepairYOLOTrainer()
    trainer._validate_tflite(dest)


def _validate_onnx(onnx_path):
    """Validate ONNX model"""
    try:
        import onnxruntime as ort
        
        print("\n🧪 Validating ONNX model (raw)...")
        session = ort.InferenceSession(str(onnx_path))
        
        input_name = session.get_inputs()[0].name
        input_shape = session.get_inputs()[0].shape
        print(f"   Input: {input_name} {input_shape}")
        
        output_name = session.get_outputs()[0].name
        output_shape = session.get_outputs()[0].shape
        print(f"   Output: {output_name} {output_shape}")
        
        # Test inference
        test_input = np.random.rand(1, 3, 320, 320).astype(np.float32)
        outputs = session.run(None, {input_name: test_input})
        output = outputs[0]
        
        print(f"   Raw output range: min={output.min():.4f}, max={output.max():.4f}")
        
        # Check class scores (assuming transposed format)
        if len(output.shape) == 3 and output.shape[1] >= 11:
            class_scores = output[0, 4:11, :]
            print(f"   Raw class logits: min={class_scores.min():.6f}, max={class_scores.max():.6f}")
                
    except ImportError:
        print("   ⚠️ onnxruntime not installed. Install with: pip install onnxruntime")
    except Exception as e:
        print(f"   ❌ ONNX raw validation failed: {e}")
    
    # Key test: run ONNX through YOLO's inference pipeline
    try:
        print("\n🔬 Testing ONNX through YOLO inference...")
        onnx_model = YOLO(str(onnx_path))
        test_img = np.ones((320, 320, 3), dtype=np.uint8) * 128
        results = onnx_model(test_img, verbose=False)
        
        print(f"   Detections: {len(results[0].boxes)}")
        if len(results[0].boxes) > 0:
            conf = results[0].boxes.conf.cpu().numpy()
            cls = results[0].boxes.cls.cpu().numpy()
            print(f"   Confidence: {conf}")
            print(f"   Classes: {cls}")
            print("   ✅ ONNX works through YOLO! Postprocessing is the issue in Flutter.")
            print("\n💡 The model IS working. We need to either:")
            print("   1. Export with NMS included (changes output format)")
            print("   2. Port YOLO's postprocess to Flutter")
        else:
            print("   ⚠️ No detections - model may have issues")
    except Exception as e:
        print(f"   ❌ YOLO inference test failed: {e}")


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        if cmd == "validate":
            validate_deployed_model()
        elif cmd == "check" or cmd == "check_weights":
            weights_path = sys.argv[2] if len(sys.argv) > 2 else None
            check_model_weights(weights_path)
        elif cmd == "analyze":
            # Analyze annotation format
            print("\n" + "=" * 60)
            print("🔍 Analyzing Annotation Format")
            print("=" * 60)
            analyze_annotations()
        elif cmd == "classify":
            # Force classification training
            trainer = HomeRepairClassifier()
            trainer.train(epochs=EPOCHS, img_size=IMG_SIZE, batch_size=BATCH_SIZE)
            trainer.deploy_to_flutter()
        elif cmd == "detect":
            # Force detection training (ignoring MODEL_TYPE)
            trainer = HomeRepairYOLOTrainer()
            data_yaml = Path(__file__).parent / "data.yaml"
            trainer.train(data_yaml=str(data_yaml), epochs=EPOCHS, img_size=IMG_SIZE, batch_size=BATCH_SIZE)
            trainer.deploy_to_flutter()
        elif cmd == "reexport":
            fmt = sys.argv[2] if len(sys.argv) > 2 else "tflite"
            reexport_model(export_format=fmt)
        elif cmd == "help" or cmd == "--help" or cmd == "-h":
            print_usage()
        else:
            print(f"Unknown command: {cmd}")
            print_usage()
    else:
        train_and_deploy()


def print_usage():
    """Print usage information"""
    print("""
╔══════════════════════════════════════════════════════════════════╗
║            Home Repair YOLO Training Script                       ║
╚══════════════════════════════════════════════════════════════════╝

Usage:
  python model_train.py                  Auto-detect and train (uses MODEL_TYPE)
  python model_train.py classify         Train IMAGE CLASSIFICATION model
  python model_train.py detect           Train OBJECT DETECTION model
  python model_train.py analyze          Analyze annotation format
  python model_train.py check            Check weights of trained detection model
  python model_train.py validate         Validate deployed TFLite model
  python model_train.py reexport         Re-export to TFLite

⚠️  IMPORTANT: Check your annotation format first!
  
  If your labels are like "0 0.5 0.5 1.0 1.0" (full-image bboxes):
    → Use: python model_train.py classify
    
  If your labels have actual localized bounding boxes:
    → Use: python model_train.py detect

Configuration (edit MODEL_TYPE at top of file):
  MODEL_TYPE = "classify"  # For full-image labels (RECOMMENDED for your data)
  MODEL_TYPE = "detect"    # For localized bounding boxes

See MODEL_DEBUG_LOG.md for details on the weight collapse issue.
""")