# EcoRoute: Project Concept Document (Milestone 1)

## 1. Project Title
**EcoRoute – On-Demand Community Waste Pickup & Collection Scheduler**

---

## 2. Problem Statement
Urban communities face pervasive delays and uncoordinated informal waste collection. Piles of uncollected domestic and commercial waste accumulate in alleys and by the curbside, breeding vectors, clogging drainage systems, and releasing greenhouse gases. Currently, residents have no transparent way to signal when waste is ready for pickup, no visibility into collector arrival, and collectors have no geotagged map of where waste is accumulating. Informal waste pickers operate opportunistically without route planning, and transactions rely haphazardly on cash without receipts or accountability.

---

## 3. Target Users
1. **Citizens / Residents (Households & Small Businesses):**
   - People who generate solid waste and want timely, reliable pickup without having waste sit outside their premises.
   - Desire transparent upfront pricing and prefer paying cash directly upon collection.
2. **Waste Collectors / Tricycle Riders:**
   - Independent collection drivers and municipal waste crews who need a steady stream of jobs, GPS route visibility, and an easy tally of hard cash collected.
3. **Operations Admins / Dispatchers:**
   - Waste management supervisors coordinating fleet assignments, tracking pending versus collected requests, and auditing daily cash receipts and recycling diversion rates.

---

## 4. Current User Workarounds
- Leaving garbage bags on street corners hoping private haulers pass by.
- Burning waste or illegal dumping in open drainage channels during rains.
- Haggling over collection fees in person with informal pushcart operators.

---

## 5. Proposed Mobile Solution
**EcoRoute** is a Flutter-based mobile application that bridges citizens, collection riders, and dispatchers:
1. **Move Closer & Snap Waste Photo:** Visual proof of volume, sorting, and bags needed.
2. **Automated GPS Capture & Reverse Geocoding:** Zero-typing address discovery via device GPS and OpenStreetMap REST APIs.
3. **Upfront Cash Estimation:** Transparent rates per bag and category (Plastics, Organic, E-Waste, Paper, Metal, General).
4. **Dispatcher & Rider Feeds:** Admins dispatch jobs, and nearby tricycle riders receive alerts with GPS location and distance.
5. **Hard Cash on Delivery Settlement:** Riders confirm physical pickup, collect exact hard cash, and generate an official receipt for the resident.
6. **Eco-Impact Analytics:** Real-time tracking of CO₂e avoided, equivalent trees saved, and landfill volume preserved.

---

## 6. Core Features & Scope
### In-Scope (Implemented)
- Automatic device GPS detection with simulated fallback for desktop/emulators.
- Camera and gallery photo attachment for waste visual verification.
- Reverse geocoding of GPS coordinates into street addresses via OpenStreetMap Nominatim.
- Dynamic pricing calculation based on waste category and bag count.
- Multi-persona role switcher (Citizen, Rider, Admin) in one cohesive app.
- Full CRUD persistent local data storage surviving app closures and restarts.
- Rider cash pouch tracker & digital cash receipt generation upon payment.
- Unit and widget test suite covering business logic, pricing, and UI components.

### Out-of-Scope (Future Iterations)
- Integrated mobile money / USSD gateway (hard cash on collection intentionally prioritized for market reality).
- Real-time turn-by-turn voice navigation (relies on device map intents).
- Heavy municipal industrial weighing scale Bluetooth hardware integration.

---

## 7. Expected Value
- **To Citizens:** Clean, hygienic neighborhoods, verified pickups, zero surprise fees.
- **To Riders:** Predictable daily income, optimized collection routes, transparent cash tracking.
- **To the Environment:** Measurable diversion of recyclables from open landfills and reduced CO₂ emissions.
