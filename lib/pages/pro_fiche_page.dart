// ════════════════════════════════════════════════════════════════
// lib/pages/pro_fiche_page.dart
// Fiche Prestataire — vue CLIENT
// ════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models.dart';
import '../services/firebase_service.dart';
import '../widgets/payment_bottom_sheet.dart';
import '../widgets/avis_form.dart';

class ProFichePage extends StatefulWidget {
  final Pro pro;
  final Position? userPos;

  const ProFichePage({super.key, required this.pro, this.userPos});

  @override
  State<ProFichePage> createState() => _ProFichePageState();
}

class _ProFichePageState extends State<ProFichePage>
    with TickerProviderStateMixin {

  late TabController _tabCtrl;
  bool _isFavori = false;
  int  _galIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final pro   = widget.pro;
    final dist  = widget.userPos != null
        ? pro.distanceDe(widget.userPos!.latitude, widget.userPos!.longitude)
        : null;
    final temps = dist != null ? pro.tempsEstime(dist) : null;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [

          // ── SliverAppBar avec galerie ──
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.bgDark,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
            actions: [
              // Favori
              GestureDetector(
                onTap: () => setState(() => _isFavori = !_isFavori),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      _isFavori
                          ? Icons.favorite_rounded
                          : Icons.favorite_outline_rounded,
                      key: ValueKey(_isFavori),
                      color: _isFavori ? AppColors.error : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              // Partager
              Container(
                margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share_rounded,
                    color: Colors.white, size: 18),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _GalerieHeader(
                pro: pro,
                selectedIndex: _galIndex,
                onIndexChanged: (i) => setState(() => _galIndex = i),
              ),
            ),
          ),

          // ── Corps ──
          SliverToBoxAdapter(
            child: Column(children: [

              // ── Carte identité ──
              Container(
                color: AppColors.bgDark,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Nom + badge dispo
                  Row(children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(pro.nom,
                            style: AppTextStyles.heading(
                                size: 22, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(pro.structure,
                            style: AppTextStyles.body(
                                size: 13, color: AppColors.textSub)),
                      ]),
                    ),
                    _DispoChip(pro.disponibilite),
                  ]),
                  const SizedBox(height: 12),

                  // Tags
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    _CatChip(pro.categorie),
                    ...pro.tags.map((t) => _TagChip(t)),
                  ]),
                  const SizedBox(height: 16),

                  // Stats rapides
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(children: [
                      _StatItem(
                        value: '${pro.note}',
                        label: 'Note',
                        icon: Icons.star_rounded,
                        color: AppColors.warning,
                        suffix: '⭐',
                      ),
                      _Vdiv(),
                      _StatItem(
                        value: '${pro.avis}',
                        label: 'Avis',
                        icon: Icons.reviews_rounded,
                        color: AppColors.blueLight,
                      ),
                      _Vdiv(),
                      _StatItem(
                        value: '${pro.prestations}',
                        label: 'Prestations',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.greenBright,
                      ),
                      if (dist != null) ...[
                        _Vdiv(),
                        _StatItem(
                          value: '${dist.toStringAsFixed(1)}',
                          label: 'km',
                          icon: Icons.place_rounded,
                          color: AppColors.teal,
                          suffix: '🕐 $temps',
                        ),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Localisation
                  Row(children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.blueLight, size: 16),
                    const SizedBox(width: 6),
                    Text('${pro.quartier}, ${pro.ville}',
                        style: AppTextStyles.body(
                            size: 13, color: AppColors.textSub)),
                    const Spacer(),
                    if (dist != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                              color: AppColors.teal.withOpacity(0.3)),
                        ),
                        child: Text('$temps en voiture',
                            style: AppTextStyles.label(
                                size: 11, color: AppColors.teal,
                                weight: FontWeight.w600)),
                      ),
                  ]),
                ]),
              ),

              // ── Tabs ──
              Container(
                color: AppColors.bgDark,
                child: TabBar(
                  controller: _tabCtrl,
                  isScrollable: true,
                  labelColor: AppColors.blueLight,
                  unselectedLabelColor: AppColors.textSub,
                  indicatorColor: AppColors.blueLight,
                  indicatorWeight: 2,
                  labelStyle: AppTextStyles.label(
                      size: 13, weight: FontWeight.w700),
                  unselectedLabelStyle:
                      AppTextStyles.label(size: 13),
                  tabs: const [
                    Tab(text: 'Description'),
                    Tab(text: 'Tarifs'),
                    Tab(text: 'Horaires'),
                    Tab(text: 'Avis'),
                  ],
                ),
              ),

              // ── Contenu tabs ──
              SizedBox(
                height: 420,
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _TabDescription(pro: pro),
                    _TabTarifs(pro: pro),
                    _TabHoraires(pro: pro),
                    _TabAvis(pro: pro),
                  ],
                ),
              ),

              const SizedBox(height: 120),
            ]),
          ),
        ],
      ),

      // ── Boutons d'action flottants ──
      bottomNavigationBar: _ActionBar(
        pro: pro,
        onAppeler:  () async {
          final uri = Uri(scheme: 'tel', path: pro.telephone);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          } else {
            _action('📞 Impossible d\'ouvrir le composeur');
          }
        },
        onMessage:  () => _showMessageSheet(context),
        onReserver: () => _showBookSheet(context),
      ),
    );
  }

  void _action(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: AppTextStyles.body(size: 13, color: Colors.white)),
      backgroundColor: AppColors.bgCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm)),
    ));
  }

  // ── Sheet Message ─────────────────────────────────────────────
  void _showMessageSheet(BuildContext ctx) {
    final msgCtrl = TextEditingController();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24, right: 24, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _BottomSheetHandle(),
          const SizedBox(height: 16),
          Row(children: [
            Text(widget.pro.emoji,
                style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Message à', style: AppTextStyles.label(size: 11)),
              Text(widget.pro.nom,
                  style: AppTextStyles.heading(
                      size: 16, color: Colors.white)),
            ]),
          ]),
          const SizedBox(height: 20),
          TextFormField(
            controller: msgCtrl,
            maxLines: 4,
            autofocus: true,
            style: AppTextStyles.body(size: 14, color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Bonjour, j\'ai besoin de vos services pour…',
              prefixIcon: Icon(Icons.message_outlined),
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: 'Envoyer le message',
            icon: Icons.send_rounded,
            onTap: () {
              Navigator.pop(ctx);
              _action('✅ Message envoyé à ${widget.pro.nom}');
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ── Sheet Réservation ─────────────────────────────────────────
  void _showBookSheet(BuildContext ctx) {
    DateTime? date;
    String? creneau;
    String? serviceChoisi;
    bool submitting = false;
    final descCtrl = TextEditingController();
    final pro = widget.pro;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx2, setSt) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 24, right: 24, top: 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _BottomSheetHandle(),
              const SizedBox(height: 16),

              Row(children: [
                Text(pro.emoji,
                    style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Réserver',
                      style: AppTextStyles.heading(
                          size: 18, color: Colors.white)),
                  Text(pro.nom,
                      style: AppTextStyles.body(
                          size: 12, color: AppColors.teal)),
                ]),
              ]),
              const SizedBox(height: 20),

              // ── Choix du service ──
              if (pro.tarifs.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Service',
                      style: AppTextStyles.label(
                          size: 12, color: AppColors.textSub,
                          weight: FontWeight.w600)),
                ),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final e in pro.tarifs.entries)
                    GestureDetector(
                      onTap: () => setSt(() => serviceChoisi = e.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: serviceChoisi == e.key
                              ? AppColors.teal.withOpacity(0.15)
                              : Colors.white.withOpacity(0.05),
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: serviceChoisi == e.key
                                ? AppColors.teal.withOpacity(0.7)
                                : Colors.white.withOpacity(0.1),
                            width: serviceChoisi == e.key ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.key,
                                style: AppTextStyles.label(
                                  size: 13,
                                  color: serviceChoisi == e.key
                                      ? AppColors.teal
                                      : Colors.white,
                                  weight: FontWeight.w600,
                                )),
                            Text(e.value,
                                style: AppTextStyles.label(
                                  size: 11,
                                  color: serviceChoisi == e.key
                                      ? AppColors.teal.withOpacity(0.8)
                                      : AppColors.textSub,
                                )),
                          ],
                        ),
                      ),
                    ),
                ]),
                const SizedBox(height: 16),
              ],

              // ── Sélecteur de date ──
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx2,
                    initialDate:
                        DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now()
                        .add(const Duration(days: 90)),
                    builder: (c, child) => Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                            primary: AppColors.blueLight),
                      ),
                      child: child!,
                    ),
                  );
                  if (d != null) setSt(() => date = d);
                },
                child: _DateSelector(date: date),
              ),
              const SizedBox(height: 14),

              // ── Créneaux horaires ──
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Créneau horaire',
                    style: AppTextStyles.label(
                        size: 12, color: AppColors.textSub,
                        weight: FontWeight.w600)),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final c in [
                  '8h00','9h00','10h00','11h00',
                  '14h00','15h00','16h00','17h00'
                ])
                  GestureDetector(
                    onTap: () => setSt(() => creneau = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: creneau == c
                            ? AppColors.blueLight.withOpacity(0.15)
                            : Colors.white.withOpacity(0.05),
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: creneau == c
                              ? AppColors.blueLight.withOpacity(0.7)
                              : Colors.white.withOpacity(0.1),
                          width: creneau == c ? 1.5 : 1,
                        ),
                      ),
                      child: Text(c,
                          style: AppTextStyles.label(
                            size: 13,
                            color: creneau == c
                                ? AppColors.blueLight
                                : AppColors.textSub,
                            weight: creneau == c
                                ? FontWeight.w700
                                : FontWeight.w500,
                          )),
                    ),
                  ),
              ]),
              const SizedBox(height: 16),

              TextFormField(
                controller: descCtrl,
                maxLines: 3,
                style:
                    AppTextStyles.body(size: 14, color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Décrivez votre besoin en détail…',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // ── Récap prix ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.greenBright.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                      color: AppColors.greenBright.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.payments_outlined,
                      color: AppColors.greenBright, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    serviceChoisi != null
                        ? 'Tarif : '
                        : 'Prix moyen estimé : ',
                    style: AppTextStyles.label(size: 13),
                  ),
                  Text(
                    serviceChoisi != null
                        ? (pro.tarifs[serviceChoisi] ?? pro.prixFormat)
                        : pro.prixFormat,
                    style: AppTextStyles.label(
                        size: 14, color: AppColors.greenBright,
                        weight: FontWeight.w700),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              GradientButton(
                label: submitting
                    ? 'Envoi en cours…'
                    : 'Confirmer la réservation',
                icon: Icons.check_rounded,
                loading: submitting,
                onTap: () async {
                  if (date == null || creneau == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text(
                          'Sélectionnez une date et un créneau',
                          style: AppTextStyles.body(
                              size: 13, color: Colors.white)),
                      backgroundColor: AppColors.bgCard,
                      behavior: SnackBarBehavior.floating,
                    ));
                    return;
                  }
                  if (submitting) return;
                  setSt(() => submitting = true);
                  try {
                    final uid = FB.auth.currentUser?.uid ?? '';
                    final montant = _parseMontant(
                        pro.tarifs[serviceChoisi] ?? '',
                        fallback: pro.prixMoyen);
                    final h = int.tryParse(
                            creneau!.replaceAll('h', '').substring(0, 2)) ??
                        8;
                    final dateTime = DateTime(
                        date!.year, date!.month, date!.day, h);
                    final service = serviceChoisi ?? 'Service général';
                    final docRef = await FB.db
                        .collection('reservations')
                        .add({
                      'clientId':  uid,
                      'clientNom': FB.auth.currentUser?.displayName ??
                          (FB.auth.currentUser?.email?.split('@').first ?? 'Client'),
                      'proId':     pro.id,
                      'proNom':    pro.nom,
                      'proEmoji':  pro.emoji,
                      'service':   service,
                      'montant':   montant,
                      'date':      Timestamp.fromDate(dateTime),
                      'creneau':   creneau,
                      'message':   descCtrl.text.trim(),
                      'statut':    'en_attente',
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (!ctx2.mounted) return;
                    Navigator.pop(ctx2);
                    if (!mounted) return;
                    await PaymentBottomSheet.show(
                      context,
                      reservationId: docRef.id,
                      proId:         pro.id,
                      clientId:      uid,
                      montant:       montant,
                      proNom:        pro.nom,
                      proEmoji:      pro.emoji,
                      service:       service,
                    );
                  } catch (e) {
                    setSt(() => submitting = false);
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text('Erreur : $e',
                          style: AppTextStyles.body(
                              size: 13, color: Colors.white)),
                      backgroundColor: AppColors.error,
                    ));
                  }
                },
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ),
    );
  }

  double _parseMontant(String tarif, {required double fallback}) {
    final digits = tarif.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return fallback;
    return double.tryParse(digits) ?? fallback;
  }
}

