// ════════════════════════════════════════════════════════════════
// lib/pages/welcome_page.dart   —   PAGE 4 : Bienvenue + Choix
// ════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {

  late AnimationController _bgCtrl;
  late AnimationController _cardCtrl;
  late Animation<double>    _cardScale;
  late Animation<double>    _cardOpacity;
  late AnimationController _logoCtrl;
  late Animation<double>    _logoSlide;
  late Animation<double>    _logoOpacity;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _logoSlide   = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic)
        .drive(Tween(begin: -40.0, end: 0.0));
    _logoOpacity = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));

    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _cardScale   = CurvedAnimation(parent: _cardCtrl, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.7, end: 1.0));
    _cardOpacity = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));

    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardCtrl.forward();
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _cardCtrl.dispose();
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

            // ── Décor fond ──
            Positioned.fill(child: CustomPaint(painter: _BgPainter(ctrl: _bgCtrl))),

            SafeArea(
              child: Column(
                children: [

                  // ── Logo + Titre (haut) ──
                  Expanded(
                    flex: 4,
                    child: AnimatedBuilder(
                      animation: _logoCtrl,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _logoSlide.value),
                        child: Opacity(opacity: _logoOpacity.value, child: child),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          // Logo cercle blanc
                          Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.bluePrimary.withOpacity(0.4),
                                  blurRadius: 40,
                                  spreadRadius: 8,
                                ),
                                BoxShadow(
                                  color: AppColors.greenBright.withOpacity(0.2),
                                  blurRadius: 60,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Image.asset('assets/logo/logo.png', fit: BoxFit.contain),
                          ),

                          const SizedBox(height: 20),

                          ShaderMask(
                            shaderCallback: (r) => const LinearGradient(
                              colors: [AppColors.blueLight, AppColors.teal, AppColors.greenBright],
                            ).createShader(r),
                            child: Text(
                              'LOCAL PRO CONNECT',
                              style: AppTextStyles.display(
                                size: 20,
                                color: Colors.white,
                                weight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            'Bienvenue ! Comment souhaitez-\nvous utiliser l\'application ?',
                            style: AppTextStyles.body(size: 13, color: AppColors.textSub),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Cards de choix ──
                  Expanded(
                    flex: 6,
                    child: AnimatedBuilder(
                      animation: _cardCtrl,
                      builder: (_, child) => Transform.scale(
                        scale: _cardScale.value,
                        child: Opacity(opacity: _cardOpacity.value, child: child),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            // ── Carte CLIENT ──
                            _RoleCard(
                              gradient: const [AppColors.bluePrimary, AppColors.blueLight],
                              icon: Icons.person_search_rounded,
                              tag: 'CLIENT',
                              title: 'Je cherche un service',
                              subtitle: 'Trouver des prestataires près de moi, réserver et payer en ligne',
                              features: ['📍 Géolocalisation des services', '⭐ Avis et notations', '💳 Paiement sécurisé'],
                              onTap: () => context.go('/auth?mode=login&role=client'),
                            ),

                            const SizedBox(height: 18),

                            // ── Carte PRO ──
                            _RoleCard(
                              gradient: const [AppColors.teal, AppColors.greenBright],
                              icon: Icons.business_center_rounded,
                              tag: 'PROFESSIONNEL',
                              title: 'Je propose un service',
                              subtitle: 'Créer mon profil professionnel et être visible par des milliers de clients',
                              features: ['📊 Tableau de bord', '📱 Gestion des réservations', '💼 Profil vérifié'],
                              onTap: () => context.go('/auth?mode=register&role=pro'),
                            ),

                            const SizedBox(height: 28),

                            // ── Lien connexion rapide ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Déjà inscrit ? ',
                                  style: AppTextStyles.body(size: 13, color: AppColors.textSub),
                                ),
                                GestureDetector(
                                  onTap: () => context.go('/auth?mode=login'),
                                  child: Text(
                                    'Se connecter',
                                    style: AppTextStyles.body(
                                      size: 13,
                                      color: AppColors.blueLight,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Carte de rôle ─────────────────────────────────────────────────
class _RoleCard extends StatefulWidget {
  final List<Color> gradient;
  final IconData    icon;
  final String      tag;
  final String      title;
  final String      subtitle;
  final List<String> features;
  final VoidCallback onTap;

  const _RoleCard({
    required this.gradient, required this.icon, required this.tag,
    required this.title, required this.subtitle, required this.features,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.gradient[0];

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp:   (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Icône
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: widget.gradient),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12)],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),

              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Titre + badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            style: AppTextStyles.heading(size: 15, color: Colors.white),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            widget.tag,
                            style: AppTextStyles.label(
                              size: 9,
                              color: color,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Text(
                      widget.subtitle,
                      style: AppTextStyles.body(size: 11, color: AppColors.textSub),
                    ),
                    const SizedBox(height: 12),

                    // Features
                    ...widget.features.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(f, style: AppTextStyles.label(size: 11, color: AppColors.textSub)),
                    )),

                    const SizedBox(height: 8),

                    // Bouton flèche
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: widget.gradient),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Continuer', style: AppTextStyles.label(size: 12, color: Colors.white, weight: FontWeight.w700)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Décor fond animé ──────────────────────────────────────────────
class _BgPainter extends CustomPainter {
  final AnimationController ctrl;
  _BgPainter({required this.ctrl}) : super(repaint: ctrl);

  @override
  void paint(Canvas canvas, Size size) {
    final t = ctrl.value;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1;

    // Cercles décoratifs tournants
    for (int i = 0; i < 4; i++) {
      final r  = 80.0 + i * 60;
      final cx = size.width * 0.85 + math.sin(t * 2 * math.pi + i) * 15;
      final cy = size.height * 0.15 + math.cos(t * 2 * math.pi + i) * 15;
      paint.color = AppColors.bluePrimary.withOpacity(0.04 - i * 0.007);
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }

    // Points grille
    final dot = Paint()..color = Colors.white.withOpacity(0.03)..style = PaintingStyle.fill;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
