import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';

class HandDetectionSkeletonScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const HandDetectionSkeletonScreen({super.key, required this.cameras});

  @override
  State<HandDetectionSkeletonScreen> createState() => _HandDetectionScreenState();
}

class _HandDetectionScreenState extends State<HandDetectionSkeletonScreen> {
  static const platform = MethodChannel('handychat');
  CameraController? _cameraController;
  bool _isDetecting = false;
  int _selectedCameraIndex = 0;
  List<List<double>> _handPoints = [];
  late Interpreter _interpreter;
  String _prediction = "";
  String _sentence = "";
  final List<String> _labels = [
    'A','B','C','D','E','F','G','H','I','J','K','L',
    'M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','space'
  ];
  int _frameCount = 0;
  final int _predictEveryXFrames = 10;
  final FlutterTts flutterTts = FlutterTts();

  // Getter for camera type
  String get _cameraType => _selectedCameraIndex == 1 ? "Front" : "Back";

  @override
  void initState() {
    super.initState();
    _initializeCamera(_selectedCameraIndex);
    _setupNativeListener();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/tflite/model_unquant.tflite');
    } catch (e) {
      debugPrint('Error loading model: $e');
    }
  }

  Future<void> _initializeCamera(int cameraIndex) async {
    if (widget.cameras.isEmpty) return;
    _cameraController?.dispose();

    _cameraController = CameraController(
      widget.cameras[cameraIndex],
      ResolutionPreset.low,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {}); // Trigger rebuild to update camera type display
      _startFrameProcessing();
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  void _setupNativeListener() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'handLandmarkerResult') {
        final points = (call.arguments['points'] as List)
            .map((e) => List<double>.from(e))
            .toList();
        setState(() {
          _handPoints = points;
          // Clear prediction if no hand points detected
          if (points.isEmpty) {
            _prediction = "";
          }
        });

        _frameCount++;
        if (_frameCount % _predictEveryXFrames == 0 && points.isNotEmpty) {
          _predictFromSkeleton();
        }
      }
    });
  }

  void _startFrameProcessing() {
    if (_cameraController == null) return;

    _cameraController?.startImageStream((CameraImage image) async {
      if (_isDetecting) return;
      _isDetecting = true;

      try {
        final Uint8List bytes = await _convertYUV420ToByteArray(image);
        await platform.invokeMethod('handMarker', {
          'bytes': bytes,
          'width': image.width,
          'height': image.height,
          'isFrontCamera': _selectedCameraIndex == 1,
        });
      } catch (e) {
        debugPrint('Error processing frame: $e');
      }

      _isDetecting = false;
    });
  }

  Future<Uint8List> _convertYUV420ToByteArray(CameraImage image) async {
    try {
      final int width = image.width;
      final int height = image.height;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel!;

      final Uint8List yuvBytes = Uint8List(width * height * 3 ~/ 2);

      int yIndex = 0;
      int uvIndex = width * height;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          yuvBytes[yIndex++] =
          image.planes[0].bytes[y * image.planes[0].bytesPerRow + x];
        }
      }

      for (int y = 0; y < height ~/ 2; y++) {
        for (int x = 0; x < width ~/ 2; x++) {
          int uvOffset = y * uvRowStride + x * uvPixelStride;
          yuvBytes[uvIndex++] = image.planes[1].bytes[uvOffset];
          yuvBytes[uvIndex++] = image.planes[2].bytes[uvOffset];
        }
      }
      return yuvBytes;
    } catch (e) {
      debugPrint('Error converting image: $e');
      return Uint8List(0);
    }
  }

  Future<void> _predictFromSkeleton() async {
    try {
      ui.Image skeletonImage = await _createSkeletonImage(_handPoints, 300);
      ByteData? byteData =
      await skeletonImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return;

      Uint8List rgbaBytes = byteData.buffer.asUint8List();
      List<double> input = [];
      for (int i = 0; i < rgbaBytes.length; i += 4) {
        input.addAll([
          rgbaBytes[i] / 255.0,
          rgbaBytes[i + 1] / 255.0,
          rgbaBytes[i + 2] / 255.0,
        ]);
      }

      final modelInput = [
        List.generate(300, (y) {
          return List.generate(300, (x) {
            int idx = (y * 300 + x) * 3;
            return [input[idx], input[idx + 1], input[idx + 2]];
          });
        })
      ];

      var output = [List.filled(_labels.length, 0.0)];
      _interpreter.run(modelInput, output);

      int maxIndex = output[0]
          .indexOf(output[0].reduce((curr, next) => curr > next ? curr : next));

      setState(() {
        _prediction = _labels[maxIndex];
      });
    } catch (e) {
      debugPrint('Prediction failed: $e');
    }
  }

  Future<ui.Image> _createSkeletonImage(List<List<double>> points, int size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));

    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      Paint()..color = Colors.white,
    );

    if (points.isEmpty) {
      final picture = recorder.endRecording();
      return picture.toImage(size, size);
    }

    // Calculate bounding box
    double minX = points.map((p) => p[0]).reduce(min);
    double minY = points.map((p) => p[1]).reduce(min);
    double maxX = points.map((p) => p[0]).reduce(max);
    double maxY = points.map((p) => p[1]).reduce(max);

    double boxSize = max(maxX - minX, maxY - minY);
    if (boxSize == 0) boxSize = 1;

    double margin = size * 0.1;
    double scale = (size - 2 * margin) / boxSize;
    double centerX = (minX + maxX) / 2;
    double centerY = (minY + maxY) / 2;

    // Draw connections
    final connections = [
      [0,1],[1,2],[2,3],[3,4],   // Thumb
      [0,5],[5,6],[6,7],[7,8],     // Index finger
      [5,9],[9,10],[10,11],[11,12], // Middle finger
      [9,13],[13,14],[14,15],[15,16], // Ring finger
      [13,17],[17,18],[18,19],[19,20], // Little finger
      [0,17] // Wrist connection
    ];

    final linePaint = Paint()
      ..color = const Color(0xFF00FF00)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (var connection in connections) {
      if (connection[0] >= points.length || connection[1] >= points.length) continue;

      final start = points[connection[0]];
      final end = points[connection[1]];

      canvas.drawLine(
        Offset(
          (start[0] - centerX) * scale + size / 2,
          (start[1] - centerY) * scale + size / 2,
        ),
        Offset(
          (end[0] - centerX) * scale + size / 2,
          (end[1] - centerY) * scale + size / 2,
        ),
        linePaint,
      );
    }

    // Draw joints
    final jointPaint = Paint()
      ..color = const Color(0xFF0000FF)
      ..style = PaintingStyle.fill;

    for (var point in points) {
      canvas.drawCircle(
        Offset(
          (point[0] - centerX) * scale + size / 2,
          (point[1] - centerY) * scale + size / 2,
        ),
        4.0,
        jointPaint,
      );
    }

    final picture = recorder.endRecording();
    return picture.toImage(size, size);
  }

  void _switchCamera() {
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
      _initializeCamera(_selectedCameraIndex);
    });
  }

  void _confirmPrediction() {
    setState(() {
      _sentence += _prediction == "space" ? " " : _prediction;
      _prediction = "";
    });
  }

  void _clearPrediction() {
    setState(() {
      _prediction = "";
    });
  }

  void _clearSentence() {
    setState(() {
      _sentence = "";
    });
  }

  void _deleteLastCharacter() {
    if (_sentence.isEmpty) return;
    setState(() {
      _sentence = _sentence.substring(0, _sentence.length - 1);
    });
  }

  Future<void> _speakSentence() async {
    if (_sentence.isEmpty) return;

    try {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setPitch(1.0);
      await flutterTts.speak(_sentence);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _interpreter.close();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181F39),
        title: const Text(
          "Hand Detection",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Camera type indicator
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF181F39),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "$_cameraType Camera",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // White Box with Hand Landmarks
            Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _handPoints.isEmpty
                  ? const Center(
                child: Text(
                  "No hand detected",
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : CustomPaint(
                painter: _SkeletonDebugPainter(_handPoints),
              ),
            ),
            const SizedBox(height: 24),

            // Prediction and Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Current Prediction:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF181F39),
                        ),
                      ),
                      Text(
                        _prediction.isEmpty ? "-" : _prediction,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF181F39),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _handPoints.isEmpty ? null : _confirmPrediction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A80F0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        child: const Text(
                          "Confirm",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sentence Display
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _sentence.isEmpty ? "Your sentence will appear here" : _sentence,
                            style: TextStyle(
                              fontSize: 18,
                              color: _sentence.isEmpty
                                  ? Colors.grey
                                  : const Color(0xFF181F39),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _deleteLastCharacter,
                              onLongPress: _clearSentence,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.withOpacity(0.2),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _speakSentence,
                              icon: const Icon(Icons.volume_up, color: Color(0xFF4A80F0)),
                              tooltip: "Speak sentence",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _switchCamera,
        backgroundColor: const Color(0xFF4A80F0),
        child: const Icon(Icons.cameraswitch, color: Colors.white),
      ),
    );
  }
}