// ════════════════════════════════════════════════════════════════
// SECTIONS DU CORPS
// ════════════════════════════════════════════════════════════════

// ── Galerie header ────────────────────────────────────────────────
class _GalerieHeader extends StatelessWidget {
  final Pro    pro;
  final int    selectedIndex;
  final void Function(int) onIndexChanged;
  const _GalerieHeader({
    required this.pro, required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.bluePrimary.withOpacity(0.3),
            AppColors.bgDark,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(children: [
        // Image principale
        Expanded(
          child: Stack(children: [
            // Fond décoratif
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.bluePrimary.withOpacity(0.15),
                    AppColors.bgDark.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Photo principale (emoji large)
            Center(
              child: Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                  border: Border.all(
                      color: AppColors.blueLight.withOpacity(0.3),
                      width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.bluePrimary.withOpacity(0.3),
                      blurRadius: 30, spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(pro.galerie[selectedIndex],
                      style: const TextStyle(fontSize: 52)),
                ),
              ),
            ),
          ]),
        ),

        // Miniatures galerie
        Container(
          color: AppColors.bgDark.withOpacity(0.9),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(children: [
            ...List.generate(pro.galerie.length, (i) {
              final sel = i == selectedIndex;
              return GestureDetector(
                onTap: () => onIndexChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  width: sel ? 44 : 36,
                  height: sel ? 44 : 36,
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.blueLight.withOpacity(0.2)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: sel
                          ? AppColors.blueLight.withOpacity(0.7)
                          : Colors.white.withOpacity(0.1),
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(pro.galerie[i],
                        style: TextStyle(fontSize: sel ? 22 : 18)),
                  ),
                ),
              );
            }),
            const Spacer(),
            Text('${selectedIndex + 1}/${pro.galerie.length}',
                style: AppTextStyles.label(
                    size: 11, color: AppColors.textSub)),
          ]),
        ),
      ]),
    );
  }
}

