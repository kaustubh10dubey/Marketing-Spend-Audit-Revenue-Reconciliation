-- ============================================================================
-- MARKETING SPEND AUDIT & REVENUE RECONCILIATION
-- PostgreSQL Analysis Queries
-- ============================================================================
-- 
-- This file contains comprehensive SQL queries to reconcile marketing spend
-- against revenue data from Marketing and Finance departments.
--
-- Datasets Required:
--   1. marketing_spend    - Daily campaign spending (58 rows)
--   2. funnel_events      - User journey events (145 rows)
--   3. revenue_marketing  - Marketing-attributed revenue (35 rows)
--   4. revenue_finance    - Finance-verified revenue (24 rows)
--
-- Author: Data Analytics Team
-- Created: 2025-01-04
-- ============================================================================


-- ============================================================================
-- SECTION 0: TABLE CREATION (For importing CSV data)
-- ============================================================================
-- Run these CREATE statements first, then use COPY or \copy to import CSVs

-- Marketing spend by campaign and date
CREATE TABLE IF NOT EXISTS marketing_spend (
    date DATE NOT NULL,
    campaign VARCHAR(50) NOT NULL,
    spend DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (date, campaign)
);

-- User funnel events (page views, cart additions, checkouts, purchases)
CREATE TABLE IF NOT EXISTS funnel_events (
    event_id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    user_id VARCHAR(50) NOT NULL,
    event_type VARCHAR(50) NOT NULL
);

-- Revenue as reported by Marketing team (attributed to campaigns)
CREATE TABLE IF NOT EXISTS revenue_marketing (
    date DATE NOT NULL,
    campaign VARCHAR(50) NOT NULL,
    revenue DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (date, campaign)
);

-- Revenue as recorded by Finance team (verified actuals by product)
CREATE TABLE IF NOT EXISTS revenue_finance (
    date DATE NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    revenue DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (date, product_id)
);

-- Create indexes for performance on JOIN operations
CREATE INDEX IF NOT EXISTS idx_funnel_user ON funnel_events(user_id);
CREATE INDEX IF NOT EXISTS idx_funnel_event_type ON funnel_events(event_type);
CREATE INDEX IF NOT EXISTS idx_funnel_timestamp ON funnel_events(timestamp);
CREATE INDEX IF NOT EXISTS idx_spend_campaign ON marketing_spend(campaign);
CREATE INDEX IF NOT EXISTS idx_revenue_mkt_campaign ON revenue_marketing(campaign);


-- ============================================================================
-- SECTION 1: TRUE CUSTOMER ACQUISITION COST (CAC) BY CHANNEL
-- ============================================================================
-- Calculates the actual cost to acquire a paying customer per campaign/channel
-- CAC = Total Spend / Number of Verified Paid Users (those who completed checkout)

WITH 
-- Step 1: Aggregate total spend per campaign
campaign_spend AS (
    SELECT 
        campaign,
        SUM(spend) AS total_spend,
        COUNT(DISTINCT date) AS active_days
    FROM marketing_spend
    GROUP BY campaign
),

-- Step 2: Identify users who completed checkout (paid users)
-- We extract the date from the event timestamp to match with campaigns
paid_users AS (
    SELECT 
        user_id,
        DATE(timestamp) AS conversion_date,
        MIN(timestamp) AS first_purchase_time
    FROM funnel_events
    WHERE event_type = 'checkout'  -- checkout = successful payment
    GROUP BY user_id, DATE(timestamp)
),

-- Step 3: Count paid users per day (to distribute across campaigns)
daily_conversions AS (
    SELECT 
        conversion_date,
        COUNT(DISTINCT user_id) AS paid_user_count
    FROM paid_users
    GROUP BY conversion_date
),

-- Step 4: Allocate conversions to campaigns based on spend proportion
-- (Weighted attribution based on daily spend share)
campaign_conversions AS (
    SELECT 
        ms.campaign,
        ms.date,
        ms.spend,
        dc.paid_user_count,
        -- Calculate this campaign's share of daily spend
        ms.spend / NULLIF(SUM(ms.spend) OVER (PARTITION BY ms.date), 0) AS spend_share,
        -- Allocate conversions proportionally to spend
        dc.paid_user_count * (ms.spend / NULLIF(SUM(ms.spend) OVER (PARTITION BY ms.date), 0)) AS attributed_conversions
    FROM marketing_spend ms
    LEFT JOIN daily_conversions dc ON ms.date = dc.conversion_date
)

