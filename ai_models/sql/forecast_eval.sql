-- Step 6: Evaluate ARIMA_PLUS on last 4 weeks (WAPE)
WITH preds AS (
  SELECT *
  FROM ML.FORECAST(MODEL `ai_classmate.demand_arima`, STRUCT(4 AS horizon))
), actuals AS (
  SELECT
    CONCAT(subject_code, '|', area_code) AS ts_id,
    week_start,
    enrols
  FROM `ai_classmate.weekly_demand`
  WHERE week_start >= DATE_SUB(CURRENT_DATE(), INTERVAL 4 WEEK)
)
SELECT
  SUM(ABS(a.enrols - p.forecast_value)) / NULLIF(SUM(a.enrols), 0) AS wape
FROM preds p
JOIN actuals a
  ON a.ts_id = p.time_series_id
 AND a.week_start = p.forecast_timestamp;
