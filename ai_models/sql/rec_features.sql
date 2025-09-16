-- Build RECS_TRAINING_PAIRS from existing final tables
-- Output: ai_classmate.recs_training_pairs

CREATE OR REPLACE TABLE ai_classmate.recs_training_pairs AS
WITH published_classes AS (
  SELECT c.*
  FROM ai_classmate.class c
  WHERE c.status = 'published'
),
students AS (
  SELECT u.user_id AS student_id, sp.grade, sp.area_code, sp.subjects_of_interest
  FROM ai_classmate.`user` u
  JOIN ai_classmate.student_profile sp ON sp.user_id = u.user_id
  WHERE u.role = 'student' AND u.is_active IS TRUE
),
class_time AS (
  SELECT
    cs.class_id,
    LOGICAL_OR(EXTRACT(DAYOFWEEK FROM cs.session_date) IN (1,7)) AS has_weekend,
    LOGICAL_OR(cs.start_time >= TIME '16:00:00') AS has_evening
  FROM ai_classmate.class_session cs
  GROUP BY cs.class_id
),
area_points AS (
  SELECT area_code, ST_GEOGPOINT(lng, lat) AS geom
  FROM ai_classmate.area
),
class_area AS (
  SELECT c.class_id, c.tutor_id, c.subject_code, c.area_code, ap.geom AS geom
  FROM published_classes c
  LEFT JOIN area_points ap ON ap.area_code = c.area_code
),
student_area AS (
  SELECT s.student_id, s.grade, s.area_code, s.subjects_of_interest, ap.geom AS geom
  FROM students s
  LEFT JOIN area_points ap ON ap.area_code = s.area_code
),
distances AS (
  SELECT
    sa.student_id,
    ca.class_id,
    CASE
      WHEN sa.geom IS NULL OR ca.geom IS NULL THEN 'unknown'
      WHEN sa.area_code = ca.area_code THEN 'same_area'
      ELSE (
        CASE
          WHEN ST_DISTANCE(sa.geom, ca.geom) < 5000 THEN '0_5km'
          WHEN ST_DISTANCE(sa.geom, ca.geom) < 10000 THEN '5_10km'
          WHEN ST_DISTANCE(sa.geom, ca.geom) < 20000 THEN '10_20km'
          ELSE 'gt_20km'
        END
      )
    END AS distance_bucket
  FROM student_area sa
  CROSS JOIN class_area ca
),
tutor_pop AS (
  SELECT
    c.tutor_id,
    COALESCE(SUM(
      CASE e.event_type
        WHEN 'enrol' THEN 3.0
        WHEN 'click' THEN 1.0
        WHEN 'view_class' THEN 0.2
        WHEN 'impression' THEN 0.1
        ELSE 0.0
      END
    ), 0.0) AS ev_score
  FROM ai_classmate.event_interaction e
  JOIN ai_classmate.class c ON c.class_id = e.class_id
  WHERE e.ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
  GROUP BY c.tutor_id
),
tutor_meta AS (
  SELECT tp.user_id AS tutor_id, tp.rating_count
  FROM ai_classmate.tutor_profile tp
),
combined_pop AS (
  SELECT
    COALESCE(tp.tutor_id, tm.tutor_id) AS tutor_id,
    COALESCE(tp.ev_score, 0.0) + COALESCE(tm.rating_count, 0) * 0.01 AS tutor_popularity
  FROM tutor_pop tp
  FULL OUTER JOIN tutor_meta tm ON tp.tutor_id = tm.tutor_id
),
clicks30 AS (
  SELECT student_id, class_id, COUNTIF(event_type = 'click') AS past_clicks_30d
  FROM ai_classmate.event_interaction
  WHERE ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  GROUP BY student_id, class_id
),
enrols90 AS (
  SELECT student_id, class_id, COUNTIF(event_type = 'enrol') AS past_enrols_90d
  FROM ai_classmate.event_interaction
  WHERE ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
  GROUP BY student_id, class_id
),
labels AS (
  SELECT student_id, class_id, COUNTIF(event_type IN ('click','enrol')) > 0 AS label_clicked_or_enrolled
  FROM ai_classmate.event_interaction
  GROUP BY student_id, class_id
)
SELECT
  sa.student_id,
  ca.class_id,
  -- Label
  IFNULL(l.label_clicked_or_enrolled, FALSE) AS label_clicked_or_enrolled,
  -- Features
  ca.subject_code IN UNNEST(sa.subjects_of_interest) AS subject_match,
  sa.grade = c.grade AS grade_match,
  IFNULL(ct.has_weekend, FALSE) OR IFNULL(ct.has_evening, FALSE) AS time_overlap,
  d.distance_bucket,
  CASE
    WHEN sa.grade <= 9  AND c.price_band IN ('low','mid') THEN TRUE
    WHEN sa.grade BETWEEN 10 AND 11 AND c.price_band = 'mid' THEN TRUE
    WHEN sa.grade >= 12 AND c.price_band IN ('mid','high') THEN TRUE
    ELSE FALSE
  END AS price_band_fit,
  IFNULL(tp.tutor_popularity, 0.0) AS tutor_popularity,
  IFNULL(c30.past_clicks_30d, 0) AS past_clicks_30d,
  IFNULL(e90.past_enrols_90d, 0) AS past_enrols_90d
FROM student_area sa
JOIN class_area ca ON TRUE
JOIN published_classes c ON c.class_id = ca.class_id
LEFT JOIN class_time ct ON ct.class_id = ca.class_id
LEFT JOIN distances d ON d.student_id = sa.student_id AND d.class_id = ca.class_id
LEFT JOIN combined_pop tp ON tp.tutor_id = ca.tutor_id
LEFT JOIN clicks30 c30 ON c30.student_id = sa.student_id AND c30.class_id = ca.class_id
LEFT JOIN enrols90 e90 ON e90.student_id = sa.student_id AND e90.class_id = ca.class_id
LEFT JOIN labels l ON l.student_id = sa.student_id AND l.class_id = ca.class_id;
