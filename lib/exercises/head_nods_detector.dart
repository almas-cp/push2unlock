import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math';

class HeadNodsDetector {
  final int targetReps;
  final Function(int) onRepComplete;
  final Function() onExerciseComplete;

  int _currentReps = 0;
  String _currentState = 'NEUTRAL'; // NEUTRAL, TURNED_LEFT, TURNED_RIGHT
  double? _previousHeadAngle;
  double? _neutralAngle; // Reference angle when head is centered
  static const double _turnThreshold = 40.0; // degrees to detect turn (increased for better accuracy)
  static const double _returnThreshold = 15.0; // degrees to return to center
  
  // Throttling for logs
  DateTime? _lastLogTime;
  static const Duration _logThrottle = Duration(milliseconds: 200);
  
  // Cooldown to prevent rapid counting
  DateTime? _lastRepTime;
  static const Duration _repCooldown = Duration(milliseconds: 500);
  
  // Calibration for neutral angle
  List<double> _calibrationAngles = [];
  static const int _calibrationFrames = 10;

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
    
    // Calibrate neutral angle over first few frames
    if (_calibrationAngles.length < _calibrationFrames) {
      _calibrationAngles.add(currentHeadAngle);
      if (shouldLog) {
        print('🔄 [HeadNods] Calibrating... Frame ${_calibrationAngles.length}/$_calibrationFrames | Angle: ${currentHeadAngle.toStringAsFixed(1)}°');
        _lastLogTime = now;
      }
      
      if (_calibrationAngles.length == _calibrationFrames) {
        // Calculate average as neutral angle
        _neutralAngle = _calibrationAngles.reduce((a, b) => a + b) / _calibrationAngles.length;
        print('✅ [HeadNods] Calibration complete! Neutral angle: ${_neutralAngle!.toStringAsFixed(1)}°');
      }
      _previousHeadAngle = currentHeadAngle;
      return;
    }
    
    if (shouldLog) {
      print('📐 [HeadNods] Head Rotation: ${currentHeadAngle.toStringAsFixed(1)}° | Neutral: ${_neutralAngle!.toStringAsFixed(1)}° | Confidence: ${(nose.likelihood * 100).toStringAsFixed(0)}%');
      print('📍 [HeadNods] Nose: (${nose.x.toStringAsFixed(0)}, ${nose.y.toStringAsFixed(0)}) | Left Ear: (${leftEar.x.toStringAsFixed(0)}, ${leftEar.y.toStringAsFixed(0)}) | Right Ear: (${rightEar.x.toStringAsFixed(0)}, ${rightEar.y.toStringAsFixed(0)})');
    }

    if (_previousHeadAngle != null && _neutralAngle != null) {
      final deviationFromNeutral = currentHeadAngle - _neutralAngle!;
      final absDeviation = deviationFromNeutral.abs();
      
      if (shouldLog) {
        print('📊 [HeadNods] Deviation: ${deviationFromNeutral.toStringAsFixed(1)}° | Abs: ${absDeviation.toStringAsFixed(1)}° | Turn Threshold: $_turnThreshold° | Return Threshold: $_returnThreshold° | State: $_currentState');
        _lastLogTime = now;
      }

      // Check cooldown
      final canCountRep = _lastRepTime == null || now.difference(_lastRepTime!) >= _repCooldown;

      // State machine for turn detection
      if (_currentState == 'NEUTRAL') {
        // Detect left turn (negative deviation)
        if (deviationFromNeutral < -_turnThreshold) {
          _currentState = 'TURNED_LEFT';
          print('👈 [HeadNods] ✅ LEFT TURN DETECTED! Deviation: ${deviationFromNeutral.toStringAsFixed(1)}° from neutral');
        }
        // Detect right turn (positive deviation)
        else if (deviationFromNeutral > _turnThreshold) {
          _currentState = 'TURNED_RIGHT';
          print('👉 [HeadNods] ✅ RIGHT TURN DETECTED! Deviation: +${deviationFromNeutral.toStringAsFixed(1)}° from neutral');
        }
      }
      // Return to center from any turn
      else if (absDeviation < _returnThreshold && canCountRep) {
        final direction = _currentState == 'TURNED_LEFT' ? 'left' : 'right';
        _currentState = 'NEUTRAL';
        _currentReps++;
        _lastRepTime = now;
        print('↩️ [HeadNods] ✅ RETURNED TO CENTER from $direction! Deviation: ${deviationFromNeutral.toStringAsFixed(1)}°');
        print('🎯 [HeadNods] REP COMPLETED! Total Reps: $_currentReps/$targetReps');
        
        // Update neutral angle slightly (account for small movements)
        _neutralAngle = (_neutralAngle! * 0.9) + (currentHeadAngle * 0.1);
        
        onRepComplete(_currentReps);

        if (_currentReps >= targetReps) {
          print('🎉 [HeadNods] 🏆 EXERCISE COMPLETE! All $_currentReps reps done!');
          onExerciseComplete();
        }
      }
    }

    _previousHeadAngle = currentHeadAngle;
  }

  void reset() {
    _currentReps = 0;
    _currentState = 'NEUTRAL';
    _previousHeadAngle = null;
    _neutralAngle = null;
    _lastRepTime = null;
    _calibrationAngles.clear();
  }
}
