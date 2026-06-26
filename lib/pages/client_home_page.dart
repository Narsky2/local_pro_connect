// ════════════════════════════════════════════════════════════════
// lib/pages/client_home_page.dart
// Accueil Client — Navigation fluide, UX pensée utilisateur
// ════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../models.dart';
import 'pro_fiche_page.dart';

// ── Catégories ───────────────────────────────────────────────────
const _cats = [
  ('Tous',          Icons.apps_rounded,              Color(0xFF4DA6FF)),
  ('Plomberie',     Icons.plumbing_rounded,           Color(0xFF42A5F5)),
  ('Électricité',   Icons.bolt_rounded,               Color(0xFFFFD54F)),
  ('Mécanique',     Icons.build_rounded,              Color(0xFFFF8A65)),
  ('Informatique',  Icons.computer_rounded,           Color(0xFF80DEEA)),
  ('Coiffure',      Icons.content_cut_rounded,        Color(0xFFF48FB1)),
  ('Livraison',     Icons.local_shipping_rounded,     Color(0xFFA5D6A7)),
  ('Ménage',        Icons.cleaning_services_rounded,  Color(0xFFCE93D8)),
  ('Climatisation', Icons.ac_unit_rounded,            Color(0xFF80CBC4)),
  ('Construction',  Icons.construction_rounded,       Color(0xFFFFCC02)),
  ('Jardinage',     Icons.yard_rounded,               Color(0xFF66BB6A)),
];

