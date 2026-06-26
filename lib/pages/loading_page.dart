// ════════════════════════════════════════════════════════════════
// lib/pages/loading_page.dart   —   PAGE 2 : Chargement
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});
  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> with TickerProviderStateMixin {

  late AnimationController _barCtrl;
  late Animation<double>    _barProgress;

  late AnimationController _fadeCtrl;
  late Animation<double>    _fadeAnim;

  String _statusText = 'Initialisation…';
  int    _stepIndex  = 0;

  static const _steps = [
    (0.18, 'Initialisation…'),
    (0.38, 'Chargement des ressources…'),
    (0.58, 'Préparation de la carte…'),
    (0.78, 'Calibration GPS…'),
    (0.92, 'Presque prêt…'),
    (1.00, 'Bienvenue !'),
  ];

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _barCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _barProgress = _barCtrl.drive(Tween(begin: 0.0, end: 1.0));

    _runSteps();
  }

  Future<void> _runSteps() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      setState(() {
        _statusText = _steps[i].$2;
        _stepIndex  = i;
      });
      await _barCtrl.animateTo(
        _steps[i].$1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _navigate();
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final seen  = prefs.getBool('onboarding_done') ?? false;
    if (!mounted) return;
    context.go(seen ? '/welcome' : '/onboarding');
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          width: size.width,
          height: size.height,
          decoration: const BoxDecoration(gradient: AppColors.bgGradient),
          child: SafeArea(
            child: Column(
              children: [

                // ── Zone logo (60% hauteur) ──
                Expanded(
                  flex: 6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        // Logo dans cercle blanc
                        Container(
                          width: 130, height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.bluePrimary.withOpacity(0.35),
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
                          padding: const EdgeInsets.all(14),
                          child: Image.asset('assets/logo/logo.png', fit: BoxFit.contain),
                        ),

                        const SizedBox(height: 28),

                        // Nom application
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

                        const SizedBox(height: 8),

                        Text(
                          'Services à portée de main',
                          style: AppTextStyles.body(size: 13, color: AppColors.textSub),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Zone barre de progression (40% hauteur) ──
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        // Indicateur d'étape animé
                        _StepDots(current: _stepIndex, total: _steps.length),
                        const SizedBox(height: 28),

                        // Track barre
                        Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: AnimatedBuilder(
                            animation: _barProgress,
                            builder: (_, __) => Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: _barProgress.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: const LinearGradient(
                                      colors: [AppColors.bluePrimary, AppColors.teal, AppColors.greenBright],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.teal.withOpacity(0.6),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Texte statut + pourcentage
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _statusText,
                              style: AppTextStyles.label(
                                size: 12,
                                color: AppColors.textSub,
                              ),
                            ),
                            AnimatedBuilder(
                              animation: _barProgress,
                              builder: (_, __) => Text(
                                '${(_barProgress.value * 100).toInt()}%',
                                style: AppTextStyles.label(
                                  size: 12,
                                  color: AppColors.blueLight,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // Footer
                        Text(
                          '© 2025 Local Pro Connect',
                          style: AppTextStyles.label(
                            size: 10,
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Indicateur d'étapes sous forme de points ─────────────────────
class _StepDots extends StatelessWidget {
  final int current;
  final int total;
  const _StepDots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        final done   = i < current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width:  active ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: done
                ? AppColors.greenBright.withOpacity(0.6)
                : active
                    ? AppColors.blueLight
                    : Colors.white.withOpacity(0.15),
          ),
        );
      }),
    );
  }
}
