# New Wheels Sales Analytics — Automotive / Transportation
### Enterprise SQL Analytics, Fulfillment Intelligence, & Strategic Turnaround Roadmap

[![MySQL 8.0](https://img.shields.io/badge/MySQL-8.0+-00758F?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com/)
[![SQL-Advanced](https://img.shields.io/badge/SQL-Advanced%20Analytics-4479A1?style=for-the-badge&logo=databricks&logoColor=white)](https://github.com/Rupesh4113/New-Wheels-Sales-Analytics-Automotive-Transportation)
[![Power BI / Tableau Ready](https://img.shields.io/badge/BI-Power%20BI%20%7C%20Tableau-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)](dashboard/dashboard_specification.md)
[![License-MIT](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

---

## 1. Executive Summary

New Wheels, a nationwide automotive distribution and retail enterprise, experienced severe business deterioration across calendar year 2024. Operating across 5 major geographic territories and 8 regional distribution hubs, the company observed a continuous Quarter-over-Quarter (QoQ) sales contraction, rising fulfillment delays, and precipitous declines in customer satisfaction (CSAT).

Management commissioned this comprehensive investigative analytics engagement to identify the empirical root causes of the business decline, evaluate supply chain bottlenecks, assess vehicle portfolio performance, audit commercial discount concessions, and provide actionable operational recommendations.

```
+----------------------------------------------------------------------------------------------------+
|                                    2024 PERFORMANCE SNAPSHOT                                       |
+------------------------------------+----------------------------------+----------------------------+
| TOTAL NET REVENUE:  $121,012,017.50| TOTAL ORDERS:              2,569 | COMPLETED ORDERS:    2,423 |
| TOTAL UNITS SOLD:             2,814| AVERAGE ORDER VALUE:  $47,104.72 | AVERAGE SELLING PRICE: $43K|
| OVERALL ON-TIME SLA:         74.29%| AVG DELIVERY DURATION: 4.06 DAYS | AVERAGE CSAT:   4.01 / 5.0 |
| DISCOUNT LEAKAGE:    $5,247,866.48 | TOP BOTTLENECKS:    DC-6 & DC-3  | PEARSON DELAY-CSAT: -0.8155|
+------------------------------------+----------------------------------+----------------------------+
```

### Core Business Findings:
1. **Sales Contraction Velocity**: Net realized revenue contracted by **-41.5%** from 2024-Q1 ($37.17M) to 2024-Q4 ($21.75M), with the sharpest contraction occurring in **Q3 (-22.36% QoQ)**.
2. **The Logistics Bottleneck**: In Q3, nationwide on-time delivery collapsed from **86.49% down to 56.70%** (a 29.79 percentage point deterioration), driven by severe operational congestion at two specific fulfillment nodes:
   - **Gulf Coast Fulfillment Center (DC-6 - Houston)**: 1,609 cumulative delay days (**47.20% of network total delays**; on-time rate: 59.68%).
   - **Midwest Central Terminal (DC-3 - Chicago)**: 695 cumulative delay days (**20.39% of network total delays**; on-time rate: 58.77%).
   - Combined, these two facilities account for **67.59%** of all customer transit delays across the enterprise.
3. **Severe CSAT Deterioration**: Customer satisfaction is strongly negatively associated with delivery delay days (**Pearson $r = -0.8155$, $p < 0.0001$, $N = 2,076$**). Orders delivered within 0-2 days achieved an average rating of **4.61 stars** (0% negative reviews), whereas orders delayed past 8 days suffered an average CSAT of **1.24 stars** (94.82% negative reviews).
4. **Repeat Purchase Decay**: Customers experiencing $>5$ days of delivery delay exhibited a repeat purchase rate of only **29.46%** (compared to **87.75%** for customers experiencing minor delays), cutting customer lifetime value by more than half.
5. **Commercial Discount Leakage**: In a misguided attempt to arrest falling volume, commercial sales teams escalated average discounts from **4.33%** in Q1 to **12.30%** in Q4. Price elasticity analysis reveals a negative correlation between discount % and net sales volume ($r = -0.1688$). This unconstrained panic discounting generated **$5,247,866.48** in direct margin leakage without reversing unit contraction.

---

## 2. Business Problem & Investigation Questions

Management framed the analytics mandate around seven diagnostic questions:
- **Why are sales declining, and which quarter experienced the largest deterioration?**
- **Are delivery delays contributing to lower customer satisfaction?**
- **Which vehicle models, classes, and styles perform best vs underperform?**
- **Which geographic regions are creating fulfillment bottlenecks?**
- **Which dispatch centers contribute disproportionately to delivery delays?**
- **Does delivery performance influence repeat purchasing and customer retention?**
- **Where is discount leakage occurring, and what is the recoverable margin opportunity?**

---

## 3. Technology Stack & SQL Architecture

- **Database Engine**: MySQL 8.0+ (InnoDB Storage Engine, UTF-8 `utf8mb4_unicode_ci`)
- **Advanced SQL Dialect**:
  - **Common Table Expressions (CTEs)**: Multi-layered staging, cohort timelines, and regional share benchmarks.
  - **Window Functions**: `LAG()` for QoQ momentum, `LEAD()` for customer purchase cycles, `ROW_NUMBER()` for regional champions, `RANK()` & `DENSE_RANK()` for bottleneck and revenue benchmarking.
  - **Relational Integrity**: Foreign key constraints with `ON DELETE RESTRICT` and `ON DELETE CASCADE`.
  - **Mathematical Statistics in Pure SQL**: Deterministic formulation of Pearson correlation coefficient ($r$).
  - **Query Performance & Optimization**: Execution plan analysis via `EXPLAIN ANALYZE`, composite indexing, and covering indexes.
- **Reporting & Business Intelligence**:
  - Standardized modular views for **Power BI / Tableau** consumption.
  - Production-grade dashboard wireframe and measure catalog.

---

## 4. Relational Data Model

The schema comprises 8 normalized entities designed for high-throughput OLTP execution and OLAP analytical querying:

```
                          +-------------------+
                          |  dispatch_centers |
                          +-------------------+
                                    | 1
                                    |
                                    | *
+-----------------+ 1       * +-------------+ *       1 +-----------------+
|    customers    |-----------|   orders    |-----------|    vehicles     |
+-----------------+           +-------------+           +-----------------+
         |                           | 1                         | 1
         | 1                         |                           |
         |                           | *                         | *
         |                    +-------------+           +-----------------+
         |                    | order_items |-----------|   (catalog)     |
         |                    +-------------+           +-----------------+
         |                           | 1
         | *                         | 1
+-------------------+         +-------------+ *       1 +-----------------+
| customer_feedback |---------|  shipping   |-----------|    carriers     |
+-------------------+         +-------------+           +-----------------+
```

### Entity Summary:
1. `dispatch_centers`: 8 regional fulfillment centers with monthly vehicle capacities and location metadata.
2. `carriers`: 5 contracted freight carriers with service regions and agreed Service Level Agreements (SLAs).
3. `customers`: 1,600 verified purchasing accounts across 5 geographic regions and 3 commercial segments.
4. `vehicles`: 20 distinct automobile models spanning 6 vehicle classes and 5 body styles.
5. `orders`: 2,569 validated, deduplicated customer vehicle orders across 2024.
6. `order_items`: Line-item verification of quantities, unit list prices, and line discounts.
7. `shipping`: Granular transit logs tracking dispatch dates, promised SLA dates, actual delivery, and delay days.
8. `customer_feedback`: 2,139 survey responses recording numerical ratings (1-5), sentiments, and verbatim feedback.

---

## 5. Repository Project Structure

```
new-wheels-sales-analytics/
│
├── README.md                                 # Executive presentation, architecture & reproduction guide
├── requirements.txt                          # Python dependencies for automation & notebooks
│
├── data/
│   ├── raw/                                  # Raw synthetic automotive transactional CSVs
│   │   ├── dispatch_centers.csv
│   │   ├── carriers.csv
│   │   ├── customers.csv
│   │   ├── vehicles.csv
│   │   ├── orders.csv
│   │   ├── order_items.csv
│   │   ├── shipping.csv
│   │   └── customer_feedback.csv
│   └── processed/                            # Staging directory for cleaned exports
│
├── sql/
│   ├── 01_create_database.sql                # Database initialization & session parameters
│   ├── 02_create_tables.sql                  # DDL with Primary Keys, Foreign Keys & Constraints
│   ├── 03_load_data.sql                      # Batch DML loading script for all entities
│   ├── 04_data_quality.sql                   # Referential integrity, NULLs, duplicate audits
│   ├── 05_data_cleaning.sql                  # Staging deduplication & defensible survey views
│   ├── 06_exploratory_analysis.sql           # Baseline aggregations across Sales, Customer, Fulfillment
│   ├── 07_window_functions.sql               # LAG, LEAD, ROW_NUMBER, RANK, DENSE_RANK
│   ├── 08_customer_retention.sql             # Cohort retention, interpurchase cadence, customer LTV
│   ├── 09_delivery_sla.sql                   # Transit duration buckets (0-2, 3-5, 6-8, >8 days) & breaches
│   ├── 10_vehicle_analysis.sql               # Vehicle quadrant matrix & dispatch bottleneck rankings
│   ├── 11_regional_analysis.sql              # Regional performance & vehicle style demand ratio
│   ├── 12_discount_analysis.sql              # Margin erosion, elasticity failure, & discount leakage
│   ├── 13_correlation_analysis.sql           # Exact Pearson correlation calculations in pure SQL
│   ├── 14_analytical_views.sql               # 5 standardized production BI reporting views
│   └── 15_query_optimization.sql             # EXPLAIN ANALYZE execution plans & index benchmarking
│
├── dashboard/
│   └── dashboard_specification.md            # Power BI / Tableau architecture, DAX measures & wireframes
│
├── notebooks/
│   └── supplementary_analysis.ipynb          # Python EDA, statistical validation & walkthrough
│
├── docs/
│   ├── data_dictionary.md                    # Column-level data dictionary & constraints
│   ├── methodology.md                        # Formulations, survey ethics, & causal boundaries
│   └── business_recommendations.md           # Strategic initiatives with KPI impact matrix
│
└── scripts/
    ├── generate_data.py                      # Realistic automotive dataset synthesis
    ├── generate_sql_inserts.py               # Generates standalone DML batch loading script
    └── benchmark_optimization.py             # Multi-run query latency benchmarking harness
```

---

## 6. Key Analytical Findings

### 6.1 Quarterly Executive Scorecard (`sql/07_window_functions.sql`)

Calculated directly from the live database using `LAG()` window functions:

| Quarter | Orders | Units | Net Revenue ($) | QoQ Rev Growth % | On-Time % | Avg Delivery Days | Avg CSAT | Repeat Order Rate % |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **2024-Q1** | 749 | 827 | $37,173,425.33 | *Baseline* | 87.32% | 3.07 | 4.40 | 83.85% |
| **2024-Q2** | 681 | 735 | $32,442,567.88 | **-12.73%** | 86.49% | 3.06 | 4.37 | 82.39% |
| **2024-Q3** | 552 | 607 | $25,188,011.46 | **-22.36%** | **56.70%** | **5.39** | **3.50** | 78.91% |
| **2024-Q4** | 492 | 541 | $21,749,047.54 | **-13.65%** | 57.32% | 5.46 | 3.49 | 77.06% |

> **Takeaway**: Q3 experienced the most severe collapse across every metric: revenue dropped by **-$7.25M (-22.36% QoQ)**, on-time delivery plummeted by **-29.79 percentage points**, average transit duration increased by **+2.33 days**, and customer rating dropped by **-0.87 points**.

---

### 6.2 Fulfillment Transit Buckets vs Customer CSAT & Loyalty (`sql/09_delivery_sla.sql`)

| Transit Duration Bucket | Orders | Total Net Revenue | Avg Delivery Days | Avg Delay Days | Rated Orders | Avg CSAT Rating | Dissatisfied % (1-2 Stars) | Repeat Order Share % |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **0-2 Days** | 919 | $43,980,557.83 | 1.6 | 0.0 | 775 | **4.61** | **0.00%** | 82.05% |
| **3-5 Days** | 1,119 | $53,074,823.51 | 3.8 | 0.4 | 935 | **4.40** | **4.28%** | 82.57% |
| **6-8 Days** | 204 | $9,544,673.80 | 7.0 | 4.0 | 173 | **2.31** | **60.12%** | 80.39% |
| **>8 Days** | 232 | $9,952,997.07 | 12.3 | 9.3 | 193 | **1.24** | **94.82%** | **71.55%** |
| *Cancelled* | 95 | $4,458,965.29 | 0.0 | 0.0 | 0 | *N/A* | *N/A* | 76.84% |

---

### 6.3 Dispatch Center Bottleneck Ranking (`sql/10_vehicle_analysis.sql`)

Ranked by cumulative delay days using window ranking functions:

| Bottleneck Rank | Dispatch Center Name | Region | City | Shipments Handled | Late Shipments | On-Time Rate % | Cumulative Delay Days | Share of Network Delays % | Operational Risk Tier |
| :---: | :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **1** | **Gulf Coast Fulfillment Center** | Southeast | Houston, TX | 496 | 200 | **59.68%** | **1,609** | **47.20%** | **Severe Bottleneck Tier 1** |
| **2** | **Midwest Central Terminal** | Midwest | Chicago, IL | 211 | 87 | **58.77%** | **695** | **20.39%** | **Severe Bottleneck Tier 1** |
| **3** | Northeast Distribution Hub | Northeast | Newark, NJ | 518 | 99 | 80.89% | 307 | 9.01% | Moderate Bottleneck Tier 2 |
| **4** | Pacific Gateway Facility | West | Los Angeles, CA | 279 | 59 | 78.85% | 196 | 5.75% | Stable Operational Tier 3 |
| **5** | Southwest Freight Depot | Southwest | Dallas, TX | 250 | 53 | 78.80% | 181 | 5.31% | Stable Operational Tier 3 |
| **6** | Southeast Logistics Center | Southeast | Atlanta, GA | 249 | 51 | 79.52% | 163 | 4.78% | Stable Operational Tier 3 |
| **7** | Great Lakes Transit Hub | Midwest | Detroit, MI | 233 | 46 | 80.26% | 131 | 3.84% | Stable Operational Tier 3 |
| **8** | Northwest Regional Center | West | Seattle, WA | 238 | 41 | 82.77% | 127 | 3.73% | Stable Operational Tier 3 |

> **Key Operational Insight**: **DC-6 (Houston)** and **DC-3 (Chicago)** combined contributed **2,304 out of 3,409 total network delay days (67.59%)**. Interventions focused exclusively on these two facilities will resolve two-thirds of all fulfillment delays nationwide.

---

### 6.4 Statistical Correlation Analysis (`sql/13_correlation_analysis.sql`)

| Relationship Evaluated | Sample Size ($N$) | Pearson Correlation ($r$) | Direction | Strength | Causal & Business Interpretation |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Delivery Delay Days vs Customer CSAT** | 2,076 | **-0.8155** | Negative | **Strong** | Extreme negative association: transit delays reliably coincide with severe rating deterioration. Correlation proves strong co-occurrence, while survey text supports causal dissatisfaction. |
| **Discount % vs Net Sales Amount** | 2,569 | **-0.1688** | Negative | Weak | Price elasticity failure: higher commercial discount percentages failed to drive higher sales volume, establishing clear discount leakage. |
| **Delay Exposure vs Repeat Purchase** | 1,207 | **-0.1053** | Negative | Weak | Customers experiencing chronic delivery delays exhibit lower repeat purchase likelihood. |
| **Customer CSAT vs Repeat Purchase** | 1,120 | **+0.0888** | Positive | Weak | Higher satisfaction positively influences customer account retention. |

---

### 6.5 Commercial Discount Leakage Audit (`sql/12_discount_analysis.sql`)

- **Healthy Baseline Anchor (2024-Q1)**: **4.3344%** average discount.
- **Total Gross Catalog Revenue**: **$164,939,000.00**
- **Total Discounts Actually Granted**: **$12,396,982.50** (7.52% overall rate)
- **Baseline Allowable Discount**: **$7,149,116.02**
- **Unconstrained Discount Leakage**: **$5,247,866.48** (**42.33% of all discount expenditure!**)
- **Quarterly Leakage Escalation**:
  - Q1: $2,243.60
  - Q2: $471,039.37
  - Q3: $2,118,918.23
  - Q4: $2,662,922.60

---

## 7. Query Performance & Optimization Benchmarking (`sql/15_query_optimization.sql`)

A multi-table analytical query joining `orders`, `vehicles`, `shipping`, and `customer_feedback` with temporal filtering and aggregation was benchmarked before and after custom indexing.

```
+----------------------------------------------------------------------------------------------------+
|                                    QUERY OPTIMIZATION SUMMARY                                      |
+------------------------------------+----------------------------------+----------------------------+
| METRIC                             | BEFORE OPTIMIZATION (BASELINE)   | AFTER TARGETED INDEXING    |
+------------------------------------+----------------------------------+----------------------------+
| Query Execution Latency (Internal) | 68.10 ms                         | 41.10 ms                   |
| Absolute Latency Improvement       | -27.00 ms                        | (Reduced by 39.6%)         |
| Execution Speedup Factor           | 1.00x                            | 1.66x Faster               |
| Access Method: orders              | Full Table Scan (cost=261, n=2570) Index Lookup via vehicle_id |
| Access Method: customer_feedback   | Full Index Scan                  | Covering Index Lookup      |
| Access Method: shipping            | Standard Join                    | Composite Index Condition  |
+------------------------------------+----------------------------------+----------------------------+
```

### Applied Indexes:
```sql
CREATE INDEX idx_orders_date_region_veh ON orders (order_date, order_region, vehicle_id);
CREATE INDEX idx_orders_cust_date ON orders (customer_id, order_date);
CREATE INDEX idx_shipping_order_status ON shipping (order_id, delivery_status);
CREATE INDEX idx_shipping_dc_delay ON shipping (dispatch_center_id, delay_days, delivery_days);
CREATE INDEX idx_feedback_order_rating ON customer_feedback (order_id, rating);
CREATE INDEX idx_customers_region_seg ON customers (region, customer_segment);
```

---

## 8. Strategic Management Recommendations

| # | Action Area | Finding & Diagnosis | Recommended Management Action | Expected KPI Impact |
| :---: | :--- | :--- | :--- | :--- |
| **1** | **Fulfillment Reallocation** | DC-6 (Houston) & DC-3 (Chicago) generate **67.6% of network delays**. | Re-route 35% of DC-6 volume to DC-2 (Atlanta); divert 40% of DC-3 volume to DC-7 (Detroit). | **-45% reduction in delay days**; On-time rate restored to **>= 82%**. |
| **2** | **Discount Discipline** | **$5.25M in discount leakage** caused by panic discounting with zero volume elasticity ($r = -0.1688$). | Enforce a hard **5.0% discount ceiling**; eliminate discounting on bottlenecked vehicles. | **+$3.8M to $5.2M margin recovery**; stabilize ASP at >$47,500. |
| **3** | **Proactive CSAT Recovery** | CSAT collapses to **1.24** on orders taking >8 days ($r = -0.8155$). | Automated SMS/Email outreach at **Day 4** with revised timeline + $250 credit. | Delayed order CSAT improved to **>= 2.80**; repeat rate up +15% pts. |
| **4** | **Regional Inventory Alignment**| Full-Size Trucks dominate Midwest (40% share); EVs dominate West (Zenith E-Crown: $3.3M). | Rebalance factory replenishment to match empirical regional demand ratios. | Cross-region freight costs down **30%**; fulfillment time reduced by 1.2 days. |
| **5** | **Carrier SLA Enforcement**| Carriers 4 & 5 breach SLA on **21.03% of shipments**. | Implement 5% freight fee clawbacks on severe breaches; shift volume to Carrier 3. | **$320,000 annual freight recovery**; carrier compliance up +10% pts. |

---

## 9. How to Reproduce the Project

### Prerequisites
- MySQL Server 8.0+ installed and running.
- Python 3.9+ installed.

### Step-by-Step Execution Guide

#### Step 1: Clone Repository
```bash
git clone https://github.com/Rupesh4113/New-Wheels-Sales-Analytics-Automotive-Transportation.git
cd New-Wheels-Sales-Analytics-Automotive-Transportation
```

#### Step 2: Generate Raw Transactional Data
```bash
python scripts/generate_data.py
python scripts/generate_sql_inserts.py
```

#### Step 3: Execute MySQL Analytics Scripts
Run the SQL scripts sequentially using the MySQL CLI client:
```bash
# 1. Initialize Database & Session
mysql -h 127.0.0.1 -P 3306 -u root -p < sql/01_create_database.sql

# 2. Build Relational DDL Schema
mysql -h 127.0.0.1 -P 3306 -u root -p new_wheels_db < sql/02_create_tables.sql

# 3. Ingest All Transactional Records
mysql -h 127.0.0.1 -P 3306 -u root -p new_wheels_db < sql/03_load_data.sql

# 4. Run Data Quality & Integrity Audit
mysql -h 127.0.0.1 -P 3306 -u root -p new_wheels_db < sql/04_data_quality.sql

# 5. Build Clean Analytical Staging Views
mysql -h 127.0.0.1 -P 3306 -u root -p new_wheels_db < sql/05_data_cleaning.sql

# 6. Execute Exploratory SQL Analytics
mysql -h 127.0.0.1 -P 3306 -u root -p new_wheels_db < sql/06_exploratory_analysis.sql

# 7. Execute Advanced Window Function Modules (LAG, LEAD, RANK)
mysql -h 127.0.0.1 -P 3306 -u root -p new_wheels_db < sql/07_window_functions.sql

# 8. Customer Retention & Cohort Analytics
mysql -h 127.0.0.1 -P 3306 -u root -p new_wheels_db < sql/08_customer_retention.sql

# 9. Delivery SLA & Transit Duration Bucketing
mysql -h 127.0.0.1 -P 3306 -u root -p new_wheels_db < sql/09_delivery_sla.sql

# 10. Vehicle Performance Matrix & Bottlenecks
mysql -h 127.0.0.1 -P 3306 -u root -p new_wheels_db < sql/10_vehicle_analysis.sql

# 11. Cross-Regional Performance & Style Demand Ratios
mysql -h 127.0.0.1 -P 3306 -u root -p new_wheels_db < sql/11_regional_analysis.sql

# 12. Commercial Discount Leakage Audit
mysql -h 127.0.0.1 -P 3306 -u root -p new_wheels_db < sql/12_discount_analysis.sql

# 13. Statistical Pearson Correlation Calculations
mysql -h 127.0.0.1 -P 3306 -u root -p new_wheels_db < sql/13_correlation_analysis.sql

# 14. Compile Production BI Views
mysql -h 127.0.0.1 -P 3306 -u root -p new_wheels_db < sql/14_analytical_views.sql

# 15. Benchmark Query Optimization & Indexing
mysql -h 127.0.0.1 -P 3306 -u root -p new_wheels_db < sql/15_query_optimization.sql
```

#### Step 4: Run Optimization Benchmark Harness (Optional)
```bash
python scripts/benchmark_optimization.py
```

---

## 10. Future Enhancements

1. **Predictive Delivery Delay Modeling**: Develop a gradient-boosted classifier (e.g., LightGBM) utilizing weather, carrier lead times, and dispatch center utilization to forecast fulfillment delays at order checkout.
2. **Automated Dynamic Repricing Engine**: Replace static discretionary sales discounts with an algorithmic pricing model that adjusts vehicle promotions based on real-time inventory holding duration and regional demand indices.
3. **Real-Time Streaming Pipeline**: Transition batch SQL ingestion to an event-driven Kafka / Debezium Change Data Capture (CDC) pipeline streaming directly into analytical OLAP views.

---

## License
Distributed under the MIT License. See `LICENSE` for more information.
---

## 11. Interactive Streamlit Dashboard Deployment

The project includes an executive-grade interactive **Streamlit web application** (`app.py`) featuring dynamic KPI cards, interactive cross-filters, Plotly visualizations, and relational data explorers.

### Launch Streamlit Locally:
```bash
python -m streamlit run app.py
```
The app will automatically open at `http://localhost:8501`.

### 1-Click Streamlit Community Cloud Deployment:
1. Push repository to GitHub.
2. Visit [share.streamlit.io](https://share.streamlit.io/).
3. Connect repository `New-Wheels-Sales-Analytics-Automotive-Transportation` with main file path `app.py`.
4. Click **Deploy**. (Zero database configuration needed: the app automatically serves from clean cached transactional data!).

### Containerized Docker Deployment:
```bash
docker build -t new-wheels-analytics .
docker run -p 8501:8501 new-wheels-analytics
```