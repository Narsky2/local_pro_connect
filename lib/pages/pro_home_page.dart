// ════════════════════════════════════════════════════════════════
// lib/pages/pro_home_page.dart   —   Accueil Professionnel
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models.dart';
import '../services/firebase_service.dart';

class ProHomePage extends StatefulWidget {
  const ProHomePage({super.key});
  @override
  State<ProHomePage> createState() => _ProHomePageState();
}

class _ProHomePageState extends State<ProHomePage> {
  int    _navIndex = 0;
  Pro?   _pro;
  String _statut      = 'en_attente';
  bool   _isAvailable = true;
  bool   _loading     = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FB.auth.currentUser?.uid;
    if (uid == null) { setState(() => _loading = false); return; }
    final doc = await FB.db.collection('pros').doc(uid).get();
    if (!mounted) return;
    if (doc.exists) {
      final d = doc.data()!;
      setState(() {
        _pro         = Pro.fromMap(uid, d);
        _statut      = d['statut']      ?? 'en_attente';
        _isAvailable = d['isAvailable'] ?? true;
        _loading     = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(child: CircularProgressIndicator(color: AppColors.teal)),
      );
    }
    if (_pro == null) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.person_off_rounded, color: AppColors.textSub, size: 48),
          const SizedBox(height: 16),
          Text('Profil introuvable', style: AppTextStyles.heading(size: 18)),
          const SizedBox(height: 8),
          GradientButton(label: 'Compléter mon profil', onTap: () => context.go('/pro-register')),
        ])),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: IndexedStack(
        index: _navIndex,
        children: [
          _DashboardTab(pro: _pro!, statut: _statut, isAvailable: _isAvailable,
              onToggle: (v) async {
                setState(() => _isAvailable = v);
                await FB.db.collection('pros').doc(_pro!.id).update({'isAvailable': v});
              }),
          _ReservationsTab(),
          _AvisTab(pro: _pro!),
          _ProfilTab(pro: _pro!, statut: _statut),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        current: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// NAVIGATION BAS
// ════════════════════════════════════════════════════════════════
class _BottomNav extends StatelessWidget {
  final int current;
  final void Function(int) onTap;
  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.dashboard_rounded, Icons.dashboard_outlined,            'Accueil'),
      (Icons.calendar_month_rounded, Icons.calendar_month_outlined,  'Réservations'),
      (Icons.star_rounded,      Icons.star_outline_rounded,          'Avis'),
      (Icons.person_rounded,    Icons.person_outline_rounded,        'Profil'),
    ];
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final sel = i == current;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 76,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.teal.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      sel ? items[i].$1 : items[i].$2,
                      color: sel ? AppColors.teal : AppColors.textHint,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(items[i].$3,
                      style: AppTextStyles.label(
                        size: 10,
                        color: sel ? AppColors.teal : AppColors.textHint,
                        weight: sel ? FontWeight.w700 : FontWeight.w400,
                      )),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// ONGLET 1 — DASHBOARD
// ════════════════════════════════════════════════════════════════
class _DashboardTab extends StatelessWidget {
  final Pro pro;
  final String statut;
  final bool isAvailable;
  final void Function(bool) onToggle;
  const _DashboardTab({required this.pro, required this.statut, required this.isAvailable, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Header ──
            Row(children: [
              Container(
                width: 34, height: 34,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                padding: const EdgeInsets.all(3),
                child: Image.asset('assets/logo/logo.png', fit: BoxFit.contain),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bonjour 👋', style: AppTextStyles.label(size: 11, color: AppColors.textSub)),
                  Text(pro.nom, style: AppTextStyles.heading(size: 16, color: Colors.white)),
                ],
              )),
              // Notifications
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Stack(children: [
                  const Center(child: Icon(Icons.notifications_outlined, color: Colors.white, size: 20)),
                  Positioned(top: 8, right: 8, child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.error),
                  )),
                ]),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Statut compte ──
            _StatutCard(statut: statut),
            const SizedBox(height: 20),

            // ── Stats principales ──
            Row(children: [
              Expanded(child: _StatCard(
                icon: Icons.check_circle_rounded, color: AppColors.greenBright,
                value: '${pro.prestations}', label: 'Prestations\nréalisées',
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                icon: Icons.star_rounded, color: AppColors.warning,
                value: '${pro.note}', label: 'Note\nmoyenne',
              )),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _StatCard(
                icon: Icons.reviews_rounded, color: AppColors.blueLight,
                value: '${pro.avis}', label: 'Avis\nclients',
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                icon: Icons.pending_actions_rounded, color: AppColors.teal,
                value: '3', label: 'Demandes\nen attente',
              )),
            ]),
            const SizedBox(height: 24),

            // ── Toggle disponibilité ──
            _DispoToggle(initValue: isAvailable, onToggle: onToggle),
            const SizedBox(height: 24),

            // ── Réservations récentes ──
            Row(children: [
              Text('Demandes récentes', style: AppTextStyles.heading(size: 15, color: Colors.white)),
              const Spacer(),
              Text('Voir tout', style: AppTextStyles.label(size: 12, color: AppColors.blueLight)),
            ]),
            const SizedBox(height: 12),
            _ReservationMini(
              client: 'Alice Mballa', service: 'Dépannage urgent',
              date: 'Aujourd\'hui, 14h00', statut: 'pending',
            ),
            const SizedBox(height: 10),
            _ReservationMini(
              client: 'Paul Tchoumi', service: 'Installation tableau',
              date: 'Demain, 9h00', statut: 'confirmed',
            ),
            const SizedBox(height: 10),
            _ReservationMini(
              client: 'Sara Kamga', service: 'Mise aux normes',
              date: '22 juin, 10h00', statut: 'completed',
            ),
            const SizedBox(height: 24),

            // ── Raccourcis ──
            Text('Actions rapides', style: AppTextStyles.heading(size: 15, color: Colors.white)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _QuickAction(
                icon: Icons.edit_rounded, label: 'Modifier\nmon profil', color: AppColors.blueLight,
                onTap: () {},
              )),
              const SizedBox(width: 12),
              Expanded(child: _QuickAction(
                icon: Icons.add_photo_alternate_rounded, label: 'Ajouter\ndes photos', color: AppColors.greenBright,
                onTap: () {},
              )),
              const SizedBox(width: 12),
              Expanded(child: _QuickAction(
                icon: Icons.payments_rounded, label: 'Gérer mes\ntarifs', color: AppColors.teal,
                onTap: () {},
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// ONGLET 2 — RÉSERVATIONS
// ════════════════════════════════════════════════════════════════
class _ReservationsTab extends StatefulWidget {
  @override
  State<_ReservationsTab> createState() => _ReservationsTabState();
}

class _ReservationsTabState extends State<_ReservationsTab> {
  String _filter = 'Toutes';
  final _filters = ['Toutes', 'En attente', 'Confirmées', 'Terminées'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Text('Mes réservations', style: AppTextStyles.heading(size: 18, color: Colors.white)),
            ]),
          ),
          const SizedBox(height: 14),

          // Filtres
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final sel = f == _filter;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.teal.withOpacity(0.15) : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: sel ? AppColors.teal.withOpacity(0.6) : Colors.white.withOpacity(0.1)),
                    ),
                    child: Text(f, style: AppTextStyles.label(
                      size: 12, color: sel ? AppColors.teal : AppColors.textSub,
                      weight: sel ? FontWeight.w700 : FontWeight.w500,
                    )),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                _ReservationCard(
                  client: 'Alice Mballa', service: 'Dépannage urgent',
                  date: 'Aujourd\'hui, 14h00', statut: 'pending',
                  prix: '15 000 FCFA',
                ),
                const SizedBox(height: 12),
                _ReservationCard(
                  client: 'Paul Tchoumi', service: 'Installation tableau électrique',
                  date: 'Demain, 9h00', statut: 'confirmed',
                  prix: '45 000 FCFA',
                ),
                const SizedBox(height: 12),
                _ReservationCard(
                  client: 'Sara Kamga', service: 'Mise aux normes',
                  date: '22 juin, 10h00', statut: 'completed',
                  prix: '60 000 FCFA',
                ),
                const SizedBox(height: 12),
                _ReservationCard(
                  client: 'Hervé Mbida', service: 'Dépannage prise électrique',
                  date: '20 juin, 16h30', statut: 'completed',
                  prix: '12 000 FCFA',
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// ONGLET 3 — AVIS
// ════════════════════════════════════════════════════════════════
class _AvisTab extends StatelessWidget {
  final Pro pro;
  const _AvisTab({required this.pro});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Avis clients', style: AppTextStyles.heading(size: 18, color: Colors.white)),
            const SizedBox(height: 16),

            // Note globale
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.warning.withOpacity(0.25)),
              ),
              child: Row(children: [
                Column(children: [
                  Text('${pro.note}', style: AppTextStyles.display(size: 36, color: AppColors.warning)),
                  Row(children: List.generate(5, (i) => Icon(
                    i < pro.note.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.warning, size: 14,
                  ))),
                ]),
                const SizedBox(width: 20),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${pro.avis} avis au total', style: AppTextStyles.body(size: 13, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Basé sur ${pro.prestations} prestations réalisées',
                      style: AppTextStyles.label(size: 11, color: AppColors.textHint)),
                ])),
              ]),
            ),
            const SizedBox(height: 20),

            ...pro.reviews.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: AppColors.blueLight.withOpacity(0.15), shape: BoxShape.circle),
                    child: Center(child: Text(r.client[0],
                        style: AppTextStyles.heading(size: 15, color: AppColors.blueLight))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.client, style: AppTextStyles.label(size: 13, color: Colors.white, weight: FontWeight.w600)),
                    Text(r.date, style: AppTextStyles.label(size: 10, color: AppColors.textHint)),
                  ])),
                  Row(children: List.generate(5, (i) => Icon(
                    i < r.note.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.warning, size: 13,
                  ))),
                ]),
                const SizedBox(height: 10),
                Text(r.commentaire, style: AppTextStyles.body(size: 12, color: AppColors.textSub)),
              ]),
            )),
          ]),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// ONGLET 4 — PROFIL
