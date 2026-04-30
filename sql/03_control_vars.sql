-- 03_control_vars.sql
-- Seasonality, holidays, and external control variables
-- Essential for separating media effects from baseline

CREATE OR REPLACE VIEW `your_project.marketing_mmm.weekly_controls` AS
SELECT 
  week_start,
  -- Day of year for seasonal sine/cosine
  MOD(EXTRACT(DAYOFYEAR FROM week_start), 52) AS week_of_year,
  -- Holiday flags (Portuguese holidays)
  CASE WHEN FORMAT_DATE('%m-%d', week_start) IN (
    '01-01','04-25','05-01','06-10','08-15','12-25','12-31'
  ) THEN 1 ELSE 0 END AS is_holiday,
  -- Month indicators for seasonality
  EXTRACT(MONTH FROM week_start) AS month_num,
  -- COVID period flag (if relevant)
  CASE WHEN week_start BETWEEN '2020-03-01' AND '2020-06-30' THEN 1 ELSE 0 END AS covid_period,
  -- Black Friday / Cyber Monday week
  CASE WHEN EXTRACT(MONTH FROM week_start) = 11 
    AND EXTRACT(DAY FROM week_start) BETWEEN 20 AND 30 THEN 1 ELSE 0 END AS black_friday_week,
  -- Summer sale period (Portugal)
  CASE WHEN EXTRACT(MONTH FROM week_start) IN (7,8) THEN 1 ELSE 0 END AS summer_period
FROM UNNEST(
  GENERATE_DATE_ARRAY('2020-01-06', '2022-12-26', INTERVAL 1 WEEK)
) AS week_start;
