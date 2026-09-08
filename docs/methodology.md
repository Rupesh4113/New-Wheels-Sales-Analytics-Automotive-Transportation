# Analytical Methodology: New Wheels Sales Analytics
## Quantitative Framework, Statistical Formulations & Causal Boundaries

---

### 1. Executive Analytics Framework
The New Wheels Sales Analytics project investigates multi-dimensional organizational decay across commercial sales, logistics execution, and customer loyalty. Rather than relying on high-level averages or black-box modeling, this investigation utilizes an end-to-end relational data architecture implemented entirely within MySQL 8.0+.

The analytical pipeline follows an enterprise methodology:
1. Relational Data Ingestion & Integrity Auditing
2. Defensive Data Cleaning & Staging
3. Exploratory Dimension Slicing
4. Advanced Window Function Computations
5. Fulfillment SLA & Bottleneck Decomposition
6. Commercial Discount Leakage Quantification
7. Empirical Statistical Verification

---

### 2. Defensible Handling of Missing Customer Feedback Ratings
A critical pitfall in survey analytics is the arbitrary imputation of missing survey values (e.g., replacing unrated surveys with 0). 

#### Why Zero-Imputation is Analytically Defective:
1. **Scale Distortion**: The customer satisfaction survey operates on a standard Likert scale from 1 (Very Negative) to 5 (Very Positive). Assigning a value of 0 introduces an artificial data point below the theoretical minimum of the scale, drastically skewing summary statistics downward.
2. **Non-Response Bias Distortion**: A missing rating represents survey non-response (Missing at Random or Missing Not at Random due to indifference), not an explicit evaluation of catastrophic failure. Conflating non-response with extreme dissatisfaction corrupts statistical modeling.

#### Implemented Methodology:
- **Clean Staging View (stg_clean_feedback)**: Unrated records are preserved as NULL in the numerical rating column while being tagged with the explicit qualitative status 'Unrated / Survey Non-Response' in satisfaction_category.
- **SQL Aggregation Handling**: Standard SQL functions (AVG(rating), COUNT(rating)) naturally omit NULL values from the numerator and denominator, preserving unbiased empirical mean ratings across quarters, vehicle classes, and delivery transit buckets.

---

### 3. Correlation vs. Causation Demarcation
Senior analytical rigor requires explicitly distinguishing between mathematical correlation and empirical causation:

> **Core Principle**: A strong statistical correlation between delivery delay days and customer CSAT (r = -0.8155) establishes that customer dissatisfaction reliably coincides with transit delays. It does **not** prove that delivery delays are the sole causal driver of company-wide sales contraction.

- **Fulfillment vs. CSAT**: The empirical data demonstrates that customers experiencing >8 days transit give an average rating of 1.24 stars (94.8% negative). While logistics delays directly deteriorate post-purchase sentiment, sales contraction from Q1 ($37.17M) to Q4 ($21.75M) is simultaneously compounded by declining initial order volume, regional product-style mismatches, and macro automotive market softening.
- **Repeat Purchase Behavior**: Repurchase rates drop from 56.37% (0-2 days transit) to 23.71% (>8 days transit). Fulfillment friction damages customer retention, but does not explain first-time customer acquisition slowdowns.

---

### 4. Advanced Window Function Formulations

#### 4.1 Longitudinal Quarter-over-Quarter (QoQ) Deltas via LAG()
To evaluate the velocity of business deterioration, quarterly metrics are compared to the immediate preceding period:
QoQ Growth % = ((Current Quarter - Previous Quarter) / Previous Quarter) * 100

#### 4.2 Repurchase Interval & Churn Tracking via LEAD()
By projecting the subsequent order timestamp for each customer partition, the pipeline measures customer purchase cycles and days between transactions.

#### 4.3 Distinct Ranking Behaviors (ROW_NUMBER, RANK, DENSE_RANK)
- **ROW_NUMBER()**: Generates unique, strictly sequential integer ranks per partition without ties. Used to isolate the #1 vehicle model per region and the most recent customer order.
- **RANK()**: Evaluates competitive order volume and revenue where tied values receive identical ranks, followed by a gap in ranking sequence (e.g., 1, 2, 2, 4). Used to benchmark dispatch center total delay volumes.
- **DENSE_RANK()**: Evaluates tied performance metrics without ordinal gaps (e.g., 1, 2, 2, 3). Used for vehicle revenue tiering.

---

### 5. Delivery Transit Duration Bucketing & SLA Breaches
Fulfillment performance is segmented into 4 discrete operational transit buckets based on calendar elapsed days from fulfillment center dispatch to customer delivery:
1. **0-2 Days (Rapid Fulfillment)**: Best-in-class logistics execution. (Avg CSAT: 4.61)
2. **3-5 Days (Standard SLA)**: Contracted standard freight transit. (Avg CSAT: 4.40)
3. **6-8 Days (Delayed Transit)**: Operational friction and early SLA breaches. (Avg CSAT: 2.31)
4. **>8 Days (Severe Failure)**: Systemic breakdown, carrier failure, or warehouse stagnation. (Avg CSAT: 1.24)

SLA breaches are calculated relative to carrier contractual commitments:
delay_days = GREATEST(0, actual_delivery_date - promised_delivery_date)

---

### 6. Transparent Discount Leakage Audit Methodology
Discount leakage represents the destruction of operating margin through commercial price concessions that fail to stimulate compensatory unit volume elasticity.

#### Methodological Baseline:
1. **Healthy Operational Anchor**: In **2024-Q1**, New Wheels operated under disciplined commercial controls, realizing an enterprise discount rate of **4.3344%** ($2.21M discount on $50.92M gross sales).
2. **Panic Discount Escalation**: In response to falling sales in Q3 and Q4, management escalated discounting to **10.09%** in Q3 and **12.30%** in Q4.
3. **Leakage Formula**: Any discount expenditure exceeding the healthy Q1 baseline rate represents unconstrained discount leakage:
Baseline Allowable Discount = Gross List Revenue * 0.043344
Estimated Discount Leakage = Actual Discount Granted - Baseline Allowable Discount

#### Empirical Finding:
- Total Discounts Granted: **$12,396,982.50**
- Baseline Allowable Discount: **$7,149,116.02**
- **Unconstrained Discount Leakage: $5,247,866.48 (42.33% of all discount spend)**.
- Price elasticity testing reveals a negative correlation between discount % and net sales volume (r = -0.1688), confirming that aggressive discounting failed to generate incremental sales.

---

### 7. Pure SQL Pearson Correlation Coefficient Derivation
To ensure 100% database reproducibility, Pearson's product-moment correlation coefficient (r) is calculated natively in MySQL 8.0 without external math libraries:
r = (N * SUM(xy) - SUM(x)*SUM(y)) / (SQRT(N*SUM(x^2) - (SUM(x))^2) * SQRT(N*SUM(y^2) - (SUM(y))^2))