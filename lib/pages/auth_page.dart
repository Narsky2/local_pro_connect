// ════════════════════════════════════════════════════════════════
// lib/pages/auth_page.dart   —   PAGE 6 : Inscription / Connexion
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class AuthPage extends StatefulWidget {
  final bool isLogin;
  final String role; // 'client' ou 'pro'
  const AuthPage({super.key, this.isLogin = false, this.role = 'client'});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {

  late bool _isLogin;

  // Formulaire inscription
  final _regKey     = GlobalKey<FormState>();
  final _regName    = TextEditingController();
  final _regEmail   = TextEditingController();
  final _regPhone   = TextEditingController();
  final _regPass    = TextEditingController();
  final _regConfirm = TextEditingController();
  bool _regShowPass     = false;
  bool _regShowConfirm  = false;
  bool _regLoading      = false;

  // Formulaire connexion
  final _loginKey   = GlobalKey<FormState>();
  final _loginEmail = TextEditingController();
  final _loginPass  = TextEditingController();
  bool _loginShowPass = false;
  bool _loginLoading  = false;

  late AnimationController _switchCtrl;
  late Animation<double>    _switchOpacity;
  late Animation<Offset>    _switchSlide;

  late AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.isLogin;

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

    _switchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _switchOpacity = CurvedAnimation(parent: _switchCtrl, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));
    _switchSlide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _switchCtrl, curve: Curves.easeOut));
    _switchCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _switchCtrl.dispose();
    _regName.dispose(); _regEmail.dispose(); _regPhone.dispose();
    _regPass.dispose(); _regConfirm.dispose();
    _loginEmail.dispose(); _loginPass.dispose();
    super.dispose();
  }

  void _toggle() {
    _switchCtrl.reset();
    setState(() => _isLogin = !_isLogin);
    _switchCtrl.forward();
  }

  // ── INSCRIPTION ──
  Future<void> _register() async {
    if (!_regKey.currentState!.validate()) return;
    setState(() => _regLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _regLoading = false);
    // TODO: Firebase createUserWithEmailAndPassword
    _showSuccess('Compte créé avec succès !');
    // Redirection selon le rôle
    if (widget.role == 'pro') {
      context.go('/pro-register');
    } else {
      context.go('/client-home');
    }
  }

  // ── CONNEXION ──
  Future<void> _login() async {
    if (!_loginKey.currentState!.validate()) return;
    setState(() => _loginLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _loginLoading = false);
    // TODO: Firebase signInWithEmailAndPassword + redirection selon rôle
    if (widget.role == 'pro') {
      context.go('/pro-register');
    } else {
      context.go('/client-home');
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.greenBright, size: 18),
        const SizedBox(width: 10),
        Text(msg, style: AppTextStyles.body(size: 13, color: Colors.white)),
      ]),
      backgroundColor: AppColors.bgCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Stack(
          children: [

            // Fond animé
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgCtrl,
                builder: (_, __) => CustomPaint(painter: _AuthBgPainter(t: _bgCtrl.value)),
              ),
            ),

            SafeArea(
              child: Column(
                children: [

                  // ── Header ──
                  _AuthHeader(onBack: () => context.go('/welcome'), role: widget.role),

                  // ── Toggle Connexion / Inscription ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: _ToggleBar(isLogin: _isLogin, onToggle: _toggle),
                  ),

                  // ── Formulaire ──
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: FadeTransition(
                        opacity: _switchOpacity,
                        child: SlideTransition(
                          position: _switchSlide,
                          child: _isLogin ? _buildLogin() : _buildRegister(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // FORMULAIRE CONNEXION
  // ────────────────────────────────────────────────────────────────
  Widget _buildLogin() {
    return Form(
      key: _loginKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Center(
            child: Column(children: [
              Text('Bon retour !', style: AppTextStyles.display(size: 26)),
              const SizedBox(height: 6),
              Text('Connectez-vous à votre compte', style: AppTextStyles.body(size: 13)),
            ]),
          ),
          const SizedBox(height: 32),

          _Label('Adresse email'),
          _Field(
            hint: 'exemple@email.com',
            ctrl: _loginEmail,
            icon: Icons.email_outlined,
            keyboard: TextInputType.emailAddress,
            validator: (v) {
              if (v!.isEmpty) return 'Champ requis';
              if (!v.contains('@')) return 'Email invalide';
              return null;
            },
          ),
          const SizedBox(height: 16),

          _Label('Mot de passe'),
          _Field(
            hint: '••••••••',
            ctrl: _loginPass,
            icon: Icons.lock_outline_rounded,
            obscure: !_loginShowPass,
            suffixIcon: IconButton(
              icon: Icon(_loginShowPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSub),
              onPressed: () => setState(() => _loginShowPass = !_loginShowPass),
            ),
            validator: (v) => v!.isEmpty ? 'Champ requis' : null,
          ),

          // Mot de passe oublié
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showResetDialog(),
              child: Text(
                'Mot de passe oublié ?',
                style: AppTextStyles.label(size: 12, color: AppColors.blueLight),
              ),
            ),
          ),

          const SizedBox(height: 8),

          GradientButton(
            label: 'Se connecter',
            onTap: _login,
            loading: _loginLoading,
            icon: Icons.login_rounded,
          ),

          const SizedBox(height: 32),

          // Divider
          _Divider(),
          const SizedBox(height: 24),

          // Créer un compte
          Center(
            child: GestureDetector(
              onTap: _toggle,
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(text: 'Pas encore inscrit ? ',
                    style: AppTextStyles.body(size: 13, color: AppColors.textSub)),
                  TextSpan(text: 'Créer un compte',
                    style: AppTextStyles.body(size: 13, color: AppColors.greenBright, weight: FontWeight.w700)),
                ]),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // FORMULAIRE INSCRIPTION
  // ────────────────────────────────────────────────────────────────
  Widget _buildRegister() {
    return Form(
      key: _regKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Center(
            child: Column(children: [
              Text('Créer un compte', style: AppTextStyles.display(size: 26)),
              const SizedBox(height: 6),
              Text('Rejoignez Local Pro Connect', style: AppTextStyles.body(size: 13)),
            ]),
          ),
          const SizedBox(height: 32),

          _Label('Nom complet *'),
          _Field(
            hint: 'Jean Dupont',
            ctrl: _regName,
            icon: Icons.person_outline_rounded,
            validator: (v) => v!.isEmpty ? 'Champ requis' : null,
          ),
          const SizedBox(height: 14),

          _Label('Adresse email *'),
          _Field(
            hint: 'exemple@email.com',
            ctrl: _regEmail,
            icon: Icons.email_outlined,
            keyboard: TextInputType.emailAddress,
            validator: (v) {
              if (v!.isEmpty) return 'Champ requis';
              if (!v.contains('@')) return 'Email invalide';
              return null;
            },
          ),
          const SizedBox(height: 14),

          _Label('Numéro de téléphone *'),
          _PhoneField(ctrl: _regPhone),
          const SizedBox(height: 14),

          _Label('Mot de passe *'),
          _Field(
            hint: 'Minimum 6 caractères',
            ctrl: _regPass,
            icon: Icons.lock_outline_rounded,
            obscure: !_regShowPass,
            suffixIcon: IconButton(
              icon: Icon(_regShowPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSub),
              onPressed: () => setState(() => _regShowPass = !_regShowPass),
            ),
            validator: (v) {
              if (v!.isEmpty) return 'Champ requis';
              if (v.length < 6) return 'Minimum 6 caractères';
              return null;
            },
          ),
          const SizedBox(height: 14),

          _Label('Confirmer le mot de passe *'),
          _Field(
            hint: 'Répétez le mot de passe',
            ctrl: _regConfirm,
            icon: Icons.lock_outline_rounded,
            obscure: !_regShowConfirm,
            suffixIcon: IconButton(
              icon: Icon(_regShowConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSub),
              onPressed: () => setState(() => _regShowConfirm = !_regShowConfirm),
            ),
            validator: (v) {
              if (v!.isEmpty) return 'Champ requis';
              if (v != _regPass.text) return 'Les mots de passe ne correspondent pas';
              return null;
            },
          ),
          const SizedBox(height: 28),

          GradientButton(
            label: 'Créer mon compte',
            onTap: _register,
            loading: _regLoading,
            icon: Icons.person_add_rounded,
          ),

          const SizedBox(height: 24),

          // Se connecter
          Center(
            child: GestureDetector(
              onTap: _toggle,
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(text: 'Déjà un compte ? ',
                    style: AppTextStyles.body(size: 13, color: AppColors.textSub)),
                  TextSpan(text: 'Se connecter',
                    style: AppTextStyles.body(size: 13, color: AppColors.blueLight, weight: FontWeight.w700)),
                ]),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showResetDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        title: Text('Réinitialiser', style: AppTextStyles.heading(size: 18)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Entrez votre email pour recevoir un lien.',
            style: AppTextStyles.body(size: 13)),
          const SizedBox(height: 14),
          TextFormField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            style: AppTextStyles.body(size: 14, color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: AppTextStyles.body(size: 13, color: AppColors.textSub))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccess('Email de réinitialisation envoyé !');
            },
            child: Text('Envoyer', style: AppTextStyles.body(size: 13, color: AppColors.blueLight)),
          ),
        ],
      ),
    );
  }
}

