import 'package:flutter/material.dart';
import '../services/face_detection_service.dart';

class FaceBoxPainter extends CustomPainter {
  final DriverState driverState;
  final Size previewSize;

  FaceBoxPainter({
    required this.driverState,
    required this.previewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (driverState.boundingBox == null || driverState.imageSize == null) {
      return;
    }

    final Paint paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final Rect box = driverState.boundingBox!;

    // Scale coordinates from image size → screen size
    final double scaleX = size.width / driverState.imageSize!.width;
    final double scaleY = size.height / driverState.imageSize!.height;

    final Rect scaledBox = Rect.fromLTRB(
      box.left * scaleX,
      box.top * scaleY,
      box.right * scaleX,
      box.bottom * scaleY,
    );

    canvas.drawRect(scaledBox, paint);
  }

  @override
  bool shouldRepaint(FaceBoxPainter oldDelegate) => true;
}