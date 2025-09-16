Param(
  [string]$ProjectId = "ai-classmate-sri-lanka-001",
  [string]$Location  = "asia-south1",
  [string]$AgentDisplay = "AI ClassMate FAQ",
  [string]$TimeZone = "Asia/Colombo"
)

$ErrorActionPreference = "Stop"

function Get-GcloudCmd {
  $gcloudBin1 = "${env:ProgramFiles(x86)}\Google\Cloud SDK\google-cloud-sdk\bin"
  $gcloudBin2 = "${env:ProgramFiles}\Google\Cloud SDK\google-cloud-sdk\bin"
  if (Test-Path (Join-Path $gcloudBin2 'gcloud.cmd')) { return (Join-Path $gcloudBin2 'gcloud.cmd') }
  elseif (Test-Path (Join-Path $gcloudBin1 'gcloud.cmd')) { return (Join-Path $gcloudBin1 'gcloud.cmd') }
  else { return 'gcloud' }
}

$gcloud = Get-GcloudCmd
& $gcloud config set project $ProjectId | Out-Null
$token = & $gcloud auth print-access-token
$base = "https://dialogflow.googleapis.com/v3/projects/$ProjectId/locations/$Location"
$headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }

# Idempotent Agent fetch-or-create
$agents = Invoke-RestMethod -Method Get -Uri "$base/agents" -Headers $headers
$found = $null
if ($agents.agents) { $found = @($agents.agents | Where-Object { $_.displayName -eq $AgentDisplay }) }
if ($found -and $found.Count -gt 0) {
  $agentName = $found[0].name
  Write-Host "Using existing agent: $agentName"
}
else {
  Write-Host "Creating agent $AgentDisplay in $Location ..."
  $agentBody = @{ displayName = $AgentDisplay; defaultLanguageCode = "en"; timeZone = $TimeZone } | ConvertTo-Json
  $agent = Invoke-RestMethod -Method Post -Uri "$base/agents" -Headers $headers -Body $agentBody
  $agentName = $agent.name
  Write-Host "Agent created: $agentName"
}
$agentId = ($agentName -split "/")[-1]

# Helper to create or fetch an intent by display name
function Ensure-Intent($display, $trainingPhrases) {
  $existing = Invoke-RestMethod -Method Get -Uri "$base/agents/$agentId/intents" -Headers $headers
  $here = $null
  if ($existing.intents) { $here = @($existing.intents | Where-Object { $_.displayName -eq $display }) }
  if ($here -and $here.Count -gt 0) { return $here[0] }
  $parts = @()
  foreach ($tp in $trainingPhrases) { $parts += @{ parts = @(@{ text = $tp }) } }
  $intentBody = @{ displayName = $display; trainingPhrases = $parts } | ConvertTo-Json -Depth 6
  return Invoke-RestMethod -Method Post -Uri "$base/agents/$agentId/intents" -Headers $headers -Body $intentBody
}

# Core FAQ intents
$intents = @{}
$intents['enrollment_faq'] = Ensure-Intent "enrollment_faq" @(
  "How do I enroll in a class?","What is the enrollment process?","How can a student join a class?","How to register for a class?","How to enroll from the app?"
)
$intents['payment_faq'] = Ensure-Intent "payment_faq" @(
  "How do I pay?","Payment methods","Where to upload payment proof?","How long does payment verification take?","How to view my invoice?"
)
$intents['schedule_faq'] = Ensure-Intent "schedule_faq" @(
  "What is the class schedule?","Weekly timetable","When is the next session?","Will I get notified if a class is canceled?"
)
$intents['materials_faq'] = Ensure-Intent "materials_faq" @(
  "Where to find class materials?","How to download notes?","How to access recordings?","I cannot download materials"
)
$intents['notifications_faq'] = Ensure-Intent "notifications_faq" @(
  "How do notifications work?","Why did I get an enrollment notification?","How to stop notifications?","Turn off notifications"
)
# Additional useful FAQs
$intents['refund_faq'] = Ensure-Intent "refund_faq" @(
  "How do refunds work?","When will I get my refund?","Refund policy","How to request a refund"
)
$intents['account_faq'] = Ensure-Intent "account_faq" @(
  "How do I update my profile?","Change phone number","Update email","Edit profile information"
)
$intents['approval_faq'] = Ensure-Intent "approval_faq" @(
  "How are tutors approved?","How are classes approved?","Why is my class still pending approval?"
)
$intents['announcement_faq'] = Ensure-Intent "announcement_faq" @(
  "How are announcements sent?","Broadcast announcements","Where can I read announcements?"
)
$intents['reschedule_faq'] = Ensure-Intent "reschedule_faq" @(
  "How to reschedule a class?","Class canceled","What if I miss a session?"
)
$intents['support_faq'] = Ensure-Intent "support_faq" @(
  "How to contact support?","Help center","Get help"
)

