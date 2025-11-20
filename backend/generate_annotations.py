#!/usr/bin/env python3
"""
Generate YOLO annotations for pre-cropped images.
Since each image is already cropped to show the defect, 
we create annotations that cover the entire image.
"""

import os
import shutil
from pathlib import Path
import random

# Class mapping
CLASSES = {
    'algae': 0,
    'major_crack': 1,
    'minor_crack': 2,
    'peeling': 3,
    'spalling': 4,
    'stain': 5,
    'plain': 6
}

def generate_full_image_annotation(class_id):
    """
    Generate YOLO annotation for full image.
    Format: class_id x_center y_center width height (all normalized 0-1)
    
    For full image:
    - x_center = 0.5 (center horizontally)
    - y_center = 0.5 (center vertically)  
    - width = 1.0 (full width)
    - height = 1.0 (full height)
    """
    return f"{class_id} 0.5 0.5 1.0 1.0\n"


def setup_yolo_dataset(data_dir, train_split=0.8):
    """
    Organize images and create annotations in YOLO format.
    
    Args:
        data_dir: Path to data directory with class folders
        train_split: Fraction of data to use for training (rest is validation)
    """
    data_dir = Path(data_dir)
    
    # Create YOLO structure
    train_img_dir = data_dir / "train" / "images"
    train_lbl_dir = data_dir / "train" / "labels"
    val_img_dir = data_dir / "val" / "images"
    val_lbl_dir = data_dir / "val" / "labels"
    
    for dir_path in [train_img_dir, train_lbl_dir, val_img_dir, val_lbl_dir]:
        dir_path.mkdir(parents=True, exist_ok=True)
    
    print("=" * 60)
    print("🏗️  Generating YOLO Dataset")
    print("=" * 60)
    print(f"Train/Val split: {train_split:.0%} / {1-train_split:.0%}")
    print()
    
    total_train = 0
    total_val = 0
    
    # Process each class folder
    for class_name, class_id in CLASSES.items():
        class_dir = data_dir / class_name
        
        if not class_dir.exists():
            print(f"⚠️  Skipping {class_name} (folder not found)")
            continue
        
        # Get all images in this class
        image_files = []
        for ext in ['*.jpg', '*.jpeg', '*.png', '*.JPG', '*.JPEG', '*.PNG']:
            image_files.extend(list(class_dir.glob(ext)))
        
        if not image_files:
            print(f"⚠️  No images in {class_name}")
            continue
        
        # Shuffle and split
        random.shuffle(image_files)
        split_idx = int(len(image_files) * train_split)
        train_images = image_files[:split_idx]
        val_images = image_files[split_idx:]
        
        # Process training images
        for img_path in train_images:
            # Copy image
            dest_img = train_img_dir / f"{class_name}_{img_path.name}"
            shutil.copy(img_path, dest_img)
            
            # Create annotation
            annotation = generate_full_image_annotation(class_id)
            annotation_path = train_lbl_dir / f"{dest_img.stem}.txt"
            annotation_path.write_text(annotation)
            
            total_train += 1
        
        # Process validation images
        for img_path in val_images:
            # Copy image
            dest_img = val_img_dir / f"{class_name}_{img_path.name}"
            shutil.copy(img_path, dest_img)
            
            # Create annotation
            annotation = generate_full_image_annotation(class_id)
            annotation_path = val_lbl_dir / f"{dest_img.stem}.txt"
            annotation_path.write_text(annotation)
            
            total_val += 1
        
        print(f"✅ {class_name:15} - Train: {len(train_images):4} | Val: {len(val_images):4}")
    
    print()
    print("=" * 60)
    print(f"✅ Dataset Ready!")
    print(f"   Training:   {total_train} images")
    print(f"   Validation: {total_val} images")
    print(f"   Total:      {total_train + total_val} images")
    print("=" * 60)
    print()
    print("📁 Dataset structure:")
    print(f"   {train_img_dir}")
    print(f"   {train_lbl_dir}")
    print(f"   {val_img_dir}")
    print(f"   {val_lbl_dir}")
    print()
    print("🚀 Now run: python model_train.py")


if __name__ == "__main__":
    # Set random seed for reproducibility
    random.seed(42)
    
    # Generate dataset
    data_dir = Path(__file__).parent / "data"
    setup_yolo_dataset(data_dir, train_split=0.8)

