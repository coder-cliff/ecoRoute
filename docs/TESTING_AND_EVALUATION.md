# Week 12 Milestone Brief: Testing, Debugging & User Evaluation

## 1. Quality Assurance & Test Strategy
EcoRoute employs a comprehensive multi-tier testing strategy combining:
1. **Domain Unit Testing:** Pure Dart mathematical verification of pricing formulas, zone radius geometry, and state machine transition graphs without widget overhead.
2. **Repository & Storage Unit Testing:** Verification of CRUD persistence, asynchronous JSON serialization, and corrupt-state recovery.
3. **REST API Service Mock Testing:** Verification of HTTP request handling, timeout triggers, weather status categorization, and offline fallback failover using `http/testing.dart`.
4. **Widget & End-to-End Flow Testing:** Headless UI testing verifying screen rendering, viewport responsiveness ($412 \times 700$ and narrow screens), form validation errors, and cross-role state propagation.
5. **Advanced Feature Testing:** Automated testing for the Waste Camera proximity scanner, Mobile Money simulation (+256394880352) with digital receipts, and multilingual string translation (Lugbara/Swahili).
6. **Open Database & Smart Auto-Scan Testing:** Full-text stemming verification across English and Lugbara keywords, resale rate calculators, municipal facility queries, and auto-camera trigger workflows.

---

## 2. Test Execution Summary

```
Total Test Cases: 38 passed, 0 failed, 0 skipped
Flutter Analyze: 0 errors, 0 warnings, 0 lints
Execution Time: ~9.8 seconds
```

