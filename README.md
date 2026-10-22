# EcoRoute — Municipal Waste Collection & Smart Dispatch Platform

[![Flutter Tests](https://img.shields.io/badge/Flutter%20Tests-26%20Passed-2EA043?style=flat-square&logo=flutter)](test/)
[![Analysis](https://img.shields.io/badge/Flutter%20Analyze-0%20Issues-2EA043?style=flat-square&logo=dart)](lib/)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-blue?style=flat-square)](lib/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

**EcoRoute** is an offline-first Flutter mobile application designed to solve municipal solid waste accumulation, uncoordinated collection routes, and opaque pricing in **Arua City, Uganda**. 

The application connects **Residents**, **Waste Collection Route Riders** (tricycle and cart operators), and **Municipal Environmental Administrators** through automated zone scheduling, real-time sack-based tariff calculation, GPS service boundary verification, and meteorological route safety integration.

---

## 14-Week Project-Based Roadmap Compliance

EcoRoute has been developed and reviewed strictly according to the **14-Week Project-Based Flutter Roadmap**:

| Week | Milestone | Status | Key Deliverable in Repo |
| :---: | :--- | :---: | :--- |
| **1** | **Problem Discovery & Definition** | Completed | [`docs/PROJECT_CONCEPT.md`](docs/PROJECT_CONCEPT.md) |
| **2** | **Environment & First Build** | Completed | Clean Flutter 3.47+ structure in [`lib/`](lib/) & [`android/`](android/) |
| **3** | **UI Prototype** | Completed | Material 3 themes & role dashboards in [`lib/features/`](lib/features/) |
| **4** | **Application Navigation** | Completed | Declarative router in [`lib/app/router.dart`](lib/app/router.dart) |
| **5** | **User Input & Validation** | Completed | Dynamic form & sack pricing in [`lib/features/request/order_page.dart`](lib/features/request/order_page.dart) |
| **6** | **Dynamic Behaviour & State** | Completed | State transition graph in [`lib/domain/rules/status_machine.dart`](lib/domain/rules/status_machine.dart) |
| **7** | **Persistent Local Data** | Completed | CRUD engine in [`lib/core/pickup_request_repository.dart`](lib/core/pickup_request_repository.dart) |
| **8** | **Mid-Semester Prototype** | Completed | [`docs/MID_SEMESTER_REVIEW.md`](docs/MID_SEMESTER_REVIEW.md) |
| **9** | **External REST API Integration** | Completed | Open-Meteo REST service in [`lib/core/services/waste_api_service.dart`](lib/core/services/waste_api_service.dart) |
| **10** | **Authentication & Cloud Data** | Completed | Persistent session auth in [`lib/core/services/auth_service.dart`](lib/core/services/auth_service.dart) |
| **11** | **Mobile Device Capability** | Completed | Geolocator GPS & permissions in [`lib/core/services/location_service.dart`](lib/core/services/location_service.dart) |
| **12** | **Testing & Defect Evaluation** | Completed | 26 automated tests & defect log in [`docs/TESTING_AND_EVALUATION.md`](docs/TESTING_AND_EVALUATION.md) |
| **13** | **Product Refinement & Release** | Completed | Polished UI, Android Manifest permissions, & [`docs/USER_GUIDE.md`](docs/USER_GUIDE.md) |
| **14** | **Demonstration & Technical Defence** | Completed | Comprehensive Q&A defence manual in [`docs/FINAL_DEFENCE_GUIDE.md`](docs/FINAL_DEFENCE_GUIDE.md) |

---

## Core Features

- **Multi-Role Experience:**
  - **Residents:** Order waste collection, view dynamic per-sack pricing (UGX), autofill zone using device GPS, and track pickup progress.
  - **Riders:** View today's route stops grouped by zone, mark stops as collected, and submit loads for payment auditing.
  - **Admins:** Review pending collections, approve payment settlements or return loads for reinspection, and analyze city-wide collection statistics.
- **REST API Route Weather Safety:** Fetches live temperature and precipitation warnings via the Open-Meteo REST API to alert riders when heavy tropical rain compromises unpaved roads in Arua.
- **GPS Boundary & Zone Resolver:** Automatically tests device coordinates against the central Arua landmark (3.05°N, 30.91°E) and verifies adherence within the 12 km municipal perimeter.
- **Offline-First Resilience:** Seamlessly functions without internet connectivity, storing orders and user sessions locally with failover caching.

---

## Quickstart Guide

### Prerequisites
- Flutter SDK 3.24+ (Tested on Flutter 3.47.4 / Dart 3.13.3)
- Android Studio / VS Code with Flutter extension
- Windows / macOS / Linux / Web

### Running the App Locally
```powershell
# 1. Clone repository
git clone https://github.com/coder-cliff/ecoRoute.git
cd ecoRoute

# 2. Install dependencies
flutter pub get

# 3. Launch application
flutter run
```

### Running Test Suites
```powershell
# Run all 26 automated tests
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
