import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math';

class PushupsDetector {
  final int targetReps;
  final Function(int) onRepComplete;
  final Function() onExerciseComplete;

  int _currentReps = 0;
  bool _isPushingDown = false;
  double? _previousNoseToWristDistance;
  double? _maxNoseToWristDistance; // Reference distance when up
  static const double _closeThreshold = 80.0; // pixels - how close nose gets to wrists when down
  static const double _farThreshold = 120.0; // pixels - how far nose is from wrists when up
  
  // Throttling for logs
  DateTime? _lastLogTime;
  static const Duration _logThrottle = Duration(milliseconds: 200);
  
  // Calibration
  List<double> _calibrationDistances = [];
  static const int _calibrationFrames = 10;

  PushupsDetector({
    required this.targetReps,
    required this.onRepComplete,
    required this.onExerciseComplete,
  });

  void processPose(Pose pose) {
    final now = DateTime.now();
    final shouldLog = _lastLogTime == null || now.difference(_lastLogTime!) >= _logThrottle;
    
    // Get nose and wrist landmarks
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    
    // Need all landmarks detected
    if (nose == null || leftWrist == null || rightWrist == null) {
      if (shouldLog) {
        print('⚠️ [Pushups] Required landmarks not detected');
        _lastLogTime = now;
      }
      return;
    }
    
    if (nose.likelihood < 0.7 || leftWrist.likelihood < 0.6 || rightWrist.likelihood < 0.6) {
      if (shouldLog) {
        print('⚠️ [Pushups] Low confidence - Nose: ${(nose.likelihood * 100).toStringAsFixed(0)}%, LW: ${(leftWrist.likelihood * 100).toStringAsFixed(0)}%, RW: ${(rightWrist.likelihood * 100).toStringAsFixed(0)}%');
        _lastLogTime = now;
      }
      return;
    }

    // Calculate distance from nose to wrists
    // Average distance from nose to both wrists
    final leftDistance = sqrt(pow(nose.x - leftWrist.x, 2) + pow(nose.y - leftWrist.y, 2));
    final rightDistance = sqrt(pow(nose.x - rightWrist.x, 2) + pow(nose.y - rightWrist.y, 2));
    final currentNoseToWristDistance = (leftDistance + rightDistance) / 2;
    
    // Calibrate max distance (plank/up position) over first few frames
    if (_calibrationDistances.length < _calibrationFrames) {
      _calibrationDistances.add(currentNoseToWristDistance);
      if (shouldLog) {
        print('🔄 [Pushups] Calibrating... Frame ${_calibrationDistances.length}/$_calibrationFrames | Nose-to-Wrist Distance: ${currentNoseToWristDistance.toStringAsFixed(1)}px');
        _lastLogTime = now;
      }
      
      if (_calibrationDistances.length == _calibrationFrames) {
        // Calculate average as max distance (up position)
        _maxNoseToWristDistance = _calibrationDistances.reduce((a, b) => a + b) / _calibrationDistances.length;
        print('✅ [Pushups] Calibration complete! Max nose-to-wrist distance (up): ${_maxNoseToWristDistance!.toStringAsFixed(1)}px');
      }
      _previousNoseToWristDistance = currentNoseToWristDistance;
      return;
    }
    
    if (shouldLog) {
      print('📍 [Pushups] Nose: (${nose.x.toStringAsFixed(0)}, ${nose.y.toStringAsFixed(0)}) | LW: (${leftWrist.x.toStringAsFixed(0)}, ${leftWrist.y.toStringAsFixed(0)}) | RW: (${rightWrist.x.toStringAsFixed(0)}, ${rightWrist.y.toStringAsFixed(0)})');
      print('📐 [Pushups] Nose-to-Wrist Distance: ${currentNoseToWristDistance.toStringAsFixed(1)}px | Max: ${_maxNoseToWristDistance!.toStringAsFixed(1)}px | L: ${leftDistance.toStringAsFixed(1)}px R: ${rightDistance.toStringAsFixed(1)}px');
    }

    if (_previousNoseToWristDistance != null && _maxNoseToWristDistance != null) {
      if (shouldLog) {
        print('📊 [Pushups] Close Threshold: $_closeThreshold px | Far Threshold: $_farThreshold px | State: ${_isPushingDown ? "DOWN" : "UP"}');
        _lastLogTime = now;
      }

      // Detect based on nose-to-wrist distance
      if (!_isPushingDown) {
        // Detect pushup down (nose getting close to wrists)
        if (currentNoseToWristDistance < _closeThreshold) {
          _isPushingDown = true;
          print('⬇️ [Pushups] ✅ PUSHUP DOWN DETECTED! Nose close to wrists: ${currentNoseToWristDistance.toStringAsFixed(1)}px');
        }
      } else {
        // Detect pushup up (nose moving far from wrists)
        if (currentNoseToWristDistance > _farThreshold) {
          _isPushingDown = false;
          _currentReps++;
          print('⬆️ [Pushups] ✅ PUSHUP COMPLETED! Nose far from wrists: ${currentNoseToWristDistance.toStringAsFixed(1)}px');
          print('🎯 [Pushups] REP COMPLETED! Total Reps: $_currentReps/$targetReps');
          
          // Update max distance slightly (account for small adjustments)
          _maxNoseToWristDistance = (_maxNoseToWristDistance! * 0.9) + (currentNoseToWristDistance * 0.1);
          
          onRepComplete(_currentReps);

          if (_currentReps >= targetReps) {
            print('🎉 [Pushups] 🏆 EXERCISE COMPLETE! All $_currentReps reps done!');
            onExerciseComplete();
          }
        }
      }
    }

    _previousNoseToWristDistance = currentNoseToWristDistance;
  }

  double _calculateAngle(Point<double> a, Point<double> b, Point<double> c) {
    // Calculate angle at point b using vectors ba and bc
    final ba = Point(a.x - b.x, a.y - b.y);
    final bc = Point(c.x - b.x, c.y - b.y);

    final dotProduct = ba.x * bc.x + ba.y * bc.y;
    final magnitudeBA = sqrt(ba.x * ba.x + ba.y * ba.y);
    final magnitudeBC = sqrt(bc.x * bc.x + bc.y * bc.y);

    final cosAngle = dotProduct / (magnitudeBA * magnitudeBC);
    final angleRadians = acos(cosAngle.clamp(-1.0, 1.0));
    final angleDegrees = angleRadians * 180 / pi;

    return angleDegrees;
  }

  void reset() {
    _currentReps = 0;
    _isPushingDown = false;
    _previousNoseToWristDistance = null;
    _maxNoseToWristDistance = null;
    _calibrationDistances.clear();
  }
}
