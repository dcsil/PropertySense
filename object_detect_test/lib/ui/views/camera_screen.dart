/*
 * OBJECT DETECTION APP - MVP
 * 
 * Features:
 * - PRIMARY: Live camera object detection (on physical devices)
 * - BACKUP: Static image detection (when no camera available)
 * - Uses YOLO TFLite model for 80 COCO object classes
 * 
 * Architecture:
 * 1. Load TFLite model from assets
 * 2. Initialize camera (if available) or fallback to image mode
 * 3. Process frames/images through YOLO model
 * 4. Display bounding boxes with labels and confidence scores
 */

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:object_detect_test/ml/model_loader.dart';
import 'package:object_detect_test/ml/home_repair_detector.dart';
import 'package:object_detect_test/domain/services/price_predictor.dart';
import 'package:object_detect_test/ui/views/defect_report_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {

  List<CameraDescription> cameras = [];

  // Camera and model components
  CameraController? _controller;
  HomeRepairDetector? _detector;
  
  // Detection state
  List<Map<String, dynamic>>? _detections;
  bool _isDetecting = false;
  bool _isModelLoaded = false;
  bool _isCameraAvailable = false;
  
  // Captured images for report generation
  List<Map<String, dynamic>> _capturedDetections = [];
  
  // Backup image mode (only when no camera)
  Uint8List? _testImageBytes;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadModel();
    _initializeCamera();
  }

  /// Load TFLite model from assets
  Future<void> _loadModel() async {
    try {
      await ModelLoader.loadModel();
      _detector = HomeRepairDetector(
        interpreter: ModelLoader.interpreter,
        labels: ModelLoader.labels,
        isClassificationModel: ModelLoader.isClassificationModel,
      );
      setState(() => _isModelLoaded = true);
      print('✓ Home repair detector ready (${ModelLoader.isClassificationModel ? "classification" : "detection"} mode)');
    } catch (e) {
      print('✗ Error loading model: $e');
    }
  }

  /// Initialize camera for live detection (primary mode)
  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras.isEmpty) {
      print('No cameras available - image mode only');
      setState(() => _isCameraAvailable = false);
      return;
    }

      try {
        _controller = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        
        await _controller!.initialize();
      
      // Start live detection stream
      _controller!.startImageStream(_processCameraFrame);
      
      setState(() => _isCameraAvailable = true);
      print('✓ Camera initialized - live detection active');
    } catch (e) {
      print('✗ Camera failed: $e');
      setState(() => _isCameraAvailable = false);
    }
  }

  /// Process each camera frame for live object detection
  Future<void> _processCameraFrame(CameraImage cameraImage) async {
    // Skip if model not ready or already processing
    if (_detector == null || _isDetecting) return;
    
    _isDetecting = true;
    
    try {
      // Get model input requirements
      final inputShape = ModelLoader.interpreter.getInputTensor(0).shape;
      final inputHeight = inputShape[1];
      final inputWidth = inputShape[2];
      
      // Convert camera image to RGB (handles both iOS BGRA and Android YUV420)
      final img.Image? rgbImage = _convertYUV420ToImage(cameraImage);
      if (rgbImage == null) {
        _isDetecting = false;
        return;
      }
      
      // Preprocess image using detector
      final inputBytes = _detector!.preprocessImage(rgbImage, inputWidth);
      
      // DEBUG: Print first few pixel values to verify input changes each frame
      final debugSample = inputBytes.sublist(0, 9);
      print('🖼️ Input sample (first 3 pixels RGB): ${debugSample.map((v) => v.toStringAsFixed(3)).toList()}');
      
      final input = inputBytes.reshape([1, inputHeight, inputWidth, 3]);
      
      // Prepare output buffer based on model type
      final outputShape = ModelLoader.interpreter.getOutputTensor(0).shape;
      print('📐 Output tensor shape: $outputShape');
      
      // Create appropriate buffer for classification [1, N] or detection [1, F, P]
      dynamic outputBuffer;
      if (outputShape.length == 2) {
        // Classification model: [1, numClasses]
        outputBuffer = List.generate(
          outputShape[0],
          (i) => List.filled(outputShape[1], 0.0),
        );
      } else {
        // Detection model: [1, features, predictions]
        outputBuffer = List.generate(
          outputShape[0],
          (i) => List.generate(
            outputShape[1],
            (j) => List.filled(outputShape[2], 0.0),
          ),
        );
      }
      final Map<int, Object> outputs = {0: outputBuffer};
      
      // Run inference
      ModelLoader.interpreter.runForMultipleInputs([input], outputs);
      final outputData = outputs[0]! as List;
      
      // DEBUG: Print output info based on model type
      if (ModelLoader.isClassificationModel) {
        // Classification model: output is [1, numClasses]
        final classScores = (outputData)[0] as List;
        print('📤 Class logits: ${classScores.map((v) => (v as double).toStringAsFixed(4)).toList()}');
      } else if (outputData.isNotEmpty && outputData[0] is List && (outputData[0] as List).isNotEmpty) {
        final features = outputData[0] as List;
        print('📤 Output row 0 (cx): ${(features[0] as List).take(5).map((v) => (v as double).toStringAsFixed(6)).toList()}');
        print('📤 Output row 4 (class0): ${(features[4] as List).take(5).map((v) => (v as double).toStringAsFixed(6)).toList()}');
        print('📤 Output row 10 (class6): ${(features[10] as List).take(5).map((v) => (v as double).toStringAsFixed(6)).toList()}');
        
        // Check raw logits and sigmoid-applied scores
        double maxRawScore = -double.infinity;
        double minRawScore = double.infinity;
        for (int row = 4; row < 11; row++) {
          for (var val in (features[row] as List)) {
            final v = val as double;
            if (v > maxRawScore) maxRawScore = v;
            if (v < minRawScore) minRawScore = v;
          }
        }
        // Apply sigmoid to see actual probabilities
        double sigmoid(double x) => 1.0 / (1.0 + math.exp(-x));
        print('📊 Raw logit range: min=${minRawScore.toStringAsFixed(4)}, max=${maxRawScore.toStringAsFixed(4)}');
        print('📊 After sigmoid: min=${sigmoid(minRawScore).toStringAsFixed(4)}, max=${sigmoid(maxRawScore).toStringAsFixed(4)}');
      }
      
      // Process results using detector
      final detections = _detector!.processOutput(outputData);
      if (mounted) {
        setState(() => _detections = detections);
      }
    } catch (e) {
      print('Frame processing error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  /// Convert camera image to RGB (handles both iOS BGRA and Android YUV420)
  img.Image? _convertYUV420ToImage(CameraImage cameraImage) {
    try {
      // iOS: BGRA format (single plane)
      if (cameraImage.planes.length == 1) {
        return _convertBGRA(cameraImage);
      }
      
      // Android: YUV420 format (3 planes)
      if (cameraImage.planes.length == 3) {
        return _convertYUV420(cameraImage);
      }
      
      print('Unsupported camera format: ${cameraImage.planes.length} planes');
      return null;
      
    } catch (e, stackTrace) {
      print('Camera conversion error: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Convert BGRA (iOS single plane) to RGB
  img.Image _convertBGRA(CameraImage cameraImage) {
    final plane = cameraImage.planes[0];
    final bytes = plane.bytes;
    final int width = cameraImage.width;
    final int height = cameraImage.height;
    
    final img.Image image = img.Image(width: width, height: height);
    
    final int bytesPerPixel = plane.bytesPerPixel ?? 4;
    final int bytesPerRow = plane.bytesPerRow;
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int pixelIndex = y * bytesPerRow + x * bytesPerPixel;
        
        // Ensure we have enough bytes for R, G, B
        if (pixelIndex + 2 >= bytes.length) continue;
        
        // BGRA format: B=0, G=1, R=2, A=3
        final int b = bytes[pixelIndex];
        final int g = bytes[pixelIndex + 1];
        final int r = bytes[pixelIndex + 2];
        
        image.setPixelRgb(x, y, r, g, b);
      }
    }
    
    return image;
  }

  /// Convert YUV420 (Android 3 planes) to RGB
  img.Image _convertYUV420(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;
    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;
    
    final img.Image image = img.Image(width: width, height: height);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex = (uvPixelStride * (x / 2).floor()) + 
                           (uvRowStride * (y / 2).floor());
        final int index = y * width + x;
        
        // Get YUV values with bounds checking
        if (index >= cameraImage.planes[0].bytes.length) continue;
        if (uvIndex >= cameraImage.planes[1].bytes.length) continue;
        if (uvIndex >= cameraImage.planes[2].bytes.length) continue;
        
        final int yp = cameraImage.planes[0].bytes[index];
        final int up = cameraImage.planes[1].bytes[uvIndex];
        final int vp = cameraImage.planes[2].bytes[uvIndex];
        
        // YUV to RGB conversion (exact formula from Stack Overflow)
        int r = (yp + (vp * 1436 / 1024 - 179)).round().clamp(0, 255);
        int g = (yp - (up * 46549 / 131072) + 44 - (vp * 93604 / 131072) + 91).round().clamp(0, 255);
        int b = (yp + (up * 1814 / 1024 - 227)).round().clamp(0, 255);
        
        image.setPixelRgb(x, y, r, g, b);
      }
    }
    
    return image;
  }

  // ==================== BACKUP IMAGE MODE ====================
  // These methods are only used when camera is unavailable
  
  /// Pick image from gallery (backup mode only)
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      
      if (pickedFile != null) {
        final bytes = await File(pickedFile.path).readAsBytes();
        setState(() => _testImageBytes = bytes);
        await _detectObjectsInStaticImage(bytes);
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  /// Load test image from assets (backup mode only)
  Future<void> _loadTestImage() async {
    try {
      final data = await rootBundle.load('assets/test_image.jpg');
      final bytes = data.buffer.asUint8List();
      setState(() => _testImageBytes = bytes);
      await _detectObjectsInStaticImage(bytes);
    } catch (e) {
      print('Error: No test image found in assets folder');
    }
  }

  /// Run detection on a static image (backup mode only)
  Future<void> _detectObjectsInStaticImage(Uint8List imageBytes) async {
    if (_detector == null) return;

    setState(() => _isDetecting = true);

    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('Failed to decode image');

      // Get model requirements
      final inputShape = ModelLoader.interpreter.getInputTensor(0).shape;
      final inputSize = inputShape[1]; // Assume square input

      // Preprocess image using detector
      final inputBytes = _detector!.preprocessImage(image, inputSize);
      final input = inputBytes.reshape([1, inputSize, inputSize, 3]);

      // Prepare output buffer based on model type
      final outputShape = ModelLoader.interpreter.getOutputTensor(0).shape;
      dynamic output;
      if (outputShape.length == 2) {
        // Classification model: [1, numClasses]
        output = List.generate(
          outputShape[0],
          (i) => List.filled(outputShape[1], 0.0),
        );
      } else {
        // Detection model: [1, features, predictions]
        output = List.generate(
          outputShape[0],
          (i) => List.generate(
            outputShape[1],
            (j) => List.filled(outputShape[2], 0.0),
          ),
        );
      }

      // Run inference
      ModelLoader.interpreter.run(input, output);

      // Process results using detector
      setState(() => _detections = _detector!.processOutput(output));
      
      print('Found ${_detections?.length ?? 0} home repair issues');
    } catch (e) {
      print('Detection error: $e');
    } finally {
      setState(() => _isDetecting = false);
    }
  }


  /// Capture image and run detection
  Future<void> _captureAndDetect() async {
    if (_controller == null || !_controller!.value.isInitialized || _detector == null) {
      print('Camera or detector not ready');
      return;
    }

    setState(() => _isDetecting = true);

    try {
      // Capture image
      final XFile image = await _controller!.takePicture();
      final bytes = await File(image.path).readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      
      if (decodedImage == null) {
        print('Failed to decode captured image');
        setState(() => _isDetecting = false);
        return;
      }

      // Get model requirements
      final inputShape = ModelLoader.interpreter.getInputTensor(0).shape;
      final inputSize = inputShape[1];

      // Preprocess and run detection
      final inputBytes = _detector!.preprocessImage(decodedImage, inputSize);
      final input = inputBytes.reshape([1, inputSize, inputSize, 3]);

      final outputShape = ModelLoader.interpreter.getOutputTensor(0).shape;
      dynamic output;
      if (outputShape.length == 2) {
        // Classification model: [1, numClasses]
        output = List.generate(
          outputShape[0],
          (i) => List.filled(outputShape[1], 0.0),
        );
      } else {
        // Detection model: [1, features, predictions]
        output = List.generate(
          outputShape[0],
          (i) => List.generate(
            outputShape[1],
            (j) => List.filled(outputShape[2], 0.0),
          ),
        );
      }

      ModelLoader.interpreter.run(input, output);
      final detections = _detector!.processOutput(output);

      // Store detections (avoid duplicates by checking confidence and class)
      for (var detection in detections) {
        _capturedDetections.add({
          'class': detection['label'],
          'confidence': detection['confidence'],
        });
      }

      print('Captured image with ${detections.length} detections. Total: ${_capturedDetections.length}');
      
      // Update state to show in top bar
      if (mounted) {
        setState(() {}); // Trigger rebuild to update top bar
      }
    } catch (e) {
      print('Error capturing and detecting: $e');
    } finally {
      setState(() => _isDetecting = false);
    }
  }

  /// Generate cost report from captured detections (deduplicated)
  void _generateReport() {
    if (_capturedDetections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No defects captured. Take photos first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pricePredictor = PricePredictor();
    
    // Deduplicate detections by grouping similar classes with high confidence
    final Map<String, double> deduplicatedMap = {};
    for (var detection in _capturedDetections) {
      final className = detection['class'] as String;
      final confidence = detection['confidence'] as double;
      
      // Keep the highest confidence for each class
      if (!deduplicatedMap.containsKey(className) || 
          deduplicatedMap[className]! < confidence) {
        deduplicatedMap[className] = confidence;
      }
    }
    
    // Convert back to list format
    final detectionsForPredictor = deduplicatedMap.entries.map((e) => {
      'class': e.key,
      'confidence': e.value,
    }).toList();
    
    print('Deduplicated ${_capturedDetections.length} detections to ${detectionsForPredictor.length} unique defects');
    
    // Get cost predictions
    final predictedDetections = pricePredictor.predictBatch(detectionsForPredictor);
    
    // Navigate to report screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DefectReportScreen(
          detections: predictedDetections,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    ModelLoader.dispose();
    super.dispose();
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    // Show loading while model initializes
    if (!_isModelLoaded) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading model...'),
            ],
          ),
        ),
      );
    }

    // PRIMARY MODE: Live camera detection
    if (_isCameraAvailable && _controller?.value.isInitialized == true) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Camera preview
            Positioned.fill(
              child: CameraPreview(_controller!),
            ),
            // Detection overlay (live detection boxes)
            if (_detections != null)
              ..._detections!.map((d) => _buildDetectionBox(d)),
            // Status indicator
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: _buildDetectionStatus(),
            ),
            // Bottom controls
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: _buildCameraControls(),
            ),
          ],
        ),
      );
    }

    // BACKUP MODE: Static image detection (no camera)
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
              if (_testImageBytes == null) ...[
                // No image selected
                const Icon(Icons.no_photography, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Camera not available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                  'Use images for testing',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _pickImageFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Pick from Gallery'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _loadTestImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Use Test Image'),
                ),
              ] else ...[
                // Show image with detections
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Image.memory(_testImageBytes!),
                        if (_detections != null)
                          ..._detections!.map((d) => _buildDetectionBoxForImage(d, constraints)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildDetectionsList(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _detections != null && _detections!.isNotEmpty
                          ? _generateReport
                          : null,
                      icon: const Icon(Icons.assessment),
                      label: const Text('Generate Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => setState(() {
                        _testImageBytes = null;
                        _detections = null;
                      }),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Another'),
                    ),
                  ],
                ),
              ],
            ],
          ),
          ),
        ),
      );
    }

  /// Build detection status indicator
  Widget _buildDetectionStatus() {
    // Build detection info text
    String statusText = 'Scanning...';
    IconData statusIcon = Icons.search;
    
    if (_detections != null && _detections!.isNotEmpty) {
      statusIcon = Icons.check_circle;
      final detectionsText = _detections!.take(3).map((d) => 
        '${d['label']}: ${((d['confidence'] as double) * 100).toStringAsFixed(0)}%'
      ).join(', ');
      final moreText = _detections!.length > 3 ? ' (+${_detections!.length - 3} more)' : '';
      statusText = '${_detections!.length} detected: $detectionsText$moreText';
    }
    
    // Add captured defects info if any
    String capturedText = '';
    if (_capturedDetections.isNotEmpty) {
      capturedText = ' | ${_capturedDetections.length} captured';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              '$statusText$capturedText',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Build camera controls (capture and report buttons)
  Widget _buildCameraControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Generate Report button
        if (_capturedDetections.isNotEmpty)
          ElevatedButton.icon(
            onPressed: _generateReport,
            icon: const Icon(Icons.assessment),
            label: const Text('Generate Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
          ),
        if (_capturedDetections.isNotEmpty)
          const SizedBox(width: 16),
        // Capture button
        FloatingActionButton.large(
          onPressed: _isDetecting ? null : _captureAndDetect,
          backgroundColor: Colors.white,
          child: _isDetecting
              ? const CircularProgressIndicator(strokeWidth: 2)
              : const Icon(Icons.camera_alt, size: 32, color: Colors.black),
        ),
      ],
    );
  }

  /// Build detection results list
  Widget _buildDetectionsList() {
    if (_detections == null || _detections!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detected:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ..._detections!.map((d) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '• ${d['label']}: ${(d['confidence'] * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white),
            ),
          )),
        ],
      ),
    );
  }

  /// Build bounding box for live camera detection
  Widget _buildDetectionBox(Map<String, dynamic> detection) {
    final bbox = detection['bbox'] as List<double>;
    final label = detection['label'] as String;
    final confidence = detection['confidence'] as double;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Positioned(
      left: bbox[0] * screenWidth,
      top: bbox[1] * screenHeight,
      width: bbox[2] * screenWidth,
      height: bbox[3] * screenHeight,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.greenAccent, width: 2),
        ),
        child: Align(
          alignment: Alignment.topLeft,
              child: Container(
            color: Colors.greenAccent,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Text(
                  '$label ${(confidence * 100).toInt()}%',
                  style: const TextStyle(
                color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
      ),
    );
  }

  /// Build bounding box for static image detection
  Widget _buildDetectionBoxForImage(Map<String, dynamic> detection, BoxConstraints constraints) {
    final bbox = detection['bbox'] as List<double>;
    final label = detection['label'] as String;
    final confidence = detection['confidence'] as double;
    
    return Positioned(
      left: bbox[0] * constraints.maxWidth,
      top: bbox[1] * constraints.maxHeight,
      width: bbox[2] * constraints.maxWidth,
      height: bbox[3] * constraints.maxHeight,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.redAccent, width: 3),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            color: Colors.redAccent,
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
      ),
    );
  }
}
