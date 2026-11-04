# Week 1 Milestone Brief: Project Concept Document

## Project Title
**EcoRoute** — Smart Municipal Waste Collection, Recycling Taxonomy & Dispatch Platform for Arua City.

---

## 1. Problem Statement
In rapidly urbanizing secondary cities such as Arua City, Uganda, municipal solid waste management suffers from severe operational bottlenecks:
- **Informal & Illegal Dumping:** Residents and small trading businesses lack scheduled, dependable waste pickup services, leading to roadside garbage heaps and blocked drainage channels in River Oli.
- **Opaque Pricing & Informal Payments:** Residents are subjected to arbitrary charges by informal cart pushers with no receipting, verified weight/volume standards, or digital transaction records.
- **Rider Route Inefficiencies:** Waste collection tricycles and boda-boda collectors operate without route planning or zone coordination, frequently missing households or doubling back over muddy roads.
- **Lack of Municipal Visibility:** City environmental administrators have no real-time audit trail of collection volumes, collected vs. pending requests, or payments.
- **Absence of Recycling Literacy & Local Terminology:** Residents lack accessible data on waste decomposition, material sorting, resale values in UGX, and certified local recovery facilities, especially in native languages like Lugbara.

---

## 2. Target Users
1. **Urban Residents & Small Businesses:**
   - Need simple, transparent pickup scheduling, predictable collection days based on their municipal zone, transparent pricing (per-sack UGX), smart rubbish photo auto-capture, and pickup status tracking.
2. **Collection Route Riders (Tricycle / Boda Collectors):**
   - Need clear daily dispatch queues grouped by municipal zone (North, South, East, West), turn-by-turn stop validation, and immediate submission of collected loads for verification.
3. **Municipal Operations & Environmental Administrators:**
   - Need a bird's-eye view of municipal waste demand, payment verification queues, service radius compliance checks (12 km perimeter), open recycling benchmarks, and live volume/revenue analytics.

---

## 3. What Users Currently Do
- Burning trash in open backyard pits or unmonitored open-air dumping along roadsides and waterways.
- Haggling with informal waste pushers on an irregular basis.
- Calling municipal offices via landlines or word-of-mouth with no tracking or guaranteed response.
- Discarding valuable recyclables (plastics, scrap metal, organic feedstock) because recycling rates and certified municipal bays are unknown.

---

## 4. Proposed Solution
**EcoRoute** is an offline-first mobile application developed with Flutter that bridges residents, riders, and city administrators:
- **Zone-Based Scheduling:** Categorizes Arua municipality into 4 cardinal sectors (North, South, East, West) around the central reference coordinate (3.05°N, 30.91°E) with fixed weekly pickup days.
- **Smart Rubbish Camera Auto-Capture:** Utilizes ultrasonic proximity detection guidance to automatically trigger the camera shutter when waste is in range, locks GPS coordinates, and attaches photo evidence.
- **Open Municipal Waste & Recycling Database:** Free comprehensive taxonomy of solid waste materials with decomposition times, carbon savings, Lugbara translations (*Kopo kopo kabi kabi, Betiri kabi, Agbi*), market resale rates in UGX/kg, and 6 certified Arua recovery hubs.
- **Sack Count & Rule-Based Pricing Engine:** Real-time pricing calculations based on standardized municipal tariffs (1,500 UGX/sack for domestic household, 2,500 UGX/sack for commercial trading centers).
- **Mobile Money Digital Settlements:** Simulated MTN MoMo and Airtel Money digital payment workflows with official Arua City Council digital audit receipts.
- **Offline-First Resilience:** Employs persistent local storage (`SharedPreferences`) so the app operates continuously during network outages common in Northern Uganda.
- **Live Meteorological Safety Advisory:** Integrates REST APIs to alert riders when tropical rain or severe weather compromises unpaved murram roads in Arua.
- **GPS Device Integration:** Automatically evaluates device coordinates against the 12 km Arua service perimeter and assigns pickup zones without manual guesswork.

---

## 5. Core Features
| Feature Module | Description | Target User |
| :--- | :--- | :--- |
| **Smart Camera Auto-Scan** | Proximity-guided rubbish photo capture with automatic GPS lock and boundary check. | Resident |
| **Municipal Waste Database** | Free taxonomy of 12+ waste streams with Lugbara names, decomposition timelines, and UGX resale values. | All Users |
| **Pickup Order Engine** | Form with waste categorization, sack count (1–50), dynamic cost calculation in UGX, and GPS autofill. | Resident |
| **Zone Resolver** | Mathematical distance calculation determining 12 km municipal perimeter adherence and sector allocation. | Resident / Rider |
| **Rider Dispatch Queue** | Dynamic list of assigned stops; one-tap transition from *Requested* to *Collected* and *Awaiting Verification*. | Rider |
| **Admin Control Center** | Multi-step approval pipeline to verify sacks collected, settle payment, or return for reinspection. | Admin |
| **MoMo Digital Payments** | MTN MoMo / Airtel Money flow with official Arua City Council printable digital audit receipts. | Resident / Admin |
| **Live Route Weather** | Real-time weather API integration fetching temperature, wind speed, and road safety advisories. | Rider / Admin |
| **Multilingual Support** | Instant runtime language switching across English, native Lugbara, and Kiswahili. | All Users |
| **Persistent Session Auth** | Role-based authentication supporting persistent credentials and onboarding collection reminder policies. | All Users |

---

## 6. Project Scope
### Within Scope (14-Week Semester Deliverables):
- Full multi-role mobile application (Resident, Rider, Admin).
- Offline-first local data persistence with CRUD operations.
- Dynamic state machine preventing invalid status transitions.
- External REST API integration with graceful offline caching.
- GPS location verification and device capability integration.
- Camera viewfinder with proximity guidance and auto-capture.
- Open municipal solid waste and recycling database with World Bank benchmarks.
- Digital Mobile Money payment flows and audit receipts.
- Full automated test coverage (38 unit, domain rules, API mock, and widget tests).
- Production-ready Android APK configurations (both Debug and Release builds).

### Out of Scope (Future Roadmap):
- Hardware IoT ultrasonic fill sensors mounted inside physical street dumpsters.
- Direct live bank/telecom USSD automated gateway clearinghouse (simulated with verified MoMo confirmation codes).
- Cross-border municipal waste routing beyond the 12 km Arua City boundary.

---

## 7. Expected Value
- **Cleanliness & Health:** Drastic reduction in indiscriminate garbage dumping across Arua divisions.
- **Economic Fairness:** Transparent per-sack pricing (UGX) eliminates price gouging.
- **Circular Economy:** Residents discover the economic resale value of sorted plastics, scrap metal, and organic compost.
- **Operational Efficiency:** Riders reduce fuel and travel time by adhering to scheduled zone collection days.
- **Civic Governance:** Municipal authorities gain auditable, real-time data on waste generation and collection efficiency.
