Param(
  [string]$ProjectId = "ai-classmate-sri-lanka-001",
  [string]$Dataset   = "ai_classmate",
  [string]$Bucket    = "ai-classmate-data-ai-classmate-sri-lanka-001-asia-south1",
  [string]$Region    = "asia-south1"
)

$ErrorActionPreference = "Stop"

# Resolve gcloud to obtain access token
$gcloudBin1 = "${env:ProgramFiles(x86)}\Google\Cloud SDK\google-cloud-sdk\bin"
$gcloudBin2 = "${env:ProgramFiles}\Google\Cloud SDK\google-cloud-sdk\bin"
if (Test-Path (Join-Path $gcloudBin2 'gcloud.cmd')) { $gcloudCmd = Join-Path $gcloudBin2 'gcloud.cmd' } elseif (Test-Path (Join-Path $gcloudBin1 'gcloud.cmd')) { $gcloudCmd = Join-Path $gcloudBin1 'gcloud.cmd' } else { $gcloudCmd = 'gcloud' }

& $gcloudCmd config set project $ProjectId | Out-Null
$token = & $gcloudCmd auth print-access-token

$jobsUri = "https://bigquery.googleapis.com/bigquery/v2/projects/$ProjectId/jobs"
$commonHeaders = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }

function RunQuery([string]$sql) {
  $bodyObj = @{ configuration = @{ query = @{ query = $sql; useLegacySql = $false } }; jobReference = @{ location = $Region } }
  $bodyJson = $bodyObj | ConvertTo-Json -Depth 15
  return Invoke-RestMethod -Method Post -Uri $jobsUri -Headers $commonHeaders -Body $bodyJson
}

function LoadCsvRest([string]$table, [string]$file) {
  $bodyObj = @{ configuration = @{ load = @{ destinationTable = @{ projectId = $ProjectId; datasetId = $Dataset; tableId = $table };
                                                  sourceUris = @("gs://$Bucket/csv/$file");
                                                  sourceFormat = "CSV";
                                                  skipLeadingRows = 1;
                                                  writeDisposition = "WRITE_TRUNCATE";
                                                  autodetect = $true } };
                 jobReference = @{ location = $Region } }
  $bodyJson = $bodyObj | ConvertTo-Json -Depth 20
  return Invoke-RestMethod -Method Post -Uri $jobsUri -Headers $commonHeaders -Body $bodyJson
}

Write-Host "Applying DDL via REST..."
$ddlPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\sql\ddl.sql"
$ddl = Get-Content $ddlPath -Raw
RunQuery $ddl | Out-Null

Write-Host "Uploading CSVs to gs://$Bucket/csv/ (skip if already there) ..."
# Best-effort upload using gcloud storage; ignore errors if already uploaded
try { & $gcloudCmd storage cp -r "data/*.csv" "gs://$Bucket/csv/" | Out-Null } catch { Write-Host "Upload skipped or partial: $($_.Exception.Message)" }

Write-Host "Loading staging tables via REST..."
LoadCsvRest "user_stg"              "user.csv"              | Out-Null
LoadCsvRest "student_profile_stg"   "student_profile.csv"   | Out-Null
LoadCsvRest "tutor_profile_stg"     "tutor_profile.csv"     | Out-Null
LoadCsvRest "admin_profile_stg"     "admin_profile.csv"     | Out-Null
LoadCsvRest "subject_stg"           "subject.csv"           | Out-Null
LoadCsvRest "area_stg"              "area.csv"              | Out-Null
LoadCsvRest "venue_stg"             "venue.csv"             | Out-Null
LoadCsvRest "class_stg"             "class.csv"             | Out-Null
LoadCsvRest "class_session_stg"     "class_session.csv"     | Out-Null
LoadCsvRest "enrollment_stg"        "enrollment.csv"        | Out-Null
LoadCsvRest "invoice_stg"           "invoice.csv"           | Out-Null
LoadCsvRest "payment_stg"           "payment.csv"           | Out-Null
LoadCsvRest "refund_stg"            "refund.csv"            | Out-Null
LoadCsvRest "material_stg"          "material.csv"          | Out-Null
LoadCsvRest "announcement_stg"      "announcement.csv"      | Out-Null
LoadCsvRest "message_stg"           "message.csv"           | Out-Null
LoadCsvRest "notification_stg"      "notification.csv"      | Out-Null
LoadCsvRest "rating_stg"            "rating.csv"            | Out-Null
LoadCsvRest "event_interaction_stg" "event_interaction.csv" | Out-Null
LoadCsvRest "weekly_demand_stg"     "weekly_demand.csv"     | Out-Null

Write-Host "Running transform SQL via REST..."
$txPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\sql\transform.sql"
$tx = Get-Content $txPath -Raw
RunQuery $tx | Out-Null

Write-Host "Ingestion complete via REST."
