AI ClassMate — Backend Handoff

Purpose: A single source of truth so any new chat/assistant can continue backend work immediately.

Workspace
- Root: D:\classmate ai
- GCP Project: ai-classmate-sri-lanka-001
- Primary region: asia-south1 (BigQuery, Vertex AI, Dialogflow Conversational Agents)

Data Platform (BigQuery)
- Dataset: ai_classmate
- Core tables/views (created via SQL in `sql/`):
  - `recs_training_pairs` — features + label for tutor recommendations
  - `recs_scoring_input` — features-only for batch scoring
  - `subject_clicks_forecast` — subject-level 8-week forecast
  - `v_subject_clicks_forecast` — readable view over forecasts
- Models
  - Forecast: `ai_classmate.demand_arima` (BQML ARIMA_PLUS)
  - Backup recs: `ai_classmate.bqml_rec_lr` (BQML Logistic Regression)

ML (Vertex AI)
- Primary recs model: AutoML Tabular trained on `ai_classmate.recs_training_pairs` in `asia-south1`.
- Batch scoring script: `scripts\\vertex_batch_predict.py` (writes predictions to BigQuery)
- Note: `scripts\\vertex_train.ps1` exists. The previous Python entry-point (`scripts\\vertex_train.py`) is not currently in the repo and may be re-generated if needed.

Dialogflow CX (Conversational Agents)
- Agent available via bundle:
  - `dialogflow\\ai_classmate_agent_bundle.zip`
  - Full import structure under `dialogflow\\import_bundle\\...`
- Includes Default Start Flow and ~11 FAQ intents.

Scripts (entry points)
- `scripts\\bq_ingest.ps1` or `scripts\\bq_ingest_rest.ps1` — DDL + upload/load + transform
- `scripts\\run_rec_features.ps1` — builds `recs_training_pairs`
- `scripts\\run_bqml.ps1` — trains/evaluates BQML backup recommendations
- `scripts\\vertex_batch_predict.ps1` — submits Vertex AI batch prediction
- `scripts\\dfcx_create_faq.ps1` — optional; prefer Console import of bundle

SQL library
- `sql\\ddl.sql`, `sql\\transform.sql`
- `sql\\rec_features.sql`, `sql\\rec_scoring_input.sql`
- `sql\\bqml_train.sql`, `sql\\bqml_eval.sql`
- `sql\\forecast_train.sql`, `sql\\forecast_eval.sql`, `sql\\forecast_next.sql`
- `sql\\subject_forecast.sql`, `sql\\subject_forecast_view.sql`

Conventions
- Region: `asia-south1`
- BigQuery dataset: `ai_classmate`
- Prefer `CREATE OR REPLACE` for idempotency
- CSVs reside in GCS bucket: `ai-classmate-data-ai-classmate-sri-lanka-001-asia-south1`

Credentials / Setup
- `gcloud auth login gimharasithum.basg.edu@gmail.com`
- `gcloud config set project ai-classmate-sri-lanka-001`
- For Python clients: `gcloud auth application-default login`

Next: Backend kickoff (service/API layer)
- Recommend Firebase (Auth) + Cloud Run API:
  - Expose endpoints:
    - `GET /recs?student_id=...` → read top tutors from scored results in BigQuery
    - `GET /forecast/subjects` → read from `v_subject_clicks_forecast`
    - `POST /events` → log interactions (BigQuery streaming or Firestore)
  - Secure with Firebase Auth (ID token → Cloud Run/IAM)
  - Optional: Dialogflow webhook to reuse backend services

How to use this handoff in a new chat
1) In your first message, paste:

   "Workspace is D:\\classmate ai. Read docs/HANDOFF_BACKEND.md and confirm. We’re building the backend next. Use GCP project ai-classmate-sri-lanka-001, region asia-south1, dataset ai_classmate. Reuse existing SQL/ML/DFCX assets."

2) Ask the assistant to propose and implement the backend skeleton (Cloud Run/Firebase), then proceed step-by-step.



