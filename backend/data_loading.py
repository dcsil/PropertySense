import os
import torch
from torch.utils.data import Dataset, DataLoader
from torchvision import transforms
from PIL import Image

# Step 1: Download/unzip to local dir (e.g., ./bd3_dataset/)
# Use gdown if hosted on Drive: !pip install gdown; gdown --folder <drive_folder_id>

class HomeRepairDataset(Dataset):
    def __init__(self, root_dir):
        self.root_dir = root_dir
        self.classes = ['algae', 'major_crack', 'minor_crack', 'peeling', 'spalling', 'stain', 'normal']
        self.samples = []
        self.transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])
        for class_name in self.classes:
            class_dir = os.path.join(root_dir, class_name)
            for img_name in os.listdir(class_dir):
                if img_name.endswith(('.jpg', '.png')):
                    self.samples.append((os.path.join(class_dir, img_name), self.classes.index(class_name)))
    
    def __len__(self):
        return len(self.samples)
    
    def __getitem__(self, idx):
        img_path, label = self.samples[idx]
        image = Image.open(img_path).convert('RGB')
        image = self.transform(image)
        return image, label

dataset = HomeRepairDataset(root_dir='./bd3_dataset/')
dataloader = DataLoader(dataset, batch_size=32, shuffle=True)

# # Fine-tune YOLOv8 (from Ultralytics)
# from ultralytics import YOLO
# model = YOLO('yolov8n.pt')  # Pre-trained
# model.train(data='bd3.yaml', epochs=50, imgsz=640)  # Create bd3.yaml for classes/splits