// ── Composants locaux ─────────────────────────────────────────────

class _AuthHeader extends StatelessWidget {
  final VoidCallback onBack;
  final String role;
  const _AuthHeader({required this.onBack, this.role = 'client'});

  @override
  Widget build(BuildContext context) {
    final isPro = role == 'pro';
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
      child: Row(children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        ),
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          padding: const EdgeInsets.all(3),
          child: Image.asset('assets/logo/logo.png', fit: BoxFit.contain),
        ),
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [AppColors.blueLight, AppColors.teal],
          ).createShader(r),
          child: Text('LOCAL PRO CONNECT',
            style: AppTextStyles.label(size: 13, color: Colors.white, weight: FontWeight.w800)),
        ),
        const Spacer(),
        // Badge rôle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isPro
                ? AppColors.teal.withOpacity(0.15)
                : AppColors.bluePrimary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPro ? AppColors.teal.withOpacity(0.4) : AppColors.blueLight.withOpacity(0.4),
            ),
          ),
          child: Text(
            isPro ? 'PROFESSIONNEL' : 'CLIENT',
            style: AppTextStyles.label(
              size: 10,
              color: isPro ? AppColors.teal : AppColors.blueLight,
              weight: FontWeight.w800,
            ),
          ),
        ),
      ]),
    );
  }
}

