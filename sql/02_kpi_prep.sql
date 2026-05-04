-- 02_kpi_prep.sql
-- Prepare KPI (revenue/conversions) at weekly grain
-- Uses GA4 ecommerce data from BigQuery

CREATE OR REPLACE VIEW `your_project.marketing_mmm.weekly_kpi` AS
WITH base AS (
  SELECT 
    DATE_TRUNC(PARSE_DATE('%Y%m%d', event_date), WEEK(MONDAY)) AS week_start,
    -- Revenue (ensure it's numeric)
    SUM(ecommerce.purchase_revenue) AS revenue,
    -- Transactions
    COUNT(DISTINCT ecommerce.transaction_id) AS transactions,
    -- Sessions
    COUNT(DISTINCT CONCAT(user_pseudo_id, '_', 
      (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'))) AS sessions,
    -- Users
    COUNT(DISTINCT user_pseudo_id) AS users
  FROM `YOUR_PROJECT.YOUR_DATASET.events_*`
  WHERE event_name = 'purchase'
    AND _TABLE_SUFFIX BETWEEN '20210101' AND '20221231'
  GROUP BY 1
)
SELECT 
  week_start,
  revenue,
  transactions,
  sessions,
  users,
  SAFE_DIVIDE(revenue, transactions) AS avg_order_value,
  SAFE_DIVIDE(transactions, sessions) AS conversion_rate
FROM base
ORDER BY week_start;