// ══════════════════════════════════════════════════════════════
class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});
  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage>
    with TickerProviderStateMixin {

  // ── Nav ──
  int _navIndex = 0;
  late PageController _pageCtrl;

  // ── Carte ──
  final Completer<GoogleMapController> _mapCtrl = Completer();
  Position? _pos;
  Set<Marker> _markers = {};

  // ── Recherche / filtres ──
  final _searchCtrl = TextEditingController();
  String _selectedCat = 'Tous';
  double _maxDist     = 10.0;
  double _minNote     = 0.0;
  double _maxPrix     = 100000;
  String _sortBy      = 'distance';
  bool   _filterOpen  = false;

  // ── Résultats ──
  List<Pro> _results = List.from(mockPros);
  Pro? _selectedPro;

  // ── Panel detail ──
  late AnimationController _panelCtrl;
  late Animation<double>    _panelSlide;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _panelCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _panelSlide = CurvedAnimation(
        parent: _panelCtrl, curve: Curves.easeOutCubic);
    _getLocation();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _searchCtrl.dispose();
    _panelCtrl.dispose();
    super.dispose();
  }

  // ── GPS ──────────────────────────────────────────────────────
  Future<void> _getLocation() async {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.deniedForever) {
      _search();
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() => _pos = pos);
      _search();
      final ctrl = await _mapCtrl.future;
      ctrl.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(pos.latitude, pos.longitude), 15));
    } catch (_) {
      _search();
    }
  }

  // ── Recherche + filtres ───────────────────────────────────────
  void _search() {
    final q = _searchCtrl.text.toLowerCase().trim();
    var res = mockPros.where((p) {
      final matchQ    = q.isEmpty ||
          p.nom.toLowerCase().contains(q) ||
          p.categorie.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
      final matchCat  = _selectedCat == 'Tous' ||
          p.categorie == _selectedCat;
      final matchNote = p.note >= _minNote;
      final matchPrix = p.prixMoyen <= _maxPrix;
      final dist = _pos != null
          ? p.distanceDe(_pos!.latitude, _pos!.longitude) : 0.0;
      final matchDist = _pos == null || dist <= _maxDist;
      return matchQ && matchCat && matchNote && matchPrix && matchDist;
    }).toList();

    // Tri
    res.sort((a, b) {
      switch (_sortBy) {
        case 'note':
          return b.note.compareTo(a.note);
        case 'prix':
          return a.prixMoyen.compareTo(b.prixMoyen);
        default: // distance
          if (_pos == null) return 0;
          return a.distanceDe(_pos!.latitude, _pos!.longitude)
              .compareTo(b.distanceDe(_pos!.latitude, _pos!.longitude));
      }
    });

    setState(() => _results = res);
    _buildMarkers(res);
  }

  void _buildMarkers(List<Pro> pros) {
    final ms = <Marker>{};
    if (_pos != null) {
      ms.add(Marker(
        markerId: const MarkerId('me'),
        position: LatLng(_pos!.latitude, _pos!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Ma position'),
      ));
    }
    for (final p in pros) {
      ms.add(Marker(
        markerId: MarkerId(p.id),
        position: LatLng(p.lat, p.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            p.disponibilite == 'Disponible'
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: p.nom,
          snippet: '${p.note}⭐  •  ${_fmtPrix(p.prixMoyen)}',
        ),
        onTap: () => _openPanel(p),
      ));
    }
    setState(() => _markers = ms);
  }

  void _openPanel(Pro p) {
    setState(() => _selectedPro = p);
    _panelCtrl.forward();
    // Centre la carte sur le pro
    _mapCtrl.future.then((ctrl) => ctrl.animateCamera(
        CameraUpdate.newLatLng(LatLng(p.lat, p.lng))));
  }

  void _closePanel() {
    _panelCtrl.reverse().then((_) {
      if (mounted) setState(() => _selectedPro = null);
    });
  }

  void _goToFiche(Pro p) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) =>
            ProFichePage(pro: p, userPos: _pos),
        transitionsBuilder: (_, anim, __, child) =>
            SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(
                  parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _switchTab(int i) {
    HapticFeedback.lightImpact();
    setState(() {
      _navIndex = i;
      if (_selectedPro != null) _closePanel();
      if (_filterOpen) _filterOpen = false;
    });
    _pageCtrl.jumpToPage(i);
  }

  String _fmtPrix(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k FCFA' : '$v FCFA';

  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      // PageView pour navigation fluide
      body: PageView(
        controller: _pageCtrl,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildMapTab(),
          _buildExploreTab(),
          _buildHistoriqueTab(),
          _buildProfilTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Bottom nav ────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      (Icons.map_rounded,       Icons.map_outlined,        'Carte'),
      (Icons.explore_rounded,   Icons.explore_outlined,    'Explorer'),
      (Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Mes réservations'),
      (Icons.person_rounded,    Icons.person_outline_rounded, 'Profil'),
    ];
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.07))),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.4), blurRadius: 20)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final sel = i == _navIndex;
          return GestureDetector(
            onTap: () => _switchTab(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.blueLight.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      sel ? items[i].$1 : items[i].$2,
                      color: sel
                          ? AppColors.blueLight
                          : AppColors.textHint,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(items[i].$3,
                      style: AppTextStyles.label(
                        size: 10,
                        color: sel
                            ? AppColors.blueLight
                            : AppColors.textHint,
                        weight: sel
                            ? FontWeight.w700
                            : FontWeight.w400,
                      )),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // ONGLET 1 — CARTE
  // Le client ouvre l'app, voit sa position et les pros autour
  // ════════════════════════════════════════════════════════════════
  Widget _buildMapTab() {
    final center = _pos != null
        ? LatLng(_pos!.latitude, _pos!.longitude)
        : const LatLng(3.8480, 11.5021);

    return Stack(children: [

      // ── Google Maps plein écran ──
      GoogleMap(
        onMapCreated: _mapCtrl.complete,
        initialCameraPosition:
            CameraPosition(target: center, zoom: 15),
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        markers: _markers,
        onTap: (_) { if (_selectedPro != null) _closePanel(); },
      ),

      // ── Barre de recherche flottante ──
      Positioned(
        top: 0, left: 0, right: 0,
        child: _MapSearchBar(
          ctrl: _searchCtrl,
          filterOpen: _filterOpen,
          onSearch: _search,
          onFilterTap: () =>
              setState(() => _filterOpen = !_filterOpen),
        ),
      ),

      // ── Catégories scrollables ──
      Positioned(
        top: MediaQuery.of(context).padding.top + 70,
        left: 0, right: 0,
        child: _CatScrollBar(
          selected: _selectedCat,
          onSelect: (c) {
            setState(() => _selectedCat = c);
            _search();
          },
        ),
      ),

      // ── Panneau filtre avancé ──
      // IgnorePointer empêche les clics fantômes quand le panneau
      // est masqué hors écran (sinon il reste cliquable en arrière-plan).
      IgnorePointer(
        ignoring: !_filterOpen,
        child: AnimatedPositioned(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          top: _filterOpen
              ? MediaQuery.of(context).padding.top + 118
              : -420,
          left: 16, right: 16,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _filterOpen ? 1.0 : 0.0,
            child: _FilterPanel(
              maxDist: _maxDist,
              minNote: _minNote,
              maxPrix: _maxPrix,
              sortBy: _sortBy,
              onChanged: (d, n, p, s) {
                setState(() {
                  _maxDist = d; _minNote = n;
                  _maxPrix = p; _sortBy  = s;
                });
                _search();
              },
              onClose: () => setState(() => _filterOpen = false),
            ),
          ),
        ),
      ),

      // ── FAB : centrer position ──
      Positioned(
        right: 16,
        bottom: _selectedPro != null ? 290 : 140,
        child: _MapFab(
          icon: Icons.my_location_rounded,
          color: AppColors.blueLight,
          onTap: _getLocation,
        ),
      ),

      // ── Compteur résultats ──
      if (_selectedPro == null)
        Positioned(
          bottom: 148,
          left: 0, right: 0,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.bgCard.withOpacity(0.95),
                borderRadius:
                    BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                    color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                _results.isEmpty
                    ? 'Aucun prestataire trouvé'
                    : '${_results.length} prestataire(s) près de vous',
                style: AppTextStyles.label(
                    size: 12,
                    color: _results.isEmpty
                        ? AppColors.error
                        : Colors.white,
                    weight: FontWeight.w600),
              ),
            ),
          ),
        ),

      // ── Liste horizontale des prestataires ──
      if (_selectedPro == null && _results.isNotEmpty)
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: _ProHorizontalList(
            pros: _results,
            userPos: _pos,
            onTap: _openPanel,
            onFicheOpen: _goToFiche,
          ),
        ),

      // ── Fiche détail rapide ──
      if (_selectedPro != null)
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0, 1), end: Offset.zero)
                .animate(_panelSlide),
            child: _ProQuickPanel(
              pro: _selectedPro!,
              userPos: _pos,
              onClose: _closePanel,
              onVoirFiche: () => _goToFiche(_selectedPro!),
              onReserver: () => _showBookSheet(_selectedPro!),
              onAppeler: () {},
            ),
          ),
        ),
    ]);
  }

  // ════════════════════════════════════════════════════════════════
  // ONGLET 2 — EXPLORER
  // Le client cherche par catégorie + liste complète
  // ════════════════════════════════════════════════════════════════
  Widget _buildExploreTab() {
    return Container(
      color: AppColors.bgDark,
      child: CustomScrollView(
        slivers: [
          // Header fixe
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.bgGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 34, height: 34,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white),
                          padding: const EdgeInsets.all(3),
                          child: Image.asset('assets/logo/logo.png',
                              fit: BoxFit.contain),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Explorer',
                                style: AppTextStyles.heading(
                                    size: 20, color: Colors.white)),
                            Text('${_results.length} services disponibles',
                                style: AppTextStyles.label(
                                    size: 11, color: AppColors.textSub)),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 14),
                      // Barre recherche
                      _SearchInputBar(
                        ctrl: _searchCtrl,
                        onSearch: _search,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Catégories
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Catégories',
                  style: AppTextStyles.heading(
                      size: 15, color: Colors.white)),
            ),
          ),
          SliverToBoxAdapter(
            child: _CatGrid(
              selected: _selectedCat,
              onSelect: (c) {
                setState(() => _selectedCat = c);
                _search();
              },
            ),
          ),

          // Section pros disponibles maintenant
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.greenBright),
                ),
                const SizedBox(width: 8),
                Text('Disponibles maintenant',
                    style: AppTextStyles.heading(
                        size: 15, color: Colors.white)),
                const Spacer(),
                Text(
                  '${_results.where((p) => p.disponibilite == 'Disponible').length} pros',
                  style: AppTextStyles.label(
                      size: 12, color: AppColors.greenBright),
                ),
              ]),
            ),
          ),

          // Liste prestataires
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                if (i >= _results.length) return null;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _ProCard(
                    pro: _results[i],
                    userPos: _pos,
                    onTap: () => _goToFiche(_results[i]),
                  ),
                );
              },
              childCount: _results.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // ONGLET 3 — MES RÉSERVATIONS
  // Ce que le client a réservé, statuts, historique
  // ════════════════════════════════════════════════════════════════
  Widget _buildHistoriqueTab() {
    // Mock réservations
    final reservations = [
      _MockResa('Jean-Paul Électricité', '⚡', 'Dépannage urgent',
          '15 juin 2025', '10h00', 'En attente',   AppColors.warning),
      _MockResa('Marie Coiffure Pro',   '💇', 'Tresses simples',
          '10 juin 2025', '14h00', 'Confirmée',    AppColors.blueLight),
      _MockResa('Tech Repair Center',   '💻', 'Réparation écran',
          '3 juin 2025',  '9h00',  'Terminée',     AppColors.greenBright),
      _MockResa('Express Livraison',    '🚚', 'Livraison colis',
          '28 mai 2025',  '11h00', 'Annulée',      AppColors.error),
    ];

    return Container(
      color: AppColors.bgDark,
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.white),
                padding: const EdgeInsets.all(3),
                child: Image.asset('assets/logo/logo.png',
                    fit: BoxFit.contain),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Mes réservations',
                    style: AppTextStyles.heading(
                        size: 20, color: Colors.white)),
                Text('Suivi de vos demandes',
                    style: AppTextStyles.label(
                        size: 11, color: AppColors.textSub)),
              ]),
            ]),
          ),

          // Stats rapides
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(children: [
              _ResaStat('1', 'En attente', AppColors.warning),
              const SizedBox(width: 10),
              _ResaStat('1', 'Confirmées', AppColors.blueLight),
              const SizedBox(width: 10),
              _ResaStat('2', 'Terminées', AppColors.greenBright),
            ]),
          ),

          // Liste
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: reservations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _ResaCard(resa: reservations[i]),
            ),
          ),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // ONGLET 4 — PROFIL
  // ════════════════════════════════════════════════════════════════
  Widget _buildProfilTab() {
    return Container(
      color: AppColors.bgDark,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(children: [
            // Header dégradé
            Container(
              width: double.infinity,
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Column(children: [
                // Avatar
                Stack(children: [
                  Container(
                    width: 84, height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.bluePrimary,
                          AppColors.teal
                        ],
                      ),
                      boxShadow: AppColors.blueShadow,
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 42),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 26, height: 26,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.blueLight),
                      child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white, size: 13),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Text('Mon compte',
                    style: AppTextStyles.heading(
                        size: 20, color: Colors.white)),
                Text('client@email.com',
                    style: AppTextStyles.body(
                        size: 13, color: AppColors.textSub)),
                const SizedBox(height: 16),
                // Stats client
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius:
                        BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(children: [
                    _ProfilStat('4', 'Réservations'),
                    _Divider(),
                    _ProfilStat('2', 'Terminées'),
                    _Divider(),
                    _ProfilStat('3', 'Favoris'),
                    _Divider(),
                    _ProfilStat('4.8', 'Note moy.'),
                  ]),
                ),
              ]),
            ),

            // Menu
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                _MenuSection('Mon compte', [
                  _MenuItem(Icons.person_outline_rounded,
                      'Modifier mon profil', AppColors.blueLight, () {}),
                  _MenuItem(Icons.notifications_outlined,
                      'Notifications', AppColors.teal, () {}),
                  _MenuItem(Icons.lock_outline_rounded,
                      'Sécurité & mot de passe', AppColors.warning, () {}),
                ]),
                const SizedBox(height: 16),
                _MenuSection('Mes activités', [
                  _MenuItem(Icons.history_rounded,
                      'Historique des réservations', AppColors.blueLight,
                      () => _switchTab(2)),
                  _MenuItem(Icons.favorite_outline_rounded,
                      'Mes favoris', AppColors.error, () {}),
                  _MenuItem(Icons.payment_rounded,
                      'Paiements & factures', AppColors.greenBright, () {}),
                ]),
                const SizedBox(height: 16),
                _MenuSection('Aide', [
                  _MenuItem(Icons.help_outline_rounded,
                      'Centre d\'aide', AppColors.textSub, () {}),
                  _MenuItem(Icons.star_outline_rounded,
                      'Noter l\'application', AppColors.warning, () {}),
                  _MenuItem(Icons.info_outline_rounded,
                      'À propos', AppColors.textSub, () {}),
                ]),
                const SizedBox(height: 16),
                // Déconnexion
                GestureDetector(
                  onTap: () => context.go('/welcome'),
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                          color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                      const Icon(Icons.logout_rounded,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Text('Déconnexion',
                          style: AppTextStyles.button(
                              size: 15, color: AppColors.error)),
                    ]),
                  ),
                ),
                const SizedBox(height: 30),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Sheet réservation rapide ──────────────────────────────────
  void _showBookSheet(Pro pro) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _QuickBookSheet(pro: pro),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// COMPOSANTS CARTE
