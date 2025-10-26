import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../widgets/pose_painter.dart';
import '../exercises/head_nods_detector.dart';
import '../exercises/squats_detector.dart';
import '../exercises/pushups_detector.dart';

class ExercisePage extends StatefulWidget {
  final String exerciseType;
  final int repCount;
  final int rewardTime;

  const ExercisePage({
    super.key,
    required this.exerciseType,
    required this.repCount,
    required this.rewardTime,
  });

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  bool _isDetecting = false;
  bool _isCameraInitialized = false;
  
  Pose? _currentPose;
  int _currentReps = 0;
  bool _exerciseComplete = false;
  
  // Exercise detector
  dynamic _exerciseDetector;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializePoseDetector();
    _initializeExerciseDetector();
  }

  void _initializeExerciseDetector() {
    switch (widget.exerciseType.toLowerCase()) {
      case 'head nods':
        _exerciseDetector = HeadNodsDetector(
          targetReps: widget.repCount,
          onRepComplete: _onRepComplete,
          onExerciseComplete: _onExerciseComplete,
        );
        break;
      case 'squats':
        _exerciseDetector = SquatsDetector(
          targetReps: widget.repCount,
          onRepComplete: _onRepComplete,
          onExerciseComplete: _onExerciseComplete,
        );
        break;
      case 'pushups':
        _exerciseDetector = PushupsDetector(
          targetReps: widget.repCount,
          onRepComplete: _onRepComplete,
          onExerciseComplete: _onExerciseComplete,
        );
        break;
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21, // Force NV21 for Android
      );

      await _cameraController!.initialize();
      await _cameraController!.startImageStream(_processCameraImage);

      setState(() {
        _isCameraInitialized = true;
      });

      print('✅ Camera initialized successfully');
    } catch (e) {
      print('❌ Error initializing camera: $e');
    }
  }

  void _initializePoseDetector() {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    );
    _poseDetector = PoseDetector(options: options);
    print('✅ Pose detector initialized');
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || _exerciseComplete) return;
    _isDetecting = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage != null) {
        final poses = await _poseDetector!.processImage(inputImage);
        
        if (poses.isNotEmpty) {
          setState(() {
            _currentPose = poses.first;
          });
          
          // Process pose with exercise detector
          _exerciseDetector?.processPose(poses.first);
        }
      }
    } catch (e) {
      print('❌ Error processing image: $e');
    }

    _isDetecting = false;
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final camera = _cameraController!.description;
      
      InputImageRotation rotation;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotation = InputImageRotation.rotation270deg;
      } else {
        rotation = InputImageRotation.rotation90deg;
      }

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) {
        print('⚠️ Unsupported format: ${image.format.raw}');
        return null;
      }

      // For Android, we need to handle NV21 format
      if (image.format.group == ImageFormatGroup.nv21 ||
          image.format.group == ImageFormatGroup.yuv420) {
        return InputImage.fromBytes(
          bytes: image.planes[0].bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: format,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      }
      
      // For other formats
      return InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (e) {
      print('❌ Error converting camera image: $e');
      return null;
    }
  }

  void _onRepComplete(int reps) {
    setState(() {
      _currentReps = reps;
    });
    print('✅ Rep completed! Total: $reps/${widget.repCount}');
  }

  void _onExerciseComplete() {
    setState(() {
      _exerciseComplete = true;
    });
    print('🎉 Exercise complete!');
    
    // Return with reward time
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context, widget.rewardTime);
      }
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            if (_isCameraInitialized && _cameraController != null)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _cameraController!.value.previewSize!.height,
                    height: _cameraController!.value.previewSize!.width,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Pose Overlay
            if (_currentPose != null && _isCameraInitialized)
              Positioned.fill(
                child: CustomPaint(
                  painter: PosePainter(
                    pose: _currentPose!,
                    imageSize: Size(
                      _cameraController!.value.previewSize!.height,
                      _cameraController!.value.previewSize!.width,
                    ),
                  ),
                ),
              ),

            // Top Info Bar
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Exercise Type
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        widget.exerciseType.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Rep Counter
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: _exerciseComplete 
                            ? Colors.green.withOpacity(0.9)
                            : Colors.blue.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _exerciseComplete 
                            ? 'COMPLETE! 🎉'
                            : '$_currentReps / ${widget.repCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Close Button
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
