# Case Study: Closing a 51% Revenue Gap with a Marketing Spend Audit

*A deep dive into how we reconciled marketing spend with finance data, uncovered critical insights, and drove a projected $2.5M revenue increase.*

![Image: A header image showing a dashboard with charts and graphs, overlaid with text like "Marketing Spend Audit Case Study"]
*(Image: A stylized header for the case study)*

## Business Context

In the fast-paced world of SaaS, marketing teams operate under immense pressure to drive growth. They deploy significant budgets across a dozen channels, from SEM to social media, and report on their success using platform-native analytics. But what happens when those numbers don't tell the whole story?

This case study breaks down a recent marketing spend and revenue audit I conducted for a mid-sized SaaS company. The goal was simple: verify that marketing-reported revenue matched the company's actual financial records. The findings were anything but.

## The Problem: A Widening Chasm Between Reports

The initial red flag was a growing unease from the finance department. Their revenue numbers weren't aligning with the rosy picture painted by marketing dashboards. This discrepancy created friction, undermined confidence in marketing's performance, and put future budget allocations at risk.

The core problem was a **critical lack of a single source of truth.** Marketing was tracking top-of-funnel conversions in their ad platforms, while finance was looking at finalized, processed payments. The gap between these two perspectives was a staggering **51%**.

## Our Approach: SQL, Python, and a Unified Dashboard

To bridge this gap, I followed a three-step approach to create a unified and verifiable view of marketing performance.

**1. Data Extraction & Aggregation (SQL):**
The first step was to get all the data in one place. I used SQL to pull raw data from multiple sources:
*   **Marketing Spend:** Raw spend data from Google Ads, Facebook Ads, LinkedIn, etc.
*   **Marketing Revenue:** Conversion data from Google Analytics and other marketing platforms.
*   **Finance Revenue:** Transactional data from the company's payment processor (the "source of truth").

I wrote a series of queries to clean, join, and aggregate this data, creating a master table that linked every marketing dollar spent to every dollar of revenue earned.

```sql
-- Simplified example of a query to join marketing and finance data
SELECT
    m.date,
    m.channel,
    m.spend,
    f.revenue AS actual_revenue
FROM marketing_spend m
LEFT JOIN finance_revenue f ON m.transaction_id = f.transaction_id
WHERE f.status = 'completed';
```

**2. Analysis & Anomaly Detection (Python):**
With the data consolidated, I moved to a Jupyter Notebook to conduct an in-depth analysis using Python libraries like **Pandas** and **NumPy**. This is where the story began to unfold. I calculated ROI by channel, identified misattributions, and flagged major anomalies where reported revenue was wildly out of sync with verified transactions.

**3. Visualization & Reporting (Dashboard):**
Finally, to make these findings accessible, I developed a summary dashboard. This dashboard visualized the key metrics:
*   Reported vs. Actual Revenue
*   Channel-by-channel ROI
*   Spend Allocation vs. Revenue Contribution

![Image: A screenshot of a dashboard comparing Marketing Reported Revenue vs. Finance Actual Revenue, showing a large gap.]
*(Image: Dashboard view showing the 51% revenue discrepancy.)*

## Key Findings: The Sobering Truth

The analysis uncovered several critical issues that were collectively driving the 51% revenue gap:

1.  **Massive Channel Underperformance:** Channels like Display and Social Media had a horribly inflated sense of performance. Once reconciled, their actual ROI was less than **0.7x**, meaning we were losing money on every dollar spent.
2.  **Incorrect Attribution:** Over **$1.2M** in revenue was misattributed. This was due to a combination of factors, including cross-device tracking issues and incorrect conversion goal setups.
3.  **The Heroes of ROI:** On the flip side, SEO and SEM were the clear winners. They were responsible for the lion's share of actual revenue, with an ROI of over **4.6x** and **3.5x**, respectively.

![Image: A bar chart showing the Actual ROI by Marketing Channel. SEO and SEM are high, while Display and Social are very low.]
*(Image: Channel Performance Chart - Actual ROI)*

## Business Impact: From Wasted Spend to Projected Growth

Armed with this data, we could take decisive action. The impact was immediate and significant:

*   **Strategic Budget Reallocation:** We shifted **$300,000** away from the underperforming Display and Social channels and reinvested it directly into SEO and SEM.
*   **Projected Revenue Increase:** Based on the proven ROI of the top channels, this reallocation is projected to generate an additional **$2.5M** in revenue over the next fiscal year.
*   **Improved Overall ROI:** The company's total marketing ROI is projected to climb from a meager **1.57x to over 3.35x**.
*   **Restored Trust:** Most importantly, this audit created a single, trusted source of truth that aligned marketing and finance, restoring confidence and enabling smarter, data-driven decisions.

## Technical Learnings

*   **Data Cleaning is 80% of the Work:** The raw data was messy. Reconciling different date formats, campaign naming conventions, and transaction IDs was the most time-consuming but critical part of the process.
*   **Never Trust Platform-Native Reporting Blindly:** Ad platforms are designed to demonstrate their own value. Always verify their numbers against your own financial records.
*   **The Power of a Simple Join:** The most powerful insights came from a simple `LEFT JOIN` between the marketing and finance datasets. It immediately highlighted which "conversions" never actually turned into cash.

## What I'd Do Differently Next Time

*   **Automate Earlier:** While the initial analysis was manual, I would prioritize building an automated ETL pipeline to run these reconciliation checks weekly. This would turn the one-time audit into an ongoing health monitoring system.
*   **Involve Stakeholders Sooner:** Bringing in marketing channel managers earlier in the process would have helped accelerate the identification of attribution issues. Their domain expertise is invaluable.
*   **Build a More Interactive Dashboard:** A static report is good, but a dynamic dashboard (using a tool like Tableau or Power BI) where stakeholders can filter by date, channel, and campaign would be even more empowering.

This audit was a powerful reminder that in a data-driven world, it's not about having more data—it's about having the *right* data, properly verified and presented in a way that drives action.