// ════════════════════════════════════════════════════════════════

class _MapSearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool filterOpen;
  final VoidCallback onSearch, onFilterTap;
  const _MapSearchBar({
    required this.ctrl, required this.filterOpen,
    required this.onSearch, required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.bgDark, AppColors.bgDark.withOpacity(0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(children: [
          // Logo
          Container(
            width: 38, height: 38,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Colors.white),
            padding: const EdgeInsets.all(3),
            child: Image.asset('assets/logo/logo.png',
                fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          // Barre
          Expanded(
            child: GestureDetector(
              onTap: onSearch,
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.bgCard.withOpacity(0.97),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.12)),
                ),
                child: TextField(
                  controller: ctrl,
                  style: AppTextStyles.body(
                      size: 13, color: Colors.white),
                  onSubmitted: (_) => onSearch(),
                  decoration: InputDecoration(
                    hintText: 'Plombier, électricien, coiffeur…',
                    hintStyle: AppTextStyles.body(
                        size: 13, color: AppColors.textHint),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textHint, size: 20),
                    suffixIcon: ValueListenableBuilder(
                      valueListenable: ctrl,
                      builder: (_, v, __) => v.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 16,
                                  color: AppColors.textHint),
                              onPressed: () {
                                ctrl.clear();
                                onSearch();
                              })
                          : const SizedBox.shrink(),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Filtre
          GestureDetector(
            onTap: onFilterTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: filterOpen
                    ? AppColors.blueLight
                    : AppColors.bgCard.withOpacity(0.97),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: filterOpen
                      ? AppColors.blueLight
                      : Colors.white.withOpacity(0.12),
                ),
              ),
              child: Icon(Icons.tune_rounded,
                  color: filterOpen
                      ? Colors.white
                      : AppColors.textSub,
                  size: 20),
            ),
          ),
        ]),
      ),
    ),
  );
}