-- Final: Calculate CAC per campaign
SELECT 
    campaign,
    SUM(spend) AS total_spend,
    ROUND(SUM(COALESCE(attributed_conversions, 0)), 2) AS attributed_paid_users,
    CASE 
        WHEN SUM(COALESCE(attributed_conversions, 0)) > 0 
        THEN ROUND(SUM(spend) / SUM(attributed_conversions), 2)
        ELSE NULL  -- No conversions = undefined CAC
    END AS cac_per_user,
    -- CAC benchmark comparison (assuming $100 target CAC)
    CASE 
        WHEN SUM(COALESCE(attributed_conversions, 0)) > 0 
             AND (SUM(spend) / SUM(attributed_conversions)) <= 100 
        THEN 'GOOD'
        WHEN SUM(COALESCE(attributed_conversions, 0)) > 0 
             AND (SUM(spend) / SUM(attributed_conversions)) <= 200 
        THEN 'ACCEPTABLE'
        WHEN SUM(COALESCE(attributed_conversions, 0)) > 0 
        THEN 'HIGH'
        ELSE 'NO_DATA'
    END AS cac_status
FROM campaign_conversions
GROUP BY campaign
ORDER BY cac_per_user ASC NULLS LAST;


-- ============================================================================
-- SECTION 2: ROAS COMPARISON (MARKETING VS FINANCE)
-- ============================================================================
-- Compares Return on Ad Spend between Marketing-reported and Finance-actuals
-- ROAS = Revenue / Spend
-- This reveals over/under-reporting by the Marketing team

WITH 
-- Total spend per campaign
campaign_spend AS (
    SELECT 
        campaign,
        SUM(spend) AS total_spend
    FROM marketing_spend
    GROUP BY campaign
),

-- Marketing-reported revenue per campaign
marketing_revenue AS (
    SELECT 
        campaign,
        SUM(revenue) AS mkt_revenue
    FROM revenue_marketing
    GROUP BY campaign
),

-- Finance revenue is by product, not campaign - aggregate by date range
-- We'll calculate total finance revenue and compare at aggregate level
finance_totals AS (
    SELECT 
        SUM(revenue) AS total_finance_revenue,
        MIN(date) AS start_date,
        MAX(date) AS end_date,
        COUNT(DISTINCT date) AS finance_days
    FROM revenue_finance
),

-- Aggregate marketing totals for comparison
marketing_totals AS (
    SELECT 
        SUM(total_spend) AS total_spend,
        SUM(mkt_revenue) AS total_mkt_revenue
    FROM campaign_spend cs
    LEFT JOIN marketing_revenue mr ON cs.campaign = mr.campaign
)

-- Campaign-level ROAS using Marketing data
SELECT 
    'BY_CAMPAIGN' AS analysis_level,
    cs.campaign,
    cs.total_spend,
    COALESCE(mr.mkt_revenue, 0) AS marketing_revenue,
    -- Calculate Marketing ROAS
    ROUND(COALESCE(mr.mkt_revenue, 0) / NULLIF(cs.total_spend, 0), 2) AS marketing_roas,
    -- ROAS Status indicator
    CASE 
        WHEN COALESCE(mr.mkt_revenue, 0) / NULLIF(cs.total_spend, 0) >= 2.0 THEN '🟢 Profitable'
        WHEN COALESCE(mr.mkt_revenue, 0) / NULLIF(cs.total_spend, 0) >= 1.0 THEN '🟡 Break-even'
        ELSE '🔴 Losing'
    END AS roas_status
FROM campaign_spend cs
LEFT JOIN marketing_revenue mr ON cs.campaign = mr.campaign

UNION ALL

-- Aggregate comparison: Marketing vs Finance ROAS
SELECT 
    'AGGREGATE' AS analysis_level,
    'ALL_CAMPAIGNS' AS campaign,
    mt.total_spend,
    mt.total_mkt_revenue AS marketing_revenue,
    ROUND(mt.total_mkt_revenue / NULLIF(mt.total_spend, 0), 2) AS marketing_roas,
    'Marketing Reported' AS roas_status
FROM marketing_totals mt

