# EcoRoute — Municipal Waste Collection & Smart Dispatch Platform

[![Flutter Tests](https://img.shields.io/badge/Flutter%20Tests-49%20Passed-2EA043?style=flat-square&logo=flutter)](test/)
[![Analysis](https://img.shields.io/badge/Flutter%20Analyze-0%20Issues-2EA043?style=flat-square&logo=dart)](lib/)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-2EAD65?style=flat-square)](lib/)
[![Zero Cost Maps](https://img.shields.io/badge/Maps-OpenStreetMap%20%2B%20CartoDB-1F883D?style=flat-square)](lib/features/common/widgets/eco_carto_map.dart)
[![AI Engine](https://img.shields.io/badge/AI-Google%20Gemini%201.5%20(Free%20Tier)-4285F4?style=flat-square&logo=google)](lib/core/services/gemini_eco_service.dart)

EcoRoute is an offline-first, zero-operating-cost Flutter platform connecting residents, waste collection route riders, and municipal administrators for on-demand waste collection, GPS routing, and smart dispatch in Arua City, Uganda.

---

## 🚀 Key Production Features

### 1. 100% Zero-Cost Interactive Mapping Engine
- **Tile Providers**: OpenStreetMap (`tile.openstreetmap.org`) & CartoDB high-contrast tiles rendered natively via `flutter_map` v8.
- **\$0 Operating Budget**: Complete replacement of proprietary billable SDKs (Google Maps Platform billing accounts unnecessary).
- **Navigation & Routing**: Turn-by-turn polyline generation via free Open Source Routing Machine (OSRM) endpoints with localized offline Arua-to-Ediofe fallback waypoints.
- **Interactive Controls**: Hardware GPS location tracking, recenter on Arua Municipal Depot, interactive pin-drop coordinate inspector, and quick landmark discovery chips (Arua Main Market, Muni University, Ediofe Dumpsite, Arua Regional Referral Hospital).

### 2. Free Google Gemini AI Assistant & Operations Intelligence
- **Smart Waste Classification**: Powered by Google Gemini 1.5 Flash via Google AI Studio free tier.
- **Municipal Tariffs & Bylaws**: Automatic sack categorization (Organic Green, Recyclable Blue, Hazard Yellow), Arua municipal tariff calculation (1,500 UGX/sack), and contamination prevention advice.
- **Autonomous Operations Intelligence**: Summarizes collection bottlenecks, route efficiency, and truck fleet readiness for Municipal Operations Managers.
- **Offline-First Fallback**: Built-in deterministic heuristic classifier and municipal knowledge base that functions seamlessly even when offline or without an active API key.

### 3. Modernized High-Contrast Dashboards
- **Brand Consistency**: Deep Rich Sage (`#0D2618`), Forest Green (`#1E5E3A`), and Jade accents across all viewports without disruptive theme changes.
- **Resident Hub**: One-tap pickup scheduling, interactive sack counter, live tricycle tracking on OSM tiles, and quick EcoBot AI assistant sheet.
- **Rider Field Cockpit**: Real-time GPS navigation, turn-by-turn routing, cash pouch ledger reconciliation, and collection proof capture.
- **Admin Municipal Portal**: Real-time fleet overview, zone division monitoring, dynamic RBAC staff roster, and AI operations bottleneck analysis.

### 4. Resilient Auth & Field Demo Access
- **Offline-First Authentication**: Automatic smart role detection fallback when Firebase credentials or connectivity are unavailable.
- **Quick Demo Access**: One-tap chips for field inspection and testing (`Resident`, `Rider`, `Admin`).

---

## 🗺️ Project Structure

```text
lib/
├── core/
│   └── services/
│       ├── gemini_eco_service.dart       # Free Google Gemini AI & offline heuristics
│       └── osrm_routing_service.dart     # Free OSRM turn-by-turn routing
├── features/
│   ├── admin/
│   │   └── responsive_admin_dashboard.dart # Municipal oversight & AI dispatch
│   ├── auth/
│   │   ├── responsive_sign_in_screen.dart  # Sign-in with role chips & offline fallback
│   │   └── splash_screen.dart              # Animated splash & session router
│   ├── common/
│   │   └── widgets/
│   │       └── eco_carto_map.dart         # Universal OSM/CartoDB interactive map
│   ├── home/
│   │   └── widgets/
│   │       └── interactive_map_panel.dart # Web/desktop map overview panel
│   ├── resident/
│   │   ├── responsive_resident_dashboard.dart # Resident pickup & AI assistant
│   │   └── widgets/
│   │       └── eco_gemini_assistant_sheet.dart # AI chat & waste classifier modal
│   └── rider/
│       └── responsive_rider_dashboard.dart    # Rider route cockpit & cash pouch
└── main.dart                             # Application entry & global state
```

---

## 🛠️ Getting Started

```bash
# Clone the repository
git clone https://github.com/coder-cliff/ecoRoute.git
cd ecoRoute

# Install Flutter dependencies
flutter pub get

# Run on your preferred platform
flutter run -d chrome     # Web
flutter run -d android    # Android device/emulator
```

---

## 🔑 AI Configuration (Optional)
EcoRoute works out-of-the-box offline using local Arua municipal heuristics. To enable live cloud responses via Google AI Studio:
1. Obtain a free Gemini API key from [Google AI Studio](https://aistudio.google.com/).
2. Open the resident assistant sheet or admin AI modal.
3. Tap **Configure API Key** and paste your key. Keys are safely persisted in local `SharedPreferences`.
