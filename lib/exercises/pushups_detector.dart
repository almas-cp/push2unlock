import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math';

class PushupsDetector {
  final int targetReps;
  final Function(int) onRepComplete;
  final Function() onExerciseComplete;

  int _currentReps = 0;
  bool _isPushingDown = false;
  double? _previousShoulderY;
  double? _topShoulderY; // Reference Y when in plank/up position
  static const double _pushupDepthThreshold = 40.0; // pixels of vertical movement
  
  // Throttling for logs
  DateTime? _lastLogTime;
  static const Duration _logThrottle = Duration(milliseconds: 200);

  PushupsDetector({
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
        print('⚠️ [Pushups] Shoulders not detected');
        _lastLogTime = now;
      }
      return;
    }
    
    if (leftShoulder.likelihood < 0.7 || rightShoulder.likelihood < 0.7) {
      if (shouldLog) {
        print('⚠️ [Pushups] Low confidence - Left: ${(leftShoulder.likelihood * 100).toStringAsFixed(0)}%, Right: ${(rightShoulder.likelihood * 100).toStringAsFixed(0)}%');
        _lastLogTime = now;
      }
      return;
    }

    // Calculate average shoulder Y position (vertical position)
    final currentShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    
    // Initialize top position (plank position) on first detection
    if (_topShoulderY == null) {
      _topShoulderY = currentShoulderY;
      print('🔄 [Pushups] Initializing... Top (plank) shoulder position: ${currentShoulderY.toStringAsFixed(1)}');
      _previousShoulderY = currentShoulderY;
      return;
    }
    
    if (shouldLog) {
      print('📍 [Pushups] Left Shoulder: (${leftShoulder.x.toStringAsFixed(0)}, ${leftShoulder.y.toStringAsFixed(0)}) | Right Shoulder: (${rightShoulder.x.toStringAsFixed(0)}, ${rightShoulder.y.toStringAsFixed(0)})');
      print('📐 [Pushups] Avg Shoulder Y: ${currentShoulderY.toStringAsFixed(1)} | Top Y: ${_topShoulderY!.toStringAsFixed(1)} | Confidence: L${(leftShoulder.likelihood * 100).toStringAsFixed(0)}% R${(rightShoulder.likelihood * 100).toStringAsFixed(0)}%');
    }

    if (_previousShoulderY != null) {
      // Calculate vertical movement from top position
      // In pushups, Y increases when going down (moving away from top of frame)
      final verticalDrop = currentShoulderY - _topShoulderY!;
      final deltaY = currentShoulderY - _previousShoulderY!;
      
      if (shouldLog) {
        print('📊 [Pushups] Vertical Drop: ${verticalDrop.toStringAsFixed(1)}px | Delta Y: ${deltaY.toStringAsFixed(1)}px | Threshold: $_pushupDepthThreshold px | State: ${_isPushingDown ? "DOWN" : "UP"}');
        _lastLogTime = now;
      }

      // Detect pushup down (shoulders drop/move down significantly)
      if (!_isPushingDown && verticalDrop > _pushupDepthThreshold) {
        _isPushingDown = true;
        print('⬇️ [Pushups] ✅ PUSHUP DOWN DETECTED! Drop: ${verticalDrop.toStringAsFixed(1)}px');
      }
      // Detect pushup up (shoulders return to top position)
      else if (_isPushingDown && verticalDrop < _pushupDepthThreshold / 2) {
        _isPushingDown = false;
        _currentReps++;
        print('⬆️ [Pushups] ✅ PUSHUP COMPLETED! Returned to: ${verticalDrop.toStringAsFixed(1)}px from top');
        print('🎯 [Pushups] REP COMPLETED! Total Reps: $_currentReps/$targetReps');
        
        // Update top reference (in case user adjusts position slightly)
        _topShoulderY = currentShoulderY;
        
        onRepComplete(_currentReps);

        if (_currentReps >= targetReps) {
          print('🎉 [Pushups] 🏆 EXERCISE COMPLETE! All $_currentReps reps done!');
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
    _isPushingDown = false;
    _previousShoulderY = null;
    _topShoulderY = null;
  }
}
