-- BigQuery DDL for AI ClassMate (final tables + staging)
-- Dataset: ai_classmate (region: asia-south1)
-- Constraints are NOT ENFORCED (documentational) due to BigQuery behavior.

-- USER (final)
CREATE TABLE IF NOT EXISTS ai_classmate.`user` (
  user_id STRING NOT NULL,
  email STRING NOT NULL,
  phone STRING,
  display_name STRING,
  role STRING NOT NULL, -- student|tutor|admin
  is_active BOOL,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  CONSTRAINT pk_user PRIMARY KEY(user_id) NOT ENFORCED,
  CONSTRAINT uq_user_email UNIQUE(email) NOT ENFORCED,
  CONSTRAINT uq_user_phone UNIQUE(phone) NOT ENFORCED
)
CLUSTER BY role, is_active;

-- STUDENT_PROFILE (final)
CREATE TABLE IF NOT EXISTS ai_classmate.student_profile (
  user_id STRING NOT NULL,
  grade INT64,
  area_code STRING,
  subjects_of_interest ARRAY<STRING>,
  CONSTRAINT pk_student_profile PRIMARY KEY(user_id) NOT ENFORCED
);

-- TUTOR_PROFILE (final)
CREATE TABLE IF NOT EXISTS ai_classmate.tutor_profile (
  user_id STRING NOT NULL,
  bio STRING,
  qualifications STRING,
  subjects_taught ARRAY<STRING>,
  area_code STRING,
  mode STRING, -- online|physical|hybrid
  base_price NUMERIC,
  rating_avg FLOAT64,
  rating_count INT64,
  status STRING, -- pending|approved|rejected
  reviewed_by STRING,
  reviewed_at TIMESTAMP,
  CONSTRAINT pk_tutor_profile PRIMARY KEY(user_id) NOT ENFORCED
)
CLUSTER BY area_code, mode, status;

-- ADMIN_PROFILE (final)
CREATE TABLE IF NOT EXISTS ai_classmate.admin_profile (
  user_id STRING NOT NULL,
  role_type STRING -- super|academic|finance
);

-- SUBJECT (final)
CREATE TABLE IF NOT EXISTS ai_classmate.subject (
  subject_code STRING NOT NULL,
  name STRING,
  level STRING, -- OL|AL|Other
  CONSTRAINT pk_subject PRIMARY KEY(subject_code) NOT ENFORCED
);

-- AREA (final)
CREATE TABLE IF NOT EXISTS ai_classmate.area (
  area_code STRING NOT NULL,
  area_name STRING,
  lat FLOAT64,
  lng FLOAT64,
  CONSTRAINT pk_area PRIMARY KEY(area_code) NOT ENFORCED
);

-- VENUE (final)
CREATE TABLE IF NOT EXISTS ai_classmate.venue (
  venue_id STRING NOT NULL,
  name STRING,
  address STRING,
  area_code STRING,
  capacity INT64,
  CONSTRAINT pk_venue PRIMARY KEY(venue_id) NOT ENFORCED
)
CLUSTER BY area_code;

-- CLASS (final)
CREATE TABLE IF NOT EXISTS ai_classmate.class (
  class_id STRING NOT NULL,
  tutor_id STRING,
  subject_code STRING,
  grade INT64,
  mode STRING,
  area_code STRING,
  venue_id STRING,
  fee NUMERIC,
  price_band STRING,
  capacity_seats INT64,
  status STRING, -- draft|published|archived
  created_at TIMESTAMP,
  published_at TIMESTAMP,
  CONSTRAINT pk_class PRIMARY KEY(class_id) NOT ENFORCED
)
CLUSTER BY subject_code, area_code, grade, mode, price_band, status;

-- CLASS_SESSION (final)
CREATE TABLE IF NOT EXISTS ai_classmate.class_session (
  session_id STRING NOT NULL,
  class_id STRING,
  session_date DATE,
  start_time TIME,
  end_time TIME,
  room STRING,
  is_cancelled BOOL,
  cancel_reason STRING,
  CONSTRAINT pk_class_session PRIMARY KEY(session_id) NOT ENFORCED
)
PARTITION BY session_date
CLUSTER BY class_id, is_cancelled;

-- ENROLLMENT (final)
CREATE TABLE IF NOT EXISTS ai_classmate.enrollment (
  enrollment_id STRING NOT NULL,
  class_id STRING,
  student_id STRING,
  status STRING, -- pending|active|completed|cancelled
  enrolled_at TIMESTAMP,
  cancelled_at TIMESTAMP,
  cancel_reason STRING,
  CONSTRAINT pk_enrollment PRIMARY KEY(enrollment_id) NOT ENFORCED,
  CONSTRAINT uq_enrollment UNIQUE(student_id, class_id) NOT ENFORCED
)
PARTITION BY DATE(enrolled_at)
CLUSTER BY class_id, student_id, status;

