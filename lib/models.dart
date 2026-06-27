// ════════════════════════════════════════════════════════════════
// lib/models.dart  —  Modèles partagés + données mock
// ════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';

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

// ── Mock data ─────────────────────────────────────────────────────
final mockPros = <Pro>[
  Pro(
    id: '1', nom: 'Jean-Paul Essomba', structure: 'Électricité Pro Yaoundé',
    categorie: 'Électricité', emoji: '⚡', disponibilite: 'Disponible',
    description: 'Électricien certifié avec 12 ans d\'expérience. '
        'Installation, dépannage, mise aux normes pour particuliers et entreprises. '
        'Intervention rapide en moins de 2h sur Yaoundé.',
    ville: 'Yaoundé', quartier: 'Bastos', telephone: '+237 655 123 456',
    email: 'jpaul.elec@gmail.com',
    lat: 3.8520, lng: 11.5065, note: 4.8, prixMoyen: 15000,
    avis: 124, prestations: 312,
    galerie: ['⚡','🔌','🏠','🛠️','📐'],
    tags: ['Certifié','Rapide','Disponible 7j/7'],
    tarifs: {
      'Dépannage urgent':    '15 000 FCFA',
      'Installation tableau':'45 000 FCFA',
      'Mise aux normes':     'Sur devis',
    },
    horaires: {'Lun – Sam': '7h – 20h', 'Dimanche': 'Urgences uniquement'},
    reviews: [
      Avis(client:'Alice M.', commentaire:'Très professionnel, intervention rapide et soignée.', date:'12 mai 2025', note:5),
      Avis(client:'Paul T.',  commentaire:'Bon travail, prix raisonnable.', date:'3 avr. 2025', note:4.5),
      Avis(client:'Sara K.',  commentaire:'Ponctuel et efficace, je recommande !', date:'18 mars 2025', note:5),
    ],
  ),
  Pro(
    id: '2', nom: 'Marie Nguema', structure: 'Salon Marie Beauty',
    categorie: 'Coiffure', emoji: '💇', disponibilite: 'Disponible',
    description: 'Coiffeuse professionnelle spécialisée tresses africaines, '
        'défrisage, soins capillaires naturels. Matériel professionnel et produits de qualité.',
    ville: 'Yaoundé', quartier: 'Melen', telephone: '+237 699 234 567',
    email: 'marie.beauty@gmail.com',
    lat: 3.8490, lng: 11.5010, note: 4.6, prixMoyen: 5000,
    avis: 89, prestations: 540,
    galerie: ['💇','✂️','💅','🌟','🎀'],
    tags: ['Spécialiste tresses','Produits naturels','Prix doux'],
    tarifs: {
      'Tresses simples': '5 000 FCFA',
      'Défrisage':       '8 000 FCFA',
      'Soin capillaire': '3 500 FCFA',
      'Coupe + brushing':'6 000 FCFA',
    },
    horaires: {'Lun – Sam': '8h – 19h', 'Dimanche': 'Sur rendez-vous'},
    reviews: [
      Avis(client:'Cécile B.', commentaire:'Mes tresses sont superbes ! Je reviens chaque mois.', date:'20 mai 2025', note:5),
      Avis(client:'Diane N.',  commentaire:'Très douce et rapide. Salon propre.', date:'8 mai 2025', note:4.5),
    ],
  ),
  Pro(
    id: '3', nom: 'Tech Repair Center', structure: 'TRC Informatique',
    categorie: 'Informatique', emoji: '💻', disponibilite: 'Occupé',
    description: 'Centre de réparation informatique agréé. Ordinateurs, '
        'smartphones, tablettes. Récupération de données, virus, réseaux. '
        'Garantie 3 mois sur toutes les réparations.',
    ville: 'Yaoundé', quartier: 'Nlongkak', telephone: '+237 677 345 678',
    email: 'trc.info@gmail.com',
    lat: 3.8560, lng: 11.5080, note: 4.9, prixMoyen: 20000,
    avis: 203, prestations: 891,
    galerie: ['💻','📱','🖥️','⌨️','🔧'],
    tags: ['Agréé','Garantie 3 mois','Récupération données'],
    tarifs: {
      'Diagnostic':          '5 000 FCFA',
      'Réparation écran':    '25 000 FCFA',
      'Nettoyage PC':        '10 000 FCFA',
      'Récupération données':'30 000 FCFA',
    },
    horaires: {'Lun – Ven': '8h – 18h', 'Samedi': '9h – 15h'},
    reviews: [
      Avis(client:'Hervé M.', commentaire:'Mon disque dur récupéré en 24h. Miracle !', date:'15 mai 2025', note:5),
      Avis(client:'Lucie F.', commentaire:'Sérieux et compétents. Meilleur atelier de Yaoundé.', date:'2 mai 2025', note:5),
      Avis(client:'Marc R.',  commentaire:'Bon service, un peu long mais résultat parfait.', date:'22 avr. 2025', note:4.5),
    ],
  ),
  Pro(
    id: '4', nom: 'Express Livraison', structure: 'EL Delivery',
    categorie: 'Livraison', emoji: '🚚', disponibilite: 'Disponible',
    description: 'Service de livraison express à domicile et aux entreprises. '
        'Courses, colis, documents. Suivi en temps réel par SMS.',
    ville: 'Yaoundé', quartier: 'Mvog-Ada', telephone: '+237 655 456 789',
    email: 'express.livraison@gmail.com',
    lat: 3.8460, lng: 11.4990, note: 4.4, prixMoyen: 3000,
    avis: 56, prestations: 1240,
    galerie: ['🚚','📦','🛵','🗺️','⏱️'],
    tags: ['Express','Suivi SMS','Disponible 7j/7'],
    tarifs: {
      'Livraison Yaoundé centre': '2 000 FCFA',
      'Livraison banlieue':       '3 500 FCFA',
      'Course urgente':           '5 000 FCFA',
    },
    horaires: {'Tous les jours': '6h – 22h'},
    reviews: [
      Avis(client:'Sophie A.', commentaire:'Livraison en 30 min chrono. Parfait !', date:'18 mai 2025', note:5),
      Avis(client:'Eric B.',   commentaire:'Rapide et le colis était intact.', date:'10 mai 2025', note:4),
    ],
  ),
  Pro(
    id: '5', nom: 'Plombier Rapide', structure: 'PR Services',
    categorie: 'Plomberie', emoji: '🔧', disponibilite: 'Disponible',
    description: 'Plombier expérimenté, disponible 24h/24 pour urgences. '
        'Fuites, débouchage, installation sanitaire, chauffe-eau.',
    ville: 'Yaoundé', quartier: 'Ekounou', telephone: '+237 677 567 890',
    email: 'plombier.rapide@gmail.com',
    lat: 3.8530, lng: 11.5030, note: 4.7, prixMoyen: 12000,
    avis: 77, prestations: 423,
    galerie: ['🔧','🚿','🛁','💧','🪠'],
    tags: ['24h/24','Urgences','Devis gratuit'],
    tarifs: {
      'Fuite urgente':         '10 000 FCFA',
      'Débouchage':            '8 000 FCFA',
      'Installation sanitaire':'Sur devis',
    },
    horaires: {'24h/24': '7j/7'},
    reviews: [
      Avis(client:'Nadège T.', commentaire:'Arrivé en 20 min, fuite réparée en 1h. Top !', date:'14 mai 2025', note:5),
    ],
  ),
];