UNION ALL

SELECT 
    'AGGREGATE' AS analysis_level,
    'FINANCE_ACTUAL' AS campaign,
    (SELECT SUM(spend) FROM marketing_spend) AS total_spend,
    ft.total_finance_revenue AS marketing_revenue,
    ROUND(ft.total_finance_revenue / NULLIF((SELECT SUM(spend) FROM marketing_spend), 0), 2) AS marketing_roas,
    'Finance Verified' AS roas_status
FROM finance_totals ft

ORDER BY analysis_level, campaign;


-- ============================================================================
-- SECTION 3: REVENUE VARIANCE ANALYSIS (MARKETING - FINANCE)
-- ============================================================================
-- Identifies the gap between Marketing-reported and Finance-verified revenue
-- Positive variance = Marketing over-reporting
-- Negative variance = Marketing under-reporting

WITH 
-- Daily revenue from Marketing team (aggregated across campaigns)
daily_marketing_revenue AS (
    SELECT 
        date,
        SUM(revenue) AS mkt_daily_revenue,
        STRING_AGG(campaign, ', ' ORDER BY campaign) AS campaigns_active
    FROM revenue_marketing
    GROUP BY date
),

-- Daily revenue from Finance team (aggregated across products)
daily_finance_revenue AS (
    SELECT 
        date,
        SUM(revenue) AS fin_daily_revenue,
        STRING_AGG(product_id, ', ' ORDER BY product_id) AS products_sold
    FROM revenue_finance
    GROUP BY date
),

-- Full outer join to capture all dates from both sources
daily_variance AS (
    SELECT 
        COALESCE(m.date, f.date) AS date,
        COALESCE(m.mkt_daily_revenue, 0) AS marketing_revenue,
        COALESCE(f.fin_daily_revenue, 0) AS finance_revenue,
        COALESCE(m.mkt_daily_revenue, 0) - COALESCE(f.fin_daily_revenue, 0) AS variance_amount,
        m.campaigns_active,
        f.products_sold,
        -- Categorize the discrepancy
        CASE 
            WHEN m.date IS NULL THEN 'FINANCE_ONLY'
            WHEN f.date IS NULL THEN 'MARKETING_ONLY'
            WHEN m.mkt_daily_revenue = f.fin_daily_revenue THEN 'MATCHED'
            WHEN m.mkt_daily_revenue > f.fin_daily_revenue THEN 'OVER_REPORTED'
            ELSE 'UNDER_REPORTED'
        END AS variance_category
    FROM daily_marketing_revenue m
    FULL OUTER JOIN daily_finance_revenue f ON m.date = f.date
)

-- Output daily variance with running totals
SELECT 
    date,
    marketing_revenue,
    finance_revenue,
    variance_amount,
    -- Running total of variance
    SUM(variance_amount) OVER (ORDER BY date) AS cumulative_variance,
    -- Percentage variance
    ROUND(
        100.0 * variance_amount / NULLIF(finance_revenue, 0), 
        2
    ) AS variance_pct,
    variance_category,
    campaigns_active,
    products_sold
FROM daily_variance
ORDER BY date;

-- Summary statistics
SELECT 
    '--- VARIANCE SUMMARY ---' AS metric,
    NULL::DATE AS date,
    NULL::NUMERIC AS value
UNION ALL
SELECT 
    'Total Marketing Revenue',
    NULL,
    SUM(COALESCE(mkt_daily_revenue, 0))
FROM daily_marketing_revenue
UNION ALL
SELECT 
    'Total Finance Revenue',
    NULL,
    SUM(COALESCE(fin_daily_revenue, 0))
FROM daily_finance_revenue
UNION ALL
SELECT 
    'Total Variance (Mkt - Fin)',
    NULL,
    (SELECT SUM(revenue) FROM revenue_marketing) - (SELECT SUM(revenue) FROM revenue_finance)
UNION ALL
SELECT 
    'Variance Percentage',
    NULL,
    ROUND(
        100.0 * ((SELECT SUM(revenue) FROM revenue_marketing) - (SELECT SUM(revenue) FROM revenue_finance)) 
        / NULLIF((SELECT SUM(revenue) FROM revenue_finance), 0),
        2
    );


