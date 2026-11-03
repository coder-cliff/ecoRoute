# EcoRoute: Comprehensive Project & Technical Defence Guide

This documentation provides an end-to-end breakdown of the **EcoRoute** mobile application mapped directly to the **14-Week Project-Based Roadmap**. It includes technical architecture explanations, code references, and complete answers to all anticipated viva questions.

---

## 1. Project Overview & Architecture

### High-Level Architecture
EcoRoute follows a **Layered Clean Architecture** pattern:
```
lib/
├── models/         # Domain Entities (WasteRequest, WasteCategory, AppUser)
├── providers/      # Application State & Business Logic (WasteRequestProvider, AuthProvider, NotificationProvider)
├── services/       # Infrastructure Layer (StorageService, ApiService, LocationService)
├── theme/          # Design System (Material 3 palette, typography, card styles)
├── widgets/        # Reusable UI Components (UserAvatar, WasteCard, StatusBadge, CameraPickerWidget)
└── screens/        # Presentation Views
    ├── auth/       # Login, Role Switcher & Account Registration
    ├── citizen/    # Citizen Home, Search, Request Form, Request Details
    ├── rider/      # Rider Dispatch Dashboard & Cash Settlement
    ├── admin/      # Dispatcher Operations, Fleet Oversight & Cash Audit
    ├── profile/    # Profile Settings, Display Picture (DP) Customization
    └── common/     # Interactive OpenStreetMap & Sustainability Analytics
```

---

## 2. Milestone Deliverables Summary (Weeks 1 to 14)

