import 'dart:math' show cos, sin;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppIcons {
  static const String wallet = 'wallet';
  static const String settings = 'settings';
  static const String browser = 'browser';
  static const String stacking = 'stacking';
  static const String exchange = 'exchange';
  static const String eye = 'eye';
  static const String eyeOff = 'eye-off';
  static const String copy = 'copy';
  static const String arrowLeft = 'arrow-left';
  static const String arrowRight = 'arrow-right';
  static const String arrowTop = 'arrow-top';
  static const String arrowDown = 'arrow-down';
  static const String scan = 'scan';
  static const String notifications = 'notifications';
  static const String infoCircle = 'info-circle';
  static const String checkCircle = 'check-circle';
  static const String plus = 'plus';
  static const String minus = 'minus';
  static const String close = 'close';
  static const String search = 'search';
  static const String pieChart = 'pie-chart';
  static const String bubble = 'bubble';
  static const String world = 'world';
  static const String carb = 'carb';
  static const String settingsAlt = 'settings-alt';
  static const String regroup = 'regroup';
}

class AppIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color color;

  const AppIcon({
    super.key,
    required this.name,
    this.size = 24,
    this.color = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AppIconPainter(name: name, color: color),
        size: Size(size, size),
      ),
    );
  }
}

class _AppIconPainter extends CustomPainter {
  final String name;
  final Color color;