// ── Tab Description ───────────────────────────────────────────────
class _TabDescription extends StatelessWidget {
  final Pro pro;
  const _TabDescription({required this.pro});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('À propos',
          style: AppTextStyles.heading(size: 15, color: Colors.white)),
      const SizedBox(height: 10),
      Text(pro.description,
          style: AppTextStyles.body(size: 13, color: AppColors.textSub),
          textAlign: TextAlign.justify),
      const SizedBox(height: 20),

      Text('Contact',
          style: AppTextStyles.heading(size: 15, color: Colors.white)),
      const SizedBox(height: 10),
      _ContactRow(Icons.phone_rounded, AppColors.greenBright, pro.telephone),
      const SizedBox(height: 8),
      _ContactRow(Icons.email_outlined, AppColors.blueLight, pro.email),
      const SizedBox(height: 8),
      _ContactRow(Icons.place_rounded, AppColors.teal,
          '${pro.quartier}, ${pro.ville}'),
    ]),
  );
}

// ── Tab Tarifs ────────────────────────────────────────────────────
class _TabTarifs extends StatelessWidget {
  final Pro pro;
  const _TabTarifs({required this.pro});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Grille tarifaire',
          style: AppTextStyles.heading(size: 15, color: Colors.white)),
      const SizedBox(height: 4),
      Text('Prix indicatifs — devis sur demande',
          style: AppTextStyles.label(size: 11, color: AppColors.textHint)),
      const SizedBox(height: 16),
      ...pro.tarifs.entries.map((e) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
                color: AppColors.greenBright, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(e.key,
                style: AppTextStyles.body(
                    size: 13, color: Colors.white,
                    weight: FontWeight.w500)),
          ),
          Text(e.value,
              style: AppTextStyles.label(
                  size: 13, color: AppColors.greenBright,
                  weight: FontWeight.w700)),
        ]),
      )),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.blueLight.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
              color: AppColors.blueLight.withOpacity(0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.blueLight, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Les tarifs sont donnés à titre indicatif. '
              'Un devis précis sera établi après diagnostic.',
              style: AppTextStyles.label(
                  size: 11, color: AppColors.blueLight),
            ),
          ),
        ]),
      ),
    ]),
  );
}

