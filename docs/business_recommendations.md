# Strategic Business Recommendations: New Wheels Sales Analytics
## Executive Action Plan & Operational Turnaround Roadmap

---

### Executive Overview
The quantitative investigation into New Wheels identifies a critical intersection between logistics fulfillment bottlenecks, customer satisfaction decay, regional inventory mismatches, and unconstrained commercial discount leakage.

Each strategic initiative below adheres to the required executive decision framework:
$$\text{Empirical Finding} \longrightarrow \text{Business Implication} \longrightarrow \text{Recommended Action} \longrightarrow \text{Expected KPI Impact}$$

---

### 1. Logistics Fulfillment & Network Re-Engineering

#### Recommendation 1.1: Reallocate Volume from Bottleneck Facilities (DC-6 & DC-3)
- **Empirical Finding**: 
  - **Gulf Coast Fulfillment Center (DC-6 - Houston)** generated **1,609 delay days (47.20% of network total)** with an on-time delivery rate of only **59.68%**.
  - **Midwest Central Terminal (DC-3 - Chicago)** generated **695 delay days (20.39% of network total)** with an on-time delivery rate of **58.77%**.
  - Combined, these two facilities contribute **67.59%** of all network transit delays.
- **Business Implication**: Severe warehouse congestion, labor constraints, and carrier scheduling friction at DC-6 and DC-3 are creating an operational bottleneck that damages company-wide fulfillment.
- **Recommended Action**:
  - Immediately reallocate 35% of DC-6 shipment volume to **Southeast Logistics Center (DC-2 - Atlanta)**, which currently maintains a 79.52% on-time delivery rate and operates under capacity.
  - Divert 40% of DC-3 upper Midwest shipments to **Great Lakes Transit Hub (DC-7 - Detroit)**, which achieves an 80.26% on-time rate and 3.31-day average transit.
  - Implement a dynamic capacity throttling rule in the Order Management System (OMS): when a dispatch center exceeds 85% monthly capacity, automatically re-route incoming orders to adjacent regional nodes.
- **Expected KPI Impact**:
  - **-45% reduction** in network delay days within 60 days.
  - On-time delivery rate recovery from **57.32% back to >= 82.00%**.
  - Network average delivery duration reduced from **5.46 days to < 3.8 days**.

#### Recommendation 1.2: Carrier SLA Renegotiation & Performance Clawbacks
- **Empirical Finding**: 
  - **Velocity Transporters (Carrier 4)** and **PrimeRoute Haulers (Carrier 5)** suffer the lowest on-time delivery rates (**71.96%** and **72.78%** respectively) and the highest severe SLA breach rates (both **21.03%**).
  - In contrast, **TransNational Express (Carrier 3)** achieves a **77.46%** on-time rate.
- **Business Implication**: Fixed freight contracts fail to penalize carrier underperformance, shifting customer dissatisfaction directly onto the New Wheels brand.
- **Recommended Action**:
  - Implement tiered freight contracts with liquidated damages: enforce a 5% freight rate clawback for every order breaching contracted SLA by >= 3 days.
  - Shift carrier volume allocation dynamically: reward Carriers 1 and 3 with 60% baseline allocation, while capping Carriers 4 and 5 at 20% conditional on monthly SLA adherence >= 80%.
- **Expected KPI Impact**:
  - **$320,000 annual freight recovery** via SLA breach penalty clauses.
  - Carrier compliance increase of **+8 to 12 percentage points**.

---

### 2. Customer Experience & Proactive Retention Workflows

#### Recommendation 2.1: Automated Service Recovery Outreach at Day 5 Transit Threshold
- **Empirical Finding**: 
  - Transit duration exhibits a tipping point: orders delivered within 0-5 days achieve **4.40 - 4.61 CSAT** (dissatisfaction < 5%).
  - At 6-8 days, average CSAT plummets to **2.31** (60.12% negative reviews).
  - At >8 days, CSAT collapses to **1.24** (94.82% negative reviews), and subsequent repeat purchasing drops by more than half (from 56.37% down to 23.71%).
  - Pearson correlation confirms a strong negative association: $r = -0.8155$ ($p < 0.0001$).
- **Business Implication**: Silence during fulfillment delays creates customer resentment. By the time a delayed vehicle is delivered, customer churn is already cemented.
- **Recommended Action**:
  - Deploy an automated webhook from MySQL shipping tracking to the CRM: the moment a shipment exceeds **Day 4 without out-for-delivery status**, trigger an automated "White-Glove Service Recovery" alert.
  - Proactively send an SMS/Email to the buyer with realistic revised delivery dates, a dedicated concierge direct contact, and an immediate $250 vehicle accessory or maintenance credit.
