-- Step 6: Produce next 8-week forecasts table
CREATE OR REPLACE TABLE `ai_classmate.weekly_demand_forecast` AS
SELECT
  p.time_series_id AS ts_id,
  SPLIT(p.time_series_id, '|')[OFFSET(0)] AS subject_code,
  SPLIT(p.time_series_id, '|')[OFFSET(1)] AS area_code,
  p.forecast_timestamp AS week_start,
  p.forecast_value     AS enrols_pred,
  p.prediction_interval_lower AS pred_lo,
  p.prediction_interval_upper AS pred_hi
FROM ML.FORECAST(MODEL `ai_classmate.demand_arima`, STRUCT(8 AS horizon));
