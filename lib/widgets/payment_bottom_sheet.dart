// ════════════════════════════════════════════════════════════════
// lib/widgets/payment_bottom_sheet.dart
// Sheet paiement simulé — MTN / Orange / Carte
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/payment_service.dart';

class PaymentBottomSheet extends StatefulWidget {
  final String reservationId;
  final String proId;
  final String clientId;
  final double montant;
  final String proNom;
  final String proEmoji;
  final String service;

  const PaymentBottomSheet({
    super.key,
    required this.reservationId,
    required this.proId,
    required this.clientId,
    required this.montant,
    required this.proNom,
    required this.proEmoji,
    required this.service,
  });

  static Future<void> show(
    BuildContext context, {
    required String reservationId,
    required String proId,
    required String clientId,
    required double montant,
    required String proNom,
    required String proEmoji,
    required String service,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => PaymentBottomSheet(
        reservationId: reservationId,
        proId:         proId,
        clientId:      clientId,
        montant:       montant,
        proNom:        proNom,
        proEmoji:      proEmoji,
        service:       service,
      ),
    );
  }

  @override
  State<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
  String _methode = 'MTN';
  final _numCtrl  = TextEditingController();
  bool   _paying  = false;
  bool   _done    = false;
  String? _txId;

  @override
  void dispose() {
    _numCtrl.dispose();
    super.dispose();
  }

  Future<void> _payer() async {
    if (_paying) return;
    setState(() => _paying = true);
    try {
      final result = await PaymentService.simuler(
        methode:       _methode == 'Carte' ? 'carte' : 'mobile_money',
        operateur:     _methode == 'Carte' ? '' : _methode,
        montant:       widget.montant,
        reservationId: widget.reservationId,
        clientId:      widget.clientId,
        proId:         widget.proId,
      );
      if (!mounted) return;
      setState(() {
        _paying = false;
        _done   = true;
        _txId   = result['numeroTransaction'];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur paiement : $e',
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
  Widget _buildSuccess() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 8),
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: AppColors.greenBright.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(
              color: AppColors.greenBright.withOpacity(0.4), width: 1.5),
        ),
        child: const Icon(Icons.check_rounded,
            color: AppColors.greenBright, size: 40),
      ),
      const SizedBox(height: 18),
      Text('Paiement confirmé !',
          style: AppTextStyles.heading(size: 22, color: Colors.white)),
      const SizedBox(height: 6),
      Text('Votre réservation chez ${widget.proNom} est validée.',
          style: AppTextStyles.body(size: 13, color: AppColors.textSub),
          textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.receipt_long_rounded,
              color: AppColors.teal, size: 16),
          const SizedBox(width: 8),
          Text(_txId ?? '',
              style: AppTextStyles.label(
                  size: 13, color: AppColors.teal,
                  weight: FontWeight.w700)),
        ]),
      ),
      const SizedBox(height: 24),
      GradientButton(
        label: 'Fermer',
        icon: Icons.check_circle_outline_rounded,
        onTap: () => Navigator.pop(context),
      ),
      const SizedBox(height: 8),
    ]);
  }

  // ── Formulaire paiement ───────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
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

        // ── En-tête ──
        Row(children: [
          Text(widget.proEmoji,
              style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Paiement',
                    style: AppTextStyles.heading(
                        size: 18, color: Colors.white)),
                Text(widget.service,
                    style: AppTextStyles.body(
                        size: 12, color: AppColors.teal)),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Montant',
                style: AppTextStyles.label(
                    size: 11, color: AppColors.textSub)),
            Text(_fmtPrix(widget.montant),
                style: AppTextStyles.heading(
                    size: 18, color: AppColors.greenBright)),
          ]),
        ]),
        const SizedBox(height: 24),

        // ── Méthode ──
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Méthode de paiement',
              style: AppTextStyles.label(
                  size: 12, color: AppColors.textSub,
                  weight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _MethodTile('MTN',    '📲', const Color(0xFFFFCC02)),
          const SizedBox(width: 10),
          _MethodTile('Orange', '🔶', const Color(0xFFFF6D00)),
          const SizedBox(width: 10),
          _MethodTile('Carte',  '💳', AppColors.blueLight),
        ]),
        const SizedBox(height: 20),

        // ── Numéro ──
        TextFormField(
          controller: _numCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTextStyles.body(size: 15, color: Colors.white),
          decoration: InputDecoration(
            hintText: _methode == 'Carte'
                ? 'Numéro de carte (16 chiffres)'
                : 'Numéro $_methode Mobile Money',
            prefixIcon: Icon(
              _methode == 'Carte'
                  ? Icons.credit_card_rounded
                  : Icons.smartphone_rounded,
              color: AppColors.textSub,
            ),
          ),
        ),
        const SizedBox(height: 20),

        GradientButton(
          label: _paying ? 'Traitement en cours…' : 'Payer maintenant',
          icon: Icons.lock_outline_rounded,
          loading: _paying,
          onTap: _payer,
        ),
        const SizedBox(height: 10),
        Text('Simulation — aucun débit réel',
            style: AppTextStyles.label(
                size: 11, color: AppColors.textSub.withOpacity(0.6)),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _MethodTile(String label, String emoji, Color accent) {
    final sel = _methode == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _methode = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: sel
                ? accent.withOpacity(0.14)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: sel
                  ? accent.withOpacity(0.7)
                  : Colors.white.withOpacity(0.1),
              width: sel ? 1.5 : 1,
            ),
          ),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 5),
            Text(label,
                style: AppTextStyles.label(
                    size: 11,
                    color: sel ? accent : AppColors.textSub,
                    weight: sel ? FontWeight.w700 : FontWeight.w500)),
          ]),
        ),
      ),
    );
  }

  String _fmtPrix(double p) =>
      p >= 1000 ? '${(p / 1000).toStringAsFixed(0)}k FCFA'
                : '${p.toStringAsFixed(0)} FCFA';
}
