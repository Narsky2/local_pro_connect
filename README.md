# 🚀 Local_Pro Connect — Guide de déploiement

## Architecture du projet

```
lib/
├── main.dart                        # Point d'entrée + GoRouter
├── theme/
│   └── app_theme.dart               # Design system complet
├── services/
│   └── firebase_service.dart        # Firebase Auth + Firestore + Storage
└── pages/
    ├── loading_page.dart            # Splash screen animé
    ├── onboarding_page.dart         # 4 slides d'introduction
    ├── auth/
    │   ├── register_page.dart       # Inscription
    │   ├── login_page.dart          # Connexion
    │   └── role_select_page.dart    # Choix Client / Pro
    ├── pro/
    │   ├── pro_register_page.dart   # Enregistrement profil pro (2 étapes)
    │   ├── pro_dashboard_page.dart  # Tableau de bord prestataire
    │   └── pro_home_page.dart       # Page d'accueil pro (carte + 6 onglets)
    └── client/
        └── client_home_page.dart    # Page d'accueil client (carte + 5 onglets)
```

---

## ÉTAPE 1 — Créer le projet Firebase

1. Aller sur https://console.firebase.google.com
2. Créer un projet : **local-pro-connect**
3. Activer les services suivants :
   - **Authentication** → Email/Password (activer)
   - **Firestore Database** → Mode production
   - **Storage** → Mode production

---

## ÉTAPE 2 — Intégrer Firebase dans Flutter

### Installer FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### Configurer le projet
```bash
cd lpc_app
flutterfire configure --project=local-pro-connect
```
Cette commande génère automatiquement `lib/firebase_options.dart`

### Mettre à jour main.dart
Remplacer dans `main.dart` :
```dart
await Firebase.initializeApp();
```
par :
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```
Et ajouter l'import :
```dart
import 'firebase_options.dart';
```

---

## ÉTAPE 3 — Google Maps API

### Obtenir la clé API
1. https://console.cloud.google.com
2. Activer **Maps SDK for Android** et **Maps SDK for iOS**
3. Créer une clé API

### Android (`android/app/src/main/AndroidManifest.xml`)
Ajouter dans `<application>` :
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="VOTRE_CLE_API_MAPS"/>
```

### iOS (`ios/Runner/AppDelegate.swift`)
```swift
import GoogleMaps
GMSServices.provideAPIKey("VOTRE_CLE_API_MAPS")
```

---

## ÉTAPE 4 — Règles Firestore

Dans Firebase Console → Firestore → Règles :
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Utilisateurs — lecture/écriture par le propriétaire
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Professionnels — lecture publique, écriture par le propriétaire
    match /professionals/{proId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == proId;

      match /reviews/{reviewId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null;
      }
    }

    // Réservations
    match /bookings/{bookingId} {
      allow read: if request.auth != null &&
        (resource.data.clientId == request.auth.uid ||
         resource.data.proId == request.auth.uid);
      allow create: if request.auth != null;
      allow update: if request.auth != null &&
        (resource.data.proId == request.auth.uid);
    }

    // Favoris
    match /users/{userId}/favorites/{favId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## ÉTAPE 5 — Règles Firebase Storage

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // CNI — seulement accessible en lecture par admins
    match /cni/{userId} {
      allow write: if request.auth != null && request.auth.uid == userId;
      allow read: if false; // admin seulement via SDK Admin
    }

    // Logos / photos — lecture publique
    match /logos/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Photos de profil
    match /profiles/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## ÉTAPE 6 — Permissions Android

`android/app/src/main/AndroidManifest.xml` — avant `<application>` :
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

`android/app/build.gradle` — vérifier :
```gradle
minSdkVersion 21
targetSdkVersion 34
```

---

## ÉTAPE 7 — Permissions iOS

`ios/Runner/Info.plist` :
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Pour afficher les services près de vous</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Pour afficher les services près de vous</string>
<key>NSCameraUsageDescription</key>
<string>Pour ajouter votre photo de profil</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Pour choisir une image de votre galerie</string>
```

---

## ÉTAPE 8 — Déploiement

### Android (Play Store)
```bash
flutter build appbundle --release
```
Uploader le `.aab` sur Google Play Console.

### iOS (App Store)
```bash
flutter build ipa --release
```
Uploader via Transporter ou Xcode sur App Store Connect.

---

## Collections Firestore créées automatiquement

| Collection | Description |
|---|---|
| `users/{uid}` | Profil utilisateur (name, email, phone, role) |
| `professionals/{uid}` | Profil pro (service, catégorie, ville, note) |
| `professionals/{uid}/reviews` | Avis clients |
| `bookings/{id}` | Réservations client→pro |
| `users/{uid}/favorites` | Favoris par utilisateur |

---

## Flux de navigation complet

```
LoadingPage → (seen onboarding?)
  ├── Non → OnboardingPage → RegisterPage / LoginPage
  └── Oui → LoginPage
        ↓
    RoleSelectPage
        ├── Client → ClientHomePage (5 onglets: Carte, Historique, Favoris, Profil, Paiement)
        └── Pro → ProRegisterPage → ProDashboardPage
                                 ↕
                            ProHomePage (6 onglets: Carte, Historique, Favoris, Profil, Paiement, Dashboard)
```

---

## Commandes de développement

```bash
# Installer les dépendances
flutter pub get

# Lancer en dev
flutter run

# Build Android debug
flutter build apk --debug

# Vérifier les erreurs
flutter analyze
```