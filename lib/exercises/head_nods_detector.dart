import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math';

class HeadNodsDetector {
  final int targetReps;
  final Function(int) onRepComplete;
  final Function() onExerciseComplete;

  int _currentReps = 0;
  bool _isNodding = false;
  double? _previousNoseY;
  static const double _nodThreshold = 30.0; // pixels

  HeadNodsDetector({
    required this.targetReps,
    required this.onRepComplete,
    required this.onExerciseComplete,
  });

  void processPose(Pose pose) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    
    if (nose == null || nose.likelihood < 0.7) return;

    final currentNoseY = nose.y;

    if (_previousNoseY != null) {
      final diff = (currentNoseY - _previousNoseY!).abs();

      // Detect downward nod (head moving down)
      if (!_isNodding && currentNoseY > _previousNoseY! + _nodThreshold) {
        _isNodding = true;
        print('👇 Head nod detected (down)');
      }
      // Detect upward nod completion (head moving up)
      else if (_isNodding && currentNoseY < _previousNoseY! - _nodThreshold) {
        _isNodding = false;
        _currentReps++;
        print('✅ Head nod completed! Reps: $_currentReps');
        
        onRepComplete(_currentReps);

        if (_currentReps >= targetReps) {
          print('🎉 Head nods exercise complete!');
          onExerciseComplete();
        }
      }
    }

    _previousNoseY = currentNoseY;
  }

  void reset() {
    _currentReps = 0;
    _isNodding = false;
    _previousNoseY = null;
  }
}
