// ════════════════════════════════════════════════════════════════
// lib/models.dart  —  Modèles partagés + données mock
// ════════════════════════════════════════════════════════════════

import 'dart:math' as math;

// ── Avis client ───────────────────────────────────────────────────
class Avis {
  final String client, commentaire, date;
  final double note;
  const Avis({required this.client, required this.commentaire,
               required this.date,  required this.note});
}

// ── Modèle Prestataire complet ────────────────────────────────────
class Pro {
  final String id, nom, structure, categorie, emoji,
               disponibilite, description, ville, quartier,
               telephone, email;
  final double lat, lng, note, prixMoyen;
  final int    avis, prestations;
  final List<String> galerie;       // emoji/url photos du service
  final List<String> tags;          // ex: ['Rapide','Certifié','Expérimenté']
  final Map<String,String> tarifs;  // ex: {'Consultation':'5000 FCFA'}
  final Map<String,String> horaires;// ex: {'Lun-Ven':'8h-18h'}
  final List<Avis> reviews;

  const Pro({
    required this.id,          required this.nom,
    required this.structure,   required this.categorie,
    required this.emoji,       required this.disponibilite,
    required this.description, required this.ville,
    required this.quartier,    required this.telephone,
    required this.email,       required this.lat,
    required this.lng,         required this.note,
    required this.prixMoyen,   required this.avis,
    required this.prestations, required this.galerie,
    required this.tags,        required this.tarifs,
    required this.horaires,    required this.reviews,
  });

  double distanceDe(double uLat, double uLng) {
    const R = 6371.0;
    final dLat = (lat - uLat) * math.pi / 180;
    final dLng = (lng - uLng) * math.pi / 180;
    final a = math.sin(dLat/2)*math.sin(dLat/2) +
        math.cos(uLat*math.pi/180)*math.cos(lat*math.pi/180)*
        math.sin(dLng/2)*math.sin(dLng/2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
  }

  String tempsEstime(double dist) {
    final min = (dist * 60 / 30).round();
    return min < 60 ? '$min min' : '${(min/60).toStringAsFixed(1)} h';
  }

  String get prixFormat {
    if (prixMoyen >= 1000)
      return '${(prixMoyen/1000).toStringAsFixed(0)}k FCFA';
    return '${prixMoyen.toStringAsFixed(0)} FCFA';
  }

  factory Pro.fromMap(String id, Map<String, dynamic> d) => Pro(
    id:           id,
    nom:          d['nom']          ?? '',
    structure:    d['structure']    ?? '',
    categorie:    d['categorie']    ?? '',
    emoji:        d['emoji']        ?? '⭐',
    disponibilite:d['disponibilite']?? '',
    description:  d['description'] ?? '',
    ville:        d['ville']        ?? 'Yaoundé',
    quartier:     d['quartier']     ?? '',
    telephone:    d['telephone']    ?? '',
    email:        d['email']        ?? '',
    lat:          (d['lat']      as num?)?.toDouble() ?? 3.848,
    lng:          (d['lng']      as num?)?.toDouble() ?? 11.502,
    note:         (d['note']     as num?)?.toDouble() ?? 0.0,
    prixMoyen:    (d['prixMoyen']as num?)?.toDouble() ?? 0.0,
    avis:         (d['avisCount']as num?)?.toInt()    ?? 0,
    prestations:  (d['prestations'] as num?)?.toInt() ?? 0,
    galerie:      List<String>.from(d['galerie']  ?? []),
    tags:         List<String>.from(d['tags']     ?? []),
    tarifs:       Map<String,String>.from(d['tarifs']  ?? {}),
    horaires:     Map<String,String>.from(d['horaires']?? {}),
    reviews:      [],
  );
}