// ── Tab Horaires ──────────────────────────────────────────────────
class _TabHoraires extends StatelessWidget {
  final Pro pro;
  const _TabHoraires({required this.pro});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Disponibilités',
          style: AppTextStyles.heading(size: 15, color: Colors.white)),
      const SizedBox(height: 16),
      ...pro.horaires.entries.map((e) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(children: [
          const Icon(Icons.access_time_rounded,
              color: AppColors.teal, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(e.key,
                style: AppTextStyles.body(
                    size: 13, color: Colors.white,
                    weight: FontWeight.w500)),
          ),
          Text(e.value,
              style: AppTextStyles.label(
                  size: 13, color: AppColors.teal,
                  weight: FontWeight.w700)),
        ]),
      )),

      const SizedBox(height: 20),
      // Statut temps réel
      _DispoRealtime(disponibilite: pro.disponibilite),
    ]),
  );
}

// ── Tab Avis ──────────────────────────────────────────────────────
class _TabAvis extends StatelessWidget {
  final Pro pro;
  const _TabAvis({required this.pro});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FB.db
          .collection('avis')
          .where('proId', isEqualTo: pro.id)
          .snapshots(),
      builder: (_, snap) {
        final docs = snap.data?.docs ?? [];
        final dist = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
        for (final d in docs) {
          final n = ((d.data() as Map)['note'] as num?)?.round() ?? 0;
          if (n >= 1 && n <= 5) dist[n] = (dist[n] ?? 0) + 1;
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            _NoteGlobale(pro: pro, distribution: dist, totalAvis: docs.length),
            const SizedBox(height: 20),

            Text('Commentaires clients',
                style:
                    AppTextStyles.heading(size: 15, color: Colors.white)),
            const SizedBox(height: 12),

            if (snap.connectionState == ConnectionState.waiting &&
                docs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                      color: AppColors.teal, strokeWidth: 2),
                ),
              )
            else if (docs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('Aucun avis pour le moment.',
                      style: AppTextStyles.body(
                          size: 13, color: AppColors.textSub)),
                ),
              )
            else
              ...docs.map((d) => _FirestoreAvisCard(
                  data: d.data() as Map<String, dynamic>)),

            const SizedBox(height: 16),
            OutlineButton(
              label: '✏️  Laisser un avis',
              onTap: () => AvisForm.show(
                context,
                proId:    pro.id,
                proNom:   pro.nom,
                proEmoji: pro.emoji,
              ),
              color: AppColors.blueLight,
              height: 48,
            ),
          ]),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
