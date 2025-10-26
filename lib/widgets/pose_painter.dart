import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;

  PosePainter({
    required this.pose,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Flip canvas horizontally to match front camera mirror
    canvas.save();
    canvas.translate(size.width, 0);
    canvas.scale(-1.0, 1.0);
    
    final paintPoint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 8.0
      ..color = Colors.blue;

    final paintLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.green;

    final paintConfidentPoint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 8.0
      ..color = Colors.yellow;

    // Draw landmarks (points)
    for (final landmark in pose.landmarks.values) {
      // Only draw confident points
      if (landmark.likelihood > 0.5) {
        final point = _translatePoint(
          landmark.x,
          landmark.y,
          size,
        );
        
        canvas.drawCircle(
          point,
          8,
          landmark.likelihood > 0.8 ? paintConfidentPoint : paintPoint,
        );
      }
    }

    // Draw connections (sticks)
    _drawLine(
      canvas,
      pose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      paintLine,
      size,
    );
    _drawLine(
      canvas,
      pose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftElbow,
      paintLine,
      size,
    );
    _drawLine(
      canvas,
      pose,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.leftWrist,
      paintLine,
      size,
    );
    _drawLine(
      canvas,
      pose,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightElbow,
      paintLine,
      size,
    );
    _drawLine(
      canvas,
      pose,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.rightWrist,
      paintLine,
      size,
    );
    _drawLine(
      canvas,
      pose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftHip,
      paintLine,
      size,
    );
    _drawLine(
      canvas,
      pose,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightHip,
      paintLine,
      size,
    );
    _drawLine(
      canvas,
      pose,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      paintLine,
      size,
    );
    _drawLine(
      canvas,
      pose,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftKnee,
      paintLine,
      size,
    );
    _drawLine(
      canvas,
      pose,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.leftAnkle,
      paintLine,
      size,
    );
    _drawLine(
      canvas,
      pose,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightKnee,
      paintLine,
      size,
    );
    _drawLine(
      canvas,
      pose,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.rightAnkle,
      paintLine,
      size,
    );
    
    // Head connections
    _drawLine(
      canvas,
      pose,
      PoseLandmarkType.nose,
      PoseLandmarkType.leftEye,
      paintLine,
      size,
    );
    _drawLine(
      canvas,
      pose,
      PoseLandmarkType.nose,
      PoseLandmarkType.rightEye,
      paintLine,
      size,
    );
    _drawLine(
      canvas,
      pose,
      PoseLandmarkType.leftEye,
      PoseLandmarkType.leftEar,
      paintLine,
      size,
    );
    _drawLine(
      canvas,
      pose,
      PoseLandmarkType.rightEye,
      PoseLandmarkType.rightEar,
      paintLine,
      size,
    );
    
    // Restore canvas after flipping
    canvas.restore();
  }

  void _drawLine(
    Canvas canvas,
    Pose pose,
    PoseLandmarkType type1,
    PoseLandmarkType type2,
    Paint paint,
    Size size,
  ) {
    final landmark1 = pose.landmarks[type1];
    final landmark2 = pose.landmarks[type2];

    if (landmark1 != null &&
        landmark2 != null &&
        landmark1.likelihood > 0.5 &&
        landmark2.likelihood > 0.5) {
      final point1 = _translatePoint(landmark1.x, landmark1.y, size);
      final point2 = _translatePoint(landmark2.x, landmark2.y, size);
      canvas.drawLine(point1, point2, paint);
    }
  }

  Offset _translatePoint(double x, double y, Size size) {
    // Transform coordinates from image space to canvas space
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    
    return Offset(
      x * scaleX,
      y * scaleY,
    );
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.pose != pose;
  }
}