-- INVOICE (final)
CREATE TABLE IF NOT EXISTS ai_classmate.invoice (
  invoice_id STRING NOT NULL,
  enrollment_id STRING,
  amount_due NUMERIC,
  due_date DATE,
  status STRING, -- awaiting_proof|under_review|verified|rejected|refunded
  created_at TIMESTAMP,
  CONSTRAINT pk_invoice PRIMARY KEY(invoice_id) NOT ENFORCED
)
PARTITION BY DATE(created_at)
CLUSTER BY enrollment_id, status;

-- PAYMENT (final)
CREATE TABLE IF NOT EXISTS ai_classmate.payment (
  payment_id STRING NOT NULL,
  invoice_id STRING,
  paid_amount NUMERIC,
  paid_at TIMESTAMP,
  method STRING,
  proof_url STRING,
  verify_status STRING, -- verified|rejected|pending
  verified_by STRING,
  verified_at TIMESTAMP,
  verify_note STRING,
  CONSTRAINT pk_payment PRIMARY KEY(payment_id) NOT ENFORCED
)
PARTITION BY DATE(paid_at)
CLUSTER BY invoice_id, verify_status;

-- REFUND (final)
CREATE TABLE IF NOT EXISTS ai_classmate.refund (
  refund_id STRING NOT NULL,
  payment_id STRING,
  refund_amount NUMERIC,
  refunded_at TIMESTAMP,
  reason STRING,
  processed_by STRING,
  CONSTRAINT pk_refund PRIMARY KEY(refund_id) NOT ENFORCED
)
PARTITION BY DATE(refunded_at)
CLUSTER BY payment_id;

-- MATERIAL (final)
CREATE TABLE IF NOT EXISTS ai_classmate.material (
  material_id STRING NOT NULL,
  class_id STRING,
  title STRING,
  file_url STRING,
  allow_download BOOL,
  uploaded_by STRING,
  uploaded_at TIMESTAMP,
  CONSTRAINT pk_material PRIMARY KEY(material_id) NOT ENFORCED
)
PARTITION BY DATE(uploaded_at)
CLUSTER BY class_id, uploaded_by;

-- ANNOUNCEMENT (final)
CREATE TABLE IF NOT EXISTS ai_classmate.announcement (
  announcement_id STRING NOT NULL,
  scope STRING, -- class|grade|area|all
  class_id STRING,
  grade INT64,
  area_code STRING,
  title STRING,
  body STRING,
  created_by STRING,
  created_at TIMESTAMP,
  CONSTRAINT pk_announcement PRIMARY KEY(announcement_id) NOT ENFORCED
)
PARTITION BY DATE(created_at)
CLUSTER BY scope, class_id, area_code, grade;

-- MESSAGE (final)
CREATE TABLE IF NOT EXISTS ai_classmate.message (
  message_id STRING NOT NULL,
  sender_id STRING,
  recipient_id STRING,
  class_id STRING,
  text STRING,
  sent_at TIMESTAMP,
  is_deleted BOOL,
  CONSTRAINT pk_message PRIMARY KEY(message_id) NOT ENFORCED
)
PARTITION BY DATE(sent_at)
CLUSTER BY class_id, sender_id, recipient_id;

-- NOTIFICATION (final)
CREATE TABLE IF NOT EXISTS ai_classmate.notification (
  notification_id STRING NOT NULL,
  recipient_id STRING,
  type STRING, -- enrollment_status|payment_status|schedule_change|announcement|system
  title STRING,
  body STRING,
  is_read BOOL,
  created_at TIMESTAMP,
  CONSTRAINT pk_notification PRIMARY KEY(notification_id) NOT ENFORCED
)
PARTITION BY DATE(created_at)
CLUSTER BY recipient_id, type, is_read;

-- RATING (final)
CREATE TABLE IF NOT EXISTS ai_classmate.rating (
  rating_id STRING NOT NULL,
  student_id STRING,
  tutor_id STRING,
  class_id STRING,
  stars INT64,
  comment STRING,
  created_at TIMESTAMP,
  CONSTRAINT pk_rating PRIMARY KEY(rating_id) NOT ENFORCED
)
PARTITION BY DATE(created_at)
CLUSTER BY tutor_id, class_id, student_id;

-- EVENT_INTERACTION (final)
CREATE TABLE IF NOT EXISTS ai_classmate.event_interaction (
  event_id STRING NOT NULL,
  student_id STRING,
  tutor_id STRING,
  class_id STRING,
  event_type STRING, -- search|impression|view_tutor|view_class|click|bookmark|enrol
  query_text STRING,
  ts TIMESTAMP,
  CONSTRAINT pk_event PRIMARY KEY(event_id) NOT ENFORCED
)
PARTITION BY DATE(ts)
CLUSTER BY student_id, class_id, tutor_id, event_type;

