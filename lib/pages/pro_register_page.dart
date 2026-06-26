// ════════════════════════════════════════════════════════════════
// lib/pages/pro_register_page.dart
// Enregistrement Professionnel — 4 étapes complètes
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

const _categories = [
  'Santé & Médical', 'Banque & Finance', 'Éducation & Formation',
  'Restauration & Traiteur', 'Transport & Livraison', 'Réparation & Maintenance',
  'Beauté & Bien-être', 'Juridique & Conseil', 'Informatique & Tech',
  'Bâtiment & Travaux', 'Événementiel', 'Autre',
];

const _dispos = [
  'Lun – Ven  |  8h – 18h',
  'Lun – Sam  |  8h – 20h',
  'Tous les jours  |  8h – 22h',
  '24h / 24  –  7j / 7',
  'Sur rendez-vous uniquement',
];

// ════════════════════════════════════════════════════════════════
class ProRegisterPage extends StatefulWidget {
  const ProRegisterPage({super.key});
  @override
  State<ProRegisterPage> createState() => _ProRegisterPageState();
}

class _ProRegisterPageState extends State<ProRegisterPage>
    with SingleTickerProviderStateMixin {

  int _step = 0; // 0 = Perso | 1 = CNI | 2 = Service | 3 = Recap

  // ── Étape 1 – Infos personnelles ──
  final _fKey1      = GlobalKey<FormState>();
  final _nomCtrl    = TextEditingController();
  final _telCtrl    = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _addrCtrl   = TextEditingController();
  File? _avatar;

  // ── Étape 2 – Vérification CNI ──
  File? _cniAvec;
  File? _cniRecto;
  File? _cniVerso;

  // ── Étape 3 – Infos service ──
  final _fKey3        = GlobalKey<FormState>();
  final _svcNameCtrl  = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _tarifCtrl    = TextEditingController();
  String? _cat;
  String? _dispo;
  File? _logo;
  int     _nbImages   = 0;

  // ── Animation slide ──
  late AnimationController _animCtrl;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _slideAnim = Tween<Offset>(
            begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    for (final c in [
      _nomCtrl, _telCtrl, _emailCtrl, _addrCtrl,
      _svcNameCtrl, _descCtrl, _tarifCtrl
    ]) { c.dispose(); }
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────
  void _animTo(int s) {
    _animCtrl.reset();
    setState(() => _step = s);
    _animCtrl.forward();
  }

  void _next() {
    switch (_step) {
      case 0:
        if (!_fKey1.currentState!.validate()) return;
        if (_avatar == null) return _snack('Ajoutez votre photo de profil');
        _animTo(1);
      case 1:
        if (_cniAvec == null)  return _snack('Photo avec CNI en main requise');
        if (_cniRecto == null) return _snack('Photo CNI recto requise');
        if (_cniVerso == null) return _snack('Photo CNI verso requise');
        _animTo(2);
      case 2:
        if (!_fKey3.currentState!.validate()) return;
        if (_cat  == null) return _snack('Sélectionnez une catégorie');
        if (_dispo == null) return _snack('Sélectionnez vos disponibilités');
        if (_logo == null) return _snack('Ajoutez le logo ou photo principale');
        _animTo(3);
      case 3:
        // TODO: Firebase submit
        context.go('/pro-home');
    }
  }

  void _prev() => _step > 0 ? _animTo(_step - 1) : context.go('/welcome');

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(children: [
        const Icon(Icons.warning_amber_rounded,
            color: AppColors.warning, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(msg,
                style: AppTextStyles.body(size: 13, color: Colors.white))),
      ]),
      backgroundColor: AppColors.bgCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm)),
      margin: const EdgeInsets.all(16),
    ),
  );

  // ── Labels stepper ────────────────────────────────────────────
  static const _labels = [
    'Infos personnelles',
    'Vérification CNI',
    'Infos du service',
    'Confirmation',
  ];
  static const _icons = [
    Icons.person_outline_rounded,
    Icons.badge_outlined,
    Icons.business_center_outlined,
    Icons.check_circle_outline_rounded,
  ];

  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(children: [
            _header(),
            _stepper(),
            Expanded(
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: _currentStep(),
                ),
              ),
            ),
            _navButtons(),
          ]),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(8, 14, 24, 0),
    child: Row(children: [
      IconButton(
        onPressed: _prev,
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
      ),
      Container(
        width: 32, height: 32,
        decoration: const BoxDecoration(
            shape: BoxShape.circle, color: Colors.white),
        padding: const EdgeInsets.all(3),
        child: Image.asset('assets/logo/logo.png', fit: BoxFit.contain),
      ),
      const SizedBox(width: 10),
      ShaderMask(
        shaderCallback: (r) => const LinearGradient(
          colors: [AppColors.blueLight, AppColors.teal],
        ).createShader(r),
        child: Text('LOCAL PRO CONNECT',
            style: AppTextStyles.label(
                size: 13, color: Colors.white, weight: FontWeight.w800)),
      ),
      const Spacer(),
      _Badge('PRO', AppColors.teal),
    ]),
  );

  // ── Stepper ───────────────────────────────────────────────────
  Widget _stepper() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
    child: Column(children: [
      Row(
        children: List.generate(_labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final done = (i ~/ 2) < _step;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                height: 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: done
                      ? const LinearGradient(
                          colors: [AppColors.teal, AppColors.greenBright])
                      : null,
                  color: done ? null : Colors.white.withOpacity(0.1),
                ),
              ),
            );
          }
          final idx    = i ~/ 2;
          final done   = idx < _step;
          final active = idx == _step;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: active ? 42 : 36,
            height: active ? 42 : 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: (done || active)
                  ? const LinearGradient(
                      colors: [AppColors.teal, AppColors.greenBright],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight)
                  : null,
              color: (done || active) ? null : Colors.white.withOpacity(0.07),
              border: Border.all(
                color: active
                    ? AppColors.teal
                    : done
                        ? AppColors.greenBright.withOpacity(0.6)
                        : Colors.white.withOpacity(0.15),
                width: active ? 2 : 1,
              ),
              boxShadow: active
                  ? [BoxShadow(
                      color: AppColors.teal.withOpacity(0.4), blurRadius: 12)]
                  : null,
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 16)
                  : Icon(_icons[idx],
                      color: active
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      size: active ? 20 : 16),
            ),
          );
        }),
      ),
      const SizedBox(height: 10),
      Text(
        'Étape ${_step + 1} / ${_labels.length}  —  ${_labels[_step]}',
        style: AppTextStyles.label(size: 12, color: AppColors.textSub),
      ),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: (_step + 1) / _labels.length,
          backgroundColor: Colors.white.withOpacity(0.07),
          valueColor: const AlwaysStoppedAnimation(AppColors.teal),
          minHeight: 3,
        ),
      ),
    ]),
  );

  // ── Boutons navigation ────────────────────────────────────────
  Widget _navButtons() {
    final isLast = _step == _labels.length - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(children: [
        if (_step > 0) ...[
          Expanded(
            child: OutlineButton(
              label: '← Retour',
              onTap: _prev,
              color: AppColors.blueLight,
              height: 52,
            ),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          flex: 2,
          child: GradientButton(
            label: isLast ? 'Soumettre mon profil' : 'Continuer →',
            onTap: _next,
            colors: isLast
                ? [AppColors.teal, AppColors.greenBright]
                : [AppColors.bluePrimary, AppColors.teal],
            icon: isLast
                ? Icons.send_rounded
                : Icons.arrow_forward_rounded,
            height: 52,
          ),
        ),
      ]),
    );
  }

  Widget _currentStep() {
    switch (_step) {
      case 0:  return _step1();
      case 1:  return _step2();
      case 2:  return _step3();
      default: return _step4();
    }
  }

  // ════════════════════════════════════════════════════════════════
  // ÉTAPE 1 — Informations personnelles
  // ════════════════════════════════════════════════════════════════
  Widget _step1() => Form(
    key: _fKey1,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _StepTitle(
        icon: Icons.person_outline_rounded,
        title: 'Informations\npersonnelles',
        subtitle: 'Ces informations seront affichées sur votre profil public',
        color: AppColors.blueLight,
      ),
      const SizedBox(height: 28),

      // ── Photo de profil ──
      _Lbl('Photo de profil *'),
      _PhotoBox(
        label: 'Ajouter votre\nphoto de profil',
        icon: Icons.person_rounded,
        color: AppColors.blueLight,
        tall: true,
        onPicked: (f) => setState(() => _avatar = f),
      ),
      const SizedBox(height: 22),

      _Lbl('Nom complet *'),
      _TF(
        hint: 'Dr. Jean Mbarga',
        ctrl: _nomCtrl,
        icon: Icons.person_outline_rounded,
        validator: (v) => v!.isEmpty ? 'Champ requis' : null,
      ),
      const SizedBox(height: 14),

      _Lbl('Numéro de téléphone *'),
      _PhoneTF(ctrl: _telCtrl),
      const SizedBox(height: 14),

      _Lbl('Adresse email *'),
      _TF(
        hint: 'contact@monservice.cm',
        ctrl: _emailCtrl,
        icon: Icons.email_outlined,
        keyboard: TextInputType.emailAddress,
        validator: (v) {
          if (v!.isEmpty) return 'Champ requis';
          if (!v.contains('@')) return 'Email invalide';
          return null;
        },
      ),
      const SizedBox(height: 14),

      _Lbl('Adresse complète *'),
      _TF(
        hint: 'Rue, Quartier, Ville…',
        ctrl: _addrCtrl,
        icon: Icons.place_outlined,
        maxLines: 2,
        validator: (v) => v!.isEmpty ? 'Champ requis' : null,
      ),
      const SizedBox(height: 8),
    ]),
  );

  // ════════════════════════════════════════════════════════════════
  // ÉTAPE 2 — Vérification CNI
  // ════════════════════════════════════════════════════════════════
  Widget _step2() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _StepTitle(
        icon: Icons.badge_outlined,
        title: 'Vérification\nd\'identité',
        subtitle:
            'Documents requis pour valider votre compte. Jamais publiés.',
        color: AppColors.warning,
      ),
      const SizedBox(height: 16),

      // Bandeau sécurité
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.security_rounded,
              color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tous les documents sont chiffrés et stockés de façon '
              'sécurisée. Ils servent uniquement à vérifier votre '
              'identité et ne seront jamais partagés ni publiés.',
              style:
                  AppTextStyles.label(size: 11, color: AppColors.warning),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 24),

      // Photo avec CNI en main
      _Lbl('Photo avec votre CNI en main *'),
      _PhotoBox(
        label: 'Tenez votre CNI face\ncaméra et prenez\nune photo',
        icon: Icons.co_present_rounded,
        color: AppColors.blueLight,
        tall: true,
        onPicked: (f) => setState(() => _cniAvec = f),
      ),
      const SizedBox(height: 6),
      _Hint('Votre visage et votre CNI doivent être clairement visibles'),
      const SizedBox(height: 22),

      // CNI Recto + Verso
      _Lbl('Photos de votre CNI *'),
      Row(children: [
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            _SmallLbl('Recto'),
            const SizedBox(height: 6),
            _PhotoBox(
              label: 'CNI\nRecto',
              icon: Icons.credit_card_rounded,
              color: AppColors.teal,
              tall: false,
              onPicked: (f) => setState(() => _cniRecto = f),
            ),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            _SmallLbl('Verso'),
            const SizedBox(height: 6),
            _PhotoBox(
              label: 'CNI\nVerso',
              icon: Icons.credit_card_rounded,
              color: AppColors.teal,
              tall: false,
              onPicked: (f) => setState(() => _cniVerso = f),
            ),
          ]),
        ),
      ]),
      const SizedBox(height: 6),
      _Hint('Toutes les informations doivent être lisibles'),
      const SizedBox(height: 20),

      // Checklist
      _CniChecklist(avec: _cniAvec != null, recto: _cniRecto != null, verso: _cniVerso != null),
      const SizedBox(height: 8),
    ],
  );

  // ════════════════════════════════════════════════════════════════
  // ÉTAPE 3 — Informations du service
  // ════════════════════════════════════════════════════════════════
  Widget _step3() => Form(
    key: _fKey3,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _StepTitle(
        icon: Icons.business_center_outlined,
        title: 'Informations\ndu service',
        subtitle: 'Décrivez votre service pour attirer les bons clients',
        color: AppColors.greenBright,
      ),
      const SizedBox(height: 28),

      _Lbl('Nom du service *'),
      _TF(
        hint: 'Consultation médicale, Cours de maths…',
        ctrl: _svcNameCtrl,
        icon: Icons.business_center_outlined,
        validator: (v) => v!.isEmpty ? 'Champ requis' : null,
      ),
      const SizedBox(height: 14),

      _Lbl('Catégorie *'),
      _DD(
        hint: 'Choisir une catégorie',
        value: _cat,
        items: _categories,
        icon: Icons.category_outlined,
        onChanged: (v) => setState(() => _cat = v),
      ),
      const SizedBox(height: 14),

      _Lbl('Description du service *'),
      _TF(
        hint:
            'Décrivez votre service, vos spécialités, votre expérience…',
        ctrl: _descCtrl,
        icon: Icons.description_outlined,
        maxLines: 4,
        validator: (v) => v!.isEmpty ? 'Champ requis' : null,
      ),
      const SizedBox(height: 14),

      _Lbl('Tarif *'),
      _TF(
        hint: 'Ex : 5 000 FCFA / consultation',
        ctrl: _tarifCtrl,
        icon: Icons.payments_outlined,
        validator: (v) => v!.isEmpty ? 'Champ requis' : null,
      ),
      const SizedBox(height: 14),

      _Lbl('Disponibilité *'),
      _DD(
        hint: 'Choisir vos horaires',
        value: _dispo,
        items: _dispos,
        icon: Icons.access_time_rounded,
        onChanged: (v) => setState(() => _dispo = v),
      ),
      const SizedBox(height: 22),

      // Logo principal
      _Lbl('Logo ou photo principale du service *'),
      _PhotoBox(
        label: 'Ajouter votre logo\nou photo principale',
        icon: Icons.add_photo_alternate_outlined,
        color: AppColors.greenBright,
        tall: true,
        onPicked: (f) => setState(() => _logo = f),
      ),
      const SizedBox(height: 22),

      // Images supplémentaires
      _Lbl('Images supplémentaires (optionnel — max 5)'),
      const SizedBox(height: 10),
      SizedBox(
        height: 100,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            ...List.generate(
              _nbImages,
              (i) => _ImgThumb(
                index: i + 1,
                onRemove: () => setState(() => _nbImages--),
              ),
            ),
            if (_nbImages < 5)
              _AddImgBtn(onTap: () => setState(() => _nbImages++)),
          ],
        ),
      ),
      const SizedBox(height: 6),
      _Hint('Photos de votre espace, réalisations, équipements…'),
      const SizedBox(height: 8),
    ]),
  );

  // ════════════════════════════════════════════════════════════════
  // ÉTAPE 4 — Récapitulatif + Statut
  // ════════════════════════════════════════════════════════════════
  Widget _step4() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _StepTitle(
        icon: Icons.check_circle_outline_rounded,
        title: 'Récapitulatif\n& Confirmation',
        subtitle: 'Vérifiez vos informations avant de soumettre',
        color: AppColors.greenBright,
      ),
      const SizedBox(height: 24),

      // ── Recap Infos perso ──
      _Recap(
        title: 'Informations personnelles',
        icon: Icons.person_outline_rounded,
        color: AppColors.blueLight,
        rows: [
          ('Nom',        _nomCtrl.text.isEmpty   ? '—' : _nomCtrl.text),
          ('Téléphone',  _telCtrl.text.isEmpty   ? '—' : '+237 ${_telCtrl.text}'),
          ('Email',      _emailCtrl.text.isEmpty  ? '—' : _emailCtrl.text),
          ('Adresse',    _addrCtrl.text.isEmpty   ? '—' : _addrCtrl.text),
          ('Photo profil', _avatar  != null ? '✅ Ajoutée' : '❌ Manquante'),
        ],
      ),
      const SizedBox(height: 14),

      // ── Recap CNI ──
      _Recap(
        title: 'Vérification CNI',
        icon: Icons.badge_outlined,
        color: AppColors.warning,
        rows: [
          ('Avec CNI',   _cniAvec  != null ? '✅ OK' : '❌ Manquante'),
          ('CNI Recto',  _cniRecto != null ? '✅ OK' : '❌ Manquante'),
          ('CNI Verso',  _cniVerso != null ? '✅ OK' : '❌ Manquante'),
        ],
      ),
      const SizedBox(height: 14),

      // ── Recap Service ──
      _Recap(
        title: 'Informations du service',
        icon: Icons.business_center_outlined,
        color: AppColors.greenBright,
        rows: [
          ('Service',      _svcNameCtrl.text.isEmpty ? '—' : _svcNameCtrl.text),
          ('Catégorie',    _cat  ?? '—'),
          ('Tarif',        _tarifCtrl.text.isEmpty ? '—' : _tarifCtrl.text),
          ('Disponibilité',_dispo ?? '—'),
          ('Logo',         _logo       != null ? '✅ Ajouté' : '❌ Manquant'),
          ('Images supp.', _nbImages > 0 ? '✅ $_nbImages photo(s)' : 'Aucune'),
        ],
      ),
      const SizedBox(height: 22),

      // ── Bandeau Statut ──
      _StatutBanner(),
      const SizedBox(height: 22),

      // ── Conditions ──
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border:
              Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(
            'En soumettant, vous confirmez que :',
            style: AppTextStyles.label(
                size: 12,
                color: AppColors.textSub,
                weight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          for (final t in [
            'Toutes les informations fournies sont exactes',
            'Vous acceptez les Conditions Générales d\'Utilisation',
            'Vous acceptez la Politique de Confidentialité',
            'Votre compte sera examiné avant validation',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Icon(Icons.check_rounded,
                    color: AppColors.teal, size: 14),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(t,
                        style: AppTextStyles.label(
                            size: 11,
                            color: AppColors.textSub))),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: 8),
    ],
  );
}

