# Test Image Setup

## How to add a test image

To test object detection on the simulator, you need to add a test image to this folder.

### Steps:

1. Find any `.jpg` or `.jpeg` image you want to test (ideally one with objects like people, cars, animals, etc.)
2. Rename it to `test_image.jpg`
3. Place it in this `assets/` folder (same folder as `1.tflite`)

### Alternative: Use Image Picker

If you don't want to use a test image from assets, you can:
- Click "Pick Image from Gallery" button in the app
- This will let you select any image from the simulator's photo library
- In iOS Simulator, you can drag & drop images to add them to Photos

### What the app does:

1. Loads your image
2. Resizes it to match the model's input size (determined automatically)
3. Runs object detection using the `1.tflite` model
4. Displays detected objects with bounding boxes and confidence scores

### Note:

The actual detection results depend on what your `1.tflite` model was trained to detect. Make sure you're using images that contain objects your model knows about.

