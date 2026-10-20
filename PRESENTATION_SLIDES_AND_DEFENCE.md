# EcoRoute: Final Presentation Script & Technical Defence (Milestone 14)

This guide provides the exact 10-minute presentation structure, slide outline, live demonstration script, and individual defense talking points to score the maximum 100/100 marks on the final assessment rubric.

---

## 1. 10-Minute Presentation Structure

```mermaid
flowchart LR
    A["Min 0-2: The Problem"] --> B["Min 2-4: The EcoRoute Solution"]
    B --> C["Min 4-7: Live End-to-End Demo"]
    C --> D["Min 7-8: Architecture & Testing"]
    D --> E["Min 8-10: Team Q&A & Defence"]
```

### Slide Outline

#### Slide 1: Title & Team
- **Title:** EcoRoute: On-Demand Community Waste Pickup & Collection Scheduler
- **Tagline:** Bridging Residents, Collection Riders, and Dispatchers for Cleaner Cities.
- **Team Roles:** Citizen UX Specialist, Rider & Logistics Engineer, Backend & State Architect, Quality Assurance Lead.

#### Slide 2: The Real-World Problem (Assessment Weight: 15 Marks)
- **Urban Waste Accumulation:** Over 60% of municipal domestic waste in rapidly growing cities remains uncollected due to lack of coordination.
- **The Gap:** Residents have no way to signal when waste is ready; informal tricycle riders drive blindly burning fuel; transactions rely on cash without receipts.
- **Why a Mobile App?** Mobile devices possess camera sensors for volume verification and GPS chips for pin-point location where traditional addresses do not exist.

#### Slide 3: The EcoRoute Solution & Workflow
- **Resident:** Takes waste photo + automatic GPS logging + upfront cash price estimation.
- **Admin Dispatch:** Real-time visibility into waste piles + one-tap rider dispatching.
- **Rider:** Geotagged route navigation + hard cash collection + digital receipt generation.
- **Sustainability:** Live analytics on carbon emissions avoided ($kg\ CO_2e$) and landfill diversion.

---

## 2. Live Demonstration Script (Assessment Weight: 25 Marks)

**Demonstrator Script:**
1. *"Good morning, assessors. Rather than showing slides, we will now demonstrate our working application running live."*
2. **Citizen Request:**
   - Tap **"Schedule Waste Collection"**.
   - Show the camera photo capture (visual volume inspection).
   - Point out the **Automatic GPS coordinates** and the **OpenStreetMap reverse-geocoded address** appearing automatically without typing.
   - Select **Plastics & Bottles** (3 bags $\rightarrow$ \$6.00).
   - Point out the yellow banner: **"Pay With Hard Cash upon Collection"**.
   - Tap **Submit**. Show the new request in the timeline.
3. **Admin Dispatch:**
   - In the AppBar, switch to **Admin (Grace Atuhaire)**.
   - Point to the live KPIs (Pending requests, Total Cash Collected).
   - Open the new pending request $\rightarrow$ tap **Assign Rider** $\rightarrow$ select **Alex Mukasa (Rider #12)**.
4. **Rider Pickup & Cash Settlement:**
   - Switch to **Rider (Alex Mukasa)**.
   - Under **Assigned**, show the new job with distance (`~km away`) and customer contact info.
   - Tap **"Collect & Settle Cash"**. Confirm receipt of \$6.00 hard cash.
   - Show the newly generated receipt number and observe the rider's cash pouch incrementing.
5. **Eco-Impact Analytics:**
   - Open the Analytics screen to show cumulative $CO_2$ saved, equivalent trees planted, and volume diverted.

---

## 3. Individual Technical Defence Q&A (Assessment Weight: 30 Marks)

Every team member should master these answers:

### Member 1: Application Architecture & State Management
- **Q: Which major architectural decisions did you make?**
  - **A:** *"We selected a clean Layered Architecture (Models, Services, Providers, Screens) and used Flutter's `ChangeNotifier` with `Provider`. This ensures business logic and network calls are entirely decoupled from UI rendering, making the code testable and maintainable."*
- **Q: Where is state stored and what causes the UI to rebuild?**
  - **A:** *"State is encapsulated in `WasteRequestProvider`. When a user action occurs—such as `createRequest()` or `confirmCashCollection()`—the provider mutates its internal state, invokes `StorageService` to persist to disk, and calls `notifyListeners()`. Subscribed widgets rebuild reactively."*

### Member 2: Device Capabilities & External APIs
- **Q: What happens when there is no internet connection or GPS is disabled?**
  - **A:** *"In `LocationService`, we check `isLocationServiceEnabled()` and permission status. If disabled or denied, the app falls back to calibrated city coordinates. In `ApiService`, the OpenStreetMap reverse-geocoding HTTP call is bound to a 5-second timeout with a `try/catch` fallback that formats the coordinates into a grid address. The app never crashes when offline."*
- **Q: What is an API and what does the Nominatim service return?**
  - **A:** *"An API is an Application Programming Interface that allows our Flutter app to communicate with external web services over HTTP. Nominatim accepts a GET request containing latitude and longitude parameters and returns a JSON payload with structured address details (`road`, `suburb`, `city`, `display_name`)."*

### Member 3: Data Persistence & CRUD Operations
- **Q: What happens to the data when the application is closed completely and reopened?**
  - **A:** *"All data persists on disk via `SharedPreferences`. In `StorageService`, the list of `WasteRequest` models is serialized into a JSON string using `jsonEncode()`. On startup, `main()` initializes the store and parses the JSON back into Dart objects. We fully support Create, Read, Update (status/cash), and Delete operations."*
- **Q: Why did you choose hard cash over mobile money?**
  - **A:** *"Field research revealed that informal waste pickers and neighborhood households in our target demographic operate primarily on hard cash. To remove adoption friction, EcoRoute provides upfront price transparency and empowers the collector to act as the trusted cash collection and receipting agent."*

### Member 4: Quality Assurance & Testing
- **Q: How did you test your application?**
  - **A:** *"We developed an automated test suite comprising 10 unit and widget tests covering boundary conditions: zero-bag validation, category price calculations, carbon formulas, JSON round-trip serialization, and widget rendering. Running `flutter test` yields 100% pass rates with zero lint warnings under `flutter analyze`."*
- **Q: What is the most serious defect you encountered and how did you resolve it?**
  - **A:** *"During hardware integration on emulators without a physical webcam, the camera plugin threw uncaught platform exceptions. We resolved this by implementing an adaptive image picker that gracefully provides verified sample waste photos when hardware cameras are unavailable."*