-- ============================================================================
-- SECTION 4: MISSING INVOICES DETECTION
-- ============================================================================
-- Finds transactions where Marketing recorded revenue but Finance has no record
-- These represent potential missing invoices or attribution errors

WITH 
-- Dates where marketing recorded revenue
marketing_dates AS (
    SELECT DISTINCT 
        date,
        campaign,
        revenue AS mkt_revenue
    FROM revenue_marketing
),

-- Dates where finance recorded revenue
finance_dates AS (
    SELECT DISTINCT date
    FROM revenue_finance
),

-- Dates with marketing revenue but NO finance revenue
missing_invoices AS (
    SELECT 
        md.date,
        md.campaign,
        md.mkt_revenue,
        'MISSING_FINANCE_RECORD' AS issue_type,
        'Marketing recorded revenue but no Finance verification found' AS description
    FROM marketing_dates md
    LEFT JOIN finance_dates fd ON md.date = fd.date
    WHERE fd.date IS NULL
)

SELECT 
    date,
    campaign,
    mkt_revenue AS unverified_revenue,
    issue_type,
    description,
    -- Flag severity based on amount
    CASE 
        WHEN mkt_revenue > 2000 THEN 'HIGH'
        WHEN mkt_revenue > 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS severity
FROM missing_invoices
ORDER BY date, mkt_revenue DESC;

-- Summary of missing invoices
SELECT 
    COUNT(*) AS missing_invoice_count,
    SUM(mkt_revenue) AS total_unverified_revenue,
    STRING_AGG(DISTINCT campaign, ', ') AS affected_campaigns
FROM (
    SELECT 
        md.date,
        md.campaign,
        md.mkt_revenue
    FROM marketing_dates md
    LEFT JOIN finance_dates fd ON md.date = fd.date
    WHERE fd.date IS NULL
) missing;


-- ============================================================================
-- SECTION 5: DUPLICATE ATTRIBUTION DETECTION
-- ============================================================================
-- Identifies potential double-counting in marketing attribution
-- Checks for: same user with multiple checkouts, same day duplicate entries

-- 5A: Users with multiple checkout events (potential duplicate conversions)
WITH checkout_events AS (
    SELECT 
        user_id,
        DATE(timestamp) AS checkout_date,
        timestamp,
        event_id,
        -- Number this user's checkouts
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY timestamp) AS checkout_number,
        -- Total checkouts per user
        COUNT(*) OVER (PARTITION BY user_id) AS total_checkouts
    FROM funnel_events
    WHERE event_type = 'checkout'
)

SELECT 
    user_id,
    checkout_date,
    timestamp AS checkout_time,
    event_id,
    checkout_number,
    total_checkouts,
    CASE 
        WHEN checkout_number > 1 THEN 'POTENTIAL_DUPLICATE'
        ELSE 'FIRST_CONVERSION'
    END AS attribution_status,
    CASE 
        WHEN total_checkouts > 1 THEN 'REVIEW_REQUIRED'
        ELSE 'OK'
    END AS review_flag
FROM checkout_events
WHERE total_checkouts > 1
ORDER BY user_id, checkout_number;

-- 5B: Same-day duplicate revenue entries in Marketing data
WITH marketing_duplicates AS (
    SELECT 
        date,
        campaign,
        revenue,
        COUNT(*) AS entry_count,
        ROW_NUMBER() OVER (PARTITION BY date, campaign ORDER BY revenue) AS row_num
    FROM revenue_marketing
    GROUP BY date, campaign, revenue
    HAVING COUNT(*) > 1
)

SELECT 
    date,
    campaign,
    revenue,
    entry_count AS duplicate_count,
    revenue * (entry_count - 1) AS over_counted_amount,
    'DUPLICATE_ENTRY' AS issue_type
FROM marketing_duplicates
ORDER BY date, campaign;

-- 5C: Summary of potential duplicate attributions
SELECT 
    'DUPLICATE_ATTRIBUTION_SUMMARY' AS report_type,
    (
        SELECT COUNT(DISTINCT user_id) 
        FROM funnel_events 
        WHERE event_type = 'checkout'
        GROUP BY user_id 
        HAVING COUNT(*) > 1
    ) AS users_with_multiple_checkouts,
    (
        SELECT COUNT(*) 
        FROM (
            SELECT date, campaign 
            FROM revenue_marketing 
            GROUP BY date, campaign 
            HAVING COUNT(*) > 1
        ) dups
    ) AS duplicate_marketing_entries;


