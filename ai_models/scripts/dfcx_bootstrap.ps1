param(
    [string]$ProjectId = "ai-classmate-sri-lanka-001",
    [string]$Region = "asia-south1",
    [string]$AgentDisplayName = "AI ClassMate FAQ",
    [string]$LanguageCode = "en",
    [string]$TimeZone = "Asia/Colombo"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Get-AccessToken {
    $token = & gcloud auth print-access-token 2>$null
    if (-not $token) { throw "gcloud auth print-access-token failed. Run 'gcloud auth login' and select project $ProjectId." }
    return $token.Trim()
}

Write-Host "[CX] Enabling Dialogflow API for project $ProjectId ..."
& gcloud services enable dialogflow.googleapis.com --project $ProjectId | Out-Null

$base = "https://dialogflow.googleapis.com/v3"
$headers = @{ Authorization = "Bearer $(Get-AccessToken)"; "Content-Type" = "application/json; charset=utf-8" }

Write-Host "[CX] Checking for existing agents in $Region ..."
$agentsUri = "$base/projects/$ProjectId/locations/$Region/agents"
$agentsResp = Invoke-RestMethod -Method Get -Uri $agentsUri -Headers $headers
$agent = $null
if ($agentsResp.agents) { $agent = $agentsResp.agents | Where-Object { $_.displayName -eq $AgentDisplayName } | Select-Object -First 1 }

if (-not $agent) {
    Write-Host "[CX] Creating agent '$AgentDisplayName' ..."
    $agentBody = @{ displayName = $AgentDisplayName; defaultLanguageCode = $LanguageCode; timeZone = $TimeZone } | ConvertTo-Json -Depth 10
    $agent = Invoke-RestMethod -Method Post -Uri $agentsUri -Headers $headers -Body $agentBody
} else {
    Write-Host "[CX] Using existing agent '$($agent.displayName)'."
}

# Refresh to get startFlow name
$agent = Invoke-RestMethod -Method Get -Uri ("$base/" + $agent.name) -Headers $headers
$agentName = $agent.name
$startFlowName = $agent.startFlow
Write-Host "[CX] Agent: $agentName"
Write-Host "[CX] Start Flow: $startFlowName"

# Desired intents and canned responses
$intentsWanted = @(
    @{ key = "enrollment_faq"; phrases = @("How do I enroll in a class?","What is the enrollment process?","How can a student join a class?","How to register for a class?","How to enroll from the app?"); response = "To enroll: search a class, open it, tap Enroll and confirm seats. You will see the enrollment as Pending until payment is verified." },
    @{ key = "payment_faq"; phrases = @("How do I pay?","Payment methods","Where to upload payment proof?","How long does payment verification take?","How to view my invoice?"); response = "Payments: bank transfer, card, cash and online methods. Upload your payment proof on the invoice screen. Verification usually completes within 24-48 hours." },
    @{ key = "schedule_faq"; phrases = @("What is the class schedule?","Weekly timetable","When is the next session?","Will I get notified if a class is canceled?"); response = "Open Weekly Timetable to view upcoming sessions. Start times are local. If a class is canceled or changed we will notify you automatically." },
    @{ key = "materials_faq"; phrases = @("Where to find class materials?","How to download notes?","How to access recordings?","I cannot download materials"); response = "Go to the class page -> Materials to view or download notes and files. Tutors may upload recordings when available. If downloads are disabled please contact the tutor." },
    @{ key = "notifications_faq"; phrases = @("How do notifications work?","Why did I get an enrollment notification?","How to stop notifications?","Turn off notifications"); response = "We send notifications for enrollment/payment status and schedule changes. You can mute non-critical messages from Settings -> Notifications." },
    @{ key = "refund_faq"; phrases = @("How do refunds work?","When will I get my refund?","Refund policy","How to request a refund"); response = "Refunds: if your payment is verified and the tutor cancels or support approves a refund request, we process it to your original payment method within 5-10 business days." },
    @{ key = "account_faq"; phrases = @("How do I update my profile?","Change phone number","Update email","Edit profile information"); response = "Update your profile from Profile -> Edit. You can change name, grade and area. Email changes require re-verification; phone changes require OTP." },
    @{ key = "approval_faq"; phrases = @("How are tutors approved?","How are classes approved?","Why is my class still pending approval?"); response = "Tutor and class approvals: admins review documents for authenticity and schedule conflicts. Class status changes from Draft to Published once approved." },
    @{ key = "announcement_faq"; phrases = @("How are announcements sent?","Broadcast announcements","Where can I read announcements?"); response = "Admins and tutors can broadcast announcements. You can read all recent announcements from Home -> Announcements and receive push notifications." },
    @{ key = "reschedule_faq"; phrases = @("How to reschedule a class?","Class canceled","What if I miss a session?"); response = "To reschedule, contact the tutor from the class page. If a session is canceled by the tutor, a new date/time will be posted and you will be notified." },
    @{ key = "support_faq"; phrases = @("How to contact support?","Help center","Get help"); response = "Need help? Email support@classmate.lk or use Help -> Contact Support in the app. Include your user ID and the class/enrollment ID for faster assistance." }
)

$intentMap = @{}
$intentsUri = "$base/$agentName/intents"
$existingIntentsResp = Invoke-RestMethod -Method Get -Uri $intentsUri -Headers $headers
$existingIntents = @()
if ($existingIntentsResp.intents) { $existingIntents = $existingIntentsResp.intents }

foreach ($cfg in $intentsWanted) {
    $existing = $existingIntents | Where-Object { $_.displayName -eq $cfg.key } | Select-Object -First 1
    if (-not $existing) {
        Write-Host "[CX] Creating intent $($cfg.key) ..."
        $tps = @()
        foreach ($p in $cfg.phrases) { $tps += @{ parts = @(@{ text = $p }) } }
        $intentBody = @{ displayName = $cfg.key; trainingPhrases = $tps } | ConvertTo-Json -Depth 20
        $created = Invoke-RestMethod -Method Post -Uri $intentsUri -Headers $headers -Body $intentBody
        $intentMap[$cfg.key] = @{ name = $created.name; response = $cfg.response }
    } else {
        Write-Host "[CX] Intent exists: $($cfg.key)"
        $intentMap[$cfg.key] = @{ name = $existing.name; response = $cfg.response }
    }
}

# Get Start Flow and merge routes + events
$flow = Invoke-RestMethod -Method Get -Uri ("$base/" + $startFlowName) -Headers $headers
if (-not $flow.transitionRoutes) { $flow.transitionRoutes = @() }
if (-not $flow.eventHandlers) { $flow.eventHandlers = @() }

foreach ($k in $intentMap.Keys) {
    $intentName = $intentMap[$k].name
    $resp = $intentMap[$k].response
    $has = $false
    foreach ($r in $flow.transitionRoutes) { if ($r.intent -eq $intentName) { $has = $true; break } }
    if (-not $has) {
        $flow.transitionRoutes += @{ intent = $intentName; triggerFulfillment = @{ messages = @(@{ text = @{ text = @($resp) } }) } }
        Write-Host "[CX] Added route for $k"
    }
}

function Add-EventIfMissing([string]$event, [string]$message) {
    $exists = $false
    foreach ($e in $flow.eventHandlers) { if ($e.event -eq $event) { $exists = $true; break } }
    if (-not $exists) {
        $flow.eventHandlers += @{ event = $event; triggerFulfillment = @{ messages = @(@{ text = @{ text = @($message) } }) } }
        Write-Host "[CX] Added event handler $event"
    }
}

Add-EventIfMissing -event "sys.no-match-default" -message "Sorry, I did not catch that. Try asking about enrollment, payments, schedule, materials, notifications or refunds."
Add-EventIfMissing -event "sys.no-input-default" -message "Are you still there? You can ask me about enrollment, payments, schedule or materials."

$updateBody = @{ name = $flow.name; transitionRoutes = $flow.transitionRoutes; eventHandlers = $flow.eventHandlers } | ConvertTo-Json -Depth 30
$patchUri = "$base/$($flow.name)?updateMask=transition_routes,event_handlers"
Invoke-RestMethod -Method Patch -Uri $patchUri -Headers $headers -Body $updateBody | Out-Null
Write-Host "[CX] Flow updated successfully."

Write-Host "[DONE] Open Conversational Agents (region $Region), select '$AgentDisplayName', and use the Test tool. Try: 'How do I enroll in a class?' or 'Payment methods'."


