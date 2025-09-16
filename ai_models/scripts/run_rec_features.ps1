Param(
  [string]$ProjectId = "ai-classmate-sri-lanka-001",
  [string]$Region    = "asia-south1",
  [switch]$NoTranscript
)

$ErrorActionPreference = "Stop"
$ProgressPreference = 'Continue'

# Start transcript for visibility unless disabled
$logDir = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$logPath = Join-Path $logDir "run_rec_features.log"
if (-not $NoTranscript) {
  try { Start-Transcript -Path $logPath -Force | Out-Null } catch { }
}

function Get-GcloudCmd {
  $gcloudBin1 = "${env:ProgramFiles(x86)}\Google\Cloud SDK\google-cloud-sdk\bin"
  $gcloudBin2 = "${env:ProgramFiles}\Google\Cloud SDK\google-cloud-sdk\bin"
  if (Test-Path (Join-Path $gcloudBin2 'gcloud.cmd')) { return (Join-Path $gcloudBin2 'gcloud.cmd') }
  elseif (Test-Path (Join-Path $gcloudBin1 'gcloud.cmd')) { return (Join-Path $gcloudBin1 'gcloud.cmd') }
  else { return 'gcloud' }
}

function New-AccessToken([string]$ProjectId) {
  $gcloud = Get-GcloudCmd
  & $gcloud config set project $ProjectId | Out-Null
  return (& $gcloud auth print-access-token)
}

function Submit-QueryJob([string]$Sql, [string]$Token, [string]$ProjectId, [string]$Region) {
  $jobsUri = "https://bigquery.googleapis.com/bigquery/v2/projects/$ProjectId/jobs"
  $headers = @{ Authorization = "Bearer $Token"; "Content-Type" = "application/json" }
  $bodyObj = @{ configuration = @{ query = @{ query = $Sql; useLegacySql = $false } }; jobReference = @{ location = $Region } }
  $bodyJson = $bodyObj | ConvertTo-Json -Depth 20
  $resp = Invoke-RestMethod -Method Post -Uri $jobsUri -Headers $headers -Body $bodyJson
  return $resp.jobReference.jobId
}

function Get-BQJob([string]$JobId, [string]$Token, [string]$ProjectId, [string]$Region) {
  $uri = "https://bigquery.googleapis.com/bigquery/v2/projects/$ProjectId/jobs/$JobId?location=$Region"
  $headers = @{ Authorization = "Bearer $Token" }
  return Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
}

function Wait-JobDone([string]$JobId, [string]$Token, [string]$ProjectId, [string]$Region) {
  $start = Get-Date
  $i = 0
  while ($true) {
    try {
      $job = Get-BQJob -JobId $JobId -Token $Token -ProjectId $ProjectId -Region $Region
    } catch {
      if ($_.Exception.Response -and $_.Exception.Response.GetResponseStream()) {
        $reader = New-Object System.IO.StreamReader $_.Exception.Response.GetResponseStream()
        $body = $reader.ReadToEnd()
        Write-Warning ("Polling error body: {0}" -f $body)
      }
      throw
    }
    $state = $job.status.state
    $elapsed = (Get-Date) - $start
    $elapsedStr = "{0:mm\:ss}" -f $elapsed
    $i = ($i + 7) % 100
    Write-Progress -Activity "BigQuery Job $JobId" -Status "State: $state | Elapsed: $elapsedStr" -PercentComplete $i
    if ($state -eq 'DONE') {
      Write-Progress -Activity "BigQuery Job $JobId" -Completed
      if ($job.status.errorResult) {
        throw ("Job failed: {0}" -f ($job.status.errorResult | ConvertTo-Json -Compress))
      }
      return $job
    }
    Start-Sleep -Seconds 2
  }
}

try {
  $sqlPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\sql\rec_features.sql"
  $sql = Get-Content $sqlPath -Raw
  $token = New-AccessToken -ProjectId $ProjectId

  Write-Host "Submitting RECS_TRAINING_PAIRS job..."
  $jobId = Submit-QueryJob -Sql $sql -Token $token -ProjectId $ProjectId -Region $Region
  Write-Host ("Job ID: {0}" -f $jobId)
  $final = Wait-JobDone -JobId $jobId -Token $token -ProjectId $ProjectId -Region $Region
  Write-Host "RECS_TRAINING_PAIRS build completed."

  # Verify row count
  Write-Host "Counting rows in ai_classmate.recs_training_pairs ..."
  $countSql = "SELECT COUNT(*) AS cnt FROM ai_classmate.recs_training_pairs"
  $countJobId = Submit-QueryJob -Sql $countSql -Token $token -ProjectId $ProjectId -Region $Region
  $countJob = Wait-JobDone -JobId $countJobId -Token $token -ProjectId $ProjectId -Region $Region
  $resultsUri = "https://bigquery.googleapis.com/bigquery/v2/projects/$ProjectId/queries/$countJobId?location=$Region"
  $headers = @{ Authorization = "Bearer $token" }
  $result = Invoke-RestMethod -Method Get -Uri $resultsUri -Headers $headers
  if ($result.rows -and $result.rows.Count -ge 1) {
    $cnt = [int64]$result.rows[0].f[0].v
    Write-Host ("Rows: {0}" -f $cnt)
  } else {
    Write-Host "Row count unavailable."
  }
}
catch {
  Write-Error $_
}
finally {
  if (-not $NoTranscript) {
    try { Stop-Transcript | Out-Null } catch { }
  }
}
