import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math';

class SquatsDetector {
  final int targetReps;
  final Function(int) onRepComplete;
  final Function() onExerciseComplete;

  int _currentReps = 0;
  bool _isSquatting = false;
  static const double _squatAngleThreshold = 100.0; // degrees
  static const double _standAngleThreshold = 160.0; // degrees

  SquatsDetector({
    required this.targetReps,
    required this.onRepComplete,
    required this.onExerciseComplete,
  });

  void processPose(Pose pose) {
    // Get landmarks for both legs
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    // Check if all landmarks are detected with good confidence
    if (leftHip == null || leftKnee == null || leftAnkle == null ||
        rightHip == null || rightKnee == null || rightAnkle == null) {
      return;
    }

    if (leftHip.likelihood < 0.6 || leftKnee.likelihood < 0.6 || leftAnkle.likelihood < 0.6 ||
        rightHip.likelihood < 0.6 || rightKnee.likelihood < 0.6 || rightAnkle.likelihood < 0.6) {
      return;
    }

    // Calculate knee angles for both legs
    final leftKneeAngle = _calculateAngle(
      Point(leftHip.x, leftHip.y),
      Point(leftKnee.x, leftKnee.y),
      Point(leftAnkle.x, leftAnkle.y),
    );

    final rightKneeAngle = _calculateAngle(
      Point(rightHip.x, rightHip.y),
      Point(rightKnee.x, rightKnee.y),
      Point(rightAnkle.x, rightAnkle.y),
    );

    // Use average of both legs
    final avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;

    // Detect squat down
    if (!_isSquatting && avgKneeAngle < _squatAngleThreshold) {
      _isSquatting = true;
      print('⬇️ Squat down detected (angle: ${avgKneeAngle.toStringAsFixed(1)}°)');
    }
    // Detect squat up (rep complete)
    else if (_isSquatting && avgKneeAngle > _standAngleThreshold) {
      _isSquatting = false;
      _currentReps++;
      print('✅ Squat completed! Reps: $_currentReps');
      
      onRepComplete(_currentReps);

      if (_currentReps >= targetReps) {
        print('🎉 Squats exercise complete!');
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
    _isSquatting = false;
  }
}
