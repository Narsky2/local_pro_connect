// ════════════════════════════════════════════════════════════════
// lib/theme/app_theme.dart
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class AppColors {
  // Couleurs extraites du logo
  static const Color blueNavy   = Color(0xFF0D2D6B); // bleu marine (texte logo)
  static const Color bluePrimary = Color(0xFF1565C0); // bleu principal (pin haut)
  static const Color blueLight  = Color(0xFF42A5F5); // bleu clair
  static const Color greenPrimary = Color(0xFF2E7D32); // vert foncé (CONNECT)
  static const Color greenLight = Color(0xFF4CAF50); // vert vif
  static const Color greenBright = Color(0xFF00C853); // vert brillant (pin bas)
  static const Color teal       = Color(0xFF00897B); // teal (transition logo)

  // Fonds
  static const Color bgDark     = Color(0xFF061020);
  static const Color bgCard     = Color(0xFF0D1E35);
  static const Color surface    = Color(0xFF132840);

  // Texte
  static const Color textWhite  = Colors.white;
  static const Color textSub    = Color(0xFF8BAABB);
  static const Color textHint   = Color(0xFF4A6070);

  // États
  static const Color error      = Color(0xFFEF5350);
  static const Color success    = Color(0xFF66BB6A);
  static const Color warning    = Color(0xFFFFB020);

  // Gradients principaux (inspirés du logo)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [bluePrimary, teal, greenBright],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF061020), Color(0xFF0A1A30), Color(0xFF071A15)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [bluePrimary, blueLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [teal, greenBright],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Ombres
  static List<BoxShadow> blueShadow = [
    BoxShadow(color: bluePrimary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
  ];
  static List<BoxShadow> greenShadow = [
    BoxShadow(color: greenBright.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
  ];
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 4)),
  ];
}

class AppRadius {
  static const double xs  = 6.0;
  static const double sm  = 10.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double pill = 50.0;
}

class AppTextStyles {
  static TextStyle display({double size = 32, Color color = Colors.white, FontWeight weight = FontWeight.w800}) =>
    TextStyle(fontSize: size, fontWeight: weight, color: color, letterSpacing: -0.5, height: 1.15);

  static TextStyle heading({double size = 20, Color color = Colors.white, FontWeight weight = FontWeight.w700}) =>
    TextStyle(fontSize: size, fontWeight: weight, color: color, letterSpacing: -0.2, height: 1.3);

  static TextStyle body({double size = 14, Color? color, FontWeight weight = FontWeight.w400}) =>
    TextStyle(fontSize: size, fontWeight: weight, color: color ?? AppColors.textSub, height: 1.6);

  static TextStyle label({double size = 12, Color? color, FontWeight weight = FontWeight.w500}) =>
    TextStyle(fontSize: size, fontWeight: weight, color: color ?? AppColors.textSub, letterSpacing: 0.3);

  static TextStyle button({double size = 15, Color color = Colors.white}) =>
    TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.4);
}

// ── Bouton gradient réutilisable ──────────────────────────────────
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final List<Color> colors;
  final double height;
  final IconData? icon;
  final double radius;

  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.colors = const [AppColors.bluePrimary, AppColors.teal, AppColors.greenBright],
    this.height = 56,
    this.icon,
    this.radius = AppRadius.md,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap?.call(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.colors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: widget.loading ? [] : AppColors.blueShadow,
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(widget.label, style: AppTextStyles.button()),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Bouton outline ────────────────────────────────────────────────
class OutlineButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icon;
  final double height;

  const OutlineButton({
    super.key,
    required this.label,
    this.onTap,
    this.color = AppColors.blueLight,
    this.icon,
    this.height = 56,
  });

  @override
  State<OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<OutlineButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap?.call(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: widget.color.withOpacity(0.5), width: 1.5),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: widget.color, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(widget.label, style: AppTextStyles.button(color: widget.color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Logo widget ───────────────────────────────────────────────────
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({super.key, this.size = 80, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/logo/logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
        if (showText) ...[
          const SizedBox(height: 10),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(children: [
              TextSpan(
                text: 'LOCAL PRO\n',
                style: AppTextStyles.display(
                  size: size * 0.28,
                  color: AppColors.blueNavy,
                  weight: FontWeight.w900,
                ),
              ),
              TextSpan(
                text: 'CONNECT',
                style: AppTextStyles.display(
                  size: size * 0.2,
                  color: AppColors.greenPrimary,
                  weight: FontWeight.w700,
                ),
              ),
            ]),
          ),
        ],
      ],
    );
  }
}
