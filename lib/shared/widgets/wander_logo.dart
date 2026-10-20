import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Reusable WanderAI brand logo mark (compass + AI ring).
/// Can be used in splash, app bar, onboarding, etc.
class WanderAILogo extends StatelessWidget {
  final double size;
  final bool showName;
  final bool showTagline;

  const WanderAILogo({
    super.key,
    this.size = 80,
    this.showName = true,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: _LogoMarkPainter(needleProgress: 1.0),
        ),
        if (showName) ...[
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Wander',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: size * 0.32,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: 'AI',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: size * 0.32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'Your AI-Powered Tour Guide',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: size * 0.14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _LogoMarkPainter extends CustomPainter {
  final double needleProgress;
  _LogoMarkPainter({this.needleProgress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Background circle
    canvas.drawCircle(
      Offset(cx, cy),
      r - 2,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFF1A2E4A), const Color(0xFF0D1C2E)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );

    // Border
    canvas.drawCircle(
      Offset(cx, cy),
      r - 2,
      Paint()
        ..color = const Color(0xFF1E3A5F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Neural arc segments
    final arcPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - math.pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r - 9),
        angle - 0.2,
        0.32,
        false,
        arcPaint,
      );
    }

    // Compass arms
    final goldPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primary, AppColors.primaryLight],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final slatePaint = Paint()..color = const Color(0xFF3A5070);

    final armLen = r * 0.56;
    final armW = r * 0.15;

    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 - math.pi / 2;
      final isGold = i % 2 == 0;
      final p = Path()
        ..moveTo(
            cx + math.cos(angle) * armLen, cy + math.sin(angle) * armLen)
        ..lineTo(cx + math.cos(angle + math.pi / 2) * armW,
            cy + math.sin(angle + math.pi / 2) * armW)
        ..lineTo(cx, cy)
        ..lineTo(cx + math.cos(angle - math.pi / 2) * armW,
            cy + math.sin(angle - math.pi / 2) * armW)
        ..close();
      canvas.drawPath(p, isGold ? goldPaint : slatePaint);
    }

    // Needle
    if (needleProgress > 0) {
      const angle = -math.pi / 2;
      final nLen = r * 0.38;
      final sLen = r * 0.2;
      final nw = r * 0.07;

      final nPath = Path()
        ..moveTo(cx + math.cos(angle) * nLen, cy + math.sin(angle) * nLen)
        ..lineTo(cx + math.cos(angle + math.pi / 2) * nw,
            cy + math.sin(angle + math.pi / 2) * nw)
        ..lineTo(cx + math.cos(angle + math.pi) * sLen,
            cy + math.sin(angle + math.pi) * sLen)
        ..lineTo(cx + math.cos(angle - math.pi / 2) * nw,
            cy + math.sin(angle - math.pi / 2) * nw)
        ..close();
      canvas.drawPath(nPath, Paint()..color = AppColors.primary);

      final sPath = Path()
        ..moveTo(cx + math.cos(angle + math.pi) * sLen,
            cy + math.sin(angle + math.pi) * sLen)
        ..lineTo(cx + math.cos(angle + math.pi / 2) * nw,
            cy + math.sin(angle + math.pi / 2) * nw)
        ..lineTo(cx, cy)
        ..lineTo(cx + math.cos(angle - math.pi / 2) * nw,
            cy + math.sin(angle - math.pi / 2) * nw)
        ..close();
      canvas.drawPath(sPath, Paint()..color = const Color(0xFF4CC9F0));
    }

    // Center jewel
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.1,
      Paint()
        ..shader = const RadialGradient(
          colors: [Colors.white, AppColors.secondary],
        ).createShader(Rect.fromCircle(
            center: Offset(cx, cy), radius: r * 0.1)),
    );

    // Cardinal dots
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 - math.pi / 2;
      canvas.drawCircle(
        Offset(cx + math.cos(angle) * (r - 5),
            cy + math.sin(angle) * (r - 5)),
        1.8,
        Paint()..color = AppColors.primary.withValues(alpha: 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(_LogoMarkPainter old) =>
      old.needleProgress != needleProgress;
}