  _AppIconPainter({required this.name, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final half = size.width / 2;

    switch (name) {
      case 'wallet':
        _drawWallet(canvas, size, paint, fill);
        break;
      case 'settings':
        _drawSettings(canvas, center, half, paint, fill);
        break;
      case 'browser':
        _drawBrowser(canvas, size, paint);
        break;
      case 'stacking':
        _drawStacking(canvas, size, paint);
        break;
      case 'exchange':
        _drawExchange(canvas, size, paint);
        break;
      case 'eye':
        _drawEye(canvas, size, paint);
        break;
      case 'eye-off':
        _drawEyeOff(canvas, size, paint);
        break;
      case 'copy':
        _drawCopy(canvas, size, paint);
        break;
      case 'arrow-left':
        _drawArrow(canvas, size, paint, 'left');
        break;
      case 'arrow-right':
        _drawArrow(canvas, size, paint, 'right');
        break;
      case 'arrow-top':
        _drawArrow(canvas, size, paint, 'top');
        break;
      case 'arrow-down':
        _drawArrow(canvas, size, paint, 'down');
        break;
      case 'scan':
        _drawScan(canvas, size, paint);
        break;
      case 'notifications':
        _drawNotifications(canvas, size, paint, fill);
        break;
      case 'info-circle':
        _drawInfoCircle(canvas, center, half, paint, fill);
        break;
      case 'check-circle':
        _drawCheckCircle(canvas, center, half, paint, fill);
        break;
      case 'plus':
        _drawPlus(canvas, center, half, paint);
        break;
      case 'minus':
        _drawMinus(canvas, center, half, paint);
        break;
      case 'close':
        _drawClose(canvas, center, half, paint);
        break;
      case 'search':
        _drawSearch(canvas, center, half, paint);
        break;
      case 'pie-chart':
        _drawPieChart(canvas, center, half, paint, fill);
        break;
      case 'bubble':
        _drawBubble(canvas, center, paint);
        break;
      case 'world':
        _drawWorld(canvas, center, half, paint);
        break;
      case 'carb':
        _drawCarb(canvas, size, paint);
        break;
      case 'settings-alt':
        _drawSettingsAlt(canvas, center, half, paint, fill);
        break;
      case 'regroup':
        _drawRegroup(canvas, size, paint);
        break;
    }
  }

  void _drawWallet(Canvas canvas, Size size, Paint paint, Paint fill) {
    final p = Path()
      ..moveTo(size.width * 0.65, size.height * 0.25)
      ..lineTo(size.width * 0.35, size.height * 0.25)
      ..cubicTo(size.width * 0.25, size.height * 0.25, size.width * 0.2, size.height * 0.3, size.width * 0.2, size.height * 0.38)
      ..lineTo(size.width * 0.2, size.height * 0.75)
      ..cubicTo(size.width * 0.2, size.height * 0.83, size.width * 0.25, size.height * 0.88, size.width * 0.35, size.height * 0.88)
      ..lineTo(size.width * 0.65, size.height * 0.88)
      ..cubicTo(size.width * 0.75, size.height * 0.88, size.width * 0.8, size.height * 0.83, size.width * 0.8, size.height * 0.75)
      ..lineTo(size.width * 0.8, size.height * 0.38)
      ..cubicTo(size.width * 0.8, size.height * 0.3, size.width * 0.75, size.height * 0.25, size.width * 0.65, size.height * 0.25)
      ..close();
    canvas.drawPath(p, paint);
    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.6), size.width * 0.06, fill);
    canvas.drawLine(Offset(size.width * 0.2, size.height * 0.5), Offset(size.width * 0.75, size.height * 0.5), paint);
  }

  void _drawSettings(Canvas canvas, Offset center, double half, Paint paint, Paint fill) {
    canvas.drawCircle(center, half * 0.3, paint);
    canvas.drawCircle(center, half * 0.6, paint);
    for (int i = 0; i < 4; i++) {
      final angle = i * 1.5708 + 0.7854;
      canvas.drawCircle(
        Offset(center.dx + half * cos(angle), center.dy + half * sin(angle)),
        half * 0.15,
        fill,
      );
    }
  }

  void _drawBrowser(Canvas canvas, Size size, Paint paint) {
    final p = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.15, size.height * 0.2, size.width * 0.7, size.height * 0.65),
        Radius.circular(size.width * 0.08),
      ));
    canvas.drawPath(p, paint);
    canvas.drawLine(Offset(size.width * 0.15, size.height * 0.4), Offset(size.width * 0.85, size.height * 0.4), paint);
    canvas.drawLine(Offset(size.width * 0.35, size.height * 0.4), Offset(size.width * 0.35, size.height * 0.85), paint);
  }

  void _drawStacking(Canvas canvas, Size size, Paint paint) {
    final pw = size.width;
    final ph = size.height;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pw * 0.15, ph * 0.55, pw * 0.7, ph * 0.35), Radius.circular(2)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pw * 0.15, ph * 0.3, pw * 0.7, ph * 0.35), Radius.circular(2)), paint);
    canvas.drawCircle(Offset(pw * 0.65, ph * 0.55), pw * 0.04, Paint()..color = color..style = PaintingStyle.fill);
  }

  void _drawExchange(Canvas canvas, Size size, Paint paint) {
    final pw = size.width;
    final ph = size.height;
    final p = Path()
      ..moveTo(pw * 0.25, ph * 0.6)
      ..lineTo(pw * 0.5, ph * 0.85)
      ..lineTo(pw * 0.75, ph * 0.6);
    canvas.drawPath(p, paint);
    final p2 = Path()
      ..moveTo(pw * 0.25, ph * 0.4)
      ..lineTo(pw * 0.5, ph * 0.15)
      ..lineTo(pw * 0.75, ph * 0.4);
    canvas.drawPath(p2, paint);
  }

  void _drawEye(Canvas canvas, Size size, Paint paint) {
    final pw = size.width;
    final ph = size.height;
    final path = Path()
      ..moveTo(pw * 0.1, ph * 0.5)
      ..cubicTo(pw * 0.25, ph * 0.25, pw * 0.4, ph * 0.2, pw * 0.5, ph * 0.2)
      ..cubicTo(pw * 0.6, ph * 0.2, pw * 0.75, ph * 0.25, pw * 0.9, ph * 0.5)
      ..cubicTo(pw * 0.75, ph * 0.75, pw * 0.6, ph * 0.8, pw * 0.5, ph * 0.8)
      ..cubicTo(pw * 0.4, ph * 0.8, pw * 0.25, ph * 0.75, pw * 0.1, ph * 0.5)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(pw * 0.5, ph * 0.5), pw * 0.12, paint);
    canvas.drawCircle(Offset(pw * 0.5, ph * 0.5), pw * 0.04, Paint()..color = color..style = PaintingStyle.fill);
  }

  void _drawEyeOff(Canvas canvas, Size size, Paint paint) {
    _drawEye(canvas, size, paint);
    canvas.drawLine(Offset(size.width * 0.3, size.height * 0.3), Offset(size.width * 0.7, size.height * 0.7), paint);
  }

  void _drawCopy(Canvas canvas, Size size, Paint paint) {
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.35, size.height * 0.35, size.width * 0.5, size.height * 0.5), Radius.circular(2)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.15, size.height * 0.15, size.width * 0.5, size.height * 0.5), Radius.circular(2)), paint);
  }

  void _drawArrow(Canvas canvas, Size size, Paint paint, String dir) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final l = size.width * 0.3;
    double x1, y1, x2, y2, x3, y3;
    switch (dir) {
      case 'left':
        x1 = cx + l; y1 = cy - l; x2 = cx - l; y2 = cy; x3 = cx + l; y3 = cy + l;
      case 'right':
        x1 = cx - l; y1 = cy - l; x2 = cx + l; y2 = cy; x3 = cx - l; y3 = cy + l;
      case 'top':
        x1 = cx - l; y1 = cy + l; x2 = cx; y2 = cy - l; x3 = cx + l; y3 = cy + l;
      case 'down':
        x1 = cx - l; y1 = cy - l; x2 = cx; y2 = cy + l; x3 = cx + l; y3 = cy - l;
      default:
        x1 = 0; y1 = 0; x2 = 0; y2 = 0; x3 = 0; y3 = 0;
    }
    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    canvas.drawLine(Offset(x2, y2), Offset(x3, y3), paint);
  }

  void _drawScan(Canvas canvas, Size size, Paint paint) {
    final s = size.width;
    canvas.drawLine(Offset(s*0.22, s*0.65), Offset(s*0.22, s*0.78), paint);
    canvas.drawLine(Offset(s*0.22, s*0.78), Offset(s*0.35, s*0.78), paint);
    canvas.drawLine(Offset(s*0.78, s*0.65), Offset(s*0.78, s*0.78), paint);
    canvas.drawLine(Offset(s*0.78, s*0.78), Offset(s*0.65, s*0.78), paint);
    canvas.drawLine(Offset(s*0.22, s*0.35), Offset(s*0.22, s*0.22), paint);
    canvas.drawLine(Offset(s*0.22, s*0.22), Offset(s*0.35, s*0.22), paint);
    canvas.drawLine(Offset(s*0.78, s*0.35), Offset(s*0.78, s*0.22), paint);
    canvas.drawLine(Offset(s*0.78, s*0.22), Offset(s*0.65, s*0.22), paint);
    canvas.drawLine(Offset(s*0.5, s*0.35), Offset(s*0.5, s*0.65), paint);
    canvas.drawLine(Offset(s*0.35, s*0.5), Offset(s*0.65, s*0.5), paint);
  }

  void _drawNotifications(Canvas canvas, Size size, Paint paint, Paint fill) {
    final s = size.width;
    final path = Path()
      ..moveTo(s*0.5, s*0.15)
      ..cubicTo(s*0.35, s*0.15, s*0.25, s*0.28, s*0.25, s*0.45)
      ..lineTo(s*0.25, s*0.55)
      ..cubicTo(s*0.25, s*0.6, s*0.2, s*0.7, s*0.15, s*0.75)
      ..lineTo(s*0.15, s*0.8)
      ..lineTo(s*0.85, s*0.8)
      ..lineTo(s*0.85, s*0.75)
      ..cubicTo(s*0.8, s*0.7, s*0.75, s*0.6, s*0.75, s*0.55)
      ..lineTo(s*0.75, s*0.45)
      ..cubicTo(s*0.75, s*0.28, s*0.65, s*0.15, s*0.5, s*0.15)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(s*0.5, s*0.88), s*0.06, fill);
  }

  void _drawInfoCircle(Canvas canvas, Offset center, double half, Paint paint, Paint fill) {
    canvas.drawCircle(center, half, paint);
    canvas.drawLine(Offset(center.dx, center.dy - half*0.25), Offset(center.dx, center.dy + half*0.4), paint);
    fill.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, center.dy - half*0.5), half*0.12, fill);
  }

  void _drawCheckCircle(Canvas canvas, Offset center, double half, Paint paint, Paint fill) {
    canvas.drawCircle(center, half, paint);
    final p = Path()
      ..moveTo(center.dx - half*0.35, center.dy)
      ..lineTo(center.dx - half*0.1, center.dy + half*0.3)
      ..lineTo(center.dx + half*0.4, center.dy - half*0.25);
    canvas.drawPath(p, paint);
  }

  void _drawPlus(Canvas canvas, Offset center, double half, Paint paint) {
    canvas.drawLine(Offset(center.dx, center.dy - half*0.5), Offset(center.dx, center.dy + half*0.5), paint);
    canvas.drawLine(Offset(center.dx - half*0.5, center.dy), Offset(center.dx + half*0.5, center.dy), paint);
  }

  void _drawMinus(Canvas canvas, Offset center, double half, Paint paint) {
    canvas.drawLine(Offset(center.dx - half*0.5, center.dy), Offset(center.dx + half*0.5, center.dy), paint);
  }

  void _drawClose(Canvas canvas, Offset center, double half, Paint paint) {
    canvas.drawLine(Offset(center.dx - half*0.5, center.dy - half*0.5), Offset(center.dx + half*0.5, center.dy + half*0.5), paint);
    canvas.drawLine(Offset(center.dx + half*0.5, center.dy - half*0.5), Offset(center.dx - half*0.5, center.dy + half*0.5), paint);
  }

  void _drawSearch(Canvas canvas, Offset center, double half, Paint paint) {
    canvas.drawCircle(Offset(center.dx - half*0.15, center.dy - half*0.15), half*0.4, paint);
    canvas.drawLine(Offset(center.dx + half*0.15, center.dy + half*0.15), Offset(center.dx + half*0.6, center.dy + half*0.6), paint);
  }

  void _drawPieChart(Canvas canvas, Offset center, double half, Paint paint, Paint fill) {
    canvas.drawCircle(center, half, paint);
    canvas.drawLine(center, Offset(center.dx, center.dy - half), paint);
    canvas.drawLine(center, Offset(center.dx + half, center.dy), paint);
    final arcP = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: half), -1.57, 1.57, true)
      ..close();
    canvas.drawPath(arcP, fill);
  }

  void _drawBubble(Canvas canvas, Offset center, Paint paint) {
    canvas.drawCircle(Offset(center.dx, center.dy - 2), 4, paint..style = PaintingStyle.stroke);
    canvas.drawCircle(Offset(center.dx - 4, center.dy + 3), 3, paint);
    canvas.drawCircle(Offset(center.dx + 4, center.dy + 3), 2.5, paint);
  }

  void _drawWorld(Canvas canvas, Offset center, double half, Paint paint) {
    canvas.drawCircle(center, half, paint);
    canvas.drawLine(Offset(center.dx, center.dy - half), Offset(center.dx, center.dy + half), paint);
    canvas.drawLine(Offset(center.dx - half, center.dy), Offset(center.dx + half, center.dy), paint);
    final arcP = Path()
      ..moveTo(center.dx - half, center.dy)
      ..cubicTo(center.dx - half * 0.5, center.dy - half * 0.3, center.dx + half * 0.5, center.dy - half * 0.3, center.dx + half, center.dy);
    canvas.drawPath(arcP, paint);
    final arcP2 = Path()
      ..moveTo(center.dx - half, center.dy)
      ..cubicTo(center.dx - half * 0.5, center.dy + half * 0.3, center.dx + half * 0.5, center.dy + half * 0.3, center.dx + half, center.dy);
    canvas.drawPath(arcP2, paint);
  }

  void _drawCarb(Canvas canvas, Size size, Paint paint) {
    final pw = size.width;
    final ph = size.height;
    canvas.drawLine(Offset(pw * 0.25, ph * 0.7), Offset(pw * 0.45, ph * 0.3), paint);
    canvas.drawLine(Offset(pw * 0.45, ph * 0.3), Offset(pw * 0.55, ph * 0.55), paint);
    canvas.drawLine(Offset(pw * 0.55, ph * 0.55), Offset(pw * 0.7, ph * 0.25), paint);
    canvas.drawLine(Offset(pw * 0.7, ph * 0.25), Offset(pw * 0.75, ph * 0.7), paint);
  }

  void _drawSettingsAlt(Canvas canvas, Offset center, double half, Paint paint, Paint fill) {
    canvas.drawCircle(center, half * 0.3, paint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: half * 0.6), -0.3, 2.5, false, paint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: half * 0.85), -0.3, 2.5, false, paint);
  }

  void _drawRegroup(Canvas canvas, Size size, Paint paint) {
    final pw = size.width;
    final ph = size.height;
    canvas.drawRect(Rect.fromLTWH(pw * 0.2, ph * 0.2, pw * 0.28, ph * 0.28), paint);
    canvas.drawRect(Rect.fromLTWH(pw * 0.52, ph * 0.2, pw * 0.28, ph * 0.28), paint);
    canvas.drawRect(Rect.fromLTWH(pw * 0.2, ph * 0.52, pw * 0.28, ph * 0.28), paint);
    canvas.drawRect(Rect.fromLTWH(pw * 0.52, ph * 0.52, pw * 0.28, ph * 0.28), paint);
  }

  @override
  bool shouldRepaint(covariant _AppIconPainter oldDelegate) {
    return oldDelegate.name != name || oldDelegate.color != color;
  }
}