-- WEEKLY_DEMAND (final)
CREATE TABLE IF NOT EXISTS ai_classmate.weekly_demand (
  week_start DATE NOT NULL,
  subject_code STRING NOT NULL,
  area_code STRING NOT NULL,
  views INT64,
  clicks INT64,
  enrols INT64,
  CONSTRAINT pk_weekly_demand PRIMARY KEY(week_start, subject_code, area_code) NOT ENFORCED
)
CLUSTER BY subject_code, area_code;

-- =====================
-- STAGING TABLES (all STRING columns to match CSVs)
-- =====================
CREATE OR REPLACE TABLE ai_classmate.user_stg (
  user_id STRING, email STRING, phone STRING, display_name STRING, role STRING,
  is_active STRING, created_at STRING, updated_at STRING
);

CREATE OR REPLACE TABLE ai_classmate.student_profile_stg (
  user_id STRING, grade STRING, area_code STRING, subjects_of_interest STRING
);

CREATE OR REPLACE TABLE ai_classmate.tutor_profile_stg (
  user_id STRING, bio STRING, qualifications STRING, subjects_taught STRING, area_code STRING,
  mode STRING, base_price STRING, rating_avg STRING, rating_count STRING, status STRING,
  reviewed_by STRING, reviewed_at STRING
);

CREATE OR REPLACE TABLE ai_classmate.admin_profile_stg (
  user_id STRING, role_type STRING
);

CREATE OR REPLACE TABLE ai_classmate.subject_stg (
  subject_code STRING, name STRING, level STRING
);

CREATE OR REPLACE TABLE ai_classmate.area_stg (
  area_code STRING, area_name STRING, lat STRING, lng STRING
);

CREATE OR REPLACE TABLE ai_classmate.venue_stg (
  venue_id STRING, name STRING, address STRING, area_code STRING, capacity STRING
);

CREATE OR REPLACE TABLE ai_classmate.class_stg (
  class_id STRING, tutor_id STRING, subject_code STRING, grade STRING, mode STRING,
  area_code STRING, venue_id STRING, fee STRING, price_band STRING, capacity_seats STRING,
  status STRING, created_at STRING, published_at STRING
);

CREATE OR REPLACE TABLE ai_classmate.class_session_stg (
  session_id STRING, class_id STRING, session_date STRING, start_time STRING, end_time STRING,
  room STRING, is_cancelled STRING, cancel_reason STRING
);

CREATE OR REPLACE TABLE ai_classmate.enrollment_stg (
  enrollment_id STRING, class_id STRING, student_id STRING, status STRING,
  enrolled_at STRING, cancelled_at STRING, cancel_reason STRING
);

CREATE OR REPLACE TABLE ai_classmate.invoice_stg (
  invoice_id STRING, enrollment_id STRING, amount_due STRING, due_date STRING, status STRING, created_at STRING
);

CREATE OR REPLACE TABLE ai_classmate.payment_stg (
  payment_id STRING, invoice_id STRING, paid_amount STRING, paid_at STRING, method STRING, proof_url STRING,
  verify_status STRING, verified_by STRING, verified_at STRING, verify_note STRING
);

CREATE OR REPLACE TABLE ai_classmate.refund_stg (
  refund_id STRING, payment_id STRING, refund_amount STRING, refunded_at STRING, reason STRING, processed_by STRING
);

CREATE OR REPLACE TABLE ai_classmate.material_stg (
  material_id STRING, class_id STRING, title STRING, file_url STRING, allow_download STRING,
  uploaded_by STRING, uploaded_at STRING
);

CREATE OR REPLACE TABLE ai_classmate.announcement_stg (
  announcement_id STRING, scope STRING, class_id STRING, grade STRING, area_code STRING,
  title STRING, body STRING, created_by STRING, created_at STRING
);

CREATE OR REPLACE TABLE ai_classmate.message_stg (
  message_id STRING, sender_id STRING, recipient_id STRING, class_id STRING, text STRING, sent_at STRING, is_deleted STRING
);

CREATE OR REPLACE TABLE ai_classmate.notification_stg (
  notification_id STRING, recipient_id STRING, type STRING, title STRING, body STRING, is_read STRING, created_at STRING
);

CREATE OR REPLACE TABLE ai_classmate.rating_stg (
  rating_id STRING, student_id STRING, tutor_id STRING, class_id STRING, stars STRING, comment STRING, created_at STRING
);

CREATE OR REPLACE TABLE ai_classmate.event_interaction_stg (
  event_id STRING, student_id STRING, tutor_id STRING, class_id STRING, event_type STRING, query_text STRING, ts STRING
);

CREATE OR REPLACE TABLE ai_classmate.weekly_demand_stg (
  week_start STRING, subject_code STRING, area_code STRING, views STRING, clicks STRING, enrols STRING
);