class _CatScrollBar extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  const _CatScrollBar(
      {required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 38,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemCount: _cats.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final cat = _cats[i];
        final sel = cat.$1 == selected;
        return GestureDetector(
          onTap: () => onSelect(cat.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: sel
                  ? cat.$3.withOpacity(0.9)
                  : AppColors.bgCard.withOpacity(0.94),
              borderRadius:
                  BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                  color: sel
                      ? cat.$3
                      : Colors.white.withOpacity(0.12)),
              boxShadow: sel
                  ? [BoxShadow(
                      color: cat.$3.withOpacity(0.4),
                      blurRadius: 8)]
                  : null,
            ),
            child: Row(children: [
              Icon(cat.$2,
                  size: 14,
                  color: sel ? Colors.white : AppColors.textSub),
              const SizedBox(width: 5),
              Text(cat.$1,
                  style: AppTextStyles.label(
                    size: 11,
                    color: sel ? Colors.white : AppColors.textSub,
                    weight: sel
                        ? FontWeight.w700
                        : FontWeight.w500,
                  )),
            ]),
          ),
        );
      },
    ),
  );
}

class _FilterPanel extends StatefulWidget {
  final double maxDist, minNote, maxPrix;
  final String sortBy;
  final void Function(double, double, double, String) onChanged;
  final VoidCallback onClose;
  const _FilterPanel({
    required this.maxDist,  required this.minNote,
    required this.maxPrix,  required this.sortBy,
    required this.onChanged, required this.onClose,
  });
  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late double dist, note, prix;
  late String sort;

