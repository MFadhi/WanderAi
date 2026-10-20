import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  late final AnimationController _orbitCtrl;
  late final AnimationController _needleCtrl;
  late final AnimationController _logoCtrl;
  late final AnimationController _taglineCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _exitCtrl;

  // ── Animations ───────────────────────────────────────────────────────────
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _taglineSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _glowRadius;
  late final Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();

    // Orbit particles
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    // Compass needle settling
    _needleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Logo scale + fade in
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Tagline slide up
    _taglineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Glow pulse
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // Exit fade
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // ── Curve Definitions ─────────────────────────────────────────────────
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoCtrl,
          curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );
    _taglineSlide = Tween<double>(begin: 32.0, end: 0.0).animate(
      CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOutCubic),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeIn),
    );
    _glowRadius = Tween<double>(begin: 20.0, end: 48.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Small initial delay
    await Future.delayed(const Duration(milliseconds: 200));
    // Orbit starts immediately (already running via repeat)

    // Logo pops in
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));

    // Needle settles
    _needleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 600));

    // Tagline slides up
    _taglineCtrl.forward();

    // Hold for 1.8s then exit
    await Future.delayed(const Duration(milliseconds: 1800));
    await _exitCtrl.forward();

    widget.onComplete();
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _needleCtrl.dispose();
    _logoCtrl.dispose();
    _taglineCtrl.dispose();
    _glowCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitCtrl,
      builder: (context, child) {
        return Opacity(
          opacity: _exitOpacity.value,
          child: child,
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Color(0xFF0D1C2E),
                Color(0xFF080F1A),
              ],
            ),
          ),
          child: Stack(
            children: [
              // ── Background star particles ─────────────────────────────────
              const _StarField(),

              // ── Center content ────────────────────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo + orbit
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer orbit ring
                          AnimatedBuilder(
                            animation: _orbitCtrl,
                            builder: (_, __) {
                              return CustomPaint(
                                size: const Size(200, 200),
                                painter: _OrbitPainter(
                                  progress: _orbitCtrl.value,
                                  logoOpacity: _logoOpacity.value,
                                ),
                              );
                            },
                          ),

                          // Glow behind logo
                          AnimatedBuilder(
                            animation: _glowCtrl,
                            builder: (_, __) {
                              return Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.35),
                                      blurRadius: _glowRadius.value,
                                      spreadRadius: 4,
                                    ),
                                    BoxShadow(
                                      color: AppColors.secondary
                                          .withValues(alpha: 0.2),
                                      blurRadius: _glowRadius.value * 1.5,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // Logo mark
                          AnimatedBuilder(
                            animation: _logoCtrl,
                            builder: (_, __) {
                              return Transform.scale(
                                scale: _logoScale.value,
                                child: Opacity(
                                  opacity: _logoOpacity.value,
                                  child: AnimatedBuilder(
                                    animation: _needleCtrl,
                                    builder: (_, __) {
                                      return CustomPaint(
                                        size: const Size(100, 100),
                                        painter: _WanderLogoMark(
                                          needleProgress: _needleCtrl.value,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // App name
                    AnimatedBuilder(
                      animation: _logoCtrl,
                      builder: (_, __) {
                        return Opacity(
                          opacity: _logoOpacity.value,
                          child: RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Wander',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 38,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                TextSpan(
                                  text: 'AI',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 38,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    // Tagline
                    AnimatedBuilder(
                      animation: _taglineCtrl,
                      builder: (_, __) {
                        return Transform.translate(
                          offset: Offset(0, _taglineSlide.value),
                          child: Opacity(
                            opacity: _taglineOpacity.value,
                            child: const Text(
                              'Your AI-Powered Tour Guide',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── Bottom loading bar ─────────────────────────────────────────
              Positioned(
                bottom: 56,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _taglineCtrl,
                  builder: (_, __) {
                    return Opacity(
                      opacity: _taglineOpacity.value,
                      child: Column(
                        children: [
                          _AnimatedLoadingBar(controller: _glowCtrl),
                          const SizedBox(height: 14),
                          Text(
                            'Discovering your world…',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              color: AppColors.textMuted.withValues(alpha: 0.7),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── WanderAI Logo Mark (Compass + AI Neural ring) ─────────────────────────────
class _WanderLogoMark extends CustomPainter {
  final double needleProgress;
  _WanderLogoMark({required this.needleProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // ── Outer circle border
    final ringPaint = Paint()
      ..color = const Color(0xFF1E3A5F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(cx, cy), r - 2, ringPaint);

    // ── Inner gradient circle background
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1A2E4A),
          const Color(0xFF0D1C2E),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r - 4, bgPaint);

    // ── Neural arc segments (AI circuit ring)
    final arcPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - math.pi / 2;
      final startAngle = angle - 0.2;
      final sweepAngle = 0.32;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r - 10),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );
    }

    // ── Compass rose arms (N, S, E, W)
    final majorPaint = Paint()
      ..style = PaintingStyle.fill;
    final minorPaint = Paint()
      ..color = const Color(0xFF3A5070)
      ..style = PaintingStyle.fill;

    final armLength = r * 0.55;
    final armWidth = r * 0.16;

    // Draw 4 major arms alternating gold/slate
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 - math.pi / 2;
      final isGold = i % 2 == 0; // N and S are gold

      majorPaint.shader = LinearGradient(
        colors: isGold
            ? [
                AppColors.primary,
                AppColors.primaryLight,
              ]
            : [
                const Color(0xFF3A5070),
                const Color(0xFF2A3E58),
              ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCenter(
          center: Offset(cx, cy), width: armWidth * 2, height: armLength * 2));

      final path = Path();
      final tipX = cx + math.cos(angle) * armLength;
      final tipY = cy + math.sin(angle) * armLength;
      final leftX = cx + math.cos(angle + math.pi / 2) * armWidth;
      final leftY = cy + math.sin(angle + math.pi / 2) * armWidth;
      final rightX = cx + math.cos(angle - math.pi / 2) * armWidth;
      final rightY = cy + math.sin(angle - math.pi / 2) * armWidth;

      path.moveTo(tipX, tipY);
      path.lineTo(leftX, leftY);
      path.lineTo(cx, cy);
      path.lineTo(rightX, rightY);
      path.close();

      canvas.drawPath(path, isGold ? majorPaint : minorPaint);
    }

    // ── Compass needle (animated spin-in to north)
    if (needleProgress > 0) {
      final needleAngle = math.pi * 2 * (1 - needleProgress) - math.pi / 2;
      // Curved ease via elasticOut approximation
      final p = Curves.elasticOut.transform(needleProgress.clamp(0.0, 1.0));
      final finalAngle = -math.pi / 2; // Points up (North)
      final currentAngle = needleAngle + (finalAngle - needleAngle) * p;

      final needlePaint = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.fill;

      final needlePath = Path();
      final nLen = r * 0.38;
      final sLen = r * 0.2;
      final nw = r * 0.07;

      needlePath.moveTo(
          cx + math.cos(currentAngle) * nLen,
          cy + math.sin(currentAngle) * nLen);
      needlePath.lineTo(
          cx + math.cos(currentAngle + math.pi / 2) * nw,
          cy + math.sin(currentAngle + math.pi / 2) * nw);
      needlePath.lineTo(
          cx + math.cos(currentAngle + math.pi) * sLen,
          cy + math.sin(currentAngle + math.pi) * sLen);
      needlePath.lineTo(
          cx + math.cos(currentAngle - math.pi / 2) * nw,
          cy + math.sin(currentAngle - math.pi / 2) * nw);
      needlePath.close();
      canvas.drawPath(needlePath, needlePaint);

      // South half in slate
      final sPath = Path();
      final sPaint = Paint()..color = const Color(0xFF4CC9F0);
      sPath.moveTo(
          cx + math.cos(currentAngle + math.pi) * sLen,
          cy + math.sin(currentAngle + math.pi) * sLen);
      sPath.lineTo(
          cx + math.cos(currentAngle + math.pi / 2) * nw,
          cy + math.sin(currentAngle + math.pi / 2) * nw);
      sPath.lineTo(cx, cy);
      sPath.lineTo(
          cx + math.cos(currentAngle - math.pi / 2) * nw,
          cy + math.sin(currentAngle - math.pi / 2) * nw);
      sPath.close();
      canvas.drawPath(sPath, sPaint);
    }

    // ── Center jewel
    final jewel = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.white, AppColors.secondary],
      ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: 5));
    canvas.drawCircle(Offset(cx, cy), 5, jewel);

    // ── Dot markers at cardinal points
    final dotPaint = Paint()..color = AppColors.primary.withValues(alpha: 0.6);
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 - math.pi / 2;
      canvas.drawCircle(
        Offset(
          cx + math.cos(angle) * (r - 6),
          cy + math.sin(angle) * (r - 6),
        ),
        2,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_WanderLogoMark oldDelegate) =>
      oldDelegate.needleProgress != needleProgress;
}

// ── Orbiting particles ────────────────────────────────────────────────────────
class _OrbitPainter extends CustomPainter {
  final double progress;
  final double logoOpacity;
  _OrbitPainter({required this.progress, required this.logoOpacity});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Outer orbit
    final orbitR1 = size.width / 2 - 2.0;
    final orbitR2 = size.width / 2 - 22.0;

    final ringPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08 * logoOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawCircle(Offset(cx, cy), orbitR1, ringPaint);
    canvas.drawCircle(Offset(cx, cy), orbitR2, ringPaint);

    // Orbiting dots on outer ring
    final dotPositions = [0.0, 0.33, 0.66];
    for (final offset in dotPositions) {
      final angle = (progress + offset) * 2 * math.pi;
      final x = cx + math.cos(angle) * orbitR1;
      final y = cy + math.sin(angle) * orbitR1;

      final dotPaint = Paint()
        ..color = AppColors.secondary.withValues(alpha: 0.7 * logoOpacity);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);

      // Trail
      for (int t = 1; t <= 5; t++) {
        final trailAngle = angle - t * 0.08;
        final tx = cx + math.cos(trailAngle) * orbitR1;
        final ty = cy + math.sin(trailAngle) * orbitR1;
        canvas.drawCircle(
          Offset(tx, ty),
          1.5 * (1 - t / 5),
          Paint()
            ..color = AppColors.secondary
                .withValues(alpha: 0.3 * (1 - t / 5) * logoOpacity),
        );
      }
    }

    // Orbiting dot on inner ring (counter-clockwise, amber)
    final innerAngle = -progress * 2 * math.pi;
    final ix = cx + math.cos(innerAngle) * orbitR2;
    final iy = cy + math.sin(innerAngle) * orbitR2;
    canvas.drawCircle(
      Offset(ix, iy),
      2.5,
      Paint()..color = AppColors.primary.withValues(alpha: 0.8 * logoOpacity),
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => true;
}

// ── Static star field ─────────────────────────────────────────────────────────
class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _StarPainter(),
    );
  }
}

class _StarPainter extends CustomPainter {
  final _rng = math.Random(42);
  final List<Offset> _stars = [];
  final List<double> _sizes = [];

  _StarPainter() {
    for (int i = 0; i < 90; i++) {
      _stars.add(Offset(
        _rng.nextDouble(),
        _rng.nextDouble(),
      ));
      _sizes.add(0.5 + _rng.nextDouble() * 1.8);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _stars.length; i++) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.1 + _rng.nextDouble() * 0.3);
      canvas.drawCircle(
        Offset(_stars[i].dx * size.width, _stars[i].dy * size.height),
        _sizes[i],
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => false;
}

// ── Animated loading bar ──────────────────────────────────────────────────────
class _AnimatedLoadingBar extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedLoadingBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 80),
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 2,
              color: AppColors.primary.withValues(alpha: 0.15),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (0.4 + controller.value * 0.6).clamp(0.0, 1.0),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
