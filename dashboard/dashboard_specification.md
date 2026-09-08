# Executive Dashboard Specification: New Wheels Sales Analytics
## Automotive Sales, Customer Satisfaction & Fulfillment Intelligence

---

## 1. Executive Summary & Dashboard Architecture

This document provides the complete Business Intelligence (BI) architectural specification for the **New Wheels Sales Analytics Executive Dashboard**, designed for cross-platform deployment in **Microsoft Power BI**, **Tableau**, or modern cloud BI platforms (Looker, Preset/Superset).

The dashboard ingests data directly from the curated MySQL 8.0 analytical views (w_quarterly_sales_performance, w_customer_retention, w_delivery_sla, w_vehicle_performance, and w_dispatch_center_performance). It translates multi-table relational intelligence into a unified command center for C-suite and VP-level stakeholders across Operations, Supply Chain, Commercial Sales, and Customer Experience.

`
+----------------------------------------------------------------------------------------------------+
| HEADER: New Wheels Sales Analytics | Automotive Sales, CSAT & Fulfillment Intelligence            |
+----------------------------------------------------------------------------------------------------+
| KPI CARDS:                                                                                         |
| [ Total Net Revenue ] [ Total Orders ] [ Total Units ] [ QoQ Revenue Growth ]                     |
|     .01M              2,569            2,814             -22.36% (Q3)                          |
| [ Average CSAT ]     [ On-Time Delivery ] [ Repeat Buyer Rate ] [ Avg Delivery Duration ]          |
|      4.01 / 5.0             74.29%              60.29%                 4.06 Days                   |
+--------------------------------------------------+-------------------------------------------------+
| VISUALIZATION 1: Quarterly Sales & Growth Trend  | VISUALIZATION 2: Demand Volume vs SLA Breakdown |
| (Dual-Axis: Revenue Bars + QoQ Growth Line)      | (Orders Line vs On-Time Fulfillment % Line)     |
+--------------------------------------------------+-------------------------------------------------+
| VISUALIZATION 3: Transit Latency vs CSAT Impact  | VISUALIZATION 4: Vehicle Portfolio Matrix       |
| (Scatter Plot: Delay Days vs Customer Rating,    | (Strategic Quadrant: Revenue vs Rating vs Qty)  |
|  Pearson r = -0.8155 with Fitted OLS Trendline)  |                                                 |
+--------------------------------------------------+-------------------------------------------------+
| VISUALIZATION 5: Cross-Regional Performance Map  | VISUALIZATION 6: Dispatch Bottleneck Ranking    |
| (Matrix: Sales, On-Time %, CSAT, Style Demand)   | (Horizontal Bars: Delay Share %, DC-6 & DC-3)   |
+--------------------------------------------------+-------------------------------------------------+
`

---

## 2. Global Canvas & Theme Palette

- **Canvas Size**: 1920 x 1080 px (16:9 Standard High-Definition)
- **Background**: #0F172A (Slate Navy 900)
- **Card / Container Background**: #1E293B (Slate Navy 800) with #334155 1px border, 8px border-radius
- **Typography**: 
  - Primary Font: *Inter*, *Segoe UI*, or *Roboto*
  - KPI Hero Numbers: 28pt Bold, #F8FAFC
  - Chart Titles: 14pt Semi-Bold, #94A3B8
  - Axis Labels: 10pt Regular, #64748B
- **Color Coding**:
  - Positive / Target: #10B981 (Emerald Green)
  - Warning / Moderate: #F59E0B (Amber Orange)
  - Critical Bottleneck / Breach: #EF4444 (Crimson Red)
  - Primary Corporate Accent: #3B82F6 (Electric Blue)
  - Secondary Accent: #8B5CF6 (Royal Purple)

---

## 3. Executive KPI Cards (Top Banner)

