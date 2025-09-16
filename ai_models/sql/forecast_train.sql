-- Step 6: Demand forecasting with BQML ARIMA_PLUS (train)
-- Trains per subject_code × area_code panel using last N-4 weeks; reserves 4 weeks for eval

CREATE OR REPLACE MODEL `ai_classmate.demand_arima`
OPTIONS (
  MODEL_TYPE = 'ARIMA_PLUS',
  TIME_SERIES_TIMESTAMP_COL = 'week_start',
  TIME_SERIES_DATA_COL      = 'enrols',
  TIME_SERIES_ID_COL        = 'ts_id',
  HOLIDAY_REGION            = 'IN',           -- closest to LK in availability
  AUTO_ARIMA                = TRUE,
  DECOMPOSE_TIME_SERIES     = TRUE
) AS
SELECT
  week_start,
  enrols,
  CONCAT(subject_code, '|', area_code) AS ts_id
FROM `ai_classmate.weekly_demand`
WHERE week_start < DATE_SUB(CURRENT_DATE(), INTERVAL 4 WEEK);