  @override
  void initState() {
    super.initState();
    dist = widget.maxDist; note = widget.minNote;
    prix = widget.maxPrix; sort = widget.sortBy;
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
      boxShadow: AppColors.cardShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Filtres avancés',
              style: AppTextStyles.heading(
                  size: 15, color: Colors.white)),
          const Spacer(),
          GestureDetector(
            onTap: widget.onClose,
            child: const Icon(Icons.close_rounded,
                color: AppColors.textSub, size: 20),
          ),
        ]),
        const SizedBox(height: 14),
        _SliderRow('Distance max', '${dist.toInt()} km',
            dist, 1, 50, AppColors.blueLight, (v) {
          setState(() => dist = v);
          widget.onChanged(dist, note, prix, sort);
        }, divisions: 49),
        _SliderRow('Note minimum', '${note.toStringAsFixed(1)}⭐',
            note, 0, 5, AppColors.warning, (v) {
          setState(() => note = v);
          widget.onChanged(dist, note, prix, sort);
        }, divisions: 10),
        _SliderRow('Prix max',
            '${(prix / 1000).toStringAsFixed(0)}k FCFA',
            prix, 1000, 100000, AppColors.greenBright, (v) {
          setState(() => prix = v);
          widget.onChanged(dist, note, prix, sort);
        }, divisions: 99),
        const SizedBox(height: 8),
        Text('Trier par',
            style: AppTextStyles.label(
                size: 12,
                color: AppColors.textSub,
                weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: [
          for (final s in [
            ('distance', '📍 Distance'),
            ('note', '⭐ Note'),
            ('prix', '💰 Prix'),
          ])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() => sort = s.$1);
                    widget.onChanged(dist, note, prix, sort);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 36,
                    decoration: BoxDecoration(
                      color: sort == s.$1
                          ? AppColors.blueLight
                              .withOpacity(0.15)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(
                          AppRadius.sm),
                      border: Border.all(
                        color: sort == s.$1
                            ? AppColors.blueLight
                                .withOpacity(0.6)
                            : Colors.white.withOpacity(0.08),
                        width: sort == s.$1 ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(s.$2,
                          style: AppTextStyles.label(
                            size: 11,
                            color: sort == s.$1
                                ? AppColors.blueLight
                                : AppColors.textSub,
                            weight: sort == s.$1
                                ? FontWeight.w700
                                : FontWeight.w500,
                          )),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ],
    ),
  );
}

class _SliderRow extends StatelessWidget {
  final String label, value;
  final double val, min, max;
  final int? divisions;
  final Color color;
  final void Function(double) onChanged;
  const _SliderRow(this.label, this.value, this.val,
      this.min, this.max, this.color, this.onChanged, {this.divisions});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(children: [
        Text(label,
            style: AppTextStyles.label(
                size: 11, color: AppColors.textSub)),
        const Spacer(),
        Text(value,
            style: AppTextStyles.label(
                size: 11,
                color: Colors.white,
                weight: FontWeight.w700)),
      ]),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        ),
        child: Slider(
          value: val.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: color,
          inactiveColor: Colors.white12,
          onChanged: onChanged,
        ),
      ),
    ],
  );
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MapFab(
      {required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 46, height: 46,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Icon(icon, color: color, size: 22),
    ),
  );
}

// ── Liste horizontale carte ───────────────────────────────────────
class _ProHorizontalList extends StatelessWidget {
  final List<Pro> pros;
  final Position? userPos;
  final void Function(Pro) onTap;
  final void Function(Pro) onFicheOpen;
  const _ProHorizontalList({
    required this.pros, required this.userPos,
    required this.onTap, required this.onFicheOpen,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 140,
    decoration: BoxDecoration(
      color: AppColors.bgCard,
      borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg)),
      boxShadow: AppColors.cardShadow,
    ),
    child: Column(children: [
      const SizedBox(height: 6),
      Center(child: Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 6),
      Expanded(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: pros.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => _ProMiniMapCard(
            pro: pros[i],
            userPos: userPos,
            onPin: () => onTap(pros[i]),
            onOpen: () => onFicheOpen(pros[i]),
          ),
        ),
      ),
      const SizedBox(height: 6),
    ]),
  );
}

