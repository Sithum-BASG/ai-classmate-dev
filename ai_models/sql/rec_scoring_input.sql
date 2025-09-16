-- Scoring input table (features only; no label)
CREATE OR REPLACE TABLE ai_classmate.recs_scoring_input AS
SELECT
  student_id,
  class_id,
  subject_match,
  grade_match,
  time_overlap,
  distance_bucket,
  price_band_fit,
  tutor_popularity,
  past_clicks_30d,
  past_enrols_90d
FROM ai_classmate.recs_training_pairs;
