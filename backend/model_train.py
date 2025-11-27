from ultralytics import YOLO
import torch
import shutil
import numpy as np
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
        
        dest = flutter_assets / "trained_model.tflite"
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
            # Run: python model_train.py validate
            validate_deployed_model()
        elif cmd == "reexport":
            # Run: python model_train.py reexport [format]
            # format can be: tflite, onnx, coreml
            fmt = sys.argv[2] if len(sys.argv) > 2 else "tflite"
            reexport_model(export_format=fmt)
        else:
            print(f"Unknown command: {cmd}")
            print("Usage:")
            print("  python model_train.py             # Train and deploy")
            print("  python model_train.py validate    # Validate deployed model")
            print("  python model_train.py reexport    # Re-export to TFLite")
            print("  python model_train.py reexport onnx    # Export to ONNX")
            print("  python model_train.py reexport coreml  # Export to CoreML (iOS)")
    else:
        # Run: python model_train.py
        train_and_deploy()