class _ToggleBar extends StatelessWidget {
  final bool isLogin;
  final VoidCallback onToggle;
  const _ToggleBar({required this.isLogin, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(children: [
        Expanded(child: _Tab(label: 'Connexion', active: isLogin, onTap: isLogin ? null : onToggle,
          gradient: const [AppColors.bluePrimary, AppColors.blueLight])),
        Expanded(child: _Tab(label: 'Inscription', active: !isLogin, onTap: isLogin ? onToggle : null,
          gradient: const [AppColors.teal, AppColors.greenBright])),
      ]),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final List<Color> gradient;
  const _Tab({required this.label, required this.active, required this.onTap, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: active ? LinearGradient(colors: gradient) : null,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          boxShadow: active ? [BoxShadow(color: gradient[0].withOpacity(0.4), blurRadius: 10)] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.label(
              size: 13,
              color: active ? Colors.white : AppColors.textSub,
              weight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(text, style: AppTextStyles.label(size: 12, color: AppColors.textSub, weight: FontWeight.w600)),
  );
}

class _Field extends StatelessWidget {
  final String hint;
  final TextEditingController ctrl;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType keyboard;
  final String? Function(String?)? validator;

  const _Field({
    required this.hint, required this.ctrl, required this.icon,
    this.obscure = false, this.suffixIcon,
    this.keyboard = TextInputType.text, this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    obscureText: obscure,
    keyboardType: keyboard,
    style: AppTextStyles.body(size: 14, color: Colors.white),
    validator: validator,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppColors.textSub),
      suffixIcon: suffixIcon,
    ),
  );
}

class _PhoneField extends StatelessWidget {
  final TextEditingController ctrl;
  const _PhoneField({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.6),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(children: [
          const Text('🇨🇲', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Text('+237', style: AppTextStyles.body(size: 14, color: Colors.white, weight: FontWeight.w600)),
        ]),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.phone,
          style: AppTextStyles.body(size: 14, color: Colors.white),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
          decoration: const InputDecoration(hintText: '6XX XXX XXX'),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Requis';
            if (v.length < 9) return 'Numéro invalide';
            return null;
          },
        ),
      ),
    ]);
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.08))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('ou', style: AppTextStyles.label(size: 12, color: AppColors.textHint)),
      ),
      Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.08))),
    ]);
  }
}

class _AuthBgPainter extends CustomPainter {
  final double t;
  _AuthBgPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Cercle décoratif haut-droite
    paint.color = AppColors.bluePrimary.withOpacity(0.05);
    canvas.drawCircle(Offset(size.width + 30, -30), 200, paint);

    // Cercle bas-gauche
    paint.color = AppColors.greenBright.withOpacity(0.04);
    canvas.drawCircle(Offset(-40, size.height + 40), 220, paint);

    // Grille de points
    paint.color = Colors.white.withOpacity(0.025);
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
