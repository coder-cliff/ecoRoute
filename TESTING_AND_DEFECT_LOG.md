# EcoRoute: Test Plan, Defect Log & User Evaluation (Milestone 12)

This document contains the systematic quality assurance records, automated test results, boundary conditions tested, defect remediation log, and user evaluation feedback required for Milestone 12.

---

## 1. Test Plan

### Objectives
- Verify that waste collection requests accurately record waste photo, GPS coordinates, category, and bag counts.
- Ensure that the upfront cash estimation matches the business rate rules.
- Confirm that data persists across application restarts (SharedPreferences JSON serialization).
- Verify that status transitions propagate across Citizen, Rider, and Admin views in real time.
- Verify graceful offline handling when external APIs (OpenStreetMap) or location sensors are unavailable.

### Testing Scope
| Component | Functionality Tested | Test Type |
|---|---|---|
| `WasteCategory` & Pricing | Unit price multiplication, carbon mitigation formula | Automated Unit Test |
| `WasteRequest` Model | JSON serialization & deserialization round-trip, status copyWith | Automated Unit Test |
| `ApiService` | Environmental impact metrics, Nominatim timeout handling | Automated Unit Test & Integration |
| `LocationService` | Haversine GPS distance calculation, permission fallback | Automated Unit Test |
| `StatusBadge` & `CashPaymentBanner` | UI rendering, conditional color badges, cash amount strings | Automated Widget Test |
| `WasteCard` | Card layout, bag count formatting, address presentation | Automated Widget Test |
| `NewRequestScreen` | Input validation (empty photo, empty address, bag count < 1) | Manual & Automated Validation |
| `RiderDashboardScreen` | Cash pouch accumulation, cash payment confirmation modal | End-to-End Simulation |

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

---

## 3. Defect Log & Corrective Actions

| Defect ID | Severity | Description | Root Cause | Corrective Action Taken | Status |
|---|---|---|---|---|---|
| **DEF-01** | High | `Border.Border.all` compilation error in several screen files. | Typo invoking `Border.Border.all` instead of `Border.all`. | Refactored all container decorations across UI screens to `Border.all`. | **RESOLVED** |
| **DEF-02** | Medium | `CardTheme` vs `CardThemeData` type mismatch in Flutter 3.47 theme. | In Flutter 3.47+, `ThemeData.cardTheme` expects `CardThemeData`. | Updated `AppTheme` to assign `CardThemeData`. | **RESOLVED** |
| **DEF-03** | Medium | Deprecated `desiredAccuracy` and `timeLimit` in `geolocator: ^14.1.2`. | `Geolocator.getCurrentPosition` deprecated direct parameters in v14. | Migrated to `LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 7))`. | **RESOLVED** |
| **DEF-04** | Low | Unused local variable `createdStr` in `RequestDetailsScreen`. | Variable declared but replaced by `scheduledStr`. | Cleaned up unused variable; verified clean `flutter analyze`. | **RESOLVED** |
| **DEF-05** | High | Camera device crash on desktop/emulator without physical webcam. | Native camera driver returns null/error when hardware is absent. | Added fallback modal with verified sample waste photos for instant testing. | **RESOLVED** |

---

## 4. User Evaluation & Feedback Integration

Three representative target users evaluated the prototype:

1. **Household Resident (Sarah, Kampala):**
   - *Feedback:* "I don't know my exact plot number or street name off the top of my head when reporting."
   - *Improvement Made:* Implemented automatic reverse geocoding via OpenStreetMap so the address is filled in automatically from the GPS pin.

2. **Tricycle Rider / Collector (Alex, Kololo):**
   - *Feedback:* "I need to know how much cash to expect from the customer before I arrive so I have change."
   - *Improvement Made:* Added prominent cash badge on the rider card showing the exact amount due and a pouch summary of total cash collected today.

3. **Operations Supervisor (Grace, Dispatch Admin):**
   - *Feedback:* "Need to filter out completed requests so the dispatch screen doesn't get cluttered."
   - *Improvement Made:* Added filter tabs (`All`, `Pending`, `Assigned`, `Done`) and quick KPI overview counters.
