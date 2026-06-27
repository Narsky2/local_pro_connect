// ════════════════════════════════════════════════════════════════
// lib/widgets/avis_form.dart
// Formulaire d'avis client — étoiles interactives + commentaire
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';

class AvisForm extends StatefulWidget {
  final String  proId;
  final String  proNom;
  final String  proEmoji;
  final String? reservationId;

  const AvisForm({
    super.key,
    required this.proId,
    required this.proNom,
    required this.proEmoji,
    this.reservationId,
  });

  static Future<void> show(
    BuildContext context, {
    required String proId,
    required String proNom,
    required String proEmoji,
    String? reservationId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => AvisForm(
        proId: proId, proNom: proNom,
        proEmoji: proEmoji, reservationId: reservationId,
      ),
    );
  }

  @override
  State<AvisForm> createState() => _AvisFormState();
}

class _AvisFormState extends State<AvisForm> {
  double _note     = 5;
  final  _ctrl     = TextEditingController();
  bool   _submitting = false;
  bool   _done       = false;

  static const _labels = ['Mauvais', 'Passable', 'Bien', 'Très bien', 'Excellent'];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final user = FB.auth.currentUser;
      final clientNom = user?.displayName ??
          (user?.email?.split('@').first ?? 'Client');

      await FB.db.collection('avis').add({
        'clientId':    user?.uid ?? '',
        'clientNom':   clientNom,
        'proId':       widget.proId,
        'note':        _note,
        'commentaire': _ctrl.text.trim(),
        'createdAt':   FieldValue.serverTimestamp(),
        if (widget.reservationId != null)
          'reservationId': widget.reservationId,
      });

      // Recalcul note moyenne du pro
      final snap = await FB.db
          .collection('avis')
          .where('proId', isEqualTo: widget.proId)
          .get();
      final notes = snap.docs
          .map((d) => (d.data()['note'] as num?)?.toDouble() ?? 0.0)
          .toList();
      if (notes.isNotEmpty) {
        final moyenne = notes.reduce((a, b) => a + b) / notes.length;
        await FB.db.collection('pros').doc(widget.proId).update({
          'note':      double.parse(moyenne.toStringAsFixed(1)),
          'avisCount': notes.length,
        });
      }

      if (!mounted) return;
      setState(() { _submitting = false; _done = true; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur : $e',
            style: AppTextStyles.body(size: 13, color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24, right: 24, top: 20,
      ),
      child: _done ? _buildSuccess() : _buildForm(),
    );
  }

  // ── Écran succès ──────────────────────────────────────────────
  Widget _buildSuccess() => Column(mainAxisSize: MainAxisSize.min, children: [
    const SizedBox(height: 8),
    Container(
      width: 64, height: 64,
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(
            color: AppColors.warning.withOpacity(0.4), width: 1.5),
      ),
      child: const Icon(Icons.star_rounded,
          color: AppColors.warning, size: 36),
    ),
    const SizedBox(height: 16),
    Text('Merci pour votre avis !',
        style: AppTextStyles.heading(size: 20, color: Colors.white)),
    const SizedBox(height: 6),
    Text('Votre note aide d\'autres clients à choisir.',
        style: AppTextStyles.body(size: 13, color: AppColors.textSub),
        textAlign: TextAlign.center),
    const SizedBox(height: 24),
    GradientButton(
      label: 'Fermer',
      icon: Icons.check_circle_outline_rounded,
      onTap: () => Navigator.pop(context),
    ),
    const SizedBox(height: 8),
  ]);

  // ── Formulaire ────────────────────────────────────────────────
  Widget _buildForm() => SingleChildScrollView(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      // Handle
      Center(
        child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      const SizedBox(height: 20),

      // En-tête
      Row(children: [
        Text(widget.proEmoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Laisser un avis',
              style: AppTextStyles.heading(size: 18, color: Colors.white)),
          Text(widget.proNom,
              style: AppTextStyles.body(size: 12, color: AppColors.teal)),
        ]),
      ]),
      const SizedBox(height: 28),

      // Étoiles interactives
      Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
        final filled = i < _note;
        return GestureDetector(
          onTap: () => setState(() => _note = i + 1.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              key: ValueKey('$i-$filled'),
              color: AppColors.warning,
              size: 44,
            ),
          ),
        );
      })),
      const SizedBox(height: 8),
      Text(_labels[_note.toInt() - 1],
          style: AppTextStyles.label(
              size: 14, color: AppColors.warning,
              weight: FontWeight.w700)),
      const SizedBox(height: 20),

      // Commentaire
      TextFormField(
        controller: _ctrl,
        maxLines: 4,
        style: AppTextStyles.body(size: 14, color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Décrivez votre expérience avec ce prestataire…',
          prefixIcon: Icon(Icons.rate_review_outlined),
        ),
      ),
      const SizedBox(height: 20),

      GradientButton(
        label: _submitting ? 'Publication…' : 'Publier l\'avis',
        icon: Icons.send_rounded,
        loading: _submitting,
        onTap: _submit,
      ),
      const SizedBox(height: 8),
    ]),
  );
}