### Breakdown by Test Suite:
| Test File | Milestone Covered | Focus Area | Result |
| :--- | :--- | :--- | :--- |
| [`domain_rules_test.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/test/domain_rules_test.dart) | Weeks 1, 6 | Pricing bounds, 12 km radius geometry, state transitions | **6 / 6 PASSED** |
| [`pickup_request_repository_test.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/test/pickup_request_repository_test.dart) | Week 7 | Persistent local data, CRUD operations, ordering | **2 / 2 PASSED** |
| [`waste_api_service_test.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/test/waste_api_service_test.dart) | Week 9 | Open-Meteo REST API, JSON parse, timeout fallback, tariffs | **4 / 4 PASSED** |
| [`auth_service_test.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/test/auth_service_test.dart) | Week 10 | Demo auth, registration, persistent sessions, logout | **3 / 3 PASSED** |
| [`location_service_test.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/test/location_service_test.dart) | Week 11 | GPS coordinate evaluation, Arua boundary, zones | **3 / 3 PASSED** |
| [`enhanced_order_test.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/test/enhanced_order_test.dart) | Weeks 5, 6, 7 | Sack calculation, phone validation, extended persistence | **2 / 2 PASSED** |
| [`widget_test.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/test/widget_test.dart) | Weeks 3, 4, 8 | Dashboard browsing, multi-role flow, compact viewport | **6 / 6 PASSED** |
| [`advanced_features_test.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/test/advanced_features_test.dart) | Week 11 | Proximity camera scanner, MoMo dialog, Lugbara/Swahili | **3 / 3 PASSED** |
| [`waste_database_and_auto_scan_test.dart`](file:///C:/Users/HP%20Laptop%2015/.gemini/antigravity/scratch/ecoRoute/test/waste_database_and_auto_scan_test.dart) | Weeks 9, 11 | Open taxonomy, Lugbara stemming, World Bank stats, auto-scan | **9 / 9 PASSED** |

---

## 3. Systematic Test Cases Matrix

### A. Boundary & Invalid Input Cases
| Test ID | Input / Action | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- |
| **TC-01** | Sack count input = 0 | Throws `ArgumentError` ("Must be between 1 and 50") | Throws `ArgumentError` as expected | **PASSED** |
| **TC-02** | Sack count input = 51 | Throws `ArgumentError` | Throws `ArgumentError` as expected | **PASSED** |
| **TC-03** | Order form submitted with empty waste type | Shows error: `'Select a waste type'` | Error rendered below dropdown | **PASSED** |
| **TC-04** | Order description $< 10$ characters | Shows error: `'Please enter at least 10 characters'` | Error rendered below textfield | **PASSED** |
| **TC-05** | GPS coordinates $3.28^\circ\text{N}, 30.91^\circ\text{E}$ ($> 12$ km) | Status `outsideServiceArea`, warns user | Warning banner displayed | **PASSED** |

### B. Network & Exception Cases
| Test ID | Input / Action | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- |
| **TC-06** | Open-Meteo REST API returns HTTP 500 | Graceful fallback to offline cached weather | Returns `AruaWeatherReport.fallback()` with `isOnline: false` | **PASSED** |
| **TC-07** | Network socket timeout ($> 4$s) | Graceful offline fallback | Immediate fallback without hanging UI | **PASSED** |
| **TC-08** | Corrupted JSON stored in `SharedPreferences` | Returns empty list rather than crashing app | Returns `[]` safely via `try-catch` | **PASSED** |

### C. Advanced Device & Flow Cases
| Test ID | Input / Action | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- |
| **TC-09** | Switch language to `AppLanguage.lugbara` | Translates schedule pickup to `'Liru omba'` | Displayed translated string | **PASSED** |
| **TC-10** | Manual shutter trigger in camera scanner | Acquires photo and auto-GPS location | Captures result with service area verified | **PASSED** |
| **TC-11** | MoMo payment simulation with `+256394880352` | Emits USSD push, generates receipt | Status updated to `paid` with audit receipt | **PASSED** |
| **TC-12** | Camera proximity auto-capture triggers | Automatically locks GPS and auto-confirms return | Saves photo label and returns without tap | **PASSED** |
| **TC-13** | Search waste database with "Battery" | Stemming matches "Dry-Cell Radio & Solar Batteries" | Matches item correctly | **PASSED** |
| **TC-14** | Estimate recycling value for 10 kg PET bottles | Calculates 10 kg $\times$ 800 UGX = 8,000 UGX | Returns 8,000 UGX | **PASSED** |
| **TC-15** | Query certified facilities for Zone.north | Returns Arua Central Market Eco-Station | Facility returned with coordinates | **PASSED** |
| **TC-16** | Mount OrderPage with `autoTriggerCamera: true` | Automatically pops camera dialog on load | Viewfinder mounted automatically | **PASSED** |

---

## 4. Defect Log & Corrective Actions

| Defect ID | Description | Root Cause | Corrective Action Taken | Status |
| :--- | :--- | :--- | :--- | :--- |
| **DEF-01** | RenderFlex overflow on small displays ($412 \times 700$ viewport). | Fixed-width map labels and weather card rows without `Expanded` or `FittedBox`. | Wrapped header text with `FittedBox`, constrained text with `TextOverflow.ellipsis`, and applied flexible column padding. | **RESOLVED** |
| **DEF-02** | Flutter assertion: `ListTile background color or ink splashes may be invisible`. | `SwitchListTile` internally wrapped in a `DecoratedBox` with background color. | Replaced `SwitchListTile` with custom `Row` (Text + Switch) avoiding internal ListTile conflicts. | **RESOLVED** |
| **DEF-03** | `Submit collection order` button scrolled offscreen during automated headless testing. | Adding expanded fields increased form height beyond initial test frame. | Compacted form inputs into multi-column rows, ensuring primary action remains accessible. | **RESOLVED** |
| **DEF-04** | Accidental duplicate `lib/android` and `lib/ios` folders inside `lib/`. | Duplicate files committed during initial workspace bootstrapping. | Safely removed via `git rm -r lib/android lib/ios`. | **RESOLVED** |
| **DEF-05** | RenderFlex overflow on MoMo receipt rows. | Long value strings inside unconstrained row. | Wrapped value widgets in `Expanded` with `TextAlign.end`. | **RESOLVED** |
| **DEF-06** | Singular vs plural keyword mismatch in waste database search. | Typing singular "Battery" failed to match plural "Batteries". | Implemented stem-matching algorithm adding singular and plural variations (`-y`, `-ies`, `-s`). | **RESOLVED** |

---

## 5. User Evaluation & Representative Feedback
Four representative users evaluated the application:
1. **Resident (Amina D. - Oli Division):**
   - *Feedback:* "I love that I can tap Auto-Scan and the camera captures the rubbish as soon as I hold it close. And the Lugbara terms help my household sort plastic from organic peels."
   - *Improvement Made:* Added smart auto-capture with proximity countdown and Lugbara taxonomy.
2. **Rider (Juma O. - Central Division):**
   - *Feedback:* "When it rains, the dirt roads in River Oli are flooded. Having the weather alert on the home screen tells me when to delay tricycle departures."
   - *Improvement Made:* Integrated real-time rain detection from Open-Meteo REST API.
3. **Municipal Admin (Grace C. - Arua City Council):**
   - *Feedback:* "The interactive map with landmarks like Arua Hill, Muni University, and the referral hospital makes it easy to visualize collection zones."
   - *Improvement Made:* Implemented zoomable and pannable vector map canvas with landmark markers.
4. **Recycling Hub Operator (David M. - Arua Hill):**
   - *Feedback:* "Showing the scrap price in UGX/kg helps residents know that plastic bottles and cardboard are valuable rather than burning them."
   - *Improvement Made:* Added UGX/kg scrap rate estimations and listed certified municipal drop-off hubs.
