import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math';

class HeadNodsDetector {
  final int targetReps;
  final Function(int) onRepComplete;
  final Function() onExerciseComplete;

  int _currentReps = 0;
  bool _isTurningRight = false;
  double? _previousHeadAngle;
  static const double _rotationThreshold = 15.0; // degrees of head rotation
  
  // Throttling for logs
  DateTime? _lastLogTime;
  static const Duration _logThrottle = Duration(milliseconds: 200);

  HeadNodsDetector({
    required this.targetReps,
    required this.onRepComplete,
    required this.onExerciseComplete,
  });

  void processPose(Pose pose) {
    final now = DateTime.now();
    final shouldLog = _lastLogTime == null || now.difference(_lastLogTime!) >= _logThrottle;
    
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftEar = pose.landmarks[PoseLandmarkType.leftEar];
    final rightEar = pose.landmarks[PoseLandmarkType.rightEar];
    
    // Need all three landmarks to calculate head rotation
    if (nose == null || leftEar == null || rightEar == null) {
      if (shouldLog) {
        print('⚠️ [HeadNods] Required landmarks not detected');
        _lastLogTime = now;
      }
      return;
    }
    
    if (nose.likelihood < 0.7 || leftEar.likelihood < 0.5 || rightEar.likelihood < 0.5) {
      if (shouldLog) {
        print('⚠️ [HeadNods] Low confidence - Nose: ${(nose.likelihood * 100).toStringAsFixed(0)}%, Left Ear: ${(leftEar.likelihood * 100).toStringAsFixed(0)}%, Right Ear: ${(rightEar.likelihood * 100).toStringAsFixed(0)}%');
        _lastLogTime = now;
      }
      return;
    }

    // Calculate head rotation angle using ear positions
    // When head is straight: ears are roughly at same X position
    // When head turns right: left ear X > right ear X (left ear more visible)
    // When head turns left: right ear X > left ear X (right ear more visible)
    final earMidpointX = (leftEar.x + rightEar.x) / 2;
    final earMidpointY = (leftEar.y + rightEar.y) / 2;
    
    // Calculate angle using nose position relative to ear midpoint
    final deltaX = nose.x - earMidpointX;
    final deltaY = nose.y - earMidpointY;
    final currentHeadAngle = atan2(deltaX, deltaY) * (180 / pi);
    
    if (shouldLog) {
      print('📐 [HeadNods] Head Rotation: ${currentHeadAngle.toStringAsFixed(1)}° | Confidence: ${(nose.likelihood * 100).toStringAsFixed(0)}%');
      print('📍 [HeadNods] Nose: (${nose.x.toStringAsFixed(0)}, ${nose.y.toStringAsFixed(0)}) | Left Ear: (${leftEar.x.toStringAsFixed(0)}, ${leftEar.y.toStringAsFixed(0)}) | Right Ear: (${rightEar.x.toStringAsFixed(0)}, ${rightEar.y.toStringAsFixed(0)})');
    }

    if (_previousHeadAngle != null) {
      final angleDelta = currentHeadAngle - _previousHeadAngle!;
      final absAngleDelta = angleDelta.abs();
      
      if (shouldLog) {
        print('📊 [HeadNods] Angle Delta: ${angleDelta.toStringAsFixed(1)}° | Abs: ${absAngleDelta.toStringAsFixed(1)}° | Threshold: $_rotationThreshold° | State: ${_isTurningRight ? "TURNING_RIGHT" : "NEUTRAL"}');
        _lastLogTime = now;
      }

      // Detect rightward turn (positive angle change)
      if (!_isTurningRight && angleDelta > _rotationThreshold) {
        _isTurningRight = true;
        print('👉 [HeadNods] ✅ RIGHT TURN DETECTED! Rotation: +${angleDelta.toStringAsFixed(1)}°');
      }
      // Detect leftward turn completion (negative angle change)
      else if (_isTurningRight && angleDelta < -_rotationThreshold) {
        _isTurningRight = false;
        _currentReps++;
        print('👈 [HeadNods] ✅ LEFT TURN COMPLETED! Rotation: ${angleDelta.toStringAsFixed(1)}°');
        print('🎯 [HeadNods] REP COMPLETED! Total Reps: $_currentReps/$targetReps');
        
        onRepComplete(_currentReps);

        if (_currentReps >= targetReps) {
          print('🎉 [HeadNods] 🏆 EXERCISE COMPLETE! All $_currentReps reps done!');
          onExerciseComplete();
        }
      }
    } else {
      print('🔄 [HeadNods] Initializing... First frame detected');
    }

    _previousHeadAngle = currentHeadAngle;
  }

  void reset() {
    _currentReps = 0;
    _isTurningRight = false;
    _previousHeadAngle = null;
  }
}
