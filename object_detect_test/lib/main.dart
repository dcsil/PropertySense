import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  
  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Object Detection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: CameraScreen(cameras: cameras),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Interpreter? _interpreter;
  List<dynamic>? _recognitions;
  bool _isDetecting = false;
  bool _isModelLoaded = false;
  File? _selectedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isNotEmpty) {
      try {
        _controller = CameraController(
          widget.cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        
        await _controller!.initialize();
        _controller!.startImageStream(_processImage);
        setState(() {});
      } catch (e) {
        print('Camera initialization failed: $e');
        // Camera failed to initialize, but we'll continue with mock data
        setState(() {});
      }
    } else {
      print('No cameras available - running in simulator mode');
      // No cameras available (simulator), but we'll continue with mock data
      setState(() {});
    }
  }

  Future<void> _loadModel() async {
    try {
      final modelPath = 'assets/1.tflite';
      _interpreter = await Interpreter.fromAsset(modelPath);
      setState(() {
        _isModelLoaded = true;
      });
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (_interpreter == null || _isDetecting) return;
    
    _isDetecting = true;
    
    try {
      // Convert camera image to the format expected by the model
      final input = _convertImageToInput(image);
      
      // Run inference
      final output = List.filled(1 * 10 * 4, 0.0).reshape([1, 10, 4]) as List<List<double>>;
      _interpreter!.run(input, output);
      
      // Process results (simplified for demo)
      setState(() {
        _recognitions = _processOutput(output);
      });
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      _isDetecting = false;
    }
  }

  List<List<double>> _convertImageToInput(CameraImage image) {
    // Simplified conversion - in practice, you'd need proper preprocessing
    // based on your specific model requirements
    final input = List.filled(1 * 224 * 224 * 3, 0.0).reshape([1, 224, 224, 3]) as List<List<double>>;
    return input;
  }

  List<Map<String, dynamic>> _processOutput(List<List<double>> output) {
    // Simplified output processing - adjust based on your model's output format
    final List<Map<String, dynamic>> recognitions = [];
    
    // Mock detection for demonstration
    if (math.Random().nextDouble() > 0.7) {
      recognitions.add({
        'label': 'Object',
        'confidence': 0.8,
        'bbox': [0.2, 0.3, 0.6, 0.7], // [x, y, width, height] normalized
      });
    }
    
    return recognitions;
  }

  Future<void> _pickAndDetectImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      
      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        final Uint8List imageBytes = await imageFile.readAsBytes();
        
        setState(() {
          _selectedImage = imageFile;
          _imageBytes = imageBytes;
        });
        
        await _runDetectionOnImage(imageBytes);
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _loadAndDetectTestImage() async {
    try {
      // Try to load a test image from assets
      final ByteData data = await rootBundle.load('assets/test_image.jpg');
      final Uint8List bytes = data.buffer.asUint8List();
      
      setState(() {
        _imageBytes = bytes;
        _selectedImage = null; // Clear file reference when using asset
      });
      
      await _runDetectionOnImage(bytes);
    } catch (e) {
      print('Error loading test image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: No test image found. Please add test_image.jpg to assets folder or pick an image.')),
      );
    }
  }

  Future<void> _runDetectionOnImage(Uint8List imageBytes) async {
    if (_interpreter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model not loaded yet')),
      );
      return;
    }

    setState(() {
      _isDetecting = true;
    });

    try {
      // Decode the image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Get model input shape
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final inputType = _interpreter!.getInputTensor(0).type;
      
      print('Model input shape: $inputShape');
      print('Model input type: $inputType');
      
      // Resize image to model input size (assuming [1, height, width, 3])
      final inputHeight = inputShape[1];
      final inputWidth = inputShape[2];
      
      img.Image resizedImage = img.copyResize(image, 
        width: inputWidth, 
        height: inputHeight
      );

      // Convert image to input tensor
      var input = _imageToByteListFloat32(resizedImage, inputHeight, inputWidth);

      // Get output shape
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      print('Model output shape: $outputShape');
      
      // Prepare output buffer based on actual model output
      // For YOLO models with output [1, 6300, 85], create proper 3D structure
      var output = List.generate(
        outputShape[0],
        (i) => List.generate(
          outputShape[1],
          (j) => List.filled(outputShape[2], 0.0),
        ),
      );

      // Run inference
      _interpreter!.run(input, output);

      // Process and display results
      setState(() {
        _recognitions = _processModelOutput(output);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Detection complete! Found ${_recognitions?.length ?? 0} objects'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error running detection: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Detection error: $e')),
      );
      
      // // Show mock detection as fallback
      // setState(() {
      //   _recognitions = [
      //     {
      //       'label': 'Demo Object',
      //       'confidence': 0.85,
      //       'bbox': [0.2, 0.3, 0.6, 0.7],
      //     }
      //   ];
      // });
    } finally {
      setState(() {
        _isDetecting = false;
      });
    }
  }

  Float32List _imageToByteListFloat32(img.Image image, int inputHeight, int inputWidth) {
    var convertedBytes = Float32List(1 * inputHeight * inputWidth * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < inputHeight; i++) {
      for (var j = 0; j < inputWidth; j++) {
        var pixel = image.getPixel(j, i);
        // Normalize to [0, 1] or [-1, 1] depending on your model
        buffer[pixelIndex++] = pixel.r / 255.0;
        buffer[pixelIndex++] = pixel.g / 255.0;
        buffer[pixelIndex++] = pixel.b / 255.0;
      }
    }
    
    return convertedBytes;
  }

  List<Map<String, dynamic>> _processModelOutput(List<dynamic> output) {
    final List<Map<String, dynamic>> recognitions = [];
    
    // YOLO output format: [1, 6300, 85]
    // 85 = 4 bbox coords (x, y, w, h) + 1 objectness + 80 class scores
    
    try {
      print('Processing output: ${output.length} batches');
      
      if (output.isEmpty) return recognitions;
      
      final detections = output[0] as List; // Get first batch
      print('Number of detections: ${detections.length}');
      
      const confidenceThreshold = 0.5; // Minimum confidence to show
      const iouThreshold = 0.4; // For NMS (Non-Maximum Suppression)
      
      // COCO dataset class names (80 classes) - shortened list for common objects
      const classNames = [
        'person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train', 'truck', 'boat',
        'traffic light', 'fire hydrant', 'stop sign', 'parking meter', 'bench', 'bird', 'cat',
        'dog', 'horse', 'sheep', 'cow', 'elephant', 'bear', 'zebra', 'giraffe', 'backpack',
        'umbrella', 'handbag', 'tie', 'suitcase', 'frisbee', 'skis', 'snowboard', 'sports ball',
        'kite', 'baseball bat', 'baseball glove', 'skateboard', 'surfboard', 'tennis racket',
        'bottle', 'wine glass', 'cup', 'fork', 'knife', 'spoon', 'bowl', 'banana', 'apple',
        'sandwich', 'orange', 'broccoli', 'carrot', 'hot dog', 'pizza', 'donut', 'cake', 'chair',
        'couch', 'potted plant', 'bed', 'dining table', 'toilet', 'tv', 'laptop', 'mouse',
        'remote', 'keyboard', 'cell phone', 'microwave', 'oven', 'toaster', 'sink', 'refrigerator',
        'book', 'clock', 'vase', 'scissors', 'teddy bear', 'hair drier', 'toothbrush'
      ];
      
      // Process each detection
      for (var i = 0; i < detections.length; i++) {
        final detection = detections[i] as List;
        
        if (detection.length < 85) continue;
        
        // Get bounding box (assuming center format: cx, cy, w, h)
        final cx = detection[0] as double;
        final cy = detection[1] as double;
        final w = detection[2] as double;
        final h = detection[3] as double;
        
        // Get objectness score
        final objectness = detection[4] as double;
        
        // Find class with highest score
        var maxClassScore = 0.0;
        var maxClassIndex = 0;
        
        for (var j = 5; j < detection.length; j++) {
          final classScore = detection[j] as double;
          if (classScore > maxClassScore) {
            maxClassScore = classScore;
            maxClassIndex = j - 5; // Subtract 5 to get class index
          }
        }
        
        // Calculate final confidence
        final confidence = objectness * maxClassScore;
        
        // Filter by confidence threshold
        if (confidence < confidenceThreshold) continue;
        
        // Convert from center format to corner format and normalize
        // Assuming coordinates are already normalized (0-1)
        final x = (cx - w / 2).clamp(0.0, 1.0);
        final y = (cy - h / 2).clamp(0.0, 1.0);
        final width = w.clamp(0.0, 1.0);
        final height = h.clamp(0.0, 1.0);
        
        // Get class name
        final className = maxClassIndex < classNames.length 
            ? classNames[maxClassIndex] 
            : 'Object $maxClassIndex';
        
        recognitions.add({
          'label': className,
          'confidence': confidence,
          'bbox': [x, y, width, height],
        });
      }
      
      print('Found ${recognitions.length} objects above confidence threshold');
      
      // Sort by confidence (highest first)
      recognitions.sort((a, b) => 
        (b['confidence'] as double).compareTo(a['confidence'] as double));
      
      // Limit to top 10 detections
      if (recognitions.length > 10) {
        return recognitions.sublist(0, 10);
      }
      
    } catch (e) {
      print('Error processing output: $e');
      print('Stack trace: ${StackTrace.current}');
    }
    
    return recognitions;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isModelLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Object Detection'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_imageBytes == null) ...[
                  const Icon(Icons.image, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Camera not available',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Test object detection with images',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ] else ...[
                  // Display selected image with detections
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Image.memory(_imageBytes!),
                          if (_recognitions != null)
                            ..._recognitions!.map((recognition) => _buildBoundingBoxForImage(recognition, constraints)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_recognitions != null && _recognitions!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detected Objects:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._recognitions!.map((r) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '${r['label']}: ${(r['confidence'] * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(color: Colors.white),
                            ),
                          )),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 24),
                if (_isDetecting)
                  const CircularProgressIndicator()
                else ...[
                  ElevatedButton.icon(
                    onPressed: _pickAndDetectImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pick Image from Gallery'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _loadAndDetectTestImage,
                    icon: const Icon(Icons.image_search),
                    label: const Text('Use Test Image'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  if (_imageBytes != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _imageBytes = null;
                          _selectedImage = null;
                          _recognitions = null;
                        });
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Object Detection'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Camera preview or placeholder
          Positioned.fill(
            child: _controller != null && _controller!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: CameraPreview(_controller!),
                  )
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 64, color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Camera Preview',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          // Bounding boxes overlay
          if (_recognitions != null)
            ..._recognitions!.map((recognition) => _buildBoundingBox(recognition)),
        ],
      ),
    );
  }

  Widget _buildBoundingBox(Map<String, dynamic> recognition) {
    final bbox = recognition['bbox'] as List<double>;
    final label = recognition['label'] as String;
    final confidence = recognition['confidence'] as double;
    
    return Positioned(
      left: bbox[0] * MediaQuery.of(context).size.width,
      top: bbox[1] * MediaQuery.of(context).size.height,
      width: bbox[2] * MediaQuery.of(context).size.width,
      height: bbox[3] * MediaQuery.of(context).size.height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                color: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  '$label ${(confidence * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoundingBoxForImage(Map<String, dynamic> recognition, BoxConstraints constraints) {
    final bbox = recognition['bbox'] as List<double>;
    final label = recognition['label'] as String;
    final confidence = recognition['confidence'] as double;
    
    // Validate bbox values to prevent Infinity
    final left = bbox[0].isFinite ? bbox[0] : 0.0;
    final top = bbox[1].isFinite ? bbox[1] : 0.0;
    final width = bbox[2].isFinite ? bbox[2] : 0.0;
    final height = bbox[3].isFinite ? bbox[3] : 0.0;
    
    // For static images, we need to calculate based on image dimensions
    return Positioned(
      left: left * constraints.maxWidth,
      top: top * constraints.maxHeight,
      width: width * constraints.maxWidth,
      height: height * constraints.maxHeight,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 3),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                color: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Text(
                  '$label ${(confidence * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
