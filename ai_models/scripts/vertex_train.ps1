Param(
  [string]$ProjectId = "ai-classmate-sri-lanka-001",
  [string]$Region    = "asia-south1",
  [string]$BQProject = "ai-classmate-sri-lanka-001",
  [string]$BQTable   = "ai_classmate.recs_training_pairs",
  [string]$Bucket    = "ai-classmate-data-ai-classmate-sri-lanka-001-asia-south1",
  [double]$BudgetHours = 1.0
)

$ErrorActionPreference = "Stop"

# Python venv
if (-not (Test-Path .venv)) { python -m venv .venv }
. .\.venv\Scripts\Activate.ps1
pip install --upgrade pip --disable-pip-version-check
pip install google-cloud-aiplatform --disable-pip-version-check

# Run training
python scripts\vertex_train.py `
  --project $ProjectId `
  --location $Region `
  --dataset_project $BQProject `
  --dataset_bq $BQTable `
  --target label_clicked_or_enrolled `
  --staging_bucket "gs://$Bucket" `
  --budget_hours $BudgetHours

