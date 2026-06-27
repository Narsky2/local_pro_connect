// ════════════════════════════════════════════════════════════════
// lib/services/payment_service.dart
// Paiement simulé — remplacer le corps de simuler() pour CinetPay
// ════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class PaymentService {
  static Future<Map<String, String>> simuler({
    required String methode,       // 'mobile_money' | 'carte'
    required String operateur,     // 'MTN' | 'Orange' | ''
    required double montant,
    required String reservationId,
    required String clientId,
    required String proId,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    final txId = 'LPC-${DateTime.now().millisecondsSinceEpoch}';
    await FB.db.collection('transactions').add({
      'reservationId':    reservationId,
      'clientId':         clientId,
      'proId':            proId,
      'montant':          montant,
      'methode':          methode,
      'operateur':        operateur,
      'statut':           'simulé',
      'numeroTransaction': txId,
      'createdAt':        FieldValue.serverTimestamp(),
    });
    await FB.db
        .collection('reservations')
        .doc(reservationId)
        .update({'statut': 'confirmée'});
    return {'statut': 'simulé', 'numeroTransaction': txId};
  }
}
