# EcoRoute: Test Plan, Defect Log & User Evaluation (Milestones 12 & 14)

This document contains the systematic quality assurance records, automated test results, boundary conditions tested, defect remediation log, and user evaluation feedback for EcoRoute.

---

## 1. Test Plan

### Objectives
- Verify that waste collection requests accurately record waste photo, GPS coordinates, category, volume size, and container counts.
- Ensure that the upfront cash estimation matches the business rate rules and volume multipliers ($1.0\times, 1.8\times, 3.2\times$).
- Confirm that data persists across application restarts (`SharedPreferences` JSON serialization).
- Verify that status transitions propagate across Citizen, Rider, and Admin views in real time.
- Verify graceful offline handling when external APIs (OpenStreetMap) or location sensors are unavailable.
- Verify user display pictures (DPs), profile customizability, and role-based badge representations.
- Verify that Admin controls, municipal system settings, and CSV audit exports operate without paid third-party dependencies.

### Testing Scope
| Component | Functionality Tested | Test Type |
|---|---|---|
| `WasteCategory` & Pricing | Unit price multiplication, volume size multipliers, carbon mitigation formula | Automated Unit Test |
| `WasteRequest` Model | JSON serialization & deserialization round-trip, status copyWith, scientific impact | Automated Unit Test |
| `WasteGuideItem` | Offline catalog items across Plastics, Organic, Paper, Metal, E-Waste, Hazardous | Automated Unit Test |
| `ApiService` | Environmental impact metrics, Nominatim timeout handling | Automated Unit Test & Integration |
| `LocationService` | Haversine GPS distance calculation, permission fallback | Automated Unit Test |
| `StatusBadge` & `CashPaymentBanner` | UI rendering, conditional color badges, cash amount strings | Automated Widget Test |
| `WasteCard` | Card layout, volume size tag, bag count formatting, address presentation | Automated Widget Test |
| `UserAvatar` Component | Initials rendering, role badge rendering, image error fallback | Automated Widget Test |
| `MilestoneStepperWidget` | 4-stage visual progress pipeline (`Requested` $\rightarrow$ `Assigned` $\rightarrow$ `Collected`) | Automated & Manual Validation |
| `AdminDashboardScreen` | Fleet directory view, dispatch queue, 1-tap call, municipal CSV export | Integration & Manual Validation |
| `ProfileSettingsScreen` | Municipal operating hours policy, container pricing multipliers, central depot | Integration & Manual Validation |

---

## 2. Test Cases & Execution Results

| Test Case ID | Feature / Module | Input / Action | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| **TC-01** | Pricing Logic | 4 bags of Plastics ($2.00/bag) | Estimated cash = $8.00, Carbon = 7.2 kg CO₂e | Total cash = $8.00, Carbon = 7.2 kg | **PASS** |
| **TC-02** | Pricing Logic | 1 item of E-Waste ($4.00/item) | Estimated cash = $4.00, Carbon = 5.0 kg CO₂e | Total cash = $4.00, Carbon = 5.0 kg | **PASS** |
| **TC-03** | Local Persistence | Serialize `WasteRequest` to JSON and restore via `fromJson` | All fields identical, status preserved | Restored object matches original exactly | **PASS** |
| **TC-04** | State Transition | Assign Rider $\rightarrow$ Settle Cash | Status transitions: `pending` $\rightarrow$ `assigned` $\rightarrow$ `collected` | Status and receipt updated correctly | **PASS** |
| **TC-05** | Form Validation | Submit request without capturing/selecting photo | Form blocks submit; displays red error SnackBar | Submission prevented; SnackBar shown | **PASS** |
| **TC-06** | Form Validation | Submit request with empty address | Form blocks submit; displays address validation error | Submission prevented; field highlighted | **PASS** |
| **TC-07** | GPS Fallback | GPS permission denied on device/emulator | Gracefully switches to city coordinates without crashing | Simulated GPS coordinates auto-filled | **PASS** |
| **TC-08** | Offline Resilience | Network disconnected during Nominatim reverse geocode | Timeout caught; fallback sector string displayed | Offline fallback address generated | **PASS** |
| **TC-09** | UI Widget Test | Render `StatusBadge` with `RequestStatus.pending` | Displays 'Pending Dispatch' with hourglass icon | Matched widget in widget tree | **PASS** |
| **TC-10** | UI Widget Test | Render `CashPaymentBanner` ($5.50) | Displays 'Pay With Hard Cash: $5.50' | Exact string rendered with cash icon | **PASS** |
| **TC-11** | Profile Avatar Test | Render `UserAvatar` without image URL | Displays stylized uppercase initials with gradient | 'SN' rendered for Sarah Namukasa | **PASS** |
| **TC-12** | Profile Avatar Test | Render `UserAvatar` for rider with badge | Displays blue role badge with motorcycle icon | Role badge rendered accurately | **PASS** |
| **TC-13** | Profile Avatar Test | Render `UserAvatar` for admin with badge | Displays purple role badge with admin shield icon | Admin badge rendered accurately | **PASS** |
| **TC-14** | Municipal Guide Test | Search offline catalog for common items | Returns proper bin color & recycling tips across 6 categories | All categories covered | **PASS** |
| **TC-15** | Volume Sizing Test | Test Small (1.0x), Medium (1.8x), Large (3.2x) | Multipliers correctly scale pricing and waste metrics | Multipliers match specifications | **PASS** |
| **TC-16** | Scientific Impact | Calculate weight diverted and tree absorption equivalent | Plastics medium bag = 18.0 kg waste, ~0.59 tree absorption eq. | Calculated metrics match formulas | **PASS** |
| **TC-17** | CSV Audit Export | Generate municipal CSV operations report | Produces CSV headers with all pickup data | Valid CSV format generated | **PASS** |

