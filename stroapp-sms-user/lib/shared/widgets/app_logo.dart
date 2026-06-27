import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({
    super.key,
    this.size = 92,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size * (106 / 92),
          child: CustomPaint(
            painter: _LogoIconPainter(color: AppColors.primary),
            size: Size(size, size * (106 / 92)),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: size * (208 / 92),
            height: size * (30 / 92),
            child: CustomPaint(
              painter: _LogoTextPainter(color: AppColors.primary),
              size: Size(size * (208 / 92), size * (30 / 92)),
            ),
          ),
        ],
      ],
    );
  }
}

class _LogoIconPainter extends CustomPainter {
  final Color color;

  _LogoIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.75, h * 0.2)
      ..lineTo(w * 0.75, h * 0.4)
      ..lineTo(w * 0.5, h * 0.6)
      ..lineTo(w * 0.25, h * 0.4)
      ..lineTo(w * 0.25, h * 0.2)
      ..close();

    canvas.drawPath(path, paint);

    final p2 = Path()
      ..moveTo(w * 0.35, h * 0.55)
      ..lineTo(w * 0.5, h * 0.7)
      ..lineTo(w * 0.65, h * 0.55)
      ..lineTo(w * 0.75, h * 0.65)
      ..lineTo(w * 0.5, h * 0.9)
      ..lineTo(w * 0.25, h * 0.65)
      ..close();

    canvas.drawPath(p2, paint);

    final p3 = Path()
      ..moveTo(w * 0.1, h * 0.7)
      ..lineTo(w * 0.25, h * 0.55)
      ..lineTo(w * 0.4, h * 0.7)
      ..lineTo(w * 0.5, h * 0.6)
      ..lineTo(w * 0.5, h * 0.85)
      ..close();

    canvas.drawPath(p3, paint);

    final p4 = Path()
      ..moveTo(w * 0.6, h * 0.7)
      ..lineTo(w * 0.75, h * 0.55)
      ..lineTo(w * 0.9, h * 0.7)
      ..lineTo(w * 0.5, h * 0.85)
      ..lineTo(w * 0.5, h * 0.6)
      ..close();

    canvas.drawPath(p4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LogoTextPainter extends CustomPainter {
  final Color color;

  _LogoTextPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final h = size.height;
    final w = size.width;

    canvas.drawRect(Rect.fromLTWH(0, h * 0.1, w * 0.15, h * 0.8), paint);
    canvas.drawRect(Rect.fromLTWH(w * 0.18, h * 0.1, w * 0.08, h * 0.8), paint);
    canvas.drawRect(Rect.fromLTWH(w * 0.28, h * 0.1, w * 0.15, h * 0.8), paint);
    canvas.drawRect(Rect.fromLTWH(w * 0.46, h * 0.1, w * 0.08, h * 0.8), paint);
    canvas.drawRect(Rect.fromLTWH(w * 0.56, h * 0.3, w * 0.15, h * 0.6), paint);
    canvas.drawRect(Rect.fromLTWH(w * 0.74, h * 0.1, w * 0.08, h * 0.8), paint);
    canvas.drawRect(Rect.fromLTWH(w * 0.84, h * 0.3, w * 0.15, h * 0.6), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}