class _ProMiniMapCard extends StatelessWidget {
  final Pro pro;
  final Position? userPos;
  final VoidCallback onPin, onOpen;
  const _ProMiniMapCard({
    required this.pro, required this.userPos,
    required this.onPin, required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final dist = userPos != null
        ? pro.distanceDe(userPos!.latitude, userPos!.longitude)
        : null;
    return GestureDetector(
      onTap: onPin,
      onLongPress: onOpen,
      child: Container(
        width: 155,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(pro.emoji,
                  style: const TextStyle(fontSize: 20)),
              const Spacer(),
              _DispoMini(pro.disponibilite),
            ]),
            const SizedBox(height: 6),
            Text(pro.nom,
                style: AppTextStyles.label(
                    size: 12,
                    color: Colors.white,
                    weight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(pro.categorie,
                style: AppTextStyles.label(
                    size: 10, color: AppColors.textSub)),
            const Spacer(),
            Row(children: [
              const Icon(Icons.star_rounded,
                  color: AppColors.warning, size: 12),
              Text(' ${pro.note}',
                  style: AppTextStyles.label(
                      size: 11, color: AppColors.warning)),
              const Spacer(),
              if (dist != null)
                Text('${dist.toStringAsFixed(1)} km',
                    style: AppTextStyles.label(
                        size: 10,
                        color: AppColors.blueLight)),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Panel rapide (fiche compacte sur la carte) ────────────────────
class _ProQuickPanel extends StatelessWidget {
  final Pro pro;
  final Position? userPos;
  final VoidCallback onClose, onVoirFiche, onReserver, onAppeler;
  const _ProQuickPanel({
    required this.pro,       required this.userPos,
    required this.onClose,   required this.onVoirFiche,
    required this.onReserver, required this.onAppeler,
  });

  @override
  Widget build(BuildContext context) {
    final dist = userPos != null
        ? pro.distanceDe(userPos!.latitude, userPos!.longitude) : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg)),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Center(child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.white24,
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 14),

        // En-tête
        Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppColors.blueLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                  color: AppColors.blueLight.withOpacity(0.2)),
            ),
            child: Center(child: Text(pro.emoji,
                style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pro.nom,
                  style: AppTextStyles.heading(
                      size: 16, color: Colors.white)),
              const SizedBox(height: 2),
              Text(pro.categorie,
                  style: AppTextStyles.body(
                      size: 12, color: AppColors.textSub)),
              const SizedBox(height: 5),
              Row(children: [
                const Icon(Icons.star_rounded,
                    color: AppColors.warning, size: 14),
                Text(' ${pro.note}',
                    style: AppTextStyles.label(
                        size: 12, color: AppColors.warning,
                        weight: FontWeight.w700)),
                Text(' (${pro.avis} avis)',
                    style: AppTextStyles.label(
                        size: 11, color: AppColors.textHint)),
                const SizedBox(width: 8),
                if (dist != null) ...[
                  const Icon(Icons.place_rounded,
                      color: AppColors.blueLight, size: 12),
                  Text(' ${dist.toStringAsFixed(1)} km',
                      style: AppTextStyles.label(
                          size: 11,
                          color: AppColors.blueLight)),
                ],
              ]),
            ],
          )),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white54, size: 16),
            ),
          ),
        ]),

        const SizedBox(height: 14),
        const Divider(color: Colors.white10),
        const SizedBox(height: 12),

        // Chips info
        Row(children: [
          _InfoChip(Icons.payments_outlined, AppColors.greenBright,
              pro.prixFormat),
          const SizedBox(width: 8),
          _DispoChip(pro.disponibilite),
          const SizedBox(width: 8),
          _InfoChip(Icons.check_circle_rounded, AppColors.blueLight,
              '${pro.prestations} prestations'),
        ]),
        const SizedBox(height: 14),

        // Actions
        Row(children: [
          // Appeler
          _ActionBtn(
            icon: Icons.phone_rounded,
            label: 'Appeler',
            color: AppColors.greenBright,
            onTap: onAppeler,
          ),
          const SizedBox(width: 8),
          // Voir fiche
          _ActionBtn(
            icon: Icons.info_outline_rounded,
            label: 'Voir profil',
            color: AppColors.blueLight,
            onTap: onVoirFiche,
          ),
          const SizedBox(width: 8),
          // Réserver
          Expanded(
            child: GradientButton(
              label: 'Réserver',
              onTap: onReserver,
              icon: Icons.calendar_today_rounded,
              height: 46,
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── Card prestataire (liste explore) ─────────────────────────────
class _ProCard extends StatelessWidget {
  final Pro pro;
  final Position? userPos;
  final VoidCallback onTap;
  const _ProCard(
      {required this.pro, required this.userPos, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dist = userPos != null
        ? pro.distanceDe(userPos!.latitude, userPos!.longitude) : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(children: [
          // Emoji
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
              color: AppColors.blueLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(child: Text(pro.emoji,
                style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(pro.nom,
                      style: AppTextStyles.label(
                          size: 14,
                          color: Colors.white,
                          weight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                _DispoMini(pro.disponibilite),
              ]),
              const SizedBox(height: 3),
              Text(pro.structure,
                  style: AppTextStyles.label(
                      size: 11, color: AppColors.textHint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.star_rounded,
                    color: AppColors.warning, size: 13),
                Text(' ${pro.note}',
                    style: AppTextStyles.label(
                        size: 12, color: AppColors.warning)),
                Text(' (${pro.avis})',
                    style: AppTextStyles.label(
                        size: 11, color: AppColors.textHint)),
                const SizedBox(width: 10),
                if (dist != null) ...[
                  const Icon(Icons.place_rounded,
                      color: AppColors.blueLight, size: 12),
                  Text(' ${dist.toStringAsFixed(1)} km',
                      style: AppTextStyles.label(
                          size: 11, color: AppColors.blueLight)),
                ],
                const Spacer(),
                Text(pro.prixFormat,
                    style: AppTextStyles.label(
                        size: 11, color: AppColors.greenBright,
                        weight: FontWeight.w600)),
              ]),
            ],
          )),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textHint, size: 18),
        ]),
      ),
    );
  }
}