class _SkeletonDebugPainter extends CustomPainter {
  final List<List<double>> points;
  _SkeletonDebugPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Calculate bounding box
    double minX = points.map((p) => p[0]).reduce(min);
    double minY = points.map((p) => p[1]).reduce(min);
    double maxX = points.map((p) => p[0]).reduce(max);
    double maxY = points.map((p) => p[1]).reduce(max);

    double boxSize = max(maxX - minX, maxY - minY);
    if (boxSize == 0) boxSize = 1;

    double margin = size.width * 0.1;
    double scale = (size.width - 2 * margin) / boxSize;
    double centerX = (minX + maxX) / 2;
    double centerY = (minY + maxY) / 2;

    // Draw connections
    final connections = [
      [0,1],[1,2],[2,3],[3,4],   // Thumb
      [0,5],[5,6],[6,7],[7,8],     // Index finger
      [5,9],[9,10],[10,11],[11,12], // Middle finger
      [9,13],[13,14],[14,15],[15,16], // Ring finger
      [13,17],[17,18],[18,19],[19,20], // Little finger
      [0,17] // Wrist connection
    ];

    final linePaint = Paint()
      ..color = const Color(0xFF00FF00)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (var connection in connections) {
      if (connection[0] >= points.length || connection[1] >= points.length) continue;

      final start = points[connection[0]];
      final end = points[connection[1]];

      canvas.drawLine(
        Offset(
          (start[0] - centerX) * scale + size.width / 2,
          (start[1] - centerY) * scale + size.height / 2,
        ),
        Offset(
          (end[0] - centerX) * scale + size.width / 2,
          (end[1] - centerY) * scale + size.height / 2,
        ),
        linePaint,
      );
    }

    // Draw joints
    final jointPaint = Paint()
      ..color = const Color(0xFF0000FF)
      ..style = PaintingStyle.fill;

    for (var point in points) {
      canvas.drawCircle(
        Offset(
          (point[0] - centerX) * scale + size.width / 2,
          (point[1] - centerY) * scale + size.height / 2,
        ),
        4.0,
        jointPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
