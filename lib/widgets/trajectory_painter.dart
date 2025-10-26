import 'package:flutter/material.dart';
import '../services/trajectory_buffer.dart';

/// CustomPainter for rendering acceleration trajectory path.
///
/// Draws a continuous path from trajectory points in the buffer,
/// with a current position indicator. Uses RepaintBoundary optimization
/// for efficient rendering at 30 Hz update rate.
class TrajectoryPainter extends CustomPainter {
  final TrajectoryBuffer buffer;

  /// Create painter that listens to buffer changes
  ///
  /// The painter will automatically repaint when buffer is updated
  /// via ChangeNotifier.
  TrajectoryPainter(this.buffer) : super(repaint: buffer);

  @override
  void paint(Canvas canvas, Size size) {
    final points = buffer.points;

    if (points.isEmpty) {
      // Draw placeholder when no data
      _drawPlaceholder(canvas, size);
      return;
    }

    // Draw trajectory path
    _drawTrajectoryPath(canvas, points);

    // Draw current position indicator
    _drawCurrentPositionIndicator(canvas, points.last);

    // Draw center crosshair for reference
    _drawCenterCrosshair(canvas, size);
  }

  /// Draw trajectory path connecting all points
  void _drawTrajectoryPath(Canvas canvas, List points) {
    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points.first.x, points.first.y);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].x, points[i].y);
    }

    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  /// Draw indicator at current acceleration position
  void _drawCurrentPositionIndicator(Canvas canvas, dynamic currentPoint) {
    // Outer circle (pulsing effect)
    final outerPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(currentPoint.x, currentPoint.y),
      10.0,
      outerPaint,
    );

    // Inner circle (solid)
    final innerPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(currentPoint.x, currentPoint.y),
      6.0,
      innerPaint,
    );
  }

  /// Draw center reference crosshair
  void _drawCenterCrosshair(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final crosshairSize = 20.0;

    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Horizontal line
    canvas.drawLine(
      Offset(centerX - crosshairSize, centerY),
      Offset(centerX + crosshairSize, centerY),
      paint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(centerX, centerY - crosshairSize),
      Offset(centerX, centerY + crosshairSize),
      paint,
    );

    // Center dot
    final dotPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerX, centerY), 3.0, dotPaint);
  }

  /// Draw placeholder text when no data
  void _drawPlaceholder(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Move device to see trajectory',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

    // Still draw center crosshair
    _drawCenterCrosshair(canvas, size);
  }

  @override
  bool shouldRepaint(TrajectoryPainter oldDelegate) {
    // Always repaint when buffer notifies changes
    return true;
  }
}