// ════════════════════════════════════════════════════════════════
// WIDGETS RÉUTILISABLES
// ════════════════════════════════════════════════════════════════

// ── Titre d'étape ──────────────────────────────────────────────
class _StepTitle extends StatelessWidget {
  final IconData icon;
  final String   title, subtitle;
  final Color    color;
  const _StepTitle({
    required this.icon, required this.title,
    required this.subtitle, required this.color,
  });
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: AppTextStyles.heading(size: 22, color: Colors.white)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: AppTextStyles.body(size: 12, color: AppColors.textSub)),
        ]),
      ),
    ],
  );
}

// ── Labels ────────────────────────────────────────────────────
class _Lbl extends StatelessWidget {
  final String text;
  const _Lbl(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: AppTextStyles.label(
            size: 12,
            color: AppColors.textSub,
            weight: FontWeight.w600)),
  );
}

class _SmallLbl extends StatelessWidget {
  final String text;
  const _SmallLbl(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTextStyles.label(size: 11, color: AppColors.textHint));
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);
  @override
  Widget build(BuildContext context) => Row(children: [
    const Icon(Icons.info_outline_rounded,
        size: 12, color: AppColors.textHint),
    const SizedBox(width: 6),
    Expanded(
        child: Text(text,
            style: AppTextStyles.label(
                size: 11, color: AppColors.textHint))),
  ]);
}

