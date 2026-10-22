# EcoRoute User Guide

Welcome to **EcoRoute**, the smart municipal waste collection platform designed for Arua City, Uganda.

---

## 1. Quickstart & Installation
To run EcoRoute locally on your machine or in your browser:

```powershell
# 1. Navigate to project root
cd "C:\Users\HP Laptop 15\.gemini\antigravity\scratch\ecoRoute"

# 2. Get dependencies
flutter pub get

# 3. Run the application on Web / Chrome
flutter run -d chrome

# Or run automated tests
flutter test
```

---

## 2. Using EcoRoute as a Resident

### A. Exploring the Dashboard & Interactive Map
- Launch the app. The home screen displays the live **Arua Route Weather**, service area radius (12 km), and collection days for North, South, East, and West zones.
- **Interactive Arua Map:** Scroll to the map canvas. Double-tap to zoom or pan across Arua City. Tap landmark markers (*Arua Central Market, River Oli, Arua Hill, Hospital, Muni University*) to see zone boundaries and scheduled collection days.

### B. Scheduling a Pickup with Camera & Auto-GPS
1. Tap **REPORT AN ISSUE** or **Schedule pickup**.
2. If not signed in, sign in using the **Resident** demo account (`resident@ecoroute.demo` / `demo123`).
3. **Capture Rubbish Photo (Proximity Guidance):**
   - Tap **Scan Rubbish** or the camera icon in the top app bar.
   - The fullscreen viewfinder guides you: *"Move closer to the rubbish..."*.
   - **Automatic Mode:** Align the camera frame with the waste; once the proximity threshold is reached, the shutter captures automatically.
   - **Manual Mode:** Switch to *Manual* and press the round shutter button anytime.
   - **Immediate GPS Tagging:** As soon as the photo is captured, device GPS coordinates are automatically recorded and validated against the Arua service perimeter. Tap **Confirm & Save**.
4. Select your **Waste Type** (e.g., Household Domestic).
5. Enter the number of sacks. The dynamic price updates in real-time (e.g. `3 sacks = 4,500 UGX`).
6. Confirm or enter your contact phone (prefilled with default **`+256394880352`**).
7. Tap **Submit collection order**.

### C. Paying via Mobile Money (MTN MoMo & Airtel Money)
1. Tap the **Requests** tab.
2. For any open or verified request, tap **Pay MoMo**.
3. Choose your provider: **MTN MoMo** or **Airtel Money**.
4. Confirm your phone number (default: `+256394880352`) and tap **Pay [Amount] UGX**.
5. The simulated USSD push will prompt on the phone screen.
6. Upon completion, an official **Arua City Council Digital Collection Receipt** is displayed showing the transaction audit ID, settled amount, timestamp, and location.

### D. Changing Language & Themes
- Tap the **Language** button in the top app bar to switch between **English**, **Lugbara** (*native West Nile language*), and **Kiswahili**. All dashboard cards, actions, and schedules adapt immediately.
- EcoRoute automatically respects system light and dark modes with a dedicated Material 3 dark green palette.

---

## 3. Using EcoRoute as a Route Rider

1. **Switch to Rider Role:**
   - Tap the notifications/profile icon, select the **Rider** chip (`rider@ecoroute.demo`), and tap **Sign in**.
2. **Review Today's Route Stops:**
   - The home dashboard transforms into the **Rider dispatch board**.
   - Review active stops in your assigned zone with resident contact numbers and waste categories.
3. **Advance Stops Through the Collection Pipeline:**
   - Upon arriving at a household and loading sacks onto the tricycle, tap **Mark collected**.
   - Once waste is secured, tap **Send for verification**. The stop moves to the municipal administrator queue for audit settlement.

---

## 4. Using EcoRoute as an Administrator

1. **Switch to Admin Role:**
   - Select the **Admin** chip (`admin@ecoroute.demo`) in the auth sheet.
2. **Audit Approvals:**
   - Review pending pickups submitted by riders in the **Approval queue**.
   - Tap **Approve payment** to verify collection and settle payment records.
   - If a load was improperly sorted, tap **Return to rider** to request reinspection.
3. **Analyze Operations:**
   - Review the **Transaction analytics** dashboard displaying real-time counts and proportions of requested, collected, verified, and settled pickups across Arua City.
