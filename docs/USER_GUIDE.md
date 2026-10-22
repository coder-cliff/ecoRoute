# EcoRoute User Guide

Welcome to **EcoRoute**, the smart municipal waste collection platform designed for Arua City.

---

## 1. Quickstart & Installation
To run EcoRoute locally on your machine or Android emulator:

```powershell
# 1. Navigate to project root
cd "C:\Users\HP Laptop 15\.gemini\antigravity\scratch\ecoRoute"

# 2. Get dependencies
flutter pub get

# 3. Run the application
flutter run
```

To run all automated test suites:
```powershell
flutter test
```

---

## 2. Using EcoRoute as a Resident
1. **Explore the Service Overview:**
   - Launch the app. The home screen displays the current Arua Route Weather, service area radius (12 km), and collection days for North, South, East, and West zones.
2. **Schedule a Pickup:**
   - Tap **REPORT AN ISSUE** or **Schedule pickup**.
   - If not already signed in, enter your account details or select the **Resident** demo account (`resident@ecoroute.demo` / `demo123`).
   - Select your **Waste Type** (e.g. Household Domestic).
   - Enter the number of sacks (e.g., 3). Observe the **Estimated Cost** automatically update to `4,500 UGX` (`1,500 UGX / sack`).
   - Tap the **GPS location button** to autofill your zone based on your coordinates, or choose your zone manually.
   - Enter your collection details and tap **Submit collection order**.
3. **Track Your Orders:**
   - Tap the **Requests** tab in the bottom navigation bar to monitor the status of your collection from *Requested* $\to$ *Collected* $\to$ *Paid*.
   - You can cancel any open request by tapping the red delete icon.

---

## 3. Using EcoRoute as a Route Rider
1. **Switch to Rider Role:**
   - Tap the notifications/profile icon in the top right, select the **Rider** chip (`rider@ecoroute.demo`), and tap **Sign in**.
2. **Review Today's Route Stops:**
   - The home dashboard transforms into the **Rider dispatch board**.
   - Review active stops in your assigned zone.
3. **Advance Stops Through the Collection Pipeline:**
   - Upon arriving at a household and loading sacks onto the tricycle, tap **Mark collected**.
   - Once waste is inspected and secured, tap **Send for verification**. The stop moves to the administrator queue for payment auditing.

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
