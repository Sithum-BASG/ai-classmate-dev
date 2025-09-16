-- Step 5: Train backup Logistic Regression with BigQuery ML
CREATE OR REPLACE MODEL `ai_classmate.bqml_rec_lr`
OPTIONS (
  model_type = 'logistic_reg',
  input_label_cols = ['label_clicked_or_enrolled'],
  data_split_method = 'RANDOM',
  data_split_eval_fraction = 0.2,
  auto_class_weights = TRUE,
  enable_global_explain = TRUE
) AS
SELECT
  -- cast booleans to numeric for stability
  SAFE_CAST(subject_match   AS INT64) AS subject_match,
  SAFE_CAST(grade_match     AS INT64) AS grade_match,
  SAFE_CAST(time_overlap    AS INT64) AS time_overlap,
  distance_bucket,
  SAFE_CAST(price_band_fit  AS INT64) AS price_band_fit,
  SAFE_CAST(tutor_popularity AS FLOAT64) AS tutor_popularity,
  SAFE_CAST(past_clicks_30d AS INT64) AS past_clicks_30d,
  SAFE_CAST(past_enrols_90d AS INT64) AS past_enrols_90d,
  label_clicked_or_enrolled
FROM `ai_classmate.recs_training_pairs`;
