## Tableau Dashboard Instructions

This guide provides basic instructions for creating a reconciliation dashboard in Tableau.

### 1. Connect to Data Sources

1.  Open Tableau Desktop.
2.  Connect to the four CSV data sources located in the `data/` directory:
    -   `marketing_spend.csv`
    -   `funnel_events.csv`
    -   `revenue_marketing.csv`
    -   `revenue_finance.csv`

### 2. Create Relationships

Create relationships between the data sources using the following keys:
-   `marketing_spend` and `funnel_events` on `campaign_id`.
-   `funnel_events` and `revenue_marketing` on `user_id`.
-   `revenue_marketing` and `revenue_finance` on `user_id`.

### 3. Create Calculated Fields

Create the following calculated fields to be used in the dashboard:

-   **CAC (Customer Acquisition Cost):**
    ```
    SUM([spend]) / COUNTD([user_id])
    ```
-   **ROAS (Return on Ad Spend) - Finance:**
    ```
    SUM([actual_revenue]) / SUM([spend])
    ```
-   **ROAS (Return on Ad Spend) - Marketing:**
    ```
    SUM([reported_revenue]) / SUM([spend])
    ```
-   **Revenue Variance:**
    ```
    SUM([reported_revenue]) - SUM([actual_revenue])
    ```

### 4. Build Worksheets

Create at least the following five worksheets:

1.  **ROAS Comparison:** A bar chart comparing `ROAS - Marketing` and `ROAS - Finance` by channel.
2.  **CAC by Channel:** A bar chart showing `CAC` for each marketing channel.
3.  **Funnel Waterfall:** A waterfall chart showing the user drop-off at each stage of the funnel (`click` -> `signup` -> `paid`).
4.  **Revenue Variance:** A scatter plot or heatmap showing the variance between `reported_revenue` and `actual_revenue`.
5.  **Anomaly Table:** A table showing the details from `anomalies.csv`, which can be filtered by channel, issue type, and severity.

### 5. Assemble the Dashboard

Combine the worksheets into a single dashboard. Add filters for `channel`, `campaign_id`, and `date` to allow for interactive analysis.
