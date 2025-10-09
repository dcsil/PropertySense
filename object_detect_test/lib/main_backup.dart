import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Camera not available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'This app requires a physical device with a camera.\nThe iOS Simulator does not support camera access.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Simulate detection for demo purposes
                  setState(() {
                    _recognitions = [
                      {
                        'label': 'Demo Object',
                        'confidence': 0.85,
                        'bbox': [0.2, 0.3, 0.6, 0.7],
                      }
                    ];
                  });
                },
                child: const Text('Demo Detection'),
              ),
            ],
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
}
