# Fourteen-Week Project-Based Flutter Roadmap Compliance Matrix

This document provides a comprehensive mapping between the **Fourteen-Week Project-Based Mobile Applications Development Roadmap** (Table 1 & Weekly Milestone Briefs) and the **EcoRoute** codebase implementation.

---

## Roadmap Milestone Compliance Overview

| Week | Project Milestone | Status | Key Deliverable in EcoRoute | Code Location / Test Evidence |
| :---: | :--- | :---: | :--- | :--- |
| **1** | Problem Discovery & Project Definition | **COMPLETE** | Project Concept Document, Problem Analysis, 12 km Arua Scope | [`docs/PROJECT_CONCEPT.md`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/docs/PROJECT_CONCEPT.md) |
| **2** | Flutter Environment & First Build | **COMPLETE** | Clean Architecture, Entrypoint, Android/Web Toolchain | [`lib/main.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/lib/main.dart), [`pubspec.yaml`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/pubspec.yaml) |
| **3** | UI Prototype | **COMPLETE** | Role Dashboards, Brand Lockup, Responsive Viewports | [`lib/features/home/home_screen.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/lib/features/home/home_screen.dart) |
| **4** | Application Navigation & User Flow | **COMPLETE** | IndexedStack, MaterialPageRoute, Modal Sheets | [`lib/app/router.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/lib/app/router.dart), [`lib/features/auth/auth_sheet.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/lib/features/auth/auth_sheet.dart) |
| **5** | User Input & Data Validation | **COMPLETE** | Reactive Form, Sack Bound Checks ($1 \le n \le 50$), Error Feedback | [`lib/features/request/order_page.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/lib/features/request/order_page.dart) |
| **6** | Dynamic Application Behaviour | **COMPLETE** | Dynamic Pricing, State Machine Transitions, Analytics | [`lib/domain/rules/status_machine.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/lib/domain/rules/status_machine.dart) |
| **7** | Persistent Local Data | **COMPLETE** | SharedPreferences Local CRUD, JSON Serialization | [`lib/core/pickup_request_repository.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/lib/core/pickup_request_repository.dart) |
| **8** | Mid-Semester Working Prototype | **COMPLETE** | Integrated Multi-Role Offline Prototype Review | [`docs/MID_SEMESTER_REVIEW.md`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/docs/MID_SEMESTER_REVIEW.md) |
| **9** | External Data & REST API Integration | **COMPLETE** | Open-Meteo Meteorological API & Waste Database | [`lib/core/services/waste_api_service.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/lib/core/services/waste_api_service.dart) |
| **10** | User Authentication & Cloud Data | **COMPLETE** | Multi-Role Session Auth, Persistent Login, Reminder Policy | [`lib/core/services/auth_service.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/lib/core/services/auth_service.dart) |
| **11** | Mobile Device Capability Integration | **COMPLETE** | GPS Geolocation & Smart Camera Proximity Auto-Capture | [`lib/features/request/widgets/waste_camera_scanner.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/lib/features/request/widgets/waste_camera_scanner.dart) |
| **12** | Testing, Debugging & User Evaluation | **COMPLETE** | 38 Automated Unit/Widget Tests, Defect Log | [`docs/TESTING_AND_EVALUATION.md`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/docs/TESTING_AND_EVALUATION.md) |
| **13** | Product Refinement & Release Build | **COMPLETE** | Native Release Split APKs, Material 3 Polish, User Docs | [`docs/USER_GUIDE.md`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/docs/USER_GUIDE.md), Release APKs |
| **14** | Final Demonstration & Technical Defence | **COMPLETE** | End-to-End Live Walkthrough Guide, Assessment Matrix | [`docs/FINAL_DEFENCE_GUIDE.md`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/docs/FINAL_DEFENCE_GUIDE.md) |

---

## Detailed Week-by-Week Audit