-- ============================================================================
-- SECTION 6: FUNNEL DROP-OFF RATES ANALYSIS
-- ============================================================================
-- Calculates conversion rates between each funnel stage
-- Identifies bottlenecks in the customer journey

WITH 
-- Count unique users at each funnel stage
funnel_stages AS (
    SELECT 
        event_type,
        COUNT(DISTINCT user_id) AS unique_users,
        COUNT(*) AS total_events,
        MIN(timestamp) AS first_event,
        MAX(timestamp) AS last_event
    FROM funnel_events
    GROUP BY event_type
),

-- Define funnel order and calculate metrics
ordered_funnel AS (
    SELECT 
        event_type,
        unique_users,
        total_events,
        -- Define stage order for proper funnel sequence
        CASE event_type
            WHEN 'page_view' THEN 1
            WHEN 'add_to_cart' THEN 2
            WHEN 'checkout' THEN 3
            WHEN 'purchase' THEN 4
            ELSE 99
        END AS stage_order,
        -- Get the first stage count for percentage calculations
        FIRST_VALUE(unique_users) OVER (ORDER BY 
            CASE event_type
                WHEN 'page_view' THEN 1
                WHEN 'add_to_cart' THEN 2
                WHEN 'checkout' THEN 3
                WHEN 'purchase' THEN 4
                ELSE 99
            END
        ) AS top_of_funnel_users
    FROM funnel_stages
),

-- Calculate drop-off between stages
funnel_with_dropoff AS (
    SELECT 
        event_type,
        stage_order,
        unique_users,
        total_events,
        top_of_funnel_users,
        -- Previous stage users using LAG
        LAG(unique_users) OVER (ORDER BY stage_order) AS prev_stage_users,
        -- Percentage of top of funnel
        ROUND(100.0 * unique_users / NULLIF(top_of_funnel_users, 0), 2) AS pct_of_top_funnel
    FROM ordered_funnel
    WHERE stage_order < 99
)

SELECT 
    stage_order,
    event_type AS funnel_stage,
    unique_users,
    total_events,
    pct_of_top_funnel AS pct_from_start,
    -- Stage-to-stage conversion rate
    CASE 
        WHEN prev_stage_users IS NOT NULL 
        THEN ROUND(100.0 * unique_users / NULLIF(prev_stage_users, 0), 2)
        ELSE 100.00  -- First stage = 100%
    END AS stage_conversion_rate,
    -- Drop-off rate from previous stage
    CASE 
        WHEN prev_stage_users IS NOT NULL 
        THEN ROUND(100.0 * (prev_stage_users - unique_users) / NULLIF(prev_stage_users, 0), 2)
        ELSE 0.00
    END AS drop_off_rate,
    -- Visual funnel bar (for console output)
    REPEAT('█', (unique_users * 40 / NULLIF(top_of_funnel_users, 1))::INT) AS funnel_visual
FROM funnel_with_dropoff
ORDER BY stage_order;

-- Identify the biggest bottleneck
SELECT 
    'BIGGEST_BOTTLENECK' AS analysis,
    event_type AS problem_stage,
    drop_off_rate AS drop_off_pct,
    'Focus optimization efforts here' AS recommendation
FROM (
    SELECT 
        event_type,
        stage_order,
        ROUND(
            100.0 * (LAG(unique_users) OVER (ORDER BY stage_order) - unique_users) 
            / NULLIF(LAG(unique_users) OVER (ORDER BY stage_order), 0), 
            2
        ) AS drop_off_rate
    FROM ordered_funnel
    WHERE stage_order < 99
) bottleneck
WHERE drop_off_rate = (
    SELECT MAX(drop_off_rate)
    FROM (
        SELECT 
            ROUND(
                100.0 * (LAG(unique_users) OVER (ORDER BY stage_order) - unique_users) 
                / NULLIF(LAG(unique_users) OVER (ORDER BY stage_order), 0), 
                2
            ) AS drop_off_rate
        FROM ordered_funnel
        WHERE stage_order < 99
    ) dr
    WHERE drop_off_rate IS NOT NULL
);


