import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom Painter that renders the Weekly Collection & Volume Area Chart (Image 7)
/// Featuring dual smooth bezier area fills for Tons and Active Trips
class WeeklyCollectionAreaChartPainter extends CustomPainter {
  const WeeklyCollectionAreaChartPainter({
    required this.isDark,
    this.tonData = const [15, 45, 85, 42, 60, 48, 95],
    this.tripData = const [25, 60, 40, 75, 50, 80, 20],
  });

  final bool isDark;
  final List<double> tonData;
  final List<double> tripData;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final gridPaint = Paint()
      ..color = isDark ? const Color(0xFF334155).withOpacity(0.4) : const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    // Draw horizontal grid lines
    const gridLines = 5;
    for (int i = 0; i <= gridLines; i++) {
      final y = size.height * (i / gridLines);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final double stepX = size.width / (tonData.length - 1);
    const double maxVal = 100.0;

    // 1. Draw Active Trips Area (Lighter Green)
    final tripPath = Path();
    tripPath.moveTo(0, size.height);
    for (int i = 0; i < tripData.length; i++) {
      final x = i * stepX;
      final y = size.height - (tripData[i] / maxVal) * size.height;
      if (i == 0) {
        tripPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY = size.height - (tripData[i - 1] / maxVal) * size.height;
        final midX = (prevX + x) / 2;
        tripPath.cubicTo(midX, prevY, midX, y, x, y);
      }
    }
    tripPath.lineTo(size.width, size.height);
    tripPath.close();

    final tripFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF81C784).withOpacity(0.65),
          const Color(0xFF81C784).withOpacity(0.15),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(tripPath, tripFillPaint);

    final tripStrokePaint = Paint()
      ..color = const Color(0xFF66BB6A)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(tripPath, tripStrokePaint);

    // 2. Draw Tons Area (Darker Forest Green)
    final tonPath = Path();
    tonPath.moveTo(0, size.height);
    for (int i = 0; i < tonData.length; i++) {
      final x = i * stepX;
      final y = size.height - (tonData[i] / maxVal) * size.height;
      if (i == 0) {
        tonPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY = size.height - (tonData[i - 1] / maxVal) * size.height;
        final midX = (prevX + x) / 2;
        tonPath.cubicTo(midX, prevY, midX, y, x, y);
      }
    }
    tonPath.lineTo(size.width, size.height);
    tonPath.close();

    final tonFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1B5E20).withOpacity(0.75),
          const Color(0xFF1B5E20).withOpacity(0.20),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(tonPath, tonFillPaint);

    final tonStrokePaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(tonPath, tonStrokePaint);
  }

  @override
  bool shouldRepaint(covariant WeeklyCollectionAreaChartPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.tonData != tonData;
}

/// Custom Painter that renders the Circular Donut Driver Utilization Meter (Image 1 & 7)
class DriverUtilizationDonutPainter extends CustomPainter {
  const DriverUtilizationDonutPainter({
    required this.percentage,
    required this.isDark,
    this.strokeWidth = 14.0,
  });

  final double percentage;
  final bool isDark;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // Track circle
    final trackPaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc
    final progressPaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final sweepAngle = (percentage / 100.0) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant DriverUtilizationDonutPainter oldDelegate) =>
      oldDelegate.percentage != percentage || oldDelegate.isDark != isDark;
}

/// Mini Sparkline Trend Line for Metric Cards (Image 5 & 7)
class MiniSparklinePainter extends CustomPainter {
  const MiniSparklinePainter({
    required this.points,
    required this.lineColor,
  });

  final List<double> points;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || size.width <= 0 || size.height <= 0) return;

    final minVal = points.reduce(math.min);
    final maxVal = points.reduce(math.max);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final path = Path();
    final stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height - ((points[i] - minVal) / range) * (size.height - 4) - 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MiniSparklinePainter oldDelegate) =>
      oldDelegate.lineColor != lineColor || oldDelegate.points != points;
}