// ── Grille catégories ─────────────────────────────────────────────
class _CatGrid extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  const _CatGrid(
      {required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 20),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 4,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.9,
    ),
    itemCount: _cats.length,
    itemBuilder: (_, i) {
      final cat = _cats[i];
      final sel = cat.$1 == selected;
      return GestureDetector(
        onTap: () => onSelect(cat.$1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: sel
                ? cat.$3.withOpacity(0.15)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: sel
                  ? cat.$3.withOpacity(0.6)
                  : Colors.white.withOpacity(0.07),
              width: sel ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(cat.$2, color: cat.$3, size: 24),
              const SizedBox(height: 5),
              Text(cat.$1,
                  style: AppTextStyles.label(
                    size: 9,
                    color: sel ? Colors.white : AppColors.textSub,
                    weight: sel
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2),
            ],
          ),
        ),
      );
    },
  );
}

// ════════════════════════════════════════════════════════════════
// RÉSERVATIONS MOCK
// ════════════════════════════════════════════════════════════════

class _MockResa {
  final String nom, emoji, service, date, heure, statut;
  final Color couleur;
  const _MockResa(this.nom, this.emoji, this.service,
      this.date, this.heure, this.statut, this.couleur);
}

class _ResaCard extends StatelessWidget {
  final _MockResa resa;
  const _ResaCard({required this.resa});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: Row(children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: resa.couleur.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Center(child: Text(resa.emoji,
            style: const TextStyle(fontSize: 24))),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(resa.nom,
              style: AppTextStyles.label(
                  size: 13, color: Colors.white,
                  weight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(resa.service,
              style: AppTextStyles.label(
                  size: 11, color: AppColors.textSub)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.calendar_today_rounded,
                size: 11, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text('${resa.date} à ${resa.heure}',
                style: AppTextStyles.label(
                    size: 11, color: AppColors.textHint)),
          ]),
        ],
      )),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: resa.couleur.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
              color: resa.couleur.withOpacity(0.4)),
        ),
        child: Text(resa.statut,
            style: AppTextStyles.label(
                size: 10, color: resa.couleur,
                weight: FontWeight.w700)),
      ),
    ]),
  );
}

class _ResaStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _ResaStat(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(value,
            style: AppTextStyles.heading(size: 20, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: AppTextStyles.label(size: 10,
                color: AppColors.textHint),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ════════════════════════════════════════════════════════════════
// PROFIL WIDGETS
// ════════════════════════════════════════════════════════════════

class _ProfilStat extends StatelessWidget {
  final String value, label;
  const _ProfilStat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value,
          style: AppTextStyles.heading(
              size: 18, color: Colors.white)),
      const SizedBox(height: 2),
      Text(label,
          style: AppTextStyles.label(
              size: 10, color: AppColors.textHint),
          textAlign: TextAlign.center),
    ]),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 28, color: Colors.white.withOpacity(0.1));
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection(this.title, this.items);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title,
            style: AppTextStyles.label(
                size: 12,
                color: AppColors.textHint,
                weight: FontWeight.w700)),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(
          children: List.generate(items.length, (i) => Column(
            children: [
              items[i],
              if (i < items.length - 1)
                Divider(
                    height: 1,
                    color: Colors.white.withOpacity(0.06)),
            ],
          )),
        ),
      ),
    ],
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 13),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 14),
        Expanded(child: Text(label,
            style: AppTextStyles.body(
                size: 13, color: Colors.white))),
        Icon(Icons.chevron_right_rounded,
            color: AppColors.textHint, size: 16),
      ]),
    ),
  );
}

// ════════════════════════════════════════════════════════════════
// SHEET RÉSERVATION RAPIDE
// ════════════════════════════════════════════════════════════════

class _QuickBookSheet extends StatefulWidget {
  final Pro pro;
  const _QuickBookSheet({required this.pro});
  @override
  State<_QuickBookSheet> createState() => _QuickBookSheetState();
}

class _QuickBookSheetState extends State<_QuickBookSheet> {
  DateTime? date;
  String?   creneau;
  final     descCtrl = TextEditingController();
  bool      loading  = false;

