# Data Documentation

This document provides details about the data files used in this project.

## Data Sources

The data is provided in four CSV files located in the `data/` directory.

### 1. `marketing_spend.csv`

-   **Description:** Contains marketing spend data for various campaigns.
-   **Columns:**
    -   `date`: The date of the spend.
    -   `channel`: The marketing channel (e.g., Google, Meta, LinkedIn).
    -   `campaign_id`: The unique identifier for the campaign.
    -   `spend`: The amount spent on the campaign on that day.
    -   `spend_currency`: The currency of the spend (e.g., USD).

### 2. `funnel_events.csv`

-   **Description:** Contains user interaction events from the marketing funnel.
-   **Columns:**
    -   `user_id`: The unique identifier for the user.
    -   `channel`: The channel through which the user interacted.
    -   `campaign_id`: The campaign associated with the user's interaction.
    -   `event`: The type of event (e.g., click, signup, paid).
    -   `event_date`: The date of the event.

### 3. `revenue_marketing.csv`

-   **Description:** Contains revenue data as reported by the marketing team.
-   **Columns:**
    -   `user_id`: The unique identifier for the user.
    -   `channel`: The channel to which the revenue is attributed.
    -   `campaign_id`: The campaign to which the revenue is attributed.
    -   `reported_revenue`: The amount of revenue reported by marketing.
    -   `report_date`: The date the revenue was reported.

### 4. `revenue_finance.csv`

-   **Description:** Contains revenue data as verified by the finance team.
-   **Columns:**
    -   `user_id`: The unique identifier for the user.
    -   `actual_revenue`: The actual revenue amount verified by finance.
    -   `invoice_date`: The date of the invoice.
    -   `invoice_id`: The unique identifier for the invoice.
    -   `payment_status`: The status of the payment (e.g., paid, refunded).

### 5. `anomalies.csv`

-   **Description:** Contains a list of anomalies found during the reconciliation process.
-   **Columns:**
    -   `user_id`: The user associated with the anomaly.
    -   `channel`: The marketing channel associated with the anomaly.
    -   `issue_type`: The type of issue (e.g., "Missing Invoice", "Duplicate + Missing Invoice").
    -   `severity`: The severity of the issue (e.g., LOW, MEDIUM, HIGH, CRITICAL).
    -   `variance`: The revenue variance associated with the anomaly.
