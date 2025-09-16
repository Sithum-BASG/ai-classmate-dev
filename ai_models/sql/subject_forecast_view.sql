-- View: subject forecast with names
CREATE OR REPLACE VIEW `ai_classmate.v_subject_clicks_forecast` AS
SELECT
  f.subject_code,
  s.name AS subject_name,
  f.week_start,
  f.clicks_pred,
  f.pred_lo,
  f.pred_hi
FROM `ai_classmate.subject_clicks_forecast` f
LEFT JOIN `ai_classmate.subject` s
  ON s.subject_code = f.subject_code;
