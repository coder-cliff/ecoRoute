# Technical Documentation: EcoRoute System Architecture

## 1. System Architecture Overview
EcoRoute is engineered using Clean Architecture principles, ensuring strict separation of concerns across presentation, business domain logic, and data storage/networking layers.

```mermaid
graph TD
    UI["Presentation Layer (Features & UI)<br/>Home, OrderPage, AuthSheet, CameraScanner, MoMoDialog"] --> Domain["Domain Layer (Rules & Entities)<br/>PickupRequest, AppUser, PriceCalculator, StatusMachine, ZoneResolver"]
    UI --> Core["Core & Service Layer<br/>PickupRequestRepository, AuthService, WasteApiService, LocationService, LanguageService"]
    Core --> Storage["Data & Platform Services<br/>SharedPreferences, HTTP REST Client, Geolocator GPS"]
```

### Directory Structure:
```
ecoRoute/
├── lib/
│   ├── app/                    # Application shell, router, and themes
│   │   ├── config/             # Constants (Arua coordinates, schedules, tariffs)
│   │   ├── theme/              # Material 3 light and dark green palette (CardThemeData)
│   │   ├── app.dart            # EcoRouteApp entry widget
│   │   └── router.dart         # Named routing and navigation generator
│   ├── core/                   # Infrastructure, services, and repositories
│   │   ├── services/           # WasteApiService (REST), AuthService, LocationService, LanguageService
│   │   ├── utils/              # UGX and DateTime formatters
│   │   ├── pickup_request_repository.dart # Local storage CRUD
│   │   └── result.dart         # Sealed Result monad for error handling
│   ├── domain/                 # Pure Dart business rules and entities
│   │   ├── entities/           # PickupRequest, AppUser
│   │   ├── enums/              # RequestStatus, Role, WasteType, Zone
│   │   └── rules/              # PriceCalculator, ReminderPolicy, StatusMachine, ZoneResolver
│   ├── features/               # Presentation screens & modular components
│   │   ├── admin/              # Approval queues, transaction analytics
│   │   ├── auth/               # Role switcher and registration bottom sheet
│   │   ├── home/               # Dashboard, interactive map, schedule, weather safety
│   │   ├── payment/            # Mobile Money dialog & digital audit receipts
│   │   ├── request/            # Order creation with camera scanner & GPS autofill
│   │   └── rider/              # Route stop tiles and status progression
│   └── main.dart               # App entrypoint with async dependency initialization
├── test/                       # 29 automated unit, mock, and widget tests across 8 suites
└── docs/                       # Complete project, test, and defence documentation
```

---

## 2. Domain Data Models & Entities

### `PickupRequest` Model:
| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `String` | Unique microsecond timestamp identifier |
| `wasteType` | `WasteType` | `household`, `tradingCenter`, `unknown` |
| `description` | `String` | Pickup location details and description ($\ge 10$ chars) |
| `sackCount` | `int` | Number of sacks to collect ($1 \le n \le 50$) |
| `priceUgx` | `int` | Total computed collection fee in Uganda Shillings |
| `zone` | `Zone` | `north`, `south`, `east`, `west` |
| `address` | `String` | Physical landmark or division name |
| `latitude` / `longitude` | `double?` | GPS coordinates acquired via Geolocator |
| `residentName` / `residentPhone` | `String` | Contact details for pickup coordination (Default: `+256394880352`) |
| `status` | `RequestStatus` | `requested`, `collected`, `awaitingVerification`, `paid`, `cancelled` |

---

## 3. Finite State Machine Transitions

```mermaid
stateDiagram-v2
    [*] --> requested: Resident submits order
    requested --> collected: Rider picks up waste
    requested --> cancelled: Resident cancels request
    collected --> awaitingVerification: Rider submits for audit
    awaitingVerification --> paid: Admin verifies & approves
    awaitingVerification --> collected: Admin rejects & returns to rider
    paid --> [*]
    cancelled --> [*]
```

---

## 4. REST API Integration (`WasteApiService`)
- **Endpoint:** `https://api.open-meteo.com/v1/forecast?latitude=3.05&longitude=30.91&current_weather=true`
- **Method:** `HTTP GET` with 4-second timeout.
- **Payload Parsing:** Extracts `temperature`, `windspeed`, and WMO `weathercode`.
- **Business Logic:** Codes $51 \le c \le 99$ signify active rain or showers, triggering warning banners about impassable unpaved roads in Arua.
- **Failover Mechanism:** Returns offline cached guidelines whenever a `SocketException`, `TimeoutException`, or HTTP non-200 occurs.

---

## 5. Device Capability Integration (`LocationService`)
- **Package:** `geolocator: ^14.1.2`
- **Platform Configuration:** Configured in `AndroidManifest.xml`:
  - `android.permission.INTERNET`
  - `android.permission.ACCESS_FINE_LOCATION`
  - `android.permission.ACCESS_COARSE_LOCATION`
- **Permission Flow:** Checks `isLocationServiceEnabled()`, requests permissions dynamically (`checkPermission()` / `requestPermission()`), and handles permanent denials gracefully without application disruption.
- **Spatial Resolution:** Resolves distance using Haversine approximation from center $(3.05^\circ, 30.91^\circ)$. If distance $\le 12$ km, calculates vector angle to assign Cardinal Zone.

---

## 6. Waste Camera & Proximity Guidance (`WasteCameraScanner`)
- **Proximity Sensor Simulation:** Viewfinder computes target bounding alignment. Prompts resident: *"Move closer to the rubbish..."*.
- **Dual Capture Modes:**
  - **Automatic Capture:** Once proximity reaches the $0.95$ threshold, captures evidence automatically.
  - **Manual Capture:** Shutter button allows user-initiated photo snap at any distance.
- **Automatic GPS Trigger:** Instantly acquires device GPS coordinates via `LocationService` upon capture completion and locks coordinates into the pickup request.

---

## 7. Mobile Money Payment & Digital Receipts (`MoMoPaymentDialog`)
- **Providers:** Simulates **MTN MoMo** and **Airtel Money** API gateways.
- **Default Phone Number:** Prefilled with requested municipal hotline **`+256394880352`**.
- **Digital Audit Receipt:** Emits tamper-resistant receipt showing unique transaction ID (`TX-MTN-...`), timestamp, payer details, sack breakdown, and official verification stamp.

---

## 8. Multilingual Localization Engine (`LanguageService`)
- **Languages:** Supports **English**, **Lugbara** (native language of West Nile / Arua), and **Kiswahili**.
- **Reactivity:** Singleton `ChangeNotifier` triggers instant UI updates across dashboard, schedules, forms, and dialogs.
