Param(
  [string]$ProjectId = "ai-classmate-sri-lanka-001",
  [string]$Dataset   = "ai_classmate",
  [string]$Bucket    = "ai-classmate-data-ai-classmate-sri-lanka-001-asia-south1",
  [string]$Region    = "asia-south1"
)

$ErrorActionPreference = "Stop"

# Ensure Cloud SDK uses bundled Python to avoid site-packages conflicts
$python64 = "${env:ProgramFiles}\Google\Cloud SDK\google-cloud-sdk\platform\bundledpython\python.exe"
$python32 = "${env:ProgramFiles(x86)}\Google\Cloud SDK\google-cloud-sdk\platform\bundledpython\python.exe"
if (Test-Path $python64) { $env:CLOUDSDK_PYTHON = $python64 } elseif (Test-Path $python32) { $env:CLOUDSDK_PYTHON = $python32 }
$env:CLOUDSDK_PYTHON_SITEPACKAGES = "0"

# Resolve gcloud & bq paths
$gcloudBin1 = "${env:ProgramFiles(x86)}\Google\Cloud SDK\google-cloud-sdk\bin"
$gcloudBin2 = "${env:ProgramFiles}\Google\Cloud SDK\google-cloud-sdk\bin"
if (Test-Path (Join-Path $gcloudBin2 'gcloud.cmd')) { $gcloudCmd = Join-Path $gcloudBin2 'gcloud.cmd' } elseif (Test-Path (Join-Path $gcloudBin1 'gcloud.cmd')) { $gcloudCmd = Join-Path $gcloudBin1 'gcloud.cmd' } else { $gcloudCmd = 'gcloud' }
if (Test-Path (Join-Path $gcloudBin2 'bq.cmd')) { $bqCmd = Join-Path $gcloudBin2 'bq.cmd' } elseif (Test-Path (Join-Path $gcloudBin1 'bq.cmd')) { $bqCmd = Join-Path $gcloudBin1 'bq.cmd' } else { $bqCmd = 'bq' }

# Config
& $gcloudCmd config set project $ProjectId | Out-Null

# Ensure dataset and tables exist by running DDL via bq CLI (pipe to avoid long command line)
Write-Host "Applying DDL to $Dataset ..."
$ddlPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\sql\ddl.sql"
Get-Content $ddlPath -Raw | & $bqCmd --location=$Region query --use_legacy_sql=false --quiet

# Upload CSVs to GCS
Write-Host "Uploading CSVs to gs://$Bucket/csv/ ..."
& $gcloudCmd storage cp -r "data/*.csv" "gs://$Bucket/csv/" | Out-Null

# Load into staging tables
Write-Host "Loading staging tables ..."
function LoadCsv($table, $file) {
  $target = "$($ProjectId):$Dataset.$table"
  & $bqCmd --location=$Region load --replace --source_format=CSV --skip_leading_rows=1 $target "gs://$Bucket/csv/$file"
}

LoadCsv "user_stg"              "user.csv"
LoadCsv "student_profile_stg"   "student_profile.csv"
LoadCsv "tutor_profile_stg"     "tutor_profile.csv"
LoadCsv "admin_profile_stg"     "admin_profile.csv"
LoadCsv "subject_stg"           "subject.csv"
LoadCsv "area_stg"              "area.csv"
LoadCsv "venue_stg"             "venue.csv"
LoadCsv "class_stg"             "class.csv"
LoadCsv "class_session_stg"     "class_session.csv"
LoadCsv "enrollment_stg"        "enrollment.csv"
LoadCsv "invoice_stg"           "invoice.csv"
LoadCsv "payment_stg"           "payment.csv"
LoadCsv "refund_stg"            "refund.csv"
LoadCsv "material_stg"          "material.csv"
LoadCsv "announcement_stg"      "announcement.csv"
LoadCsv "message_stg"           "message.csv"
LoadCsv "notification_stg"      "notification.csv"
LoadCsv "rating_stg"            "rating.csv"
LoadCsv "event_interaction_stg" "event_interaction.csv"
LoadCsv "weekly_demand_stg"     "weekly_demand.csv"

# Run transform SQL via bq CLI (pipe to avoid long command line)
Write-Host "Transforming staging -> final ..."
$txPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\sql\transform.sql"
Get-Content $txPath -Raw | & $bqCmd --location=$Region query --use_legacy_sql=false --quiet

Write-Host "Ingestion complete."
