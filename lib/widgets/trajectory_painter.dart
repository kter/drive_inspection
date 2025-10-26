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

    // Always draw concentric circles and center crosshair
    _drawConcentricCircles(canvas, size);
    _drawCenterCrosshair(canvas, size);

    if (points.isEmpty) {
      // Draw placeholder when no data
      _drawPlaceholder(canvas, size);
      return;
    }

    // Draw trajectory path
    _drawTrajectoryPath(canvas, points);

    // Draw current position indicator
    _drawCurrentPositionIndicator(canvas, points.last);
  }

  /// Draw trajectory path connecting all points with fade-out effect
  void _drawTrajectoryPath(Canvas canvas, List points) {
    if (points.length < 2) return;

    // Draw line segments with gradient alpha (older = more transparent)
    for (int i = 0; i < points.length - 1; i++) {
      final progress = i / (points.length - 1);
      final alpha = 0.1 + (progress * 0.6); // Fade from 0.1 to 0.7

      final paint = Paint()
        ..color = Colors.blue.withValues(alpha: alpha)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawLine(
        Offset(points[i].x, points[i].y),
        Offset(points[i + 1].x, points[i + 1].y),
        paint,
      );
    }
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

  /// Draw concentric circles for G-force reference (0.1G, 0.2G, 0.3G, 0.4G)
  void _drawConcentricCircles(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Calculate scale factor dynamically to fill ~85% of canvas
    const gToMetersPerSecondSquared = 9.81;
    const maxG = 0.4;
    final maxAcceleration = maxG * gToMetersPerSecondSquared;

    // Use 85% of the smaller dimension for the maximum circle
    final maxRadius = (size.width < size.height ? size.width : size.height) / 2 * 0.85;
    final scaleFactor = maxRadius / maxAcceleration;

    final gLevels = [0.1, 0.2, 0.3, 0.4];

    final circlePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      color: Colors.grey.withValues(alpha: 0.6),
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );

    for (final gLevel in gLevels) {
      final radius = gLevel * gToMetersPerSecondSquared * scaleFactor;

      // Draw circle
      canvas.drawCircle(
        Offset(centerX, centerY),
        radius,
        circlePaint,
      );

      // Draw label at top of circle
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${gLevel.toStringAsFixed(1)}G',
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          centerX - textPainter.width / 2,
          centerY - radius - textPainter.height - 2,
        ),
      );
    }
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
  }

  @override
  bool shouldRepaint(TrajectoryPainter oldDelegate) {
    // Always repaint when buffer notifies changes
    return true;
  }
}
