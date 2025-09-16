-- Subject-level clicks forecast (next 8 weeks)
CREATE OR REPLACE TABLE `ai_classmate.subject_clicks_forecast` AS
SELECT
  sc.ts_id AS subject_code,
  DATE(sc.forecast_timestamp) AS week_start,
  sc.forecast_value           AS clicks_pred,
  sc.prediction_interval_lower_bound AS pred_lo,
  sc.prediction_interval_upper_bound AS pred_hi
FROM ML.FORECAST(
  MODEL `ai_classmate.demand_arima_clicks_subject`,
  STRUCT(8 AS horizon)
) AS sc;