-- ============================================================================
-- SECTION 7: CHANNEL PERFORMANCE SUMMARY
-- ============================================================================
-- Comprehensive performance scorecard for each marketing channel/campaign
-- Combines spend, revenue, ROAS, and efficiency metrics

WITH 
-- Aggregate spend per campaign
spend_summary AS (
    SELECT 
        campaign,
        SUM(spend) AS total_spend,
        COUNT(DISTINCT date) AS active_days,
        ROUND(AVG(spend), 2) AS avg_daily_spend,
        MIN(date) AS first_spend_date,
        MAX(date) AS last_spend_date
    FROM marketing_spend
    GROUP BY campaign
),

-- Aggregate marketing revenue per campaign
revenue_summary AS (
    SELECT 
        campaign,
        SUM(revenue) AS total_revenue,
        COUNT(DISTINCT date) AS revenue_days,
        ROUND(AVG(revenue), 2) AS avg_daily_revenue
    FROM revenue_marketing
    GROUP BY campaign
),

-- Get funnel conversion counts (attributed by date proportion like in Section 1)
daily_conversions AS (
    SELECT 
        DATE(timestamp) AS conversion_date,
        COUNT(DISTINCT user_id) AS conversions
    FROM funnel_events
    WHERE event_type = 'checkout'
    GROUP BY DATE(timestamp)
),

-- Attribute conversions to campaigns by spend share
campaign_conversions AS (
    SELECT 
        ms.campaign,
        SUM(
            dc.conversions * (ms.spend / NULLIF(daily_spend.total_daily_spend, 0))
        ) AS attributed_conversions
    FROM marketing_spend ms
    LEFT JOIN daily_conversions dc ON ms.date = dc.conversion_date
    LEFT JOIN (
        SELECT date, SUM(spend) AS total_daily_spend
        FROM marketing_spend
        GROUP BY date
    ) daily_spend ON ms.date = daily_spend.date
    GROUP BY ms.campaign
),

-- Finance revenue totals for comparison (pro-rated by spend share)
finance_summary AS (
    SELECT 
        SUM(revenue) AS total_finance_revenue
    FROM revenue_finance
)

-- Final channel performance scorecard
SELECT 
    ss.campaign,
    -- Spend Metrics
    ss.total_spend,
    ss.active_days,
    ss.avg_daily_spend,
    
    -- Revenue Metrics (Marketing Reported)
    COALESCE(rs.total_revenue, 0) AS marketing_revenue,
    COALESCE(rs.avg_daily_revenue, 0) AS avg_daily_revenue,
    
    -- ROAS Calculation
    ROUND(
        COALESCE(rs.total_revenue, 0) / NULLIF(ss.total_spend, 0), 
        2
    ) AS roas,
    
    -- Efficiency Metrics
    ROUND(COALESCE(cc.attributed_conversions, 0), 2) AS attributed_conversions,
    CASE 
        WHEN COALESCE(cc.attributed_conversions, 0) > 0 
        THEN ROUND(ss.total_spend / cc.attributed_conversions, 2)
        ELSE NULL
    END AS cost_per_acquisition,
    
    -- Profit/Loss
    COALESCE(rs.total_revenue, 0) - ss.total_spend AS gross_profit,
    
    -- Performance Tier
    CASE 
        WHEN COALESCE(rs.total_revenue, 0) / NULLIF(ss.total_spend, 0) >= 2.5 THEN 'TIER_1_STAR'
        WHEN COALESCE(rs.total_revenue, 0) / NULLIF(ss.total_spend, 0) >= 1.5 THEN 'TIER_2_GOOD'
        WHEN COALESCE(rs.total_revenue, 0) / NULLIF(ss.total_spend, 0) >= 1.0 THEN 'TIER_3_BREAK_EVEN'
        ELSE 'TIER_4_UNDERPERFORMING'
    END AS performance_tier,
    
    -- Budget Recommendation
    CASE 
        WHEN COALESCE(rs.total_revenue, 0) / NULLIF(ss.total_spend, 0) >= 2.0 
        THEN 'INCREASE_BUDGET'
        WHEN COALESCE(rs.total_revenue, 0) / NULLIF(ss.total_spend, 0) >= 1.0 
        THEN 'MAINTAIN_BUDGET'
        ELSE 'REDUCE_BUDGET'
    END AS budget_recommendation

