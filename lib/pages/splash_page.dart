// ════════════════════════════════════════════════════════════════
// lib/pages/splash_page.dart   —   PAGE 1 : Splash Screen
// ════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {

  // Logo : apparition + rebond
  late AnimationController _logoCtrl;
  late Animation<double>    _logoScale;
  late Animation<double>    _logoOpacity;

  // Texte : glissement vers le haut
  late AnimationController _textCtrl;
  late Animation<double>    _textOpacity;
  late Animation<double>    _textSlide;

  // Cercles orbitaux
  late AnimationController _orbCtrl;
  late Animation<double>    _orbRotation;

  // Pulsation anneau
  late AnimationController _pulseCtrl;
  late Animation<double>    _pulseScale;
  late Animation<double>    _pulseOpacity;

  @override
  void initState() {
    super.initState();

    // ── Logo ──
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _logoOpacity = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));

    // ── Texte ──
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _textOpacity = CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));
    _textSlide = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 30.0, end: 0.0));

    // ── Orbites ──
    _orbCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
    _orbRotation = _orbCtrl.drive(Tween(begin: 0.0, end: 2 * math.pi));

    // ── Pulse ──
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat();
    _pulseScale   = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 1.0, end: 2.4));
    _pulseOpacity = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.5, end: 0.0));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    _navigate();
  }

  Future<void> _navigate() async {
    final user = FB.auth.currentUser;
    if (user != null) {
      final doc  = await FB.db.collection('users').doc(user.uid).get();
      final role = doc.data()?['role'] ?? 'client';
      if (!mounted) return;
      context.go(role == 'pro' ? '/pro-home' : '/client-home');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final seen  = prefs.getBool('onboarding_done') ?? false;
    if (!mounted) return;
    context.go(seen ? '/welcome' : '/loading');
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _orbCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Stack(
          children: [

            // ── Décor : grille de points ──
            Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

            // ── Orbites animées ──
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _orbRotation,
                builder: (_, __) => CustomPaint(
                  painter: _OrbitalPainter(angle: _orbRotation.value),
                ),
              ),
            ),

            // ── Centre ──
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // Anneau pulsant + logo
                  SizedBox(
                    width: 200, height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [

                        // Pulse externe (bleu)
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, __) => Transform.scale(
                            scale: _pulseScale.value,
                            child: Opacity(
                              opacity: _pulseOpacity.value,
                              child: Container(
                                width: 110, height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.bluePrimary.withOpacity(0.6),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Pulse interne (vert, décalé)
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, __) {
                            final t = (_pulseCtrl.value + 0.5) % 1.0;
                            return Transform.scale(
                              scale: 1.0 + t * 1.4,
                              child: Opacity(
                                opacity: (1.0 - t).clamp(0.0, 0.5),
                                child: Container(
                                  width: 110, height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.greenBright.withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // Halo
                        Container(
                          width: 130, height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              AppColors.bluePrimary.withOpacity(0.12),
                              Colors.transparent,
                            ]),
                          ),
                        ),

                        // Logo
                        AnimatedBuilder(
                          animation: _logoCtrl,
                          builder: (_, child) => Transform.scale(
                            scale: _logoScale.value,
                            child: Opacity(opacity: _logoOpacity.value, child: child),
                          ),
                          child: Container(
                            width: 120, height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.bluePrimary.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              'assets/logo/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Nom app
                  AnimatedBuilder(
                    animation: _textCtrl,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: Opacity(opacity: _textOpacity.value, child: child),
                    ),
                    child: Column(children: [
                      ShaderMask(
                        shaderCallback: (r) => const LinearGradient(
                          colors: [AppColors.blueLight, AppColors.teal, AppColors.greenBright],
                        ).createShader(r),
                        child: Text(
                          'LOCAL PRO CONNECT',
                          style: AppTextStyles.display(size: 22, color: Colors.white, weight: FontWeight.w900),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Services à portée de main',
                        style: AppTextStyles.body(size: 13, color: AppColors.textSub),
                      ),
                    ]),
                  ),
                ],
              ),
            ),

            // ── Version ──
            Positioned(
              bottom: 30, left: 0, right: 0,
              child: AnimatedBuilder(
                animation: _textCtrl,
                builder: (_, __) => Opacity(
                  opacity: _textOpacity.value,
                  child: Text(
                    'v1.0.0',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.label(size: 11, color: Colors.white.withOpacity(0.2)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Décor : grille de points ──────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.035)
      ..style = PaintingStyle.fill;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ── Orbites ───────────────────────────────────────────────────────
class _OrbitalPainter extends CustomPainter {
  final double angle;
  _OrbitalPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 20;

    final linePaint = Paint()..strokeWidth = 1..style = PaintingStyle.stroke;
    final nodePaint = Paint()..style = PaintingStyle.fill;

    const r1 = 120.0;
    const r2 = 190.0;

    for (int i = 0; i < 6; i++) {
      final a = angle + i * math.pi / 3;
      final x1 = cx + r1 * math.cos(a);
      final y1 = cy + r1 * math.sin(a);
      final x2 = cx + r2 * math.cos(a + 0.25);
      final y2 = cy + r2 * math.sin(a + 0.25);

      linePaint.color = AppColors.bluePrimary.withOpacity(0.07);
      canvas.drawLine(Offset(cx, cy), Offset(x1, y1), linePaint);
      linePaint.color = AppColors.teal.withOpacity(0.06);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);

      nodePaint.color = (i % 2 == 0 ? AppColors.bluePrimary : AppColors.greenBright).withOpacity(0.22);
      canvas.drawCircle(Offset(x1, y1), i % 2 == 0 ? 4.5 : 3.5, nodePaint);

      nodePaint.color = Colors.white.withOpacity(0.09);
      canvas.drawCircle(Offset(x2, y2), 2.5, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitalPainter old) => old.angle != angle;
}