/// Custom Vector Photographic Evidence Illustration (Image 3)
/// Renders an authentic commercial waste truck / dumpster collection evidence scene
class PhotoEvidenceThumbnailPainter extends CustomPainter {
  const PhotoEvidenceThumbnailPainter({this.type = 0});
  final int type; // 0: Truck with loaded sacks, 1: Municipal dumpsters

  @override
  void paint(Canvas canvas, Size size) {
    // Sky / Outdoors Background
    final skyPaint = Paint()..color = const Color(0xFFD4E6D2);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.65), skyPaint);

    // Distant Trees
    final treePaint = Paint()..color = const Color(0xFF4C7D52);
    for (double i = 0; i < size.width; i += 28) {
      canvas.drawCircle(Offset(i + 14, size.height * 0.42), 22, treePaint);
    }

    // Dirt / Gravel Road
    final groundPaint = Paint()..color = const Color(0xFFC48658);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.60, size.width, size.height * 0.40), groundPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFA66B42)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, size.height * 0.60), Offset(size.width, size.height * 0.60), borderPaint);

    if (type % 2 == 0) {
      // Commercial Waste Truck with Sacks
      final truckBlue = const Color(0xFF2B5B84);
      final darkPaint = const Color(0xFF263238);

      final cx = size.width * 0.45;
      final cy = size.height * 0.68;

      // Wheels
      final wheelPaint = Paint()..color = darkPaint;
      canvas.drawCircle(Offset(cx - 45, cy + 18), 10, wheelPaint);
      canvas.drawCircle(Offset(cx + 40, cy + 18), 10, wheelPaint);

      // Chassis & Bed
      final bedRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 65, cy - 18, 85, 28),
        const Radius.circular(3),
      );
      canvas.drawRRect(bedRect, Paint()..color = truckBlue);

      // Loaded Waste Sacks on Truck Bed
      final sackColors = [const Color(0xFFECEFF1), const Color(0xFFCFD8DC), const Color(0xFFB0BEC5), const Color(0xFF90A4AE)];
      for (int s = 0; s < 7; s++) {
        final sx = cx - 60 + s * 11;
        final sy = cy - 26 + (s % 2) * 4;
        canvas.drawOval(
          Rect.fromLTWH(sx.toDouble(), sy.toDouble(), 16, 12),
          Paint()..color = sackColors[s % sackColors.length],
        );
      }

      // Cabin
      final cabRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 20, cy - 24, 30, 34),
        const Radius.circular(4),
      );
      canvas.drawRRect(cabRect, Paint()..color = truckBlue);

      // Window
      canvas.drawRect(
        Rect.fromLTWH(cx + 32, cy - 20, 14, 12),
        Paint()..color = const Color(0xFFE0F7FA),
      );
    } else {
      // Municipal Waste Dumpsters / Bins
      final binGreen = const Color(0xFF2E7D32);
      final binDark = const Color(0xFF1B5E20);

      final bx = size.width * 0.48;
      final by = size.height * 0.65;

      // Large Green Bin 1
      final binRect1 = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx - 36, by - 24, 34, 32),
        const Radius.circular(4),
      );
      canvas.drawRRect(binRect1, Paint()..color = binGreen);
      canvas.drawRect(Rect.fromLTWH(bx - 38, by - 26, 38, 5), Paint()..color = binDark);

      // Large Green Bin 2
      final binRect2 = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx + 4, by - 20, 30, 28),
        const Radius.circular(4),
      );
      canvas.drawRRect(binRect2, Paint()..color = const Color(0xFF388E3C));
      canvas.drawRect(Rect.fromLTWH(bx + 2, by - 22, 34, 5), Paint()..color = binDark);

      // Sacks next to bin
      canvas.drawOval(Rect.fromLTWH(bx - 55, by + 2, 18, 12), Paint()..color = const Color(0xFFECEFF1));
      canvas.drawOval(Rect.fromLTWH(bx + 38, by + 4, 16, 10), Paint()..color = const Color(0xFFCFD8DC));
    }
  }

  @override
  bool shouldRepaint(covariant PhotoEvidenceThumbnailPainter oldDelegate) =>
      oldDelegate.type != type;
}