---

## 3. Defect Log & Corrective Actions

| Defect ID | Severity | Description | Root Cause | Corrective Action Taken | Status |
|---|---|---|---|---|---|
| **DEF-01** | High | `Border.Border.all` compilation error in several screen files. | Typo invoking `Border.Border.all` instead of `Border.all`. | Refactored all container decorations across UI screens to `Border.all`. | **RESOLVED** |
| **DEF-02** | Medium | `CardTheme` vs `CardThemeData` type mismatch in Flutter 3.47 theme. | In Flutter 3.47+, `ThemeData.cardTheme` expects `CardThemeData`. | Updated `AppTheme` to assign `CardThemeData`. | **RESOLVED** |
| **DEF-03** | Medium | Deprecated `desiredAccuracy` and `timeLimit` in `geolocator: ^14.1.2`. | `Geolocator.getCurrentPosition` deprecated direct parameters in v14. | Migrated to `LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 7))`. | **RESOLVED** |
| **DEF-04** | Low | Unused local variable `createdStr` in `RequestDetailsScreen`. | Variable declared but replaced by `scheduledStr`. | Cleaned up unused variable; verified clean `flutter analyze`. | **RESOLVED** |
| **DEF-05** | High | Camera device crash on desktop/emulator without physical webcam. | Native camera driver returns null/error when hardware is absent. | Added fallback modal with verified sample waste photos for instant testing. | **RESOLVED** |
| **DEF-06** | Medium | All user roles (resident, rider, admin) shared identical generic DP. | `AppUser.avatarUrl` was unpopulated and role headers lacked DP widgets. | Built `UserAvatar`, `ProfileSettingsScreen`, standard avatar presets, and camera/gallery upload. | **RESOLVED** |
| **DEF-07** | High | Image loader crashed with `FileSystemException` on seed requests. | Seed photo paths (`assets/sample_plastics.jpg`) were passed to `Image.file`. | Replaced with robust photo loaders handling network, local files, and simulated fallbacks. | **RESOLVED** |
| **DEF-08** | Medium | Scheduling allowed past times today and midnight booking. | No validation on selected time compared to `DateTime.now()`. | Added guardrails enforcing $\ge 15$ min future time and operating daylight hours (7am-7pm). | **RESOLVED** |
| **DEF-09** | Medium | Collectors lacked route map visibility and turn-by-turn navigation. | UI only displayed coordinate numbers without map integration. | Integrated `url_launcher` for Google Maps and interactive OpenStreetMap via `flutter_map`. | **RESOLVED** |
| **DEF-10** | Low | Volume size label replaced standalone bag text in `WasteCard`. | Text formatting condensed label and bag count into single string. | Rendered volume size pill alongside distinct bag counter text. | **RESOLVED** |

---

## 4. User Evaluation & Free-Tier Operational Review

1. **Household Resident (Sarah, Kampala):**
   - *Feedback:* "I need to know which bin to put strange items in before booking, and track when the rider is actually coming."
   - *Improvement Made:* Added the **Which Bin? Waste Sorting Guide** (searchable offline database of 25+ household items) and the **4-Stage Milestone Stepper** on request details.

2. **Tricycle Rider / Collector (Alex, Kololo):**
   - *Feedback:* "I need to be able to call the customer directly from the app when I reach their gate."
   - *Improvement Made:* Added a 1-tap **Call Resident** (`tel:`) button and turn-by-turn navigation.

3. **Operations Supervisor (Grace, Dispatch Admin):**
   - *Feedback:* "Need a live view of all field riders, cash collected per rider, municipal operating settings, and 1-tap CSV reports for city council audits."
   - *Improvement Made:* Added the **Fleet Riders Directory** with active cash counters, dedicated **Admin System Controls** in profile settings, and **Municipal Operations CSV Log Export**.
