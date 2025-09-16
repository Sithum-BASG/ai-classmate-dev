-- Transform from *_stg (STRINGs) into final typed tables
-- Arrays are parsed from JSON strings

-- USER
DELETE FROM ai_classmate.`user` WHERE true;
INSERT INTO ai_classmate.`user`
SELECT
  user_id,
  email,
  NULLIF(phone, '') AS phone,
  display_name,
  role,
  IFNULL(CAST(is_active AS BOOL), TRUE) AS is_active,
  SAFE.PARSE_TIMESTAMP('%FT%T%Ez', created_at) AS created_at,
  SAFE.PARSE_TIMESTAMP('%FT%T%Ez', updated_at) AS updated_at
FROM ai_classmate.user_stg;

-- STUDENT_PROFILE
DELETE FROM ai_classmate.student_profile WHERE true;
INSERT INTO ai_classmate.student_profile
SELECT
  user_id,
  SAFE_CAST(grade AS INT64),
  area_code,
  (SELECT ARRAY(SELECT JSON_VALUE(x) FROM UNNEST(JSON_QUERY_ARRAY(subjects_of_interest)) x)) AS subjects_of_interest
FROM ai_classmate.student_profile_stg;

-- TUTOR_PROFILE
DELETE FROM ai_classmate.tutor_profile WHERE true;
INSERT INTO ai_classmate.tutor_profile
SELECT
  user_id,
  bio,
  qualifications,
  (SELECT ARRAY(SELECT JSON_VALUE(x) FROM UNNEST(JSON_QUERY_ARRAY(subjects_taught)) x)) AS subjects_taught,
  area_code,
  mode,
  SAFE_CAST(base_price AS NUMERIC),
  SAFE_CAST(rating_avg AS FLOAT64),
  SAFE_CAST(rating_count AS INT64),
  status,
  NULLIF(reviewed_by, '') AS reviewed_by,
  SAFE.PARSE_TIMESTAMP('%FT%T%Ez', reviewed_at) AS reviewed_at
FROM ai_classmate.tutor_profile_stg;

-- ADMIN_PROFILE
DELETE FROM ai_classmate.admin_profile WHERE true;
INSERT INTO ai_classmate.admin_profile
SELECT user_id, role_type FROM ai_classmate.admin_profile_stg;

-- SUBJECT
DELETE FROM ai_classmate.subject WHERE true;
INSERT INTO ai_classmate.subject
SELECT subject_code, name, level FROM ai_classmate.subject_stg;

-- AREA
DELETE FROM ai_classmate.area WHERE true;
INSERT INTO ai_classmate.area
SELECT area_code, area_name, SAFE_CAST(lat AS FLOAT64), SAFE_CAST(lng AS FLOAT64) FROM ai_classmate.area_stg;

-- VENUE
DELETE FROM ai_classmate.venue WHERE true;
INSERT INTO ai_classmate.venue
SELECT venue_id, name, address, area_code, SAFE_CAST(capacity AS INT64) FROM ai_classmate.venue_stg;

-- CLASS
DELETE FROM ai_classmate.class WHERE true;
INSERT INTO ai_classmate.class
SELECT
  class_id,
  tutor_id,
  subject_code,
  SAFE_CAST(grade AS INT64),
  mode,
  area_code,
  NULLIF(venue_id, '') AS venue_id,
  SAFE_CAST(fee AS NUMERIC),
  price_band,
  SAFE_CAST(capacity_seats AS INT64),
  status,
  SAFE.PARSE_TIMESTAMP('%FT%T%Ez', created_at) AS created_at,
  SAFE.PARSE_TIMESTAMP('%FT%T%Ez', NULLIF(published_at, '')) AS published_at
FROM ai_classmate.class_stg;

-- CLASS_SESSION
DELETE FROM ai_classmate.class_session WHERE true;
INSERT INTO ai_classmate.class_session
SELECT
  session_id,
  class_id,
  SAFE_CAST(session_date AS DATE),
  SAFE_CAST(start_time AS TIME),
  SAFE_CAST(end_time AS TIME),
  NULLIF(room, '') AS room,
  SAFE_CAST(is_cancelled AS BOOL) AS is_cancelled,
  NULLIF(cancel_reason, '') AS cancel_reason
FROM ai_classmate.class_session_stg;

-- ENROLLMENT
DELETE FROM ai_classmate.enrollment WHERE true;
INSERT INTO ai_classmate.enrollment
SELECT
  enrollment_id,
  class_id,
  student_id,
  status,
  SAFE.PARSE_TIMESTAMP('%FT%T%Ez', enrolled_at) AS enrolled_at,
  SAFE.PARSE_TIMESTAMP('%FT%T%Ez', NULLIF(cancelled_at, '')) AS cancelled_at,
  NULLIF(cancel_reason, '') AS cancel_reason
FROM ai_classmate.enrollment_stg;