- **Expected KPI Impact**:
  - Mitigate extreme customer ratings: elevate >6 day transit CSAT from **1.24 up to >= 2.80**.
  - Recover repeat purchase probability on delayed cohorts from **23.71% to >= 38.00%**.

---

### 3. Commercial Governance & Discount Leakage Elimination

#### Recommendation 3.1: Enforce Strict Commercial Discount Guardrails
- **Empirical Finding**: 
  - In 2024-Q1, enterprise discount rate was **4.33%** ($2.21M).
  - By Q3 and Q4, panic discounting escalated to **10.09%** ($3.71M) and **12.30%** ($4.11M).
  - Despite increasing concessions by nearly 3x, net sales volume dropped by **-22.36%** in Q3 and **-13.65%** in Q4.
  - Price elasticity correlation is negative ($r = -0.1688$), establishing that discounts failed to stimulate demand.
  - Total unconstrained discount leakage represents **$5,247,866.48** (42.33% of total discount spend).
- **Business Implication**: Sales reps and regional managers utilized discretionary discounting to compensate for macro and fulfillment headwinds, destroying gross margin without saving volume.
- **Recommended Action**:
  - Re-establish a mandatory corporate discount ceiling of **5.0%** for standard retail sales.
  - Require Vice President of Sales approval for any commercial discount exceeding 7.5%.
  - Strictly prohibit discounting on vehicles currently experiencing warehouse fulfillment delays (e.g., luxury Zenith models shipping through DC-6).
- **Expected KPI Impact**:
  - Direct margin recapture of **$3.8M - $5.2M annually** in avoided discount leakage.
  - Immediate stabilization of Average Selling Price (ASP) above **$47,500**.

---

### 4. Supply Chain & Inventory Alignment

#### Recommendation 4.1: Align Regional Inventory with Empirical Demand Ratios
- **Empirical Finding**: 
  - **Midwest**: Full-Size Trucks and SUVs dominate sales (**40.04%** style share). Terra Hauler HD and Terra Titan 1500 generate over **$4.15M** in regional sales.
  - **West**: Electric Vehicles and Sedans dominate (Zenith E-Crown and Apex Storm EV generate **$5.90M**).
  - **Northeast**: Luxury and Sport Coupes over-index with a **1.28x demand ratio**.
- **Business Implication**: Maintaining uniform vehicle inventory across national hubs leads to stockouts of high-demand regional styles and excess carrying costs of slow-moving inventory.
- **Recommended Action**:
  - Restructure factory dispatch allocations:
    - Increase Full-Size Truck and SUV allocations to Midwest (DC-3, DC-7) and Southwest (DC-4) by **+25%**.
    - Concentrate EV inventory (Zenith E-Crown, Apex Storm EV) at Pacific Gateway (DC-5) and Northwest (DC-8).
    - Position Luxury Coupes in Northeast Distribution Hub (DC-1).
- **Expected KPI Impact**:
  - Cross-regional fulfillment transfers reduced by **30%**.
  - Regional order fulfillment velocity accelerated by **1.2 days**.
  - Local stockout cancellations reduced from 3.7% to < 1.0%.

---

### 5. Implementation Roadmap & Governance Matrix

| Initiative | Owner | Timeline | Milestone Metric | Financial / KPI Goal |
| :--- | :--- | :--- | :--- | :--- |
| **Fulfillment Volume Reallocation** | VP Supply Chain | Weeks 1 - 4 | DC-6 volume throttled to <= 75% capacity | Delay days reduced by 45% |
| **Commercial Discount Cap (5.0%)** | Chief Commercial Officer | Immediate | OMS hard discount ceiling configured | $5.25M margin leakage stopped |
| **Automated Day 4 CSAT Recovery** | VP Customer Experience | Weeks 2 - 6 | CRM tracking webhook deployed | CSAT on delayed orders >= 2.80 |
| **Regional Inventory Rebalancing** | Director Demand Planning| Weeks 4 - 8 | Factory replenishment rules aligned | Regional transit time < 3.5 days |
| **Carrier SLA Penalty Enforcement** | VP Logistics | Weeks 6 - 10| Carrier contracts amended with clawbacks | On-time rate restored to >= 82% |