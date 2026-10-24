# EcoRoute — Municipal Waste Collection & Smart Dispatch Platform

[![Flutter Tests](https://img.shields.io/badge/Flutter%20Tests-29%20Passed-2EA043?style=flat-square&logo=flutter)](test/)
[![Analysis](https://img.shields.io/badge/Flutter%20Analyze-0%20Issues-2EA043?style=flat-square&logo=dart)](lib/)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-blue?style=flat-square)](lib/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

**EcoRoute** is an offline-first Flutter mobile and web application designed to solve municipal solid waste accumulation, uncoordinated collection routes, and opaque pricing in **Arua City, Uganda**. 

The application connects **Residents**, **Waste Collection Route Riders** (tricycle and cart operators), and **Municipal Environmental Administrators** through automated zone scheduling, real-time sack-based tariff calculation, GPS service boundary verification, mobile money payments, and meteorological route safety integration.

---

## 14-Week Project-Based Roadmap Compliance

EcoRoute has been developed and reviewed strictly according to the **14-Week Project-Based Flutter Roadmap**:

| Week | Milestone | Status | Key Deliverable in Repo |
| :---: | :--- | :---: | :--- |
| **1** | **Problem Discovery & Definition** | Completed | [`docs/PROJECT_CONCEPT.md`](docs/PROJECT_CONCEPT.md) |
| **2** | **Environment & First Build** | Completed | Clean Flutter 3.24+ structure in [`lib/`](lib/) & [`android/`](android/) |
| **3** | **UI Prototype** | Completed | Material 3 themes & role dashboards in [`lib/features/`](lib/features/) |
| **4** | **Application Navigation** | Completed | Declarative router in [`lib/app/router.dart`](lib/app/router.dart) |
| **5** | **User Input & Validation** | Completed | Dynamic form & sack pricing in [`lib/features/request/order_page.dart`](lib/features/request/order_page.dart) |
| **6** | **Dynamic Behaviour & State** | Completed | State transition graph in [`lib/domain/rules/status_machine.dart`](lib/domain/rules/status_machine.dart) |
| **7** | **Persistent Local Data** | Completed | CRUD engine in [`lib/core/pickup_request_repository.dart`](lib/core/pickup_request_repository.dart) |
| **8** | **Mid-Semester Prototype** | Completed | [`docs/MID_SEMESTER_REVIEW.md`](docs/MID_SEMESTER_REVIEW.md) |
| **9** | **External REST API Integration** | Completed | Open-Meteo REST service in [`lib/core/services/waste_api_service.dart`](lib/core/services/waste_api_service.dart) |
| **10** | **Authentication & Cloud Data** | Completed | Persistent session auth in [`lib/core/services/auth_service.dart`](lib/core/services/auth_service.dart) |
| **11** | **Mobile Device Capability** | Completed | Geolocator GPS & permissions in [`lib/core/services/location_service.dart`](lib/core/services/location_service.dart) |
| **12** | **Testing & Defect Evaluation** | Completed | 29 automated tests & defect log in [`docs/TESTING_AND_EVALUATION.md`](docs/TESTING_AND_EVALUATION.md) |
| **13** | **Product Refinement & Release** | Completed | Polished UI, Android Manifest permissions, & [`docs/USER_GUIDE.md`](docs/USER_GUIDE.md) |
| **14** | **Demonstration & Technical Defence** | Completed | Comprehensive Q&A defence manual in [`docs/FINAL_DEFENCE_GUIDE.md`](docs/FINAL_DEFENCE_GUIDE.md) |

---

## Advanced Municipal Collection Features

1. **Waste Camera Proximity Scanner (`lib/features/request/widgets/waste_camera_scanner.dart`):**
   - Fullscreen viewfinder with live proximity guidance: *"Move closer to the rubbish..."*.
   - **Dual capture modes:** Supports both **Automatic Capture** (triggers once proximity threshold is reached) and **Manual Shutter** button.
   - **Automatic GPS tagging:** Immediately acquires and validates device coordinates upon photo capture.

2. **Mobile Money Settlement Simulation (`lib/features/payment/momo_payment_dialog.dart`):**
   - Direct payment flow supporting **MTN MoMo** and **Airtel Money**.
   - Default mobile number configured as **`+256394880352`**.
   - Simulates USSD network push prompt and generates official **Arua City Council Digital Collection Receipts** with verifiable transaction IDs.

3. **Interactive Arua Map Canvas (`lib/features/home/widgets/interactive_map_panel.dart`):**
   - Interactive zoomable and pannable map featuring key landmarks (*Arua Central Market, River Oli, Arua Hill, Arua Regional Referral Hospital, Muni University*).
   - Real-time zone perimeter overlays and GPS device locating pin.

4. **Multilingual Support (`lib/core/services/language_service.dart`):**
   - Live in-app language switching between **English**, **Lugbara** (*native West Nile language*), and **Kiswahili**.

5. **Modular Component Architecture & Material 3 Dark Mode:**
   - Monolithic views refactored into modular widgets (`brand_lockup.dart`, `metric_cards.dart`, `status_selector.dart`, `route_stop_tile.dart`, `approval_item_tile.dart`, `analytics_breakdown.dart`).
   - Ecological Dark Theme via `EcoRouteTheme.buildDark()`.

---

## Core System Features

- **Multi-Role Experience:**
  - **Residents:** Order waste collection, view dynamic per-sack pricing (UGX), scan rubbish with camera, autofill zone via GPS, pay with MoMo, and track pickup status.
  - **Riders:** View today's route stops grouped by zone, mark stops as collected, and submit loads for admin verification.
  - **Admins:** Review pending collections, approve payment settlements or return loads for reinspection, and analyze city-wide collection statistics.
- **REST API Route Weather Safety:** Fetches live temperature and precipitation warnings via the Open-Meteo REST API to alert riders when heavy tropical rain compromises unpaved roads in Arua.
- **GPS Boundary & Zone Resolver:** Automatically tests device coordinates against the central Arua landmark (3.05°N, 30.91°E) and verifies adherence within the 12 km municipal perimeter.
- **Offline-First Resilience:** Seamlessly functions without internet connectivity, storing orders and user sessions locally with failover caching.

---

## Cloud Database Setup

**Firebase Authentication and Cloud Firestore** are wired as the primary cloud
services on Chrome and Android. Firestore is mirrored to the existing local
SharedPreferences cache for offline use. A Supabase Postgres schema is prepared
as a future secondary reporting/mirror database:

- Firebase initialization options: [`lib/firebase_options.dart`](lib/firebase_options.dart).
- Firestore security rules and index configuration: [`firestore.rules`](firestore.rules),
  [`firestore.indexes.json`](firestore.indexes.json), and [`firebase.json`](firebase.json).
- Supabase schema, constraints, indexes, and server-only access:
  [`supabase/migrations/20261024000000_initial_schema.sql`](supabase/migrations/20261024000000_initial_schema.sql).
- Firebase users sign up as residents; elevated rider/admin roles must be assigned
  by a trusted administrator.

### Provision the free-tier projects

1. Create a Firebase project, enable **Email/Password** in Firebase Authentication,
   and create a Cloud Firestore database. The web config is already populated.
2. Install the Firebase CLI, run `firebase login`, then `firebase use --add` from
   the repository root to select your Firebase project. Deploy the Firestore rules
   and indexes with `firebase deploy --only firestore`.
3. The current Firebase Android registration uses package name `eco_Route.com`,
   but this app's Android application ID is `com.ecoroute.ecoroute`. Register the
   latter package name as an Android app in Firebase and update the Android
   `appId` in `lib/firebase_options.dart` before relying on Firebase on Android.
4. Create a Supabase project and run the SQL migration in its SQL Editor. Keep
   Supabase credentials out of the repository; do not use a service-role key in
   the Flutter client.

Supabase is not connected to runtime synchronization yet. Mirroring Firebase
records to Supabase requires a trusted server-side function; never put the
Supabase service-role key in this Flutter app. iOS and desktop remain local-only
until platform-specific Firebase app configurations are added.

---

## Quickstart Guide

### Prerequisites
- Flutter SDK 3.24+ (Tested on Flutter 3.47.4 / Dart 3.13.3)
- Android Studio / VS Code with Flutter extension
- Windows / macOS / Linux / Web (Chrome)

### Running the App Locally
```powershell
# 1. Clone repository
git clone https://github.com/coder-cliff/ecoRoute.git
cd ecoRoute

# 2. Install dependencies
flutter pub get

# 3. Launch application on Chrome or device
flutter run -d chrome
```

### Running Test Suites
```powershell
# Run all 29 automated tests across 8 suites
flutter test

# Run static code analysis
flutter analyze
```

---

## Project Documentation Links
- [Project Concept Document (Week 1)](docs/PROJECT_CONCEPT.md)
- [Mid-Semester Working Prototype Review (Week 8)](docs/MID_SEMESTER_REVIEW.md)
- [Testing, Debugging & User Evaluation (Week 12)](docs/TESTING_AND_EVALUATION.md)
- [System Architecture & Technical Documentation (Week 13)](docs/TECHNICAL_DOCUMENTATION.md)
- [EcoRoute User Guide (Week 13)](docs/USER_GUIDE.md)
- [Final Technical Defence Guide — 100 Marks (Week 14)](docs/FINAL_DEFENCE_GUIDE.md)