# Get start flow
$flows = Invoke-RestMethod -Method Get -Uri "$base/agents/$agentId/flows" -Headers $headers
$startFlow = ($flows.flows | Select-Object -First 1)
$flowName = $startFlow.name
$flowId = ($flowName -split "/")[-1]
Write-Host "Wiring transition routes on Start Flow: $flowId"

# Helper: build transition route with a text response
function RouteFor($intentKey, $replyText) {
  $iid = ($intents[$intentKey].name -split "/")[-1]
  return @{ intent = "$base/agents/$agentId/intents/$iid";
            triggerFulfillment = @{ messages = @(@{ text = @{ text = @($replyText) } }) } }
}

$routes = @(
  RouteFor 'enrollment_faq'  'To enroll: search a class, open it, tap Enroll and confirm seats. You will see the enrollment as Pending until payment is verified.' ,
  RouteFor 'payment_faq'     'Payments: bank transfer, card, cash and online methods. Upload your payment proof on the invoice screen. Verification usually completes within 24-48 hours.' ,
  RouteFor 'schedule_faq'    'Open Weekly Timetable to view upcoming sessions. Start times are local. If a class is canceled or changed we will notify you automatically.' ,
  RouteFor 'materials_faq'   'Go to the class page -> Materials to view or download notes and files. Tutors may upload recordings when available. If downloads are disabled please contact the tutor.' ,
  RouteFor 'notifications_faq' 'We send notifications for enrollment/payment status and schedule changes. You can mute non-critical messages from Settings -> Notifications.' ,
  RouteFor 'refund_faq'      'Refunds: if your payment is verified and the tutor cancels or support approves a refund request, we process it to your original payment method within 5-10 business days.' ,
  RouteFor 'account_faq'     'Update your profile from Profile -> Edit. You can change name, grade and area. Email changes require re-verification; phone changes require OTP.' ,
  RouteFor 'approval_faq'    'Tutor and class approvals: admins review documents for authenticity and schedule conflicts. Class status changes from Draft to Published once approved.' ,
  RouteFor 'announcement_faq' 'Admins and tutors can broadcast announcements. You can read all recent announcements from Home -> Announcements and receive push notifications.' ,
  RouteFor 'reschedule_faq'  'To reschedule, contact the tutor from the class page. If a session is canceled by the tutor, a new date/time will be posted and you will be notified.' ,
  RouteFor 'support_faq'     'Need help? Email support@classmate.lk or use Help -> Contact Support in the app. Include your user ID and the class/enrollment ID for faster assistance.'
)

# Fallback handlers for no-match and no-input
$fallback = @{ eventHandlers = @(
    @{ event = 'sys.no-match-default'; triggerFulfillment = @{ messages = @(@{ text = @{ text = @('Sorry, I did not catch that. Try asking about enrollment, payments, schedule, materials, notifications or refunds.') } }) } },
    @{ event = 'sys.no-input-default'; triggerFulfillment = @{ messages = @(@{ text = @{ text = @('Are you still there? You can ask me about enrollment, payments, schedule or materials.') } }) } }
  ) }

# PATCH the flow
$patchBody = @{ transitionRoutes = $routes } + $fallback | ConvertTo-Json -Depth 10
$patchUri = $base + '/agents/' + $agentId + '/flows/' + $flowId + '?updateMask=transitionRoutes%2CeventHandlers'
Invoke-RestMethod -Method Patch -Uri $patchUri -Headers $headers -Body $patchBody | Out-Null

Write-Output 'Dialogflow CX agent is ready.'
$testUrl = 'https://dialogflow.cloud.google.com/cx/projects/' + $ProjectId + '/locations/' + $Location + '/agents/' + $agentId + '/flows/' + $flowId + '/pages/-/start'
Write-Output 'Test here:'
Write-Output $testUrl