// ════════════════════════════════════════════════════════════════
class _ProfilTab extends StatelessWidget {
  final Pro    pro;
  final String statut;
  const _ProfilTab({required this.pro, required this.statut});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            // Avatar
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [AppColors.teal, AppColors.greenBright]),
                boxShadow: AppColors.greenShadow,
              ),
              child: Center(child: Text(pro.emoji, style: const TextStyle(fontSize: 40))),
            ),
            const SizedBox(height: 14),
            Text(pro.nom, style: AppTextStyles.heading(size: 20)),
            Text(pro.structure, style: AppTextStyles.body(size: 13, color: AppColors.textSub)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: (statut == 'validé' ? AppColors.teal : statut == 'refusé' ? AppColors.error : AppColors.warning).withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: (statut == 'validé' ? AppColors.teal : statut == 'refusé' ? AppColors.error : AppColors.warning).withOpacity(0.4)),
              ),
              child: Text(
                statut == 'validé' ? '✓ Compte vérifié' : statut == 'refusé' ? '✗ Compte refusé' : '⏳ En attente',
                style: AppTextStyles.label(size: 11, color: statut == 'validé' ? AppColors.teal : statut == 'refusé' ? AppColors.error : AppColors.warning, weight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 28),

            _ProfileTile(Icons.business_center_outlined, 'Mon service', AppColors.blueLight),
            _ProfileTile(Icons.photo_library_outlined, 'Galerie photos', AppColors.greenBright),
            _ProfileTile(Icons.payments_outlined, 'Tarifs & disponibilités', AppColors.teal),
            _ProfileTile(Icons.account_balance_wallet_outlined, 'Mes paiements', AppColors.warning),
            _ProfileTile(Icons.notifications_outlined, 'Notifications', AppColors.textSub),
            _ProfileTile(Icons.help_outline_rounded, 'Aide & Support', AppColors.textSub),

            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                await FB.auth.signOut();
                if (context.mounted) context.go('/welcome');
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Text('Déconnexion', style: AppTextStyles.button(size: 14, color: AppColors.error)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// WIDGETS UTILITAIRES
// ════════════════════════════════════════════════════════════════

class _StatutCard extends StatelessWidget {
  final String statut;
  const _StatutCard({required this.statut});

  @override
  Widget build(BuildContext context) {
    final isValidé   = statut == 'validé';
    final isRefusé   = statut == 'refusé';
    final color      = isValidé ? AppColors.greenBright : isRefusé ? AppColors.error : AppColors.warning;
    final icon       = isValidé ? Icons.verified_rounded : isRefusé ? Icons.block_rounded : Icons.hourglass_top_rounded;
    final titre      = isValidé ? 'Profil validé' : isRefusé ? 'Profil refusé' : 'En attente de validation';
    final sousTitre  = isValidé
        ? 'Vous êtes visible par tous les clients'
        : isRefusé
            ? 'Contactez le support pour plus d\'informations'
            : 'Votre dossier est en cours d\'examen';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.12), color.withOpacity(0.04)]),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titre,    style: AppTextStyles.label(size: 13, color: color, weight: FontWeight.w700)),
          Text(sousTitre,style: AppTextStyles.label(size: 11, color: AppColors.textHint)),
        ])),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   value, label;
  const _StatCard({required this.icon, required this.color, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 10),
      Text(value, style: AppTextStyles.heading(size: 22, color: color)),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.label(size: 11, color: AppColors.textHint)),
    ]),
  );
}

