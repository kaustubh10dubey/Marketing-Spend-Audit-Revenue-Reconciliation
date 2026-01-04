-- ============================================================================
-- DASHBOARD QUERIES FOR TABLEAU / POWER BI
-- PostgreSQL Optimized Queries for Visualization Tools
-- ============================================================================
-- 
-- Purpose: Pre-aggregated queries optimized for BI tool consumption
-- Designed for: Tableau, Power BI, Looker, Metabase, Superset
--
-- Features:
--   - Parameterized date filtering
--   - Channel/Campaign selection
--   - Optimized for visualization performance
--   - Semantic column naming for easy mapping
--
-- Usage: Replace {{parameter}} placeholders with your BI tool's syntax
--   - Tableau: <Parameters.DateStart>
--   - Power BI: @DateStart or use Power Query parameters
--
-- Author: Data Analytics Team
-- Created: 2025-01-04
-- ============================================================================


-- ============================================================================
-- DASHBOARD 1: DAILY SPEND TREND
-- ============================================================================
-- Line chart showing daily marketing spend over time
-- Supports: Time series, trend lines, moving averages
-- Chart Type: Line Chart with optional area fill

-- Parameters:
--   {{date_start}} - Analysis start date (e.g., '2023-01-01')
--   {{date_end}}   - Analysis end date (e.g., '2023-01-31')
--   {{campaign}}   - Campaign filter (e.g., 'Campaign A' or 'ALL')