### Week 1: Problem Discovery & Project Definition
- **Requirement:** Identify real problem, intended users, current user habits, proposed mobile solution, core functions, and scope.
- **EcoRoute Implementation:**
  - Real-world problem: Municipal solid waste accumulation in Arua City (120+ tonnes/day, <40% collected).
  - Target personas: Residents (Oli/Central), Tricycle Collection Riders, Municipal Health Inspectors.
  - Scope: 12 km municipal perimeter divided into 4 cardinal zones (North, South, East, West).
  - Evidence: [`docs/PROJECT_CONCEPT.md`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/docs/PROJECT_CONCEPT.md).

### Week 2: Development Environment & First Application Build
- **Requirement:** Run Flutter app on emulator/device, clean project structure, explain `main.dart`, initial commit.
- **EcoRoute Implementation:**
  - Clean Architecture separation (`lib/app`, `lib/core`, `lib/domain`, `lib/features`).
  - Asynchronous boot sequence in [`lib/main.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/lib/main.dart) ensuring SharedPreferences and repositories load before rendering.
  - Evidence: Clean Git commit history on `origin/main`.

### Week 3: User Interface Prototype
- **Requirement:** Main screens, layouts, Material components, responsive UI handling narrow viewports.
- **EcoRoute Implementation:**
  - Role-specific dashboard layouts in [`home_screen.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/lib/features/home/home_screen.dart).
  - Material 3 theme (`CardThemeData`, green brand identity `#2EAD65`).
  - Responsive text/labels (`ResponsiveButtonLabel`, `FittedBox`, `TextOverflow.ellipsis`).
  - Evidence: Tested on $412 \times 700$ compact viewport in [`test/widget_test.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/test/widget_test.dart).

### Week 4: Application Navigation & User Flow
- **Requirement:** Logical screen flow, forward/backward navigation, data passing without dead ends.
- **EcoRoute Implementation:**
  - `NavigationBar` with `IndexedStack` to preserve tab state across Home, Requests, and Profile.
  - Declarative bottom sheets (`AuthSheet`, `WasteDatabaseSheet`).
  - `OrderPage` navigation via `MaterialPageRoute`, automatically returning created requests to home state.
  - Evidence: [`test/widget_test.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/test/widget_test.dart).

### Week 5: User Input & Data Validation
- **Requirement:** Form controllers, validation rules, prevention of invalid data, clear feedback.
- **EcoRoute Implementation:**
  - `OrderPage` input form with `GlobalKey<FormState>`.
  - Description validation ($\ge 10$ non-whitespace chars).
  - Sack count validation ($1 \le n \le 50$) via pure domain validator.
  - Phone format validation (`+256...`).
  - Contextual `SnackBar` feedback on invalid inputs and successful submissions.
  - Evidence: [`test/enhanced_order_test.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/test/enhanced_order_test.dart).

### Week 6: Dynamic Application Behaviour & State Management
- **Requirement:** Responsive state changes, CRUD interactions, multi-screen state propagation.
- **EcoRoute Implementation:**
  - Dynamic tariff multiplication (`calculateAmount(sackCount, ratePerSack)`).
  - Status Machine [`status_machine.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/lib/domain/rules/status_machine.dart) enforcing valid status transitions:
    `requested` $\to$ `collected` $\to$ `awaitingVerification` $\to$ `paid`.
  - Transaction analytics bar chart updating dynamically upon status transitions.
  - Evidence: [`test/domain_rules_test.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/test/domain_rules_test.dart).

### Week 7: Persistent Local Data
- **Requirement:** Data persistence across app closures, offline CRUD operations, schema resilience.
- **EcoRoute Implementation:**
  - `LocalPickupRequestRepository` storing JSON collections in `SharedPreferences`.
  - Corrupt state handling (safe fallback to `[]` on format exceptions).
  - Asynchronous CRUD operations (Create, Read all, Update status, Delete).
  - Evidence: [`test/pickup_request_repository_test.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/test/pickup_request_repository_test.dart).