// ── Badge ─────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String text;
  final Color  color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(text,
        style: AppTextStyles.label(
            size: 10, color: color, weight: FontWeight.w800)),
  );
}

// ── Photo box — caméra ou galerie ────────────────────────────
class _PhotoBox extends StatefulWidget {
  final String   label;
  final IconData icon;
  final Color    color;
  final bool     tall;
  final void Function(File? file) onPicked;

  const _PhotoBox({
    required this.label, required this.icon,
    required this.color, required this.tall,
    required this.onPicked,
  });

  @override
  State<_PhotoBox> createState() => _PhotoBoxState();
}

class _PhotoBoxState extends State<_PhotoBox> {
  File? _file;
  final _picker = ImagePicker();

  Future<void> _pick(ImageSource source) async {
    final x = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (x == null) return;
    setState(() => _file = File(x.path));
    widget.onPicked(_file);
  }

  void _showChoice() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poignée
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ajouter une photo',
                style: AppTextStyles.heading(size: 17, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: AppTextStyles.body(size: 12, color: AppColors.textSub),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Bouton Caméra
              _PickerOption(
                icon: Icons.camera_alt_rounded,
                label: 'Prendre une photo',
                subtitle: 'Ouvrir la caméra directement',
                color: widget.color,
                onTap: () {
                  Navigator.pop(context);
                  _pick(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
              // Bouton Galerie
              _PickerOption(
                icon: Icons.photo_library_rounded,
                label: 'Choisir depuis la galerie',
                subtitle: 'Importer depuis vos photos',
                color: AppColors.blueLight,
                onTap: () {
                  Navigator.pop(context);
                  _pick(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
              // Annuler
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Center(
                    child: Text('Annuler',
                      style: AppTextStyles.label(
                          size: 14, color: AppColors.textSub)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = _file != null;
    return GestureDetector(
      onTap: _showChoice,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        height: widget.tall ? 140 : 120,
        decoration: BoxDecoration(
          color: hasFile
              ? widget.color.withOpacity(0.08)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: hasFile
                ? widget.color.withOpacity(0.6)
                : Colors.white.withOpacity(0.12),
            width: hasFile ? 1.5 : 1,
          ),
        ),
        child: hasFile
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Aperçu image
                    Image.file(_file!, fit: BoxFit.cover),
                    // Overlay sombre
                    Container(color: Colors.black.withOpacity(0.35)),
                    // Icône modifier
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(height: 8),
                          Text('Modifier la photo',
                            style: AppTextStyles.label(
                                size: 12,
                                color: Colors.white,
                                weight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    // Badge OK
                    Positioned(
                      top: 10, right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.greenBright,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('✓ OK',
                          style: AppTextStyles.label(
                              size: 11,
                              color: Colors.black,
                              weight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon,
                      size: 28, color: widget.color.withOpacity(0.5)),
                  const SizedBox(height: 10),
                  Text(widget.label,
                    style: AppTextStyles.body(
                        size: 12, color: AppColors.textSub),
                    textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MiniBtn(
                        icon: Icons.camera_alt_rounded,
                        label: 'Caméra',
                        color: widget.color,
                        onTap: () => _pick(ImageSource.camera),
                      ),
                      const SizedBox(width: 10),
                      _MiniBtn(
                        icon: Icons.photo_library_rounded,
                        label: 'Galerie',
                        color: AppColors.blueLight,
                        onTap: () => _pick(ImageSource.gallery),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String   label, subtitle;
  final Color    color;
  final VoidCallback onTap;
  const _PickerOption({
    required this.icon, required this.label, required this.subtitle,
    required this.color, required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
              style: AppTextStyles.label(
                  size: 14, color: Colors.white, weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle,
              style: AppTextStyles.label(size: 11, color: AppColors.textSub)),
          ],
        )),
        Icon(Icons.chevron_right_rounded,
            color: color.withOpacity(0.6), size: 20),
      ]),
    ),
  );
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;
  const _MiniBtn({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 5),
        Text(label,
          style: AppTextStyles.label(
              size: 11, color: color, weight: FontWeight.w600)),
      ]),
    ),
  );
}

// ── Image thumb ───────────────────────────────────────────────
class _ImgThumb extends StatelessWidget {
  final int index;
  final VoidCallback onRemove;
  const _ImgThumb({required this.index, required this.onRemove});
  @override
  Widget build(BuildContext context) => Container(
    width: 90, height: 90,
    margin: const EdgeInsets.only(right: 10),
    decoration: BoxDecoration(
      color: AppColors.greenBright.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      border: Border.all(color: AppColors.greenBright.withOpacity(0.35)),
    ),
    child: Stack(children: [
      Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.image_rounded,
              color: AppColors.greenBright, size: 26),
          const SizedBox(height: 4),
          Text('Image $index',
              style: AppTextStyles.label(
                  size: 10, color: AppColors.greenBright)),
        ]),
      ),
      Positioned(
        top: 4, right: 4,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 20, height: 20,
            decoration: const BoxDecoration(
                color: AppColors.error, shape: BoxShape.circle),
            child: const Icon(Icons.close_rounded,
                color: Colors.white, size: 12),
          ),
        ),
      ),
    ]),
  );
}

class _AddImgBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddImgBtn({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 90, height: 90,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_rounded,
            color: Colors.white.withOpacity(0.3), size: 26),
        const SizedBox(height: 4),
        Text('Ajouter',
            style:
                AppTextStyles.label(size: 10, color: AppColors.textHint)),
      ]),
    ),
  );
}

