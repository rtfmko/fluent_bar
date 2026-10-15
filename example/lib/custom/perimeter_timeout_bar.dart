import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PerimeterTimeoutBar extends StatelessWidget {
  final ValueListenable<double> progressNotifier;
  final BorderRadius borderRadius;
  final Widget child;
  final Color? strokeColor;
  final Gradient? gradient;
  final double strokeWidth;
  final double inset;

  const PerimeterTimeoutBar({
    super.key,
    required this.progressNotifier,
    required this.borderRadius,
    required this.child,
    this.strokeColor,
    this.gradient = const LinearGradient(colors: <Color>[Color(0xFFA855F7), Color(0xFFEC4899), Color(0xFF3B82F6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    this.strokeWidth = 2.0,
    this.inset = 3.5,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: progressNotifier,
      builder: (BuildContext context, double progress, Widget? cachedChild) {
        return CustomPaint(
          foregroundPainter: _PerimeterPathPainter(
            progress: progress,
            borderRadius: borderRadius,
            color: strokeColor ?? const Color(0xFFA855F7),
            gradient: gradient,
            strokeWidth: strokeWidth,
            inset: inset,
          ),
          child: cachedChild,
        );
      },
      child: child,
    );
  }
}

class _PerimeterPathPainter extends CustomPainter {
  final double progress;
  final BorderRadius borderRadius;
  final Color color;
  final Gradient? gradient;
  final double strokeWidth;
  final double inset;

  _PerimeterPathPainter({required this.progress, required this.borderRadius, required this.color, required this.gradient, required this.strokeWidth, required this.inset});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final Rect rect = Offset.zero & size;
    final RRect outerRRect = borderRadius.toRRect(rect);

    final double totalInset = inset + (strokeWidth / 2);
    final RRect rrect = outerRRect.deflate(totalInset);

    final Path path = _buildTopCenterPath(rrect);

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (gradient != null) {
      paint.shader = gradient!.createShader(rrect.outerRect);
    } else {
      paint.color = color;
    }

    final PathMetrics pathMetrics = path.computeMetrics();

    for (final PathMetric metric in pathMetrics) {
      final double extractLength = metric.length * progress.clamp(0.0, 1.0);
      final Path extractPath = metric.extractPath(0, extractLength);
      canvas.drawPath(extractPath, paint);
    }
  }

  Path _buildTopCenterPath(RRect rrect) {
    final Path path = Path();
    final double left = rrect.left;
    final double top = rrect.top;
    final double right = rrect.right;
    final double bottom = rrect.bottom;

    final double rx = rrect.tlRadiusX.clamp(0.0, rrect.width / 2);
    final double ry = rrect.tlRadiusY.clamp(0.0, rrect.height / 2);
    final double cx = rrect.center.dx;

    path.moveTo(cx, top);
    path.lineTo(right - rx, top);

    if (rx > 0 && ry > 0) {
      path.arcToPoint(Offset(right, top + ry), radius: Radius.elliptical(rx, ry));
    }

    path.lineTo(right, bottom - ry);

    if (rx > 0 && ry > 0) {
      path.arcToPoint(Offset(right - rx, bottom), radius: Radius.elliptical(rx, ry));
    }

    path.lineTo(left + rx, bottom);

    if (rx > 0 && ry > 0) {
      path.arcToPoint(Offset(left, bottom - ry), radius: Radius.elliptical(rx, ry));
    }

    path.lineTo(left, top + ry);

    if (rx > 0 && ry > 0) {
      path.arcToPoint(Offset(left + rx, top), radius: Radius.elliptical(rx, ry));
    }

    path.lineTo(cx, top);
    return path;
  }

  @override
  bool shouldRepaint(covariant _PerimeterPathPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.gradient != gradient ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.inset != inset;
  }
}
