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

    // Only draw specific landmarks (points)
    final allowedLandmarks = [
      // Head
      PoseLandmarkType.nose,
      PoseLandmarkType.leftEar,
      PoseLandmarkType.rightEar,
      // Shoulders
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      // Arms
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
      // Torso
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      // Legs
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];
    
    for (final landmarkType in allowedLandmarks) {
      final landmark = pose.landmarks[landmarkType];
      if (landmark != null && landmark.likelihood > 0.5) {
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
    
    // Head connections (nose to ears only)
    _drawLine(
      canvas,
      pose,
      PoseLandmarkType.nose,
      PoseLandmarkType.leftEar,
      paintLine,
      size,
    );
    _drawLine(
      canvas,
      pose,
      PoseLandmarkType.nose,
      PoseLandmarkType.rightEar,
      paintLine,
      size,
    );
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
    // Handle aspect ratio differences properly
    
    // Calculate scale to fit the image into the canvas while maintaining aspect ratio
    final imageAspect = imageSize.width / imageSize.height;
    final canvasAspect = size.width / size.height;
    
    double scaleX;
    double scaleY;
    double offsetX = 0;
    double offsetY = 0;
    
    if (canvasAspect > imageAspect) {
      // Canvas is wider than image - fit to height
      scaleY = size.height / imageSize.height;
      scaleX = scaleY;
      offsetX = (size.width - (imageSize.width * scaleX)) / 2;
    } else {
      // Canvas is taller than image - fit to width
      scaleX = size.width / imageSize.width;
      scaleY = scaleX;
      offsetY = (size.height - (imageSize.height * scaleY)) / 2;
    }
    
    return Offset(
      size.width - (x * scaleX + offsetX), // Mirror X coordinate
      y * scaleY + offsetY,
    );
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.pose != pose;
  }
}