// BARRE D'ACTIONS FIXE EN BAS
// ════════════════════════════════════════════════════════════════
class _ActionBar extends StatelessWidget {
  final Pro        pro;
  final VoidCallback onAppeler, onMessage, onReserver;
  const _ActionBar({
    required this.pro, required this.onAppeler,
    required this.onMessage, required this.onReserver,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    decoration: BoxDecoration(
      color: AppColors.bgCard,
      border:
          Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.5), blurRadius: 20)
      ],
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      // Prix moyen
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Text('À partir de ',
              style: AppTextStyles.body(size: 13, color: AppColors.textSub)),
          Text(pro.prixFormat,
              style: AppTextStyles.heading(
                  size: 18, color: AppColors.greenBright)),
          const Spacer(),
          // Badge prestations
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.blueLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                  color: AppColors.blueLight.withOpacity(0.3)),
            ),
            child: Text('${pro.prestations} prestations',
                style: AppTextStyles.label(
                    size: 11, color: AppColors.blueLight,
                    weight: FontWeight.w600)),
          ),
        ]),
      ),

      // Boutons
      Row(children: [
        // Appeler
        _RoundBtn(
          icon: Icons.phone_rounded,
          color: AppColors.greenBright,
          onTap: onAppeler,
          tooltip: 'Appeler',
        ),
        const SizedBox(width: 10),
        // Message
        _RoundBtn(
          icon: Icons.message_rounded,
          color: AppColors.blueLight,
          onTap: onMessage,
          tooltip: 'Message',
        ),
        const SizedBox(width: 10),
        // Réserver — bouton principal
        Expanded(
          child: GradientButton(
            label: 'Réserver maintenant',
            onTap: onReserver,
            icon: Icons.calendar_today_rounded,
            height: 50,
          ),
        ),
      ]),
    ]),
  );
}