class _DispoToggle extends StatefulWidget {
  final bool initValue;
  final void Function(bool) onToggle;
  const _DispoToggle({required this.initValue, required this.onToggle});
  @override
  State<_DispoToggle> createState() => _DispoToggleState();
}
class _DispoToggleState extends State<_DispoToggle> {
  late bool _dispo;
  @override
  void initState() { super.initState(); _dispo = widget.initValue; }
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: (_dispo ? AppColors.greenBright : AppColors.textHint).withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.circle, color: _dispo ? AppColors.greenBright : AppColors.textHint, size: 14),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_dispo ? 'Disponible' : 'Indisponible',
            style: AppTextStyles.label(size: 14, color: Colors.white, weight: FontWeight.w600)),
        Text('Visible par les clients en temps réel', style: AppTextStyles.label(size: 11, color: AppColors.textHint)),
      ])),
      Switch(
        value: _dispo,
        activeColor: AppColors.greenBright,
        onChanged: (v) {
          setState(() => _dispo = v);
          widget.onToggle(v);
        },
      ),
    ]),
  );
}

class _ReservationMini extends StatelessWidget {
  final String client, service, date, statut;
  const _ReservationMini({required this.client, required this.service, required this.date, required this.statut});
  @override
  Widget build(BuildContext context) {
    final color = statut == 'pending' ? AppColors.warning
        : statut == 'confirmed' ? AppColors.blueLight : AppColors.greenBright;
    final label = statut == 'pending' ? 'En attente' : statut == 'confirmed' ? 'Confirmée' : 'Terminée';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(client, style: AppTextStyles.label(size: 13, color: Colors.white, weight: FontWeight.w600)),
          Text('$service • $date', style: AppTextStyles.label(size: 11, color: AppColors.textHint)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
          child: Text(label, style: AppTextStyles.label(size: 10, color: color, weight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final String client, service, date, statut, prix;
  const _ReservationCard({required this.client, required this.service, required this.date, required this.statut, required this.prix});
  @override
  Widget build(BuildContext context) {
    final color = statut == 'pending' ? AppColors.warning
        : statut == 'confirmed' ? AppColors.blueLight : AppColors.greenBright;
    final label = statut == 'pending' ? 'En attente' : statut == 'confirmed' ? 'Confirmée' : 'Terminée';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(client, style: AppTextStyles.label(size: 14, color: Colors.white, weight: FontWeight.w700))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(label, style: AppTextStyles.label(size: 11, color: color, weight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(service, style: AppTextStyles.body(size: 12, color: AppColors.textSub)),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.access_time_rounded, color: AppColors.teal, size: 13),
          const SizedBox(width: 5),
          Text(date, style: AppTextStyles.label(size: 11, color: AppColors.teal)),
          const Spacer(),
          Text(prix, style: AppTextStyles.label(size: 12, color: AppColors.greenBright, weight: FontWeight.w700)),
        ]),
        if (statut == 'pending') ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () {},
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.greenBright.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.greenBright.withOpacity(0.4)),
                ),
                child: Center(child: Text('Accepter', style: AppTextStyles.label(size: 12, color: AppColors.greenBright, weight: FontWeight.w700))),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: () {},
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.error.withOpacity(0.4)),
                ),
                child: Center(child: Text('Refuser', style: AppTextStyles.label(size: 12, color: AppColors.error, weight: FontWeight.w700))),
              ),
            )),
          ]),
        ],
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.label(size: 11, color: Colors.white, weight: FontWeight.w600),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _ProfileTile(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: Colors.white.withOpacity(0.07)),
    ),
    child: Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 14),
      Expanded(child: Text(label, style: AppTextStyles.body(size: 13, color: Colors.white))),
      const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 18),
    ]),
  );
}