// ── Checklist CNI ─────────────────────────────────────────────
class _CniChecklist extends StatelessWidget {
  final bool avec, recto, verso;
  const _CniChecklist(
      {required this.avec, required this.recto, required this.verso});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: Column(children: [
      _CniRow('Photo avec CNI en main', avec),
      const SizedBox(height: 10),
      _CniRow('Photo CNI recto', recto),
      const SizedBox(height: 10),
      _CniRow('Photo CNI verso', verso),
    ]),
  );
}

class _CniRow extends StatelessWidget {
  final String label;
  final bool   done;
  const _CniRow(this.label, this.done);
  @override
  Widget build(BuildContext context) => Row(children: [
    AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 22, height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.greenBright : Colors.transparent,
        border: Border.all(
          color: done
              ? AppColors.greenBright
              : Colors.white.withOpacity(0.2),
        ),
      ),
      child: done
          ? const Icon(Icons.check_rounded,
              size: 13, color: Colors.white)
          : null,
    ),
    const SizedBox(width: 12),
    Text(label,
        style: AppTextStyles.body(
          size: 13,
          color: done ? Colors.white : AppColors.textSub,
          weight: done ? FontWeight.w600 : FontWeight.w400,
        )),
  ]);
}

// ── Récap section ────────────────────────────────────────────
class _Recap extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color    color;
  final List<(String, String)> rows;
  const _Recap({
    required this.title, required this.icon,
    required this.color, required this.rows,
  });
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.md)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 8),
          Text(title,
              style: AppTextStyles.label(
                  size: 12, color: color, weight: FontWeight.w700)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: rows.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96,
                  child: Text(r.$1,
                      style: AppTextStyles.label(size: 11)),
                ),
                Expanded(
                  child: Text(r.$2,
                      style: AppTextStyles.label(
                        size: 11,
                        color: r.$2.startsWith('✅')
                            ? AppColors.greenBright
                            : r.$2.startsWith('❌')
                                ? AppColors.error
                                : Colors.white,
                        weight: FontWeight.w500,
                      )),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    ]),
  );
}