  @override
  void dispose() { descCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24, right: 24, top: 20),
    child: SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.white24,
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Row(children: [
          Text(widget.pro.emoji,
              style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Réserver',
                  style: AppTextStyles.heading(
                      size: 18, color: Colors.white)),
              Text(widget.pro.nom,
                  style: AppTextStyles.body(
                      size: 12, color: AppColors.teal)),
            ],
          )),
        ]),
        const SizedBox(height: 20),

        // Date
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
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
            if (d != null) setState(() => date = d);
          },
          child: Container(
            height: 50,
            padding:
                const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.5),
              borderRadius:
                  BorderRadius.circular(AppRadius.md),
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
                    : '${date!.day}/${date!.month}/${date!.year}',
                style: AppTextStyles.body(
                  size: 14,
                  color: date == null
                      ? AppColors.textHint
                      : Colors.white,
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 14),

        // Créneaux
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Créneau',
              style: AppTextStyles.label(
                  size: 12,
                  color: AppColors.textSub,
                  weight: FontWeight.w600)),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8,
          children: ['8h','9h','10h','11h',
                     '14h','15h','16h','17h']
              .map((c) => GestureDetector(
            onTap: () => setState(() => creneau = c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
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
          )).toList(),
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: descCtrl,
          maxLines: 2,
          style: AppTextStyles.body(size: 14, color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Décrivez votre besoin…',
            prefixIcon: Icon(Icons.description_outlined),
          ),
        ),
        const SizedBox(height: 14),

        // Prix estimé
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.greenBright.withOpacity(0.07),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
                color: AppColors.greenBright.withOpacity(0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.payments_outlined,
                color: AppColors.greenBright, size: 16),
            const SizedBox(width: 8),
            Text('Prix estimé : ',
                style: AppTextStyles.label(size: 12)),
            Text(widget.pro.prixFormat,
                style: AppTextStyles.label(
                    size: 13,
                    color: AppColors.greenBright,
                    weight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 16),

        GradientButton(
          label: 'Confirmer la réservation',
          loading: loading,
          icon: Icons.check_rounded,
          onTap: () async {
            if (date == null || creneau == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Sélectionnez une date et un créneau'),
                ),
              );
              return;
            }
            setState(() => loading = true);
            await Future.delayed(
                const Duration(milliseconds: 900));
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.greenBright, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Réservation envoyée ! '
                      '${date!.day}/${date!.month} à $creneau',
                      style: AppTextStyles.body(
                          size: 13, color: Colors.white),
                    ),
                  ),
                ]),
                backgroundColor: AppColors.bgCard,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppRadius.sm)),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
      ]),
    ),
  );
}

// ════════════════════════════════════════════════════════════════
// MICRO-WIDGETS
// ════════════════════════════════════════════════════════════════

class _DispoMini extends StatelessWidget {
  final String dispo;
  const _DispoMini(this.dispo);
  @override
  Widget build(BuildContext context) {
    final ok = dispo == 'Disponible';
    return Container(
      width: 8, height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ok ? AppColors.greenBright : AppColors.error,
        boxShadow: [BoxShadow(
          color: (ok ? AppColors.greenBright : AppColors.error)
              .withOpacity(0.5),
          blurRadius: 4,
        )],
      ),
    );
  }
}

class _DispoChip extends StatelessWidget {
  final String dispo;
  const _DispoChip(this.dispo);
  @override
  Widget build(BuildContext context) {
    final ok = dispo == 'Disponible';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (ok ? AppColors.greenBright : AppColors.error)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
            color: (ok ? AppColors.greenBright : AppColors.error)
                .withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ok ? AppColors.greenBright : AppColors.error,
            )),
        const SizedBox(width: 4),
        Text(dispo,
            style: AppTextStyles.label(
              size: 10,
              color: ok ? AppColors.greenBright : AppColors.error,
              weight: FontWeight.w700,
            )),
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  const _InfoChip(this.icon, this.color, this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 12),
      const SizedBox(width: 4),
      Text(label,
          style: AppTextStyles.label(
              size: 10, color: color,
              weight: FontWeight.w600)),
    ]),
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label,
                    required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(width: 5),
        Text(label,
            style: AppTextStyles.label(
                size: 12, color: color,
                weight: FontWeight.w600)),
      ]),
    ),
  );
}

class _SearchInputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSearch;
  const _SearchInputBar(
      {required this.ctrl, required this.onSearch});
  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    decoration: BoxDecoration(
      color: AppColors.surface.withOpacity(0.6),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
    ),
    child: TextField(
      controller: ctrl,
      style: AppTextStyles.body(size: 13, color: Colors.white),
      onSubmitted: (_) => onSearch(),
      decoration: InputDecoration(
        hintText: 'Plombier, électricien, coiffeur…',
        hintStyle: AppTextStyles.body(
            size: 13, color: AppColors.textHint),
        prefixIcon: const Icon(Icons.search_rounded,
            color: AppColors.textHint, size: 20),
        suffixIcon: ValueListenableBuilder(
          valueListenable: ctrl,
          builder: (_, v, __) => v.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.textHint),
                  onPressed: () {
                    ctrl.clear();
                    onSearch();
                  })
              : const SizedBox.shrink(),
        ),
        border: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 13),
      ),
    ),
  );
}