| Week | Milestone | Implementation in EcoRoute | Key Code Reference |
|---|---|---|---|
| **1** | Problem Discovery | Real problem identified: uncoordinated waste piles, lack of geotagged dispatch, and cash reconciliation issues. | [`PROJECT_CONCEPT.md`](file:///c:/Users/cliff/Desktop/ecoroute/PROJECT_CONCEPT.md) |
| **2** | Environment & First Build | Flutter 3.47 SDK setup, Git repository initialized, clean project architecture. | [`main.dart`](file:///c:/Users/cliff/Desktop/ecoroute/lib/main.dart) |
| **3** | UI Prototype | Responsive Material 3 design, custom cards, chips, and reusable `UserAvatar` with role-themed badges. | [`app_theme.dart`](file:///c:/Users/cliff/Desktop/ecoroute/lib/theme/app_theme.dart), [`user_avatar.dart`](file:///c:/Users/cliff/Desktop/ecoroute/lib/widgets/user_avatar.dart) |
| **4** | App Navigation | Role-based navigation router, turn-by-turn Google Maps launching via `url_launcher`, and embedded OpenStreetMap (`flutter_map`). | [`RoleBasedMainRouter`](file:///c:/Users/cliff/Desktop/ecoroute/lib/main.dart#L50-L75), [`interactive_map_screen.dart`](file:///c:/Users/cliff/Desktop/ecoroute/lib/screens/common/interactive_map_screen.dart) |
| **5** | Input & Validation | Form validation verifying waste photo attachment, GPS coordinates, bag count (>0), operating daylight hours (7am-7pm), and future time check. | [`_submitRequest()`](file:///c:/Users/cliff/Desktop/ecoroute/lib/screens/citizen/new_request_screen.dart) |
| **6** | Dynamic State | `WasteRequestProvider` and `NotificationProvider` with reactive `ChangeNotifier` triggers live UI rebuilds when requests are created, assigned, or collected. | [`waste_request_provider.dart`](file:///c:/Users/cliff/Desktop/ecoroute/lib/providers/waste_request_provider.dart) |
| **7** | Persistent Local Data | JSON serialization to `SharedPreferences` ensuring requests and user accounts survive app restarts. CRUD operations implemented. | [`storage_service.dart`](file:///c:/Users/cliff/Desktop/ecoroute/lib/services/storage_service.dart) |
| **8** | Mid-Semester Prototype | Seamless offline-ready journey: Citizen creates request -> Admin views & dispatches -> Rider accepts & completes with cash. | Full integration |
| **9** | External API Integration | OpenStreetMap Nominatim REST API for reverse geocoding GPS coordinates to street addresses with timeout & offline fallback. | [`api_service.dart`](file:///c:/Users/cliff/Desktop/ecoroute/lib/services/api_service.dart) |
| **10** | Auth & User Data | Multi-persona user authentication with zero hardcoded dummy personas. Full account registration, standard profile DP settings, and dynamic fleet rider discovery. | [`auth_provider.dart`](file:///c:/Users/cliff/Desktop/ecoroute/lib/providers/auth_provider.dart), [`profile_settings_screen.dart`](file:///c:/Users/cliff/Desktop/ecoroute/lib/screens/profile/profile_settings_screen.dart) |
| **11** | Mobile Device Capabilities | **Camera Capture:** `image_picker` for photo verification.<br>**Device GPS:** `geolocator` with runtime permission handling.<br>**Maps & Phone:** `url_launcher` for phone dialer and Google Maps navigation. | [`camera_picker_widget.dart`](file:///c:/Users/cliff/Desktop/ecoroute/lib/widgets/camera_picker_widget.dart), [`location_service.dart`](file:///c:/Users/cliff/Desktop/ecoroute/lib/services/location_service.dart) |
| **12** | Testing & Debugging | 13 automated unit and widget tests passing with 0 lint errors in `flutter analyze`. | [`waste_request_test.dart`](file:///c:/Users/cliff/Desktop/ecoroute/test/waste_request_test.dart), [`widget_test.dart`](file:///c:/Users/cliff/Desktop/ecoroute/test/widget_test.dart), [`user_avatar_test.dart`](file:///c:/Users/cliff/Desktop/ecoroute/test/user_avatar_test.dart) |
| **13** | Product Refinement | Polished UX, live search & category filtering, cash receipt copying/sharing, daily cash reconciliation tool, and in-app notification center. | Release-ready build |
| **14** | Final Defence | Complete technical defense guide answering every rubric question below. | This document |

---

## 3. Anticipated Viva Questions & Model Answers

### Week 2: Environment & Foundation
- **Q: What happens when `main.dart` is executed?**
  - **A:** Execution starts at the `main()` function. First, `WidgetsFlutterBinding.ensureInitialized()` binds the Flutter framework to the platform engine. Next, asynchronous services (`authProvider.init()` and `requestProvider.loadRequests()`) read local persistent data from disk. Finally, `runApp()` inflates the root widget (`EcoRouteApp`) into the render tree.
- **Q: What does `runApp()` do?**
  - **A:** `runApp()` takes the given root `Widget`, attaches it to the screen by creating the root `RenderObject`, and starts the Flutter widget lifecycle loop.
- **Q: What is a widget?**
  - **A:** In Flutter, a widget is an immutable description of a part of the user interface. Widgets form a tree that the framework inflates into elements and render objects to paint pixels on the screen.
- **Q: What is the purpose of `pubspec.yaml`?**
  - **A:** It is the project's metadata and dependency manifest. It specifies external packages (such as `provider`, `shared_preferences`, `http`, `geolocator`, `flutter_map`, `url_launcher`), SDK version constraints, and asset declarations.

### Week 4 & 5: Navigation, Input & Validation
- **Q: Why did you choose this navigation structure?**
  - **A:** We implemented a `RoleBasedMainRouter` that renders role-specific hubs (Citizen, Rider, Admin). From there, modal workflows (`NewRequestScreen`, `RequestDetailsScreen`, `InteractiveMapScreen`, `ProfileSettingsScreen`) use Navigator push/pop with typed arguments. This prevents unauthorized screen access and dead ends.
- **Q: What happens when an invalid scheduling time or empty field is submitted?**
  - **A:** In `new_request_screen.dart`, form validation prevents empty photo attachments and blank addresses. Additionally, scheduling guardrails block past times and restrict bookings to daylight collection operating hours (7:00 AM – 7:00 PM).

### Week 6 & 7: State Management & Persistence
- **Q: How are you managing state and why did you choose that approach?**
  - **A:** We use `Provider` with `ChangeNotifier` (`WasteRequestProvider`, `AuthProvider`, `NotificationProvider`). It offers clean separation of business logic from UI, avoids boilerplate, allows reactive rebuilding via `notifyListeners()`, and provides testable logic without tightly coupling widgets.
- **Q: What happens to the data when the application closes?**
  - **A:** Whenever a request is created, updated, or marked collected, or a user edits their profile, `StorageService.saveRequests()` and `StorageService.saveUsers()` serialize the data to JSON and write it to `SharedPreferences`. When the app restarts, `StorageService` restores the models seamlessly, ensuring zero data loss.

### Week 9 & 10: External APIs & Cloud Data
- **Q: What external APIs and map services does your app use?**
  - **A:**
    1. **OpenStreetMap Nominatim Reverse Geocoding REST API:** Converts raw GPS latitude and longitude coordinates automatically into human-readable street addresses.
    2. **OpenStreetMap Tile Server (`flutter_map`):** Renders in-app spatial maps with color-coded markers for waste spots and collection fleet stations.
    3. **Google Maps / Apple Maps (`url_launcher`):** Launches external turn-by-turn navigation directly to the curbside pickup location.

### Week 11: Mobile Device Capabilities
- **Q: Why does your application need GPS and Camera capabilities?**
  - **A:**
    1. **GPS:** Waste piles don't have postal mailboxes. Auto-capturing coordinates pinpoints exact curbside locations for collection riders.
    2. **Camera:** Taking a photo allows the collection rider and dispatcher to assess waste volume, segregation quality, and vehicle requirements (tricycle vs. flatbed) before arriving.

### Cash Settlement Model
- **Q: Why is payment collected via hard cash?**
  - **A:** In emerging municipal markets, informal waste pickers and local residents rely heavily on direct cash-on-delivery transactions. To eliminate digital barriers, EcoRoute calculates the exact cash amount upfront, notifies the resident to prepare the cash, empowers the rider to verify physical waste volume, collect hard cash, and generate an instant official digital receipt with sharing/copying capability. Operations admins can audit and reconcile collected cash pouches at day's end.