| KPI Card | Metric Definition | Actual Calculated Value | SQL Source View & Expression | DAX / Calculated Measure |
| :--- | :--- | :--- | :--- | :--- |
| **Total Net Revenue** | Net recognized automotive sales after discounts | **,012,017.50** | w_quarterly_sales_performance: SUM(total_net_revenue) | Total Net Revenue = SUM(vw_quarterly_sales_performance[total_net_revenue]) |
| **Total Orders** | Clean, deduplicated completed/active orders | **2,569** | stg_clean_orders: COUNT(order_id) | Total Orders = DISTINCTCOUNT(stg_clean_orders[order_id]) |
| **Total Units Sold** | Total physical vehicles delivered/transacted | **2,814** | stg_clean_orders: SUM(quantity) | Total Units = SUM(stg_clean_orders[quantity]) |
| **QoQ Sales Growth** | Revenue change from prior quarter (Trough in Q3) | **-22.36% (Q3)** | w_quarterly_sales_performance: qoq_revenue_growth_pct | QoQ Growth = DIVIDE([Total Net Revenue] - [Prior Qtr Revenue], [Prior Qtr Revenue]) |
| **Average CSAT** | Mean customer satisfaction rating (1 to 5) | **4.01 / 5.00** | stg_clean_feedback: AVG(rating) | Average CSAT = AVERAGE(stg_clean_feedback[rating]) |
| **On-Time Delivery %**| Percentage of shipments delivered on or before SLA | **74.29%** | w_quarterly_sales_performance: AVG(on_time_delivery_pct)| On-Time Rate = DIVIDE(CALCULATE(COUNTROWS(shipping), shipping[delay_days]=0), COUNTROWS(shipping)) |
| **Repeat Buyer Rate** | Purchasing customers with 2+ completed orders | **60.29%** | w_customer_retention_summary: AVG(is_repeat_customer) | Repeat Rate = DIVIDE(CALCULATE(DISTINCTCOUNT(customers[customer_id]), [Total Orders] > 1), DISTINCTCOUNT(customers[customer_id])) |
| **Avg Delivery Days** | Mean elapsed days from dispatch to delivery | **4.06 Days** | w_delivery_sla: AVG(delivery_days) | Avg Delivery Days = AVERAGE(vw_delivery_sla[delivery_days]) |

---

## 4. Detailed Chart Specifications

### Visualization 1: Quarterly Sales & Growth Trend
- **Chart Type**: Dual-Axis Combo Chart (Clustered Column + Line with Markers).
- **Data Source**: w_quarterly_sales_performance
- **X-Axis**: sales_quarter (2024-Q1, 2024-Q2, 2024-Q3, 2024-Q4)
- **Y-Axis 1 (Primary - Columns)**: 	otal_net_revenue (.17M -> .44M -> .19M -> .75M). Bar color: #3B82F6 with Q3/Q4 highlighted in #F59E0B.
- **Y-Axis 2 (Secondary - Line)**: qoq_revenue_growth_pct (N/A -> -12.73% -> -22.36% -> -13.65%). Line color: #EF4444, stroke width 3px.
- **Visual Alert**: Callout annotation on 2024-Q3: *\"Q3 Contraction: -.25M (-22.36% QoQ) driven by fulfillment constraints\"*.

### Visualization 2: Orders vs Fulfillment SLA Deterioration
- **Chart Type**: Dual-Axis Line and Area Chart.
- **Data Source**: w_quarterly_sales_performance
- **X-Axis**: sales_quarter
- **Y-Axis 1 (Left - Line)**: 	otal_orders (749 -> 681 -> 552 -> 492).
- **Y-Axis 2 (Right - Area)**: on_time_delivery_pct (87.32% -> 86.49% -> **56.70%** -> 57.32%). Fill gradient: #10B981 (Q1/Q2) dropping to #EF4444 (Q3/Q4).
- **Insight**: Highlights how fulfillment SLA failure in Q3 directly preceded volume decay in Q4.

### Visualization 3: Transit Latency vs Customer CSAT Impact
- **Chart Type**: Scatter Plot with Linear Regression Trendline & Density Shading.
- **Data Source**: w_delivery_sla joined with stg_clean_feedback
- **X-Axis**: delay_days (Range: 0 to 14 days).
- **Y-Axis**: ating (Range: 1.0 to 5.0 stars).
- **Statistical Annotation**: 
  - Pearson Correlation:  = -0.8155$ (Strong Negative Association)
  - Sample Size:  = 2,076$ verified customer feedback responses.
  - OLS Trendline Equation: $\text{CSAT} = 4.48 - 0.28 \times (\text{Delay Days})$
