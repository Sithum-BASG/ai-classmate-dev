Param(
  [string]$ProjectId = "ai-classmate-sri-lanka-001",
  [string]$Region    = "asia-south1"
)

$ErrorActionPreference = "Stop"

# Resolve gcloud
$gcloudCmd = "gcloud"
if (Test-Path "$env:ProgramFiles\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd") { $gcloudCmd = "$env:ProgramFiles\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd" }
elseif (Test-Path "${env:ProgramFiles(x86)}\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd") { $gcloudCmd = "${env:ProgramFiles(x86)}\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd" }
& $gcloudCmd config set project $ProjectId | Out-Null
$token = & $gcloudCmd auth print-access-token
$uri = "https://bigquery.googleapis.com/bigquery/v2/projects/$ProjectId/queries"
$headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }

# Train
$trainSql = Get-Content "sql\bqml_train.sql" -Raw
$body = @{ query = $trainSql; useLegacySql = $false; location = $Region; timeoutMs = 1200000 } | ConvertTo-Json -Depth 50
Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body | Out-Null
Write-Host "BQML training submitted/completed."

# Evaluate
$evalSql = Get-Content "sql\bqml_eval.sql" -Raw
$body2 = @{ query = $evalSql; useLegacySql = $false; location = $Region; timeoutMs = 600000 } | ConvertTo-Json -Depth 50
$evalRes = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body2
$evalRes.rows | ForEach-Object { $_.f | ForEach-Object { $_.v } }
