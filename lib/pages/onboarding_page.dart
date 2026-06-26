// ════════════════════════════════════════════════════════════════
// lib/pages/onboarding_page.dart   —   PAGE 3 : Onboarding
// ════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../theme/app_theme.dart';

// ── Données slides ────────────────────────────────────────────────
class _Slide {
  final IconData icon;
  final Color    iconColor;
  final String   title;
  final String   subtitle;
  final String   feat1;
  final String   feat2;
  final List<Color> gradient;

  const _Slide({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.feat1,
    required this.feat2,
    required this.gradient,
  });
}

const _slides = [
  _Slide(
    icon: Icons.location_on_rounded,
    iconColor: AppColors.blueLight,
    title: 'Trouvez des services\nprès de vous',
    subtitle: 'Localisez instantanément les prestataires disponibles autour de vous grâce à la géolocalisation.',
    feat1: '🗺  Carte interactive en temps réel',
    feat2: '📍  GPS précis à quelques mètres',
    gradient: [Color(0xFF061020), Color(0xFF0A1830), Color(0xFF071520)],
  ),
  _Slide(
    icon: Icons.search_rounded,
    iconColor: AppColors.greenBright,
    title: 'Recherche intelligente\npar catégorie',
    subtitle: 'Santé, Banque, Éducation, Restauration — filtrez et trouvez exactement ce dont vous avez besoin.',
    feat1: '🏥  Santé, Banque, Éducation…',
    feat2: '⚡  Résultats triés par distance',
    gradient: [Color(0xFF061020), Color(0xFF071A18), Color(0xFF0A1F12)],
  ),
  _Slide(
    icon: Icons.calendar_today_rounded,
    iconColor: AppColors.teal,
    title: 'Réservez en quelques\ntouches',
    subtitle: 'Contactez un prestataire, choisissez votre date et confirmez votre réservation en moins d\'une minute.',
    feat1: '✅  Confirmation instantanée',
    feat2: '📋  Historique de vos réservations',
    gradient: [Color(0xFF061020), Color(0xFF071820), Color(0xFF071A18)],
  ),
  _Slide(
    icon: Icons.business_center_rounded,
    iconColor: AppColors.greenBright,
    title: 'Professionnels,\nrendez-vous visible',
    subtitle: 'Inscrivez votre service et soyez découvert par des milliers de clients autour de vous.',
    feat1: '💼  Profil professionnel complet',
    feat2: '🔒  Données 100% sécurisées',
    gradient: [Color(0xFF061020), Color(0xFF0A1A10), Color(0xFF081C12)],
  ),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _current = 0;

  late AnimationController _illuCtrl;
  late Animation<double>    _illuScale;
  late Animation<double>    _illuOpacity;
  late AnimationController _textCtrl;
  late Animation<double>    _textSlide;
  late Animation<double>    _textOpacity;
  late AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();

    _illuCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _illuScale   = CurvedAnimation(parent: _illuCtrl, curve: Curves.elasticOut).drive(Tween(begin: 0.4, end: 1.0));
    _illuOpacity = CurvedAnimation(parent: _illuCtrl, curve: Curves.easeOut).drive(Tween(begin: 0.0, end: 1.0));

    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _textSlide   = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut).drive(Tween(begin: 24.0, end: 0.0));
    _textOpacity = CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn).drive(Tween(begin: 0.0, end: 1.0));

    _orbCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();

    _enterSlide();
  }

  void _enterSlide() {
    _illuCtrl.reset();
    _textCtrl.reset();
    _illuCtrl.forward();
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) _textCtrl.forward();
    });
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    context.go('/welcome');
  }

  void _next() {
    if (_current < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _illuCtrl.dispose();
    _textCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // ── Pages ──
          PageView.builder(
            controller: _pageCtrl,
            itemCount: _slides.length,
            onPageChanged: (i) {
              setState(() => _current = i);
              _enterSlide();
            },
            itemBuilder: (_, i) => _SlidePage(
              slide: _slides[i],
              illuScale: _illuScale,
              illuOpacity: _illuOpacity,
              textSlide: _textSlide,
              textOpacity: _textOpacity,
              orbCtrl: _orbCtrl,
            ),
          ),

          // ── Overlay bas ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 44),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // Dots indicateur
                  SmoothPageIndicator(
                    controller: _pageCtrl,
                    count: _slides.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppColors.blueLight,
                      dotColor: Colors.white.withOpacity(0.2),
                      dotHeight: 7,
                      dotWidth: 7,
                      expansionFactor: 3.5,
                      spacing: 6,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Bouton suivant / commencer
                  GradientButton(
                    label: _current == _slides.length - 1 ? 'Commencer →' : 'Suivant',
                    onTap: _next,
                    icon: _current == _slides.length - 1 ? Icons.rocket_launch_rounded : null,
                  ),

                  const SizedBox(height: 14),

                  // Passer
                  if (_current < _slides.length - 1)
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        'Passer',
                        style: AppTextStyles.label(
                          size: 13,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slide individuel ──────────────────────────────────────────────
class _SlidePage extends StatelessWidget {
  final _Slide slide;
  final Animation<double> illuScale;
  final Animation<double> illuOpacity;
  final Animation<double> textSlide;
  final Animation<double> textOpacity;
  final AnimationController orbCtrl;

  const _SlidePage({
    required this.slide, required this.illuScale, required this.illuOpacity,
    required this.textSlide, required this.textOpacity, required this.orbCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: slide.gradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [

            // ── Illustration ──
            Expanded(
              flex: 5,
              child: AnimatedBuilder(
                animation: illuScale,
                builder: (_, child) => Transform.scale(
                  scale: illuScale.value,
                  child: Opacity(opacity: illuOpacity.value, child: child),
                ),
                child: _SlideIllustration(
                  slide: slide,
                  orbCtrl: orbCtrl,
                  size: size,
                ),
              ),
            ),

            // ── Texte ──
            Expanded(
              flex: 5,
              child: AnimatedBuilder(
                animation: textSlide,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, textSlide.value),
                  child: Opacity(opacity: textOpacity.value, child: child),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Icône
                      Container(
                        width: 54, height: 54,
                        decoration: BoxDecoration(
                          color: slide.iconColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: slide.iconColor.withOpacity(0.3)),
                        ),
                        child: Icon(slide.icon, color: slide.iconColor, size: 26),
                      ),
                      const SizedBox(height: 18),

                      // Titre
                      Text(
                        slide.title,
                        style: AppTextStyles.heading(size: 24, color: Colors.white),
                      ),
                      const SizedBox(height: 12),

                      // Sous-titre
                      Text(
                        slide.subtitle,
                        style: AppTextStyles.body(size: 13, color: AppColors.textSub),
                      ),
                      const SizedBox(height: 22),

                      // Feature pills
                      _FeaturePill(label: slide.feat1, color: slide.iconColor),
                      const SizedBox(height: 9),
                      _FeaturePill(label: slide.feat2, color: slide.iconColor),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 130), // espace overlay bas
          ],
        ),
      ),
    );
  }
}

// ── Illustration centrale animée ──────────────────────────────────
class _SlideIllustration extends StatelessWidget {
  final _Slide slide;
  final AnimationController orbCtrl;
  final Size size;

  const _SlideIllustration({
    required this.slide, required this.orbCtrl, required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: orbCtrl,
      builder: (_, __) => CustomPaint(
        painter: _NodePainter(slide: slide, progress: orbCtrl.value),
        child: Center(
          child: Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: slide.iconColor.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 8,
                ),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: Image.asset('assets/logo/logo.png', fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

class _NodePainter extends CustomPainter {
  final _Slide slide;
  final double progress;

  _NodePainter({required this.slide, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final linePaint = Paint()..strokeWidth = 1.2..style = PaintingStyle.stroke;
    final nodePaint = Paint()..style = PaintingStyle.fill;

    // 6 nœuds orbitaux
    for (int i = 0; i < 6; i++) {
      final baseAngle = i * math.pi / 3;
      final a = baseAngle + progress * 2 * math.pi;
      final r = i % 2 == 0 ? 110.0 : 145.0;

      final x = cx + r * math.cos(a);
      final y = cy + r * math.sin(a);

      // Oscillation douce
      final ox = x + math.sin(progress * 2 * math.pi + i) * 5;
      final oy = y + math.cos(progress * 2 * math.pi + i * 0.7) * 5;

      // Ligne centre → nœud
      final opacity = 0.1 + 0.08 * math.sin(progress * 2 * math.pi + i);
      linePaint.color = slide.iconColor.withOpacity(opacity);
      canvas.drawLine(Offset(cx, cy), Offset(ox, oy), linePaint);

      // Halo nœud
      if (i % 2 == 0) {
        nodePaint.color = slide.iconColor.withOpacity(0.08);
        canvas.drawCircle(Offset(ox, oy), 18, nodePaint);
      }

      // Nœud
      final pulse = 1.0 + 0.1 * math.sin(progress * 2 * math.pi * 2 + i);
      final nodeR = (i % 2 == 0 ? 8.0 : 5.5) * pulse;
      nodePaint.color = slide.iconColor.withOpacity(i % 2 == 0 ? 0.7 : 0.4);
      canvas.drawCircle(Offset(ox, oy), nodeR, nodePaint);

      // Anneau blanc
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = i % 2 == 0 ? 2.0 : 1.2
        ..color = Colors.white.withOpacity(i % 2 == 0 ? 0.6 : 0.3);
      canvas.drawCircle(Offset(ox, oy), nodeR, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _NodePainter old) => old.progress != progress;
}

// ── Feature pill ──────────────────────────────────────────────────
class _FeaturePill extends StatelessWidget {
  final String label;
  final Color  color;
  const _FeaturePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: AppTextStyles.label(size: 12, color: AppColors.textSub),
      ),
    );
  }
}