### Week 8: Mid-Semester Working Prototype
- **Requirement:** Integrated offline application solving core problem, code refactoring, Git cleanliness.
- **EcoRoute Implementation:**
  - Complete user lifecycle: Resident submits order $\to$ Rider collects $\to$ Admin verifies & settles.
  - Removed duplicate scaffold files, fixed parent data assertion issues.
  - Evidence: [`docs/MID_SEMESTER_REVIEW.md`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/docs/MID_SEMESTER_REVIEW.md).

### Week 9: External Data & REST API Integration
- **Requirement:** External API communication, JSON parsing, timeout handling, offline caching.
- **EcoRoute Implementation:**
  - `WasteApiService` querying Open-Meteo meteorological API for Arua City ($3.05^\circ\text{N}, 30.91^\circ\text{E}$).
  - Road safety heuristic (`isSafeForCollection`) checking precipitation codes.
  - Graceful fallback (`AruaWeatherReport.fallback(isOnline: false)`) on network failure.
  - Open Municipal Solid Waste & Recycling Database with World Bank and NEMA benchmarks.
  - Evidence: [`test/waste_api_service_test.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/test/waste_api_service_test.dart) and [`test/waste_database_and_auto_scan_test.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/test/waste_database_and_auto_scan_test.dart).

### Week 10: User Authentication & Cloud Data Management
- **Requirement:** User accounts, role-based interfaces, persistent login state, basic security.
- **EcoRoute Implementation:**
  - `AuthService` with built-in Arua demo accounts (`Resident`, `Rider`, `Admin`).
  - Session serialization to local storage (`ecoroute_current_user_v1`).
  - Role-specific UI gates: only Admins can approve payments; only Riders can advance route stops.
  - Free onboarding reminder policy (`ReminderPolicy`).
  - Evidence: [`test/auth_service_test.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/test/auth_service_test.dart).

### Week 11: Mobile Device Capability Integration
- **Requirement:** Integration of native device features directly supporting the project.
- **EcoRoute Implementation:**
  - **Location Services (GPS):** `LocationService` with `geolocator: ^14.1.2`, 12 km boundary circle check, and zone assignment.
  - **Smart Camera Proximity Auto-Capture:** Viewfinder simulating ultrasonic proximity detection. When distance $< 0.25$m, auto-triggers camera shutter, locks GPS coordinates, and returns to order screen without manual tap.
  - **Mobile Money Simulation:** USSD simulation with printable digital audit receipts.
  - Evidence: [`test/location_service_test.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/test/location_service_test.dart) and [`test/advanced_features_test.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/test/advanced_features_test.dart).

### Week 12: Testing, Debugging & User Evaluation
- **Requirement:** Systematic test cases, defect log, user feedback, automated testing evidence.
- **EcoRoute Implementation:**
  - **38 automated unit, widget, and service tests** passing 100% with 0 failures.
  - Zero analyzer errors, warnings, or lints (`flutter analyze`).
  - Documented Defect Log (DEF-01 through DEF-06) and feedback from 4 representative users.
  - Evidence: [`docs/TESTING_AND_EVALUATION.md`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/docs/TESTING_AND_EVALUATION.md).

### Week 13: Product Refinement & Release Build
- **Requirement:** Polished UI/UX, branding, installable release APK, user and technical documentation.
- **EcoRoute Implementation:**
  - Native release split APKs compiled with AOT compilation, native ARM64 machine code, and font tree-shaking (99.3% reduction):
    - `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
    - `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
    - `build/app/outputs/flutter-apk/app-x86_64-release.apk`
  - User documentation: [`docs/USER_GUIDE.md`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/docs/USER_GUIDE.md).
  - Technical documentation: [`docs/TECHNICAL_DOCUMENTATION.md`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/docs/TECHNICAL_DOCUMENTATION.md).

### Week 14: Final Application Demonstration & Technical Defence
- **Requirement:** Complete working product, live demonstration walkthrough, technical defense questions.
- **EcoRoute Implementation:**
  - Full defense guide with authoritative answers to all assessor questions for Weeks 1 to 14.
  - Complete 100-mark assessment rubric breakdown.
  - Evidence: [`docs/FINAL_DEFENCE_GUIDE.md`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/docs/FINAL_DEFENCE_GUIDE.md).
