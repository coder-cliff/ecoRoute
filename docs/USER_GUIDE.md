# EcoRoute User Guide

Welcome to **EcoRoute**, the smart municipal waste collection and recycling platform designed for Arua City, Uganda.

---

## 1. Quickstart & Installation

### Option A: Running from Source / Web
```powershell
# 1. Navigate to project root
cd "C:\Users\HP Laptop 15\.gemini\antigravity\scratch\ecoRoute"

# 2. Get dependencies
flutter pub get

# 3. Run on Web / Chrome
flutter run -d chrome --web-port=3000

# 4. Run automated test suite
flutter test
```

### Option B: Installing the APK on Your Android Device
EcoRoute provides both **Production Release APKs** (optimized, tree-shaken, fast) and **Debug APKs** in `build/app/outputs/flutter-apk/`:

1. **For modern 64-bit Android smartphones (Recommended):**
   - **Production Release:** `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
   - **Debug Version:** `build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk`
2. **For older 32-bit Android phones:**
   - **Production Release:** `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
   - **Debug Version:** `build/app/outputs/flutter-apk/app-armeabi-v7a-debug.apk`

**USB Installation via ADB:**
```powershell
adb install -r "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
```
*(Or transfer the `.apk` file via USB cable or WhatsApp/Drive to your phone, tap the file in your file manager, and allow "Install from Unknown Sources".)*

---

## 2. Using EcoRoute as a Resident

### A. Exploring the Dashboard & Open Waste Database
- **Arua Route Weather:** Real-time meteorological road safety indicator fetched via REST API. Alerts when rain makes unpaved roads impassable.
- **Municipal Waste & Recycling Database:** Tap the database banner on the home screen, the dataset icon in the top app bar, or via Profile:
  - Search materials in English (e.g., *battery, plastic, matooke*) or indigenous Lugbara (*betiri, kaveera, agbi*).
  - Filter streams: *Plastics, Organic, Paper, Metals, Glass, Hazardous*.
  - View decomposition periods, carbon avoided, and estimated resale rates in UGX/kg.
  - Discover certified Arua recovery bays (*Arua Central Market, River Oli, Arua Hill, Referral Hospital, Muni University, Ediofe*).
- **Interactive Arua Map:** Pan and zoom across Arua City to inspect collection zones and municipal landmarks.

### B. Scheduling a Pickup with Smart Camera Auto-Scan
1. Tap **AUTO-SCAN RUBBISH (SMART CAMERA)** on the home screen.
2. The camera viewfinder opens automatically with proximity detection:
   - Bring the camera within range of the waste.
   - The ultrasonic guidance counts down and **automatically triggers the shutter** when proximity is reached.
   - The device GPS coordinates and municipal boundary are automatically locked.
   - The app auto-returns to the order form with the photo attached!
3. Alternatively, tap **REPORT AN ISSUE** for manual photo capture.
4. Select your **Waste Type** and number of sacks (e.g. 3 sacks = 4,500 UGX).
5. Review the prefilled phone number (`+256394880352`) and tap **Submit collection order**.

### C. Paying via Mobile Money (MTN MoMo & Airtel Money)
1. Navigate to the **Requests** tab.
2. Tap **Pay MoMo** on any open or verified request.
3. Select **MTN MoMo** or **Airtel Money**, confirm the phone number, and approve the payment.
4. An official **Arua City Council Digital Collection Receipt** is immediately rendered with a transaction audit code and timestamp.

### D. Multilingual Support
- Tap the **Language** icon in the app bar to switch between **English**, **Lugbara** (*native West Nile language*), and **Kiswahili**.

---

## 3. Using EcoRoute as a Route Rider

1. **Switch to Rider Role:**
   - Tap the profile/notification icon, select **Rider** (`rider@ecoroute.demo`), and tap **Sign in**.
2. **Review Today's Route Stops:**
   - The dashboard transforms into the **Rider dispatch board**, grouping active stops in your zone.
3. **Advance Stops Through the Collection Pipeline:**
   - Upon arriving and loading sacks onto the tricycle, tap **Mark collected**.
   - Once the load is secured, tap **Send for verification** to forward the request to the municipal administrator.

---

## 4. Using EcoRoute as an Administrator

1. **Switch to Admin Role:**
   - Select **Admin** (`admin@ecoroute.demo`) in the auth sheet.
2. **Audit Approvals:**
   - Review pending pickups submitted by riders in the **Approval queue**.
   - Tap **Approve payment** to verify collection and settle payment records.
   - If a load was improperly sorted, tap **Return to rider** to request reinspection.
3. **Analyze Operations:**
   - Review the **Transaction analytics** dashboard displaying real-time counts and proportions of requested, collected, verified, and settled pickups across Arua City.