// ════════════════════════════════════════════════════════════════
// WIDGETS UTILITAIRES
// ════════════════════════════════════════════════════════════════

class _StatItem extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color    color;
  final String?  suffix;
  const _StatItem({
    required this.value, required this.label,
    required this.icon,  required this.color,
    this.suffix,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value,
          style: AppTextStyles.heading(size: 17, color: color)),
      const SizedBox(height: 2),
      Text(label,
          style: AppTextStyles.label(size: 10, color: AppColors.textHint),
          textAlign: TextAlign.center),
    ]),
  );
}

class _Vdiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 32, color: Colors.white.withOpacity(0.1));
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  const _ContactRow(this.icon, this.color, this.label);
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, color: color, size: 17),
    ),
    const SizedBox(width: 12),
    Text(label,
        style: AppTextStyles.body(size: 13, color: Colors.white)),
  ]);
}

class _DispoChip extends StatelessWidget {
  final String dispo;
  const _DispoChip(this.dispo);
  @override
  Widget build(BuildContext context) {
    final ok = dispo == 'Disponible';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (ok ? AppColors.greenBright : AppColors.error)
            .withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
            color: (ok ? AppColors.greenBright : AppColors.error)
                .withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 7, height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ok ? AppColors.greenBright : AppColors.error,
          ),
        ),
        const SizedBox(width: 5),
        Text(dispo,
            style: AppTextStyles.label(
              size: 11,
              color: ok ? AppColors.greenBright : AppColors.error,
              weight: FontWeight.w700,
            )),
      ]),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String cat;
  const _CatChip(this.cat);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.blueLight.withOpacity(0.12),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(color: AppColors.blueLight.withOpacity(0.3)),
    ),
    child: Text(cat,
        style: AppTextStyles.label(
            size: 11, color: AppColors.blueLight,
            weight: FontWeight.w700)),
  );
}

class _TagChip extends StatelessWidget {
  final String tag;
  const _TagChip(this.tag);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(color: Colors.white.withOpacity(0.12)),
    ),
    child: Text(tag,
        style: AppTextStyles.label(
            size: 11, color: AppColors.textSub)),
  );
}

class _DispoRealtime extends StatelessWidget {
  final String disponibilite;
  const _DispoRealtime({required this.disponibilite});
  @override
  Widget build(BuildContext context) {
    final ok = disponibilite == 'Disponible';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (ok ? AppColors.greenBright : AppColors.warning)
            .withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: (ok ? AppColors.greenBright : AppColors.warning)
              .withOpacity(0.3),
        ),
      ),
      child: Row(children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ok ? AppColors.greenBright : AppColors.warning,
            boxShadow: [BoxShadow(
              color: (ok ? AppColors.greenBright : AppColors.warning)
                  .withOpacity(0.5),
              blurRadius: 8,
            )],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ok ? 'Disponible maintenant' : 'Actuellement occupé',
                style: AppTextStyles.label(
                  size: 14,
                  color: ok ? AppColors.greenBright : AppColors.warning,
                  weight: FontWeight.w700,
                )),
            Text(ok
                ? 'Peut vous recevoir ou intervenir rapidement'
                : 'Réservez pour un autre créneau',
                style: AppTextStyles.label(
                    size: 11, color: AppColors.textHint)),
          ],
        )),
      ]),
    );
  }
}

