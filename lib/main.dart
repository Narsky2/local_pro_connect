// ════════════════════════════════════════════════════════════════
// lib/main.dart
// Routeur central — Local Pro Connect
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'pages/splash_page.dart';
import 'pages/loading_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/welcome_page.dart';
import 'pages/auth_page.dart';
import 'pages/pro_register_page.dart';
import 'pages/pro_home_page.dart';
import 'pages/client_home_page.dart';
import 'pages/pro_fiche_page.dart';
import 'models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const LocalProConnect());
}

// ════════════════════════════════════════════════════════════════
// ROUTEUR — Flux complet de navigation
// ════════════════════════════════════════════════════════════════
//
//  /splash
//     └─→ /loading  (1ère utilisation)  ou  /welcome (déjà vu l'onboarding)
//
//  /loading
//     └─→ /onboarding  (1ère utilisation)  ou  /welcome
//
//  /onboarding (4 slides)
//     └─→ /welcome  (bouton "Commencer" ou "Passer")
//
//  /welcome  (choix Client / Professionnel)
//     ├─→ /auth?mode=login&role=client   (carte "Je cherche un service")
//     ├─→ /auth?mode=register&role=pro   (carte "Je propose un service")
//     └─→ /auth?mode=login               (lien "Déjà inscrit ?")
//
//  /auth  (connexion / inscription, toggle)
//     ├─→ /client-home   (si role = client, après connexion ou inscription)
//     └─→ /pro-register  (si role = pro, après connexion ou inscription)
//
//  /pro-register  (4 étapes : infos perso, CNI, service, confirmation)
//     └─→ /pro-home  (après soumission du profil)
//
//  /client-home  (carte, recherche, favoris, profil)
//     └─→ /pro/:id  (fiche prestataire au clic sur une carte)
//
//  /pro-home  (dashboard, réservations, avis, profil)
//
// ════════════════════════════════════════════════════════════════

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [

    // ── 1. Démarrage ──
    GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
    GoRoute(path: '/loading', builder: (_, __) => const LoadingPage()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),

    // ── 2. Bienvenue / Choix du rôle ──
    GoRoute(path: '/welcome', builder: (_, __) => const WelcomePage()),

    // ── 3. Authentification (connexion + inscription) ──
    GoRoute(
      path: '/auth',
      builder: (_, state) => AuthPage(
        isLogin: state.uri.queryParameters['mode'] == 'login',
        role: state.uri.queryParameters['role'] ?? 'client',
      ),
    ),

    // ── 4. Enregistrement professionnel (après inscription pro) ──
    GoRoute(path: '/pro-register', builder: (_, __) => const ProRegisterPage()),

    // ── 5. Accueil Professionnel (après soumission du profil pro) ──
    GoRoute(path: '/pro-home', builder: (_, __) => const ProHomePage()),

    // ── 6. Accueil Client (après connexion/inscription client) ──
    GoRoute(path: '/client-home', builder: (_, __) => const ClientHomePage()),

    // ── 7. Fiche détaillée d'un prestataire (vue client) ──
    GoRoute(
      path: '/pro/:id',
      builder: (_, state) {
        final id = state.pathParameters['id']!;
        final pro = mockPros.firstWhere(
          (p) => p.id == id,
          orElse: () => mockPros.first,
        );
        return ProFichePage(pro: pro);
      },
    ),
  ],
);

// ════════════════════════════════════════════════════════════════
class LocalProConnect extends StatelessWidget {
  const LocalProConnect({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Local Pro Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF061020),
        fontFamily: 'sans-serif',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1565C0),
          secondary: Color(0xFF00C853),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF132840).withOpacity(0.6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 1.5),
          ),
          hintStyle: TextStyle(color: const Color(0xFF4A6070), fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          prefixIconColor: const Color(0xFF8BAABB),
        ),
      ),
      routerConfig: _router,
    );
  }
}