-- INVOICE
DELETE FROM ai_classmate.invoice WHERE true;
INSERT INTO ai_classmate.invoice
SELECT
  invoice_id,
  enrollment_id,
  SAFE_CAST(amount_due AS NUMERIC),
  SAFE_CAST(due_date AS DATE),
  status,
  SAFE.PARSE_TIMESTAMP('%FT%T%Ez', created_at) AS created_at
FROM ai_classmate.invoice_stg;

-- PAYMENT
DELETE FROM ai_classmate.payment WHERE true;
INSERT INTO ai_classmate.payment
SELECT
  payment_id,
  invoice_id,
  SAFE_CAST(paid_amount AS NUMERIC),
  SAFE.PARSE_TIMESTAMP('%FT%T%Ez', paid_at) AS paid_at,
  method,
  proof_url,
  verify_status,
  NULLIF(verified_by, '') AS verified_by,
  SAFE.PARSE_TIMESTAMP('%FT%T%Ez', NULLIF(verified_at, '')) AS verified_at,
  NULLIF(verify_note, '') AS verify_note
FROM ai_classmate.payment_stg;

-- REFUND
DELETE FROM ai_classmate.refund WHERE true;
INSERT INTO ai_classmate.refund
SELECT
  refund_id,
  payment_id,
  SAFE_CAST(refund_amount AS NUMERIC),
  SAFE.PARSE_TIMESTAMP('%FT%T%Ez', refunded_at) AS refunded_at,
  reason,
  processed_by
FROM ai_classmate.refund_stg;

-- MATERIAL
DELETE FROM ai_classmate.material WHERE true;
INSERT INTO ai_classmate.material
SELECT
  material_id,
  class_id,
  title,
  file_url,
  SAFE_CAST(allow_download AS BOOL) AS allow_download,
  uploaded_by,
  SAFE.PARSE_TIMESTAMP('%FT%T%Ez', uploaded_at) AS uploaded_at
FROM ai_classmate.material_stg;

-- ANNOUNCEMENT
DELETE FROM ai_classmate.announcement WHERE true;
INSERT INTO ai_classmate.announcement
SELECT
  announcement_id,
  scope,
  NULLIF(class_id, '') AS class_id,
  SAFE_CAST(NULLIF(grade, '') AS INT64) AS grade,
  NULLIF(area_code, '') AS area_code,
  title,
  body,
  created_by,
  SAFE.PARSE_TIMESTAMP('%FT%T%Ez', created_at) AS created_at
FROM ai_classmate.announcement_stg;

-- MESSAGE
DELETE FROM ai_classmate.message WHERE true;
INSERT INTO ai_classmate.message
SELECT
  message_id,
  sender_id,
  recipient_id,
  NULLIF(class_id, '') AS class_id,
  text,
  SAFE.PARSE_TIMESTAMP('%FT%T%Ez', sent_at) AS sent_at,
  SAFE_CAST(is_deleted AS BOOL) AS is_deleted
FROM ai_classmate.message_stg;

-- NOTIFICATION
DELETE FROM ai_classmate.notification WHERE true;
INSERT INTO ai_classmate.notification
SELECT
  notification_id,
  recipient_id,
  type,
  title,
  body,
  SAFE_CAST(is_read AS BOOL) AS is_read,
  SAFE.PARSE_TIMESTAMP('%FT%T%Ez', created_at) AS created_at
FROM ai_classmate.notification_stg;

-- RATING
DELETE FROM ai_classmate.rating WHERE true;
INSERT INTO ai_classmate.rating
SELECT
  rating_id,
  student_id,
  tutor_id,
  class_id,
  SAFE_CAST(stars AS INT64) AS stars,
  NULLIF(comment, '') AS comment,
  SAFE.PARSE_TIMESTAMP('%FT%T%Ez', created_at) AS created_at
FROM ai_classmate.rating_stg;

-- EVENT_INTERACTION
DELETE FROM ai_classmate.event_interaction WHERE true;
INSERT INTO ai_classmate.event_interaction
SELECT
  event_id,
  NULLIF(student_id, '') AS student_id,
  NULLIF(tutor_id, '') AS tutor_id,
  NULLIF(class_id, '') AS class_id,
  event_type,
  NULLIF(query_text, '') AS query_text,
  SAFE.PARSE_TIMESTAMP('%FT%T%Ez', ts) AS ts
FROM ai_classmate.event_interaction_stg;

-- WEEKLY_DEMAND
DELETE FROM ai_classmate.weekly_demand WHERE true;
INSERT INTO ai_classmate.weekly_demand
SELECT
  SAFE_CAST(week_start AS DATE) AS week_start,
  subject_code,
  area_code,
  SAFE_CAST(views AS INT64) AS views,
  SAFE_CAST(clicks AS INT64) AS clicks,
  SAFE_CAST(enrols AS INT64) AS enrols
FROM ai_classmate.weekly_demand_stg;