- **Cluster Annotations**:
  - Cluster A (0-2 Days): Avg CSAT **4.61**, Dissatisfaction **0.00%**
  - Cluster B (6-8 Days): Avg CSAT **2.31**, Dissatisfaction **60.12%**
  - Cluster C (>8 Days): Avg CSAT **1.24**, Dissatisfaction **94.82%**

### Visualization 4: Vehicle Portfolio Matrix
- **Chart Type**: Quadrant Scatter Plot / Bubble Matrix.
- **Data Source**: w_vehicle_performance
- **X-Axis**: 	otal_net_revenue (.6M to .6M)
- **Y-Axis**: vg_rating (3.67 to 4.19)
- **Bubble Size**: 	otal_units_sold
- **Color Category**: strategic_portfolio_quadrant
- **Key Callouts**:
  - *Star Performers*: Zenith E-Crown (.64M, 4.02 CSAT), Zenith Ascent (.51M, 4.03 CSAT).
  - *At-Risk Pillars*: Zenith Sovereignty (.32M, 3.67 CSAT due to 33.7% delay rate!).
  - *Customer Favorites*: Terra Pathfinder (4.19 CSAT), Vortech Cyclone R (4.18 CSAT).

### Visualization 5: Cross-Regional Performance Matrix
- **Chart Type**: Interactive Heatmap Table / Geographical Shape Map.
- **Data Source**: w_vehicle_performance & sql/11_regional_analysis.sql
- **Dimensions**: 5 Regions (Northeast, West, Southeast, Southwest, Midwest).
- **Metrics Displayed**:
  - Total Net Revenue & Share % (Northeast: .26M, West: .23M, Southeast: .42M, Southwest: .30M, Midwest: .82M).
  - On-Time Delivery % (Northeast 80.89%, West 80.66% vs Southeast 68.96%, Southwest 69.96%, Midwest 70.05%).
  - Average CSAT (Northeast 4.31, West 4.23 vs Southeast 3.88, Midwest 3.83, Southwest 3.76).
  - Style Over-Indexing Ratio (Coupe over-indexes in Northeast at 1.28x; Full-Size dominates Midwest at 40.04% share).

### Visualization 6: Dispatch Center Bottleneck Ranking
- **Chart Type**: Horizontal Stacked Bar Chart with Pareto Cumulative Line.
- **Data Source**: w_dispatch_center_performance
- **Y-Axis**: center_name (Sorted by 	otal_delay_days descending)
- **X-Axis 1 (Primary - Bars)**: 	otal_delay_days and delayed_shipments
- **X-Axis 2 (Secondary - Line)**: 
etwork_delay_share_pct
- **Critical Findings**:
  - **DC-6 (Gulf Coast Fulfillment Center - Houston)**: 1,609 delay days (**47.20% of network total**), On-Time Rate: 59.68%.
  - **DC-3 (Midwest Central Terminal - Chicago)**: 695 delay days (**20.39% of network total**), On-Time Rate: 58.77%.
  - **Bottleneck Concentration**: Top 2 centers generate **67.59%** of all customer transit delays across the enterprise!

---

## 5. Interactive Slicers & Cross-Filtering Parameters

1. **Date Range / Quarter Selector**: Multi-select pill slicer (2024-Q1, 2024-Q2, 2024-Q3, 2024-Q4, Full Year 2024).
2. **Geographic Region**: Dropdown (Northeast, Southeast, Midwest, Southwest, West).
3. **Vehicle Class**: Horizontal button bar (All, Electric, Luxury, SUV, Truck, Sports, Sedan, Economy).
4. **Fulfillment Status**: Toggle switch (All Shipments, Delayed Orders Only, Severe SLA Breaches (>= 3 Days)).
5. **Customer Segment**: Radio selector (All Segments, Individual, Small Business, Corporate Fleet).