SELECT 
    date AS spend_date,
    campaign AS channel,
    spend AS daily_spend,
    
    -- Running totals for cumulative view
    SUM(spend) OVER (
        PARTITION BY campaign 
        ORDER BY date 
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_spend,
    
    -- 7-day moving average for trend smoothing
    ROUND(
        AVG(spend) OVER (
            PARTITION BY campaign 
            ORDER BY date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 2
    ) AS spend_7day_ma,
    
    -- Day-over-day change
    spend - LAG(spend) OVER (PARTITION BY campaign ORDER BY date) AS daily_change,
    
    -- Percentage change
    ROUND(
        100.0 * (spend - LAG(spend) OVER (PARTITION BY campaign ORDER BY date)) 
        / NULLIF(LAG(spend) OVER (PARTITION BY campaign ORDER BY date), 0),
        2
    ) AS daily_change_pct,
    
    -- Day of week for pattern analysis
    EXTRACT(DOW FROM date) AS day_of_week,
    TO_CHAR(date, 'Day') AS day_name,
    
    -- Week number for aggregation
    EXTRACT(WEEK FROM date) AS week_number

FROM marketing_spend

WHERE 
    -- Date filter (replace with BI tool parameters)
    date >= COALESCE('{{date_start}}'::DATE, '2023-01-01'::DATE)
    AND date <= COALESCE('{{date_end}}'::DATE, '2023-12-31'::DATE)
    -- Campaign filter (use 'ALL' to include all campaigns)
    AND (
        '{{campaign}}' = 'ALL' 
        OR campaign = '{{campaign}}'
        OR '{{campaign}}' IS NULL
    )

ORDER BY date, campaign;


-- ============================================================================
-- DASHBOARD 2: ROAS BY CHANNEL (DUAL AXIS)
-- ============================================================================
-- Dual-axis chart: Bars for Spend/Revenue, Line for ROAS
-- Compares Marketing ROAS vs Finance-adjusted ROAS
-- Chart Type: Combo Chart (Bar + Line)

WITH 
-- Aggregate spend per campaign
spend_agg AS (
    SELECT 
        campaign,
        SUM(spend) AS total_spend,
        COUNT(DISTINCT date) AS active_days
    FROM marketing_spend
    WHERE date >= COALESCE('{{date_start}}'::DATE, '2023-01-01'::DATE)
      AND date <= COALESCE('{{date_end}}'::DATE, '2023-12-31'::DATE)
    GROUP BY campaign
),

-- Marketing revenue per campaign
marketing_rev AS (
    SELECT 
        campaign,
        SUM(revenue) AS marketing_revenue
    FROM revenue_marketing
    WHERE date >= COALESCE('{{date_start}}'::DATE, '2023-01-01'::DATE)
      AND date <= COALESCE('{{date_end}}'::DATE, '2023-12-31'::DATE)
    GROUP BY campaign
),

-- Finance total (for proportional allocation)
finance_total AS (
    SELECT SUM(revenue) AS total_finance_revenue
    FROM revenue_finance
    WHERE date >= COALESCE('{{date_start}}'::DATE, '2023-01-01'::DATE)
      AND date <= COALESCE('{{date_end}}'::DATE, '2023-12-31'::DATE)
),

-- Calculate total spend for proportion
total_spend AS (
    SELECT SUM(total_spend) AS all_spend
    FROM spend_agg
)

SELECT 
    s.campaign AS channel,
    
    -- Primary metrics
    s.total_spend AS spend,
    COALESCE(m.marketing_revenue, 0) AS marketing_revenue,
    
    -- Finance revenue (proportionally allocated by spend share)
    ROUND(
        f.total_finance_revenue * (s.total_spend / NULLIF(t.all_spend, 0)),
        2
    ) AS finance_revenue_allocated,
    
    -- ROAS calculations (for line axis)
    ROUND(
        COALESCE(m.marketing_revenue, 0) / NULLIF(s.total_spend, 0),
        2
    ) AS marketing_roas,
    
    ROUND(
        (f.total_finance_revenue * (s.total_spend / NULLIF(t.all_spend, 0))) 
        / NULLIF(s.total_spend, 0),
        2
    ) AS finance_roas,
    
    -- ROAS gap (marketing over-reporting)
    ROUND(
        COALESCE(m.marketing_revenue, 0) / NULLIF(s.total_spend, 0) -
        (f.total_finance_revenue * (s.total_spend / NULLIF(t.all_spend, 0))) 
        / NULLIF(s.total_spend, 0),
        2
    ) AS roas_gap,
    
    -- Profit/Loss indicators
    COALESCE(m.marketing_revenue, 0) - s.total_spend AS marketing_profit,
    
    -- Performance tier for color coding
    CASE 
        WHEN COALESCE(m.marketing_revenue, 0) / NULLIF(s.total_spend, 0) >= 2.5 THEN 'Excellent'
        WHEN COALESCE(m.marketing_revenue, 0) / NULLIF(s.total_spend, 0) >= 1.5 THEN 'Good'
        WHEN COALESCE(m.marketing_revenue, 0) / NULLIF(s.total_spend, 0) >= 1.0 THEN 'Break-even'
        ELSE 'Underperforming'
    END AS performance_tier,
    
    -- Color codes for BI tools
    CASE 
        WHEN COALESCE(m.marketing_revenue, 0) / NULLIF(s.total_spend, 0) >= 2.0 THEN '#28a745'  -- Green
        WHEN COALESCE(m.marketing_revenue, 0) / NULLIF(s.total_spend, 0) >= 1.0 THEN '#ffc107'  -- Yellow
        ELSE '#dc3545'  -- Red
    END AS status_color

FROM spend_agg s
LEFT JOIN marketing_rev m ON s.campaign = m.campaign
CROSS JOIN finance_total f
CROSS JOIN total_spend t

WHERE 
    '{{campaign}}' = 'ALL' 
    OR s.campaign = '{{campaign}}'
    OR '{{campaign}}' IS NULL

ORDER BY marketing_roas DESC;


-- ============================================================================
-- DASHBOARD 3: FUNNEL VISUALIZATION DATA
-- ============================================================================
-- Horizontal/Vertical funnel chart data
-- Each row = one funnel stage with conversion metrics
-- Chart Type: Funnel Chart, Horizontal Bar

WITH 
-- Base funnel counts
funnel_counts AS (
    SELECT 
        event_type,
        COUNT(DISTINCT user_id) AS unique_users,
        COUNT(*) AS total_events,
        MIN(timestamp) AS first_event,
        MAX(timestamp) AS last_event
    FROM funnel_events
    WHERE 
        DATE(timestamp) >= COALESCE('{{date_start}}'::DATE, '2023-01-01'::DATE)
        AND DATE(timestamp) <= COALESCE('{{date_end}}'::DATE, '2023-12-31'::DATE)
    GROUP BY event_type
),

-- Add stage ordering
ordered_funnel AS (
    SELECT 
        *,
        CASE event_type
            WHEN 'page_view' THEN 1
            WHEN 'add_to_cart' THEN 2
            WHEN 'checkout' THEN 3
            WHEN 'purchase' THEN 4
            ELSE 99
        END AS stage_order,
        CASE event_type
            WHEN 'page_view' THEN 'Page View'
            WHEN 'add_to_cart' THEN 'Add to Cart'
            WHEN 'checkout' THEN 'Checkout'
            WHEN 'purchase' THEN 'Purchase'
            ELSE 'Other'
        END AS stage_label
    FROM funnel_counts
    WHERE event_type IN ('page_view', 'add_to_cart', 'checkout', 'purchase')
),

-- Calculate metrics
funnel_metrics AS (
    SELECT 
        stage_order,
        stage_label,
        event_type,
        unique_users,
        total_events,
        -- Top of funnel for percentage
        FIRST_VALUE(unique_users) OVER (ORDER BY stage_order) AS top_funnel_users,
        -- Previous stage for conversion rate
        LAG(unique_users) OVER (ORDER BY stage_order) AS prev_stage_users
    FROM ordered_funnel
)

SELECT 
    stage_order,
    stage_label,
    event_type AS stage_code,
    unique_users,
    total_events,
    
    -- Funnel width (for visualization sizing)
    unique_users AS funnel_width,
    
    -- Percentage of top funnel
    ROUND(100.0 * unique_users / NULLIF(top_funnel_users, 0), 1) AS pct_of_top,
    
    -- Stage-to-stage conversion
    CASE 
        WHEN prev_stage_users IS NULL THEN 100.0
        ELSE ROUND(100.0 * unique_users / NULLIF(prev_stage_users, 0), 1)
    END AS stage_conversion_rate,
    
    -- Drop-off rate
    CASE 
        WHEN prev_stage_users IS NULL THEN 0.0
        ELSE ROUND(100.0 * (prev_stage_users - unique_users) / NULLIF(prev_stage_users, 0), 1)
    END AS drop_off_rate,
    
    -- Users lost at this stage
    COALESCE(prev_stage_users - unique_users, 0) AS users_lost,
    
    -- Color gradient for funnel (darker = more users)
    CASE stage_order
        WHEN 1 THEN '#0d6efd'  -- Blue
        WHEN 2 THEN '#6610f2'  -- Indigo
        WHEN 3 THEN '#6f42c1'  -- Purple
        WHEN 4 THEN '#20c997'  -- Teal (success)
        ELSE '#6c757d'
    END AS stage_color,
    
    -- Bottleneck flag
    CASE 
        WHEN prev_stage_users IS NOT NULL 
             AND (prev_stage_users - unique_users) / NULLIF(prev_stage_users, 0) > 0.3
        THEN 'Yes'
        ELSE 'No'
    END AS is_bottleneck

FROM funnel_metrics
ORDER BY stage_order;


-- ============================================================================
-- DASHBOARD 4: VARIANCE HEATMAP (DATE LEVEL)
-- ============================================================================
-- Daily variance between Marketing and Finance revenue
-- Chart Type: Heatmap, Calendar View, Matrix

WITH 
daily_marketing AS (
    SELECT 
        date,
        SUM(revenue) AS mkt_revenue,
        STRING_AGG(DISTINCT campaign, ', ') AS campaigns
    FROM revenue_marketing
    WHERE date >= COALESCE('{{date_start}}'::DATE, '2023-01-01'::DATE)
      AND date <= COALESCE('{{date_end}}'::DATE, '2023-12-31'::DATE)
    GROUP BY date
),

daily_finance AS (
    SELECT 
        date,
        SUM(revenue) AS fin_revenue,
        STRING_AGG(DISTINCT product_id, ', ') AS products
    FROM revenue_finance
    WHERE date >= COALESCE('{{date_start}}'::DATE, '2023-01-01'::DATE)
      AND date <= COALESCE('{{date_end}}'::DATE, '2023-12-31'::DATE)
    GROUP BY date
)

SELECT 
    COALESCE(m.date, f.date) AS date,
    
    -- Date components for calendar heatmap
    EXTRACT(YEAR FROM COALESCE(m.date, f.date)) AS year,
    EXTRACT(MONTH FROM COALESCE(m.date, f.date)) AS month,
    TO_CHAR(COALESCE(m.date, f.date), 'Mon') AS month_name,
    EXTRACT(DAY FROM COALESCE(m.date, f.date)) AS day,
    EXTRACT(DOW FROM COALESCE(m.date, f.date)) AS day_of_week,
    EXTRACT(WEEK FROM COALESCE(m.date, f.date)) AS week_number,
    
    -- Revenue values
    COALESCE(m.mkt_revenue, 0) AS marketing_revenue,
    COALESCE(f.fin_revenue, 0) AS finance_revenue,
    
    -- Variance calculations
    COALESCE(m.mkt_revenue, 0) - COALESCE(f.fin_revenue, 0) AS variance_amount,
    
    -- Variance percentage (for color intensity)
    CASE 
        WHEN COALESCE(f.fin_revenue, 0) = 0 AND COALESCE(m.mkt_revenue, 0) > 0 THEN 100.0
        WHEN COALESCE(f.fin_revenue, 0) = 0 THEN 0.0
        ELSE ROUND(
            100.0 * (COALESCE(m.mkt_revenue, 0) - COALESCE(f.fin_revenue, 0)) 
            / f.fin_revenue,
            1
        )
    END AS variance_pct,
    
    -- Variance category for legend
    CASE 
        WHEN m.date IS NULL THEN 'Finance Only'
        WHEN f.date IS NULL THEN 'Marketing Only'
        WHEN m.mkt_revenue = f.fin_revenue THEN 'Matched'
        WHEN m.mkt_revenue > f.fin_revenue * 1.2 THEN 'Over >20%'
        WHEN m.mkt_revenue > f.fin_revenue THEN 'Over 0-20%'
        WHEN m.mkt_revenue < f.fin_revenue * 0.8 THEN 'Under >20%'
        ELSE 'Under 0-20%'
    END AS variance_category,
    
    -- Color for heatmap (red = over, green = under, white = match)
    CASE 
        WHEN m.date IS NULL THEN '#17a2b8'  -- Blue (finance only)
        WHEN f.date IS NULL THEN '#fd7e14'  -- Orange (marketing only)
        WHEN m.mkt_revenue = f.fin_revenue THEN '#ffffff'  -- White
        WHEN m.mkt_revenue > f.fin_revenue * 1.2 THEN '#dc3545'  -- Dark red
        WHEN m.mkt_revenue > f.fin_revenue THEN '#f8d7da'  -- Light red
        WHEN m.mkt_revenue < f.fin_revenue * 0.8 THEN '#28a745'  -- Dark green
        ELSE '#d4edda'  -- Light green
    END AS heatmap_color,
    
    -- Associated data
    m.campaigns,
    f.products

FROM daily_marketing m
FULL OUTER JOIN daily_finance f ON m.date = f.date

ORDER BY COALESCE(m.date, f.date);


-- ============================================================================
-- DASHBOARD 5: CAC TREND (CUSTOMER ACQUISITION COST)
-- ============================================================================
-- Daily/Weekly CAC trend with channel breakdown
-- Chart Type: Line Chart, Area Chart

WITH 
-- Daily conversions (checkout events)
daily_conversions AS (
    SELECT 
        DATE(timestamp) AS conversion_date,
        COUNT(DISTINCT user_id) AS new_customers
    FROM funnel_events
    WHERE event_type = 'checkout'
      AND DATE(timestamp) >= COALESCE('{{date_start}}'::DATE, '2023-01-01'::DATE)
      AND DATE(timestamp) <= COALESCE('{{date_end}}'::DATE, '2023-12-31'::DATE)
    GROUP BY DATE(timestamp)
),

-- Daily spend
daily_spend AS (
    SELECT 
        date AS spend_date,
        campaign,
        spend
    FROM marketing_spend
    WHERE date >= COALESCE('{{date_start}}'::DATE, '2023-01-01'::DATE)
      AND date <= COALESCE('{{date_end}}'::DATE, '2023-12-31'::DATE)
),

-- Combined daily metrics
daily_metrics AS (
    SELECT 
        ds.spend_date AS date,
        ds.campaign,
        ds.spend,
        COALESCE(dc.new_customers, 0) AS total_conversions_day,
        -- Allocate conversions proportionally to spend
        COALESCE(
            dc.new_customers * ds.spend / NULLIF(
                SUM(ds.spend) OVER (PARTITION BY ds.spend_date), 0
            ), 0
        ) AS attributed_conversions
    FROM daily_spend ds
    LEFT JOIN daily_conversions dc ON ds.spend_date = dc.conversion_date
)

SELECT 
    date,
    campaign AS channel,
    spend,
    ROUND(attributed_conversions, 2) AS attributed_conversions,
    
    -- Daily CAC
    CASE 
        WHEN attributed_conversions > 0 
        THEN ROUND(spend / attributed_conversions, 2)
        ELSE NULL
    END AS daily_cac,
    
    -- 7-day rolling CAC (smoother trend)
    ROUND(
        SUM(spend) OVER (
            PARTITION BY campaign 
            ORDER BY date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) / NULLIF(
            SUM(attributed_conversions) OVER (
                PARTITION BY campaign 
                ORDER BY date 
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ), 0
        ),
        2
    ) AS cac_7day_rolling,
    
    -- Cumulative CAC
    ROUND(
        SUM(spend) OVER (
            PARTITION BY campaign 
            ORDER BY date 
            ROWS UNBOUNDED PRECEDING
        ) / NULLIF(
            SUM(attributed_conversions) OVER (
                PARTITION BY campaign 
                ORDER BY date 
                ROWS UNBOUNDED PRECEDING
            ), 0
        ),
        2
    ) AS cac_cumulative,
    
    -- CAC benchmark comparison ($100 target)
    CASE 
        WHEN attributed_conversions > 0 AND spend / attributed_conversions <= 100 
        THEN 'Below Target'
        WHEN attributed_conversions > 0 AND spend / attributed_conversions <= 150 
        THEN 'Near Target'
        WHEN attributed_conversions > 0 
        THEN 'Above Target'
        ELSE 'No Conversions'
    END AS cac_status,
    
    -- Color for status
    CASE 
        WHEN attributed_conversions > 0 AND spend / attributed_conversions <= 100 
        THEN '#28a745'
        WHEN attributed_conversions > 0 AND spend / attributed_conversions <= 150 
        THEN '#ffc107'
        WHEN attributed_conversions > 0 
        THEN '#dc3545'
        ELSE '#6c757d'
    END AS status_color

FROM daily_metrics

WHERE 
    '{{campaign}}' = 'ALL' 
    OR campaign = '{{campaign}}'
    OR '{{campaign}}' IS NULL

ORDER BY date, campaign;


-- ============================================================================
-- DASHBOARD 6: MISREPORTING FLAGS
-- ============================================================================
-- Identifies and categorizes data quality issues
-- Chart Type: Table, KPI Cards, Alert Dashboard

WITH 
-- Flag 1: Marketing revenue with no Finance record
missing_finance AS (
    SELECT 
        rm.date,
        rm.campaign,
        rm.revenue AS amount,
        'Missing Finance Record' AS flag_type,
        'Marketing recorded revenue but no Finance verification exists' AS description,
        'HIGH' AS severity
    FROM revenue_marketing rm
    LEFT JOIN (SELECT DISTINCT date FROM revenue_finance) rf ON rm.date = rf.date
    WHERE rf.date IS NULL
      AND rm.date >= COALESCE('{{date_start}}'::DATE, '2023-01-01'::DATE)
      AND rm.date <= COALESCE('{{date_end}}'::DATE, '2023-12-31'::DATE)
),

-- Flag 2: Large variance days (>30% difference)
large_variance AS (
    SELECT 
        COALESCE(m.date, f.date) AS date,
        STRING_AGG(DISTINCT m.campaign, ', ') AS campaign,
        ABS(COALESCE(SUM(m.revenue), 0) - COALESCE(SUM(f.revenue), 0)) AS amount,
        'Large Variance' AS flag_type,
        'Marketing vs Finance variance exceeds 30%' AS description,
        'MEDIUM' AS severity
    FROM revenue_marketing m
    FULL OUTER JOIN revenue_finance f ON m.date = f.date
    WHERE COALESCE(m.date, f.date) >= COALESCE('{{date_start}}'::DATE, '2023-01-01'::DATE)
      AND COALESCE(m.date, f.date) <= COALESCE('{{date_end}}'::DATE, '2023-12-31'::DATE)
    GROUP BY COALESCE(m.date, f.date)
    HAVING 
        COALESCE(SUM(f.revenue), 0) > 0 
        AND ABS(COALESCE(SUM(m.revenue), 0) - COALESCE(SUM(f.revenue), 0)) 
            / COALESCE(SUM(f.revenue), 1) > 0.3
),

-- Flag 3: Users with multiple checkouts (potential duplicate attribution)
duplicate_conversions AS (
    SELECT 
        MIN(DATE(timestamp)) AS date,
        user_id AS campaign,  -- Using campaign field for user_id display
        COUNT(*) - 1 AS amount,
        'Duplicate Conversion' AS flag_type,
        'User has multiple checkout events - possible double counting' AS description,
        'LOW' AS severity
    FROM funnel_events
    WHERE event_type = 'checkout'
      AND DATE(timestamp) >= COALESCE('{{date_start}}'::DATE, '2023-01-01'::DATE)
      AND DATE(timestamp) <= COALESCE('{{date_end}}'::DATE, '2023-12-31'::DATE)
    GROUP BY user_id
    HAVING COUNT(*) > 1
),

-- Flag 4: Zero spend days with revenue (attribution without spend)
revenue_without_spend AS (
    SELECT 
        rm.date,
        rm.campaign,
        rm.revenue AS amount,
        'Revenue Without Spend' AS flag_type,
        'Revenue attributed but no marketing spend recorded for this day/channel' AS description,
        'MEDIUM' AS severity
    FROM revenue_marketing rm
    LEFT JOIN marketing_spend ms ON rm.date = ms.date AND rm.campaign = ms.campaign
    WHERE ms.date IS NULL
      AND rm.date >= COALESCE('{{date_start}}'::DATE, '2023-01-01'::DATE)
      AND rm.date <= COALESCE('{{date_end}}'::DATE, '2023-12-31'::DATE)
)

-- Combine all flags
SELECT 
    date,
    campaign AS entity,
    flag_type,
    amount,
    description,
    severity,
    
    -- Severity color
    CASE severity
        WHEN 'HIGH' THEN '#dc3545'
        WHEN 'MEDIUM' THEN '#ffc107'
        WHEN 'LOW' THEN '#17a2b8'
        ELSE '#6c757d'
    END AS severity_color,
    
    -- Priority score (for sorting)
    CASE severity
        WHEN 'HIGH' THEN 1
        WHEN 'MEDIUM' THEN 2
        WHEN 'LOW' THEN 3
        ELSE 4
    END AS priority_order

FROM (
    SELECT * FROM missing_finance
    UNION ALL
    SELECT * FROM large_variance
    UNION ALL
    SELECT * FROM duplicate_conversions
    UNION ALL
    SELECT * FROM revenue_without_spend
) all_flags

ORDER BY priority_order, date;

-- Summary KPIs for flags dashboard
SELECT 
    flag_type,
    COUNT(*) AS flag_count,
    SUM(amount) AS total_amount_flagged,
    MIN(severity) AS max_severity
FROM (
    SELECT * FROM missing_finance
    UNION ALL
    SELECT * FROM large_variance
    UNION ALL
    SELECT * FROM duplicate_conversions
    UNION ALL
    SELECT * FROM revenue_without_spend
) all_flags
GROUP BY flag_type
ORDER BY 
    CASE MIN(severity)
        WHEN 'HIGH' THEN 1
        WHEN 'MEDIUM' THEN 2
        ELSE 3
    END;


-- ============================================================================
-- UTILITY VIEWS: CREATE FOR REPEATED USE
-- ============================================================================

-- View for frequently used date spine
CREATE OR REPLACE VIEW vw_date_spine AS
SELECT 
    generate_series(
        (SELECT MIN(date) FROM marketing_spend),
        (SELECT MAX(date) FROM marketing_spend),
        '1 day'::INTERVAL
    )::DATE AS date;

-- View for channel performance (refreshable)
CREATE OR REPLACE VIEW vw_channel_performance AS
SELECT 
    ms.campaign,
    SUM(ms.spend) AS total_spend,
    COALESCE(SUM(rm.revenue), 0) AS marketing_revenue,
    ROUND(COALESCE(SUM(rm.revenue), 0) / NULLIF(SUM(ms.spend), 0), 2) AS roas,
    CASE 
        WHEN COALESCE(SUM(rm.revenue), 0) / NULLIF(SUM(ms.spend), 0) >= 2.0 THEN 'Profitable'
        WHEN COALESCE(SUM(rm.revenue), 0) / NULLIF(SUM(ms.spend), 0) >= 1.0 THEN 'Break-even'
        ELSE 'Underperforming'
    END AS status
FROM marketing_spend ms
LEFT JOIN revenue_marketing rm ON ms.date = rm.date AND ms.campaign = rm.campaign
GROUP BY ms.campaign;


-- ============================================================================
-- END OF DASHBOARD QUERIES
-- ============================================================================
