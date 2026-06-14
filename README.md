# RFM Analysis — E-Commerce Customer Segmentation
 
> Segmenting customers by purchasing behavior to identify high-value personas and surface actionable retention strategies.
 
---
 
## Table of Contents
 
1. [Project Overview](#project-overview)
2. [Dataset](#dataset)
3. [Methodology](#methodology)
   - [Step 1: Compute RFM Metrics](#step-1-compute-rfm-metrics)
   - [Step 2: Score & Segment](#step-2-score--segment)
   - [Step 3: Identify the Best Persona](#step-3-identify-the-best-persona)
   - [Step 4: Analyze Buying Behavior](#step-4-analyze-buying-behavior)
4. [Customer Segments](#customer-segments)
5. [Key Findings](#key-findings)
6. [Business Recommendations](#business-recommendations)
7. [Repository Structure](#repository-structure)
---
 
## Project Overview
 
This project applies **RFM (Recency, Frequency, Monetary) Analysis** to a 3-month snapshot of transactional data from an e-commerce platform. The goal is to:
 
- Segment the entire customer base into meaningful behavioral groups
- Identify the demographic and geographic profile of the highest-value customers
- Understand their purchasing patterns (category preferences, timing, voucher usage)
- Translate findings into concrete business actions per segment
**Tools used:** SQL (BigQuery) · Google Slides (presentation)
 
---
 
## Dataset
 
**Source table:** `fact_orders`, `fact_order_items`, `dim_customer`, `dim_date`
**Time window:** 3 months of order history
 
The dataset captures order-level transactions and includes customer identifiers, order timestamps, revenue/GMV figures, product categories, applied vouchers, and customer demographic attributes (gender, age group, city).
 
> ⚠️ Raw data is not included in this repository in compliance with data privacy policy.
 
---
 
## Methodology
 
### Step 1: Compute RFM Metrics
 
For each customer, three metrics are calculated over the 3-month window:
 
| Metric | Definition |
|---|---|
| **Recency (R)** | Number of days since the customer's last order |
| **Frequency (F)** | Total days of orders placed |
| **Monetary (M)** | Total GMV contributed |
 
Full SQL logic is in [`query.sql`](./query.sql).
 
---
 
### Step 2: Score & Segment
 
Each customer receives an **R, F, M score from 1 to 5** (quintile-based), where:
- **R = 5** → purchased very recently
- **F = 5** → ordered very frequently
- **M = 5** → highest spender
Customers are then assigned to one of **8 behavioral segments** based on their combined RFM scores:
 
| Segment | Description |
|---|---|
| 🏆 Champions | High R, F, M — your best customers |
| 💛 Loyalists | Strong frequency and spend, still active |
| ⚠️ Slipping Loyalists | Were loyal, but recency is declining |
| 🆕 New Customers | Recent first-time buyers |
| 🐳 Whales | Very high spend but infrequent orders |
| 🚨 Cannot Lose Them | High historical value, now going quiet |
| 💀 Losts | Low R, F, M — churned customers |
| 🌱 Potential / At Risks | Mid-tier customers trending down |
 
---
 
### Step 3: Identify the Best Persona
 
Each customer is given a **composite RFM score scaled from 0 to 1** using min-max normalization across R, F, and M independently:
 
```
scaled_score = (value - min) / (max - min)
```
 
This normalized score is used to rank customers and identify the dominant **demographic and geographic profile** (gender, age group, city) driving the most value.
 
---
 
### Step 4: Analyze Buying Behavior
 
The best-performing persona is then examined across three behavioral dimensions:
 
- **Product preferences** — which categories do they buy most?
- **Purchase timing** — which days/hours are they most active?
- **Voucher usage** — how often do they apply vouchers, and what types?
 
---
 
## Key Findings
 
### 1. Best Customer Persona — Champions
 
The highest-value customers are predominantly **female, aged 25–44, residing in the 5 major cities in Viet Nam**.
 
| Attribute | Profile |
|---|---|
| Gender | Female |
| Age group | 25–44 |
| Location | Top 5 cities ([Hà Nội], [TP HCM], [Hải Phòng], [Đà Nẵng], [Cần Thơ]) |
 
### 2. Category Preferences
 
Best customers most frequently purchase in the **[Electronic]** category, followed by **[Nhà Cửa & Đời Sống]** and **[Sức Khoẻ]**. This suggests strong intent around [technological convenience, home living, healthcare].
 
### 3. Purchase Timing
 
Order volume peaks between **[12:00-13:00 and 20:00-23:00 daily]**. This pattern aligns with after-work browsing behavior typical of urban working women. Most of the customers purchase again after 10 days.
 
### 4. Voucher Usage
 
**[About 70%]** of Champions' orders include a voucher. They tend to use **[shipping discount, platform voucher]** most often and in sales day, indicating that promotions influence purchase decisions even among the most loyal buyers.
 
---
 
## Business Recommendations
 
| Segment | Recommended Action |
|---|---|
| 🏆 **Champions** | Launch an exclusive loyalty program or early access to new products. Prioritize retention — this group is the GMV backbone. |
| 💛 **Loyalists** | Upsell via personalized bundles. Nurture them toward Champions status with tiered rewards. |
| ⚠️ **Slipping Loyalists** | Trigger a win-back campaign (push notification + targeted voucher) before they fully churn. |
| 🆕 **New Customers** | Activate an onboarding sequence — second-order voucher, category recommendations based on first purchase. |
| 🐳 **Whales** | Focus on frequency: create high-value flash sales or subscription options to bring them back sooner. |
| 🚨 **Cannot Lose Them** | Escalate urgency — personalized outreach (email/CRM), large-value incentive. Time-sensitive offer works well here. |
| 💀 **Losts** | Low-cost reactivation (mass promo blast). Accept higher churn rate; don't over-invest. |
| 🌱 **Potential / At Risks** | Identify sub-groups: those trending down need a nudge (voucher), those trending up need nurturing (loyalty points). |
 
> 💡 **Focus budget** on Champions and Slipping Loyalists — highest ROI per marketing dollar spent.
> **Optimize listing appearance** during the peak hours.
> **Send personalized notification** around day 9 since the last time a customer buys.
---
 
## Repository Structure
 
```
rfm-analysis/
├── query.sql          # All SQL logic: RFM computation, scoring, segmentation, persona analysis
└── README.md          # This file
```
 
📎 **Presentation:** [Google Slides — RFM Analysis Deep Dive](<https://docs.google.com/presentation/d/1DBKHvCIGLFQydL8PD1qaHWo338ruXhBCmN7M60yLGFA/edit?slide=id.p#slide=id.p>)