// ── Bandeau statut ────────────────────────────────────────────
class _StatutBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [
        AppColors.warning.withOpacity(0.12),
        AppColors.warning.withOpacity(0.04),
      ]),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // En-tête
      Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.hourglass_top_rounded,
              color: AppColors.warning, size: 18),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Statut du compte',
              style:
                  AppTextStyles.label(size: 11, color: AppColors.textSub)),
          Text('En attente de validation',
              style: AppTextStyles.heading(
                  size: 15, color: AppColors.warning)),
        ]),
      ]),
      const SizedBox(height: 16),
      const Divider(color: Colors.white12),
      const SizedBox(height: 12),

      // Les 3 statuts possibles
      _StatutRow(
        icon: Icons.hourglass_top_rounded,
        label: 'En attente de validation',
        desc: 'Dossier en cours d\'examen par notre équipe',
        color: AppColors.warning,
        active: true,
      ),
      const SizedBox(height: 12),
      _StatutRow(
        icon: Icons.verified_rounded,
        label: 'Validé',
        desc: 'Profil publié et visible par les clients',
        color: AppColors.greenBright,
        active: false,
      ),
      const SizedBox(height: 12),
      _StatutRow(
        icon: Icons.block_rounded,
        label: 'Suspendu',
        desc: 'Compte désactivé temporairement (non-conformité)',
        color: AppColors.error,
        active: false,
      ),
    ]),
  );
}

