-- 01_media_spend.sql
-- Extract weekly media spend by channel from raw ad platform data
-- Assumes data is already loaded into BigQuery from Facebook/Google/TikTok APIs

CREATE OR REPLACE VIEW `your_project.marketing_mmm.weekly_media_spend` AS
WITH raw_spend AS (
  -- Facebook Ads
  SELECT 
    DATE_TRUNC(date, WEEK(MONDAY)) AS week_start,
    'facebook' AS channel,
    SUM(spend) AS spend,
    SUM(impressions) AS impressions,
    SUM(clicks) AS clicks
  FROM `your_project.raw_ads.facebook_ads`
  GROUP BY 1, 2

  UNION ALL

  -- Google Ads
  SELECT 
    DATE_TRUNC(date, WEEK(MONDAY)) AS week_start,
    'google' AS channel,
    SUM(cost) / 1000000 AS spend,  -- Micros to currency
    SUM(impressions) AS impressions,
    SUM(clicks) AS clicks
  FROM `your_project.raw_ads.google_ads`
  GROUP BY 1, 2

  UNION ALL

  -- TikTok Ads
  SELECT 
    DATE_TRUNC(date, WEEK(MONDAY)) AS week_start,
    'tiktok' AS channel,
    SUM(spend) AS spend,
    SUM(impressions) AS impressions,
    SUM(clicks) AS clicks
  FROM `your_project.raw_ads.tiktok_ads`
  GROUP BY 1, 2

  UNION ALL

  -- TV (from media plan)
  SELECT 
    DATE_TRUNC(date, WEEK(MONDAY)) AS week_start,
    'tv' AS channel,
    SUM(cost) AS spend,
    SUM(grp * universe / 100) AS impressions,
    0 AS clicks
  FROM `your_project.raw_ads.tv_spots`
  GROUP BY 1, 2

  UNION ALL

  -- Radio
  SELECT 
    DATE_TRUNC(date, WEEK(MONDAY)) AS week_start,
    'radio' AS channel,
    SUM(cost) AS spend,
    SUM(listeners) AS impressions,
    0 AS clicks
  FROM `your_project.raw_ads.radio_spots`
  GROUP BY 1, 2

  UNION ALL

  -- OOH (Out of Home)
  SELECT 
    DATE_TRUNC(date, WEEK(MONDAY)) AS week_start,
    'ooh' AS channel,
    SUM(cost) AS spend,
    SUM(estimated_views) AS impressions,
    0 AS clicks
  FROM `your_project.raw_ads.ooh_campaigns`
  GROUP BY 1, 2
)
SELECT 
  week_start,
  channel,
  spend,
  impressions,
  clicks,
  -- Cost per thousand impressions
  SAFE_DIVIDE(spend * 1000, impressions) AS cpm,
  -- Cost per click
  SAFE_DIVIDE(spend, clicks) AS cpc
FROM raw_spend
WHERE spend > 0
ORDER BY week_start, channel;