class _NoteGlobale extends StatelessWidget {
  final Pro pro;
  final Map<int, int> distribution;
  final int totalAvis;
  const _NoteGlobale({
    required this.pro,
    required this.distribution,
    required this.totalAvis,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.warning.withOpacity(0.07),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.warning.withOpacity(0.2)),
    ),
    child: Row(children: [
      Column(children: [
        Text(pro.note.toStringAsFixed(1),
            style: AppTextStyles.display(size: 40, color: AppColors.warning)),
        Row(children: List.generate(5, (i) {
          final filled = i < pro.note.floor();
          final half   = !filled && i < pro.note;
          return Icon(
            half ? Icons.star_half_rounded
                 : filled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: AppColors.warning, size: 16,
          );
        })),
        Text('$totalAvis avis',
            style: AppTextStyles.label(size: 11, color: AppColors.textHint)),
      ]),
      const SizedBox(width: 20),
      const VerticalDivider(color: Colors.white12, width: 1),
      const SizedBox(width: 20),
      Expanded(child: Column(children: [
        for (int i = 5; i >= 1; i--)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Text('$i',
                  style: AppTextStyles.label(size: 11,
                      color: AppColors.textHint)),
              const SizedBox(width: 6),
              const Icon(Icons.star_rounded,
                  color: AppColors.warning, size: 11),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalAvis == 0
                        ? 0.0
                        : (distribution[i] ?? 0) / totalAvis,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.warning),
                    minHeight: 6,
                  ),
                ),
              ),
            ]),
          ),
      ])),
    ]),
  );
}

// ── Carte avis Firestore ──────────────────────────────────────────
class _FirestoreAvisCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _FirestoreAvisCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final nom  = (data['clientNom'] as String?)?.isNotEmpty == true
        ? data['clientNom'] as String
        : 'Client';
    final note = (data['note'] as num?)?.toDouble() ?? 0.0;
    final txt  = (data['commentaire'] as String?) ?? '';
    final ts   = data['createdAt'];
    String dateStr = '';
    if (ts is Timestamp) {
      final d = ts.toDate();
      dateStr = '${d.day}/${d.month}/${d.year}';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppColors.blueLight.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(nom[0].toUpperCase(),
                  style: AppTextStyles.heading(
                      size: 15, color: AppColors.blueLight)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nom,
                    style: AppTextStyles.label(
                        size: 13, color: Colors.white,
                        weight: FontWeight.w600)),
                if (dateStr.isNotEmpty)
                  Text(dateStr,
                      style: AppTextStyles.label(
                          size: 10, color: AppColors.textHint)),
              ],
            ),
          ),
          Row(children: List.generate(5, (i) => Icon(
            i < note.floor()
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            color: AppColors.warning, size: 13,
          ))),
        ]),
        if (txt.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(txt,
              style: AppTextStyles.body(
                  size: 12, color: AppColors.textSub)),
        ],
      ]),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final VoidCallback onTap;
  final String   tooltip;
  const _RoundBtn({required this.icon, required this.color,
                   required this.onTap, required this.tooltip});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 50, height: 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Icon(icon, color: color, size: 22),
    ),
  );
}

class _DateSelector extends StatelessWidget {
  final DateTime? date;
  const _DateSelector({this.date});
  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: AppColors.surface.withOpacity(0.5),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(
        color: date != null
            ? AppColors.blueLight.withOpacity(0.5)
            : Colors.white.withOpacity(0.1),
      ),
    ),
    child: Row(children: [
      const Icon(Icons.calendar_today_rounded,
          color: AppColors.blueLight, size: 20),
      const SizedBox(width: 12),
      Text(
        date == null
            ? 'Choisir une date'
            : '${date!.day} / ${date!.month} / ${date!.year}',
        style: AppTextStyles.body(
          size: 14,
          color: date == null ? AppColors.textHint : Colors.white,
        ),
      ),
    ]),
  );
}

class _BottomSheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 36, height: 4,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}