class _StatutRow extends StatelessWidget {
  final IconData icon;
  final String   label, desc;
  final Color    color;
  final bool     active;
  const _StatutRow({
    required this.icon, required this.label, required this.desc,
    required this.color, required this.active,
  });
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: active ? 1.0 : 0.4,
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: AppTextStyles.label(
                  size: 12, color: color, weight: FontWeight.w700)),
          Text(desc,
              style: AppTextStyles.label(
                  size: 11, color: AppColors.textHint)),
        ]),
      ),
    ]),
  );
}

// ── Champ texte ───────────────────────────────────────────────
class _TF extends StatelessWidget {
  final String hint;
  final TextEditingController ctrl;
  final IconData icon;
  final TextInputType keyboard;
  final String? Function(String?)? validator;
  final int maxLines;
  const _TF({
    required this.hint, required this.ctrl, required this.icon,
    this.keyboard = TextInputType.text,
    this.validator, this.maxLines = 1,
  });
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    keyboardType: keyboard,
    maxLines: maxLines,
    style: AppTextStyles.body(size: 14, color: Colors.white),
    validator: validator,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppColors.textSub),
    ),
  );
}

// ── Champ téléphone ───────────────────────────────────────────
class _PhoneTF extends StatelessWidget {
  final TextEditingController ctrl;
  const _PhoneTF({required this.ctrl});
  @override
  Widget build(BuildContext context) => Row(children: [
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
        Text('+237',
            style: AppTextStyles.body(
                size: 14, color: Colors.white, weight: FontWeight.w600)),
      ]),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.phone,
        style: AppTextStyles.body(size: 14, color: Colors.white),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(9),
        ],
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

// ── Dropdown ──────────────────────────────────────────────────
class _DD extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final IconData icon;
  final void Function(String?) onChanged;
  const _DD({
    required this.hint, required this.value, required this.items,
    required this.icon, required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Container(
    height: 54,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: AppColors.surface.withOpacity(0.6),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        dropdownColor: AppColors.bgCard,
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSub),
        hint: Row(children: [
          Icon(icon, size: 20, color: AppColors.textSub),
          const SizedBox(width: 12),
          Text(hint,
              style: AppTextStyles.body(
                  size: 14, color: AppColors.textHint)),
        ]),
        items: items
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e,
                      style: AppTextStyles.body(
                          size: 14, color: Colors.white)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    ),
  );
}
