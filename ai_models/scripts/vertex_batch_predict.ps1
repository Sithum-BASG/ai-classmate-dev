Param(
  [string]$ProjectId = "ai-classmate-sri-lanka-001",
  [string]$Region    = "asia-south1",
  [string]$ModelId   = "",
  [string]$BQSource  = "ai-classmate-sri-lanka-001.ai_classmate.recs_scoring_input",
  [string]$BQDest    = "ai-classmate-sri-lanka-001.ai_classmate.recs_predictions"
)

$ErrorActionPreference = "Stop"

if (-not $ModelId) { throw "Provide --ModelId (e.g., 3897166188093898752)" }

# venv
if (-not (Test-Path .venv)) { python -m venv .venv }
. .\.venv\Scripts\Activate.ps1
pip install --upgrade pip --disable-pip-version-check
pip install google-cloud-aiplatform --disable-pip-version-check

python scripts\vertex_batch_predict.py `
  --project $ProjectId `
  --location $Region `
  --model_id $ModelId `
  --bq_source $BQSource `
  --bq_destination $BQDest