FROM spend_summary ss
LEFT JOIN revenue_summary rs ON ss.campaign = rs.campaign
LEFT JOIN campaign_conversions cc ON ss.campaign = cc.campaign
CROSS JOIN finance_summary fs
ORDER BY roas DESC NULLS LAST;


-- ============================================================================
-- SECTION 8: EXECUTIVE SUMMARY VIEW
-- ============================================================================
-- High-level metrics for leadership reporting

SELECT '═══════════════════════════════════════════════════════════════' AS divider
UNION ALL SELECT '                    EXECUTIVE SUMMARY REPORT                     '
UNION ALL SELECT '═══════════════════════════════════════════════════════════════';

-- Key Metrics Summary
SELECT 
    metric_name,
    metric_value,
    metric_context
FROM (
    -- Total Marketing Spend
    SELECT 
        1 AS sort_order,
        'Total Marketing Spend' AS metric_name,
        '$' || TO_CHAR(SUM(spend), 'FM999,999,990.00') AS metric_value,
        COUNT(DISTINCT campaign) || ' campaigns' AS metric_context
    FROM marketing_spend
    
    UNION ALL
    
    -- Marketing Reported Revenue
    SELECT 
        2,
        'Marketing Reported Revenue',
        '$' || TO_CHAR(SUM(revenue), 'FM999,999,990.00'),
        COUNT(DISTINCT date) || ' days'
    FROM revenue_marketing
    
    UNION ALL
    
    -- Finance Verified Revenue
    SELECT 
        3,
        'Finance Verified Revenue',
        '$' || TO_CHAR(SUM(revenue), 'FM999,999,990.00'),
        COUNT(DISTINCT product_id) || ' products'
    FROM revenue_finance
    
    UNION ALL
    
    -- Revenue Gap
    SELECT 
        4,
        'Revenue Discrepancy',
        '$' || TO_CHAR(
            (SELECT SUM(revenue) FROM revenue_marketing) - 
            (SELECT SUM(revenue) FROM revenue_finance),
            'FM999,999,990.00'
        ),
        ROUND(
            100.0 * (
                (SELECT SUM(revenue) FROM revenue_marketing) - 
                (SELECT SUM(revenue) FROM revenue_finance)
            ) / NULLIF((SELECT SUM(revenue) FROM revenue_finance), 0),
            1
        ) || '% variance'
    
    UNION ALL
    
    -- Overall ROAS (Marketing)
    SELECT 
        5,
        'Marketing ROAS',
        TO_CHAR(
            (SELECT SUM(revenue) FROM revenue_marketing) / 
            NULLIF((SELECT SUM(spend) FROM marketing_spend), 0),
            'FM0.00'
        ) || 'x',
        'Marketing reported'
    
    UNION ALL
    
    -- Overall ROAS (Finance)
    SELECT 
        6,
        'Finance-Adjusted ROAS',
        TO_CHAR(
            (SELECT SUM(revenue) FROM revenue_finance) / 
            NULLIF((SELECT SUM(spend) FROM marketing_spend), 0),
            'FM0.00'
        ) || 'x',
        'Actual verified'
    
    UNION ALL
    
    -- Total Conversions
    SELECT 
        7,
        'Total Conversions',
        COUNT(DISTINCT user_id)::TEXT,
        'Unique checkout users'
    FROM funnel_events
    WHERE event_type = 'checkout'
    
    UNION ALL
    
    -- Funnel Conversion Rate
    SELECT 
        8,
        'Overall Conversion Rate',
        ROUND(
            100.0 * (
                SELECT COUNT(DISTINCT user_id) FROM funnel_events WHERE event_type = 'checkout'
            ) / NULLIF(
                (SELECT COUNT(DISTINCT user_id) FROM funnel_events WHERE event_type = 'page_view'),
                0
            ),
            1
        ) || '%',
        'Page view to checkout'
        
) summary
ORDER BY sort_order;


-- ============================================================================
-- END OF RECONCILIATION ANALYSIS
-- ============================================================================
-- 
-- Next Steps:
-- 1. Review missing invoices and investigate root causes
-- 2. Audit duplicate attributions with the Marketing team
-- 3. Optimize funnel stages with highest drop-off rates
-- 4. Reallocate budget based on channel performance tiers
-- 5. Implement daily automated reconciliation checks
--
-- ============================================================================
