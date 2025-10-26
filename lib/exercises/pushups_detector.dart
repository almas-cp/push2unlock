import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math';

class PushupsDetector {
  final int targetReps;
  final Function(int) onRepComplete;
  final Function() onExerciseComplete;

  int _currentReps = 0;
  bool _isPushingDown = false;
  static const double _downAngleThreshold = 90.0; // degrees
  static const double _upAngleThreshold = 150.0; // degrees

  PushupsDetector({
    required this.targetReps,
    required this.onRepComplete,
    required this.onExerciseComplete,
  });

  void processPose(Pose pose) {
    // Get landmarks for arms
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    // Check if all landmarks are detected with good confidence
    if (leftShoulder == null || leftElbow == null || leftWrist == null ||
        rightShoulder == null || rightElbow == null || rightWrist == null) {
      return;
    }

    if (leftShoulder.likelihood < 0.6 || leftElbow.likelihood < 0.6 || leftWrist.likelihood < 0.6 ||
        rightShoulder.likelihood < 0.6 || rightElbow.likelihood < 0.6 || rightWrist.likelihood < 0.6) {
      return;
    }

    // Calculate elbow angles for both arms
    final leftElbowAngle = _calculateAngle(
      Point(leftShoulder.x, leftShoulder.y),
      Point(leftElbow.x, leftElbow.y),
      Point(leftWrist.x, leftWrist.y),
    );

    final rightElbowAngle = _calculateAngle(
      Point(rightShoulder.x, rightShoulder.y),
      Point(rightElbow.x, rightElbow.y),
      Point(rightWrist.x, rightWrist.y),
    );

    // Use average of both arms
    final avgElbowAngle = (leftElbowAngle + rightElbowAngle) / 2;

    // Detect pushup down
    if (!_isPushingDown && avgElbowAngle < _downAngleThreshold) {
      _isPushingDown = true;
      print('⬇️ Pushup down detected (angle: ${avgElbowAngle.toStringAsFixed(1)}°)');
    }
    // Detect pushup up (rep complete)
    else if (_isPushingDown && avgElbowAngle > _upAngleThreshold) {
      _isPushingDown = false;
      _currentReps++;
      print('✅ Pushup completed! Reps: $_currentReps');
      
      onRepComplete(_currentReps);

      if (_currentReps >= targetReps) {
        print('🎉 Pushups exercise complete!');
        onExerciseComplete();
      }
    }
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
  }
}
