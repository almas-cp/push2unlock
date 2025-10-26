import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math';

class SquatsDetector {
  final int targetReps;
  final Function(int) onRepComplete;
  final Function() onExerciseComplete;

  int _currentReps = 0;
  bool _isSquatting = false;
  double? _previousShoulderY;
  double? _standingShoulderY; // Reference Y when standing
  static const double _squatDepthThreshold = 60.0; // pixels of vertical movement
  
  // Throttling for logs
  DateTime? _lastLogTime;
  static const Duration _logThrottle = Duration(milliseconds: 200);

  SquatsDetector({
    required this.targetReps,
    required this.onRepComplete,
    required this.onExerciseComplete,
  });

  void processPose(Pose pose) {
    final now = DateTime.now();
    final shouldLog = _lastLogTime == null || now.difference(_lastLogTime!) >= _logThrottle;
    
    // Get shoulder landmarks
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    
    // Need both shoulders detected
    if (leftShoulder == null || rightShoulder == null) {
      if (shouldLog) {
        print('⚠️ [Squats] Shoulders not detected');
        _lastLogTime = now;
      }
      return;
    }
    
    if (leftShoulder.likelihood < 0.7 || rightShoulder.likelihood < 0.7) {
      if (shouldLog) {
        print('⚠️ [Squats] Low confidence - Left: ${(leftShoulder.likelihood * 100).toStringAsFixed(0)}%, Right: ${(rightShoulder.likelihood * 100).toStringAsFixed(0)}%');
        _lastLogTime = now;
      }
      return;
    }

    // Calculate average shoulder Y position (vertical position)
    final currentShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    
    // Initialize standing position on first detection
    if (_standingShoulderY == null) {
      _standingShoulderY = currentShoulderY;
      print('🔄 [Squats] Initializing... Standing shoulder position: ${currentShoulderY.toStringAsFixed(1)}');
      _previousShoulderY = currentShoulderY;
      return;
    }
    
    if (shouldLog) {
      print('📍 [Squats] Left Shoulder: (${leftShoulder.x.toStringAsFixed(0)}, ${leftShoulder.y.toStringAsFixed(0)}) | Right Shoulder: (${rightShoulder.x.toStringAsFixed(0)}, ${rightShoulder.y.toStringAsFixed(0)})');
      print('📐 [Squats] Avg Shoulder Y: ${currentShoulderY.toStringAsFixed(1)} | Standing Y: ${_standingShoulderY!.toStringAsFixed(1)} | Confidence: L${(leftShoulder.likelihood * 100).toStringAsFixed(0)}% R${(rightShoulder.likelihood * 100).toStringAsFixed(0)}%');
    }

    if (_previousShoulderY != null) {
      // Calculate vertical movement from standing position
      final verticalDrop = currentShoulderY - _standingShoulderY!;
      final deltaY = currentShoulderY - _previousShoulderY!;
      
      if (shouldLog) {
        print('📊 [Squats] Vertical Drop: ${verticalDrop.toStringAsFixed(1)}px | Delta Y: ${deltaY.toStringAsFixed(1)}px | Threshold: $_squatDepthThreshold px | State: ${_isSquatting ? "SQUATTING" : "STANDING"}');
        _lastLogTime = now;
      }

      // Detect squat down (shoulders drop significantly)
      if (!_isSquatting && verticalDrop > _squatDepthThreshold) {
        _isSquatting = true;
        print('⬇️ [Squats] ✅ SQUAT DOWN DETECTED! Drop: ${verticalDrop.toStringAsFixed(1)}px');
      }
      // Detect squat up (shoulders return to standing position)
      else if (_isSquatting && verticalDrop < _squatDepthThreshold / 2) {
        _isSquatting = false;
        _currentReps++;
        print('⬆️ [Squats] ✅ SQUAT COMPLETED! Returned to: ${verticalDrop.toStringAsFixed(1)}px from standing');
        print('🎯 [Squats] REP COMPLETED! Total Reps: $_currentReps/$targetReps');
        
        // Update standing reference (in case user moves slightly)
        _standingShoulderY = currentShoulderY;
        
        onRepComplete(_currentReps);

        if (_currentReps >= targetReps) {
          print('🎉 [Squats] 🏆 EXERCISE COMPLETE! All $_currentReps reps done!');
          onExerciseComplete();
        }
      }
    }

    _previousShoulderY = currentShoulderY;
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
    _isSquatting = false;
    _previousShoulderY = null;
    _standingShoulderY = null;
  }
}
