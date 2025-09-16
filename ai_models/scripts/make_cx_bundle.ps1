param(
    [string]$OutputRoot = "dialogflow/import_bundle",
    [string]$AgentDisplayName = "AI ClassMate FAQ",
    [string]$LanguageCode = "en",
    [string]$TimeZone = "Asia/Colombo"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Ensure-Dir([string]$p) {
    if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path $p | Out-Null }
}

function Write-JsonFile([string]$path, $obj) {
    $json = $obj | ConvertTo-Json -Depth 100
    $json | Set-Content -LiteralPath $path -Encoding UTF8
}

# 1) Prepare folder structure
Ensure-Dir $OutputRoot
Ensure-Dir (Join-Path $OutputRoot "flows")
Ensure-Dir (Join-Path $OutputRoot "flows/_")
Ensure-Dir (Join-Path $OutputRoot "intents")
Ensure-Dir (Join-Path $OutputRoot "generativeSettings")
Ensure-Dir (Join-Path $OutputRoot "playbooks")

# 2) agent.json (use Start Flow by name to satisfy Console restore requirement)
$agent = @{ displayName = $AgentDisplayName; defaultLanguageCode = $LanguageCode; timeZone = $TimeZone; startFlow = "Default Start Flow"; advancedSettings = @{ loggingSettings = @{ } }; dataResidencyOption = "DATA_RESIDENCY_IN_USE_COMPLIANT" }
Write-JsonFile (Join-Path $OutputRoot "agent.json") $agent

# 3) Define intents with phrases and canned responses
$faq = @(
    @{ name = "enrollment_faq"; phrases = @("How do I enroll in a class?","What is the enrollment process?","How can a student join a class?","How to register for a class?","How to enroll from the app?"); resp = "To enroll: search a class, open it, tap Enroll and confirm seats. You will see the enrollment as Pending until payment is verified." },
    @{ name = "payment_faq"; phrases = @("How do I pay?","Payment methods","Where to upload payment proof?","How long does payment verification take?","How to view my invoice?"); resp = "Payments: bank transfer, card, cash and online methods. Upload your payment proof on the invoice screen. Verification usually completes within 24-48 hours." },
    @{ name = "schedule_faq"; phrases = @("What is the class schedule?","Weekly timetable","When is the next session?","Will I get notified if a class is canceled?"); resp = "Open Weekly Timetable to view upcoming sessions. Start times are local. If a class is canceled or changed we will notify you automatically." },
    @{ name = "materials_faq"; phrases = @("Where to find class materials?","How to download notes?","How to access recordings?","I cannot download materials"); resp = "Go to the class page -> Materials to view or download notes and files. Tutors may upload recordings when available. If downloads are disabled please contact the tutor." },
    @{ name = "notifications_faq"; phrases = @("How do notifications work?","Why did I get an enrollment notification?","How to stop notifications?","Turn off notifications"); resp = "We send notifications for enrollment/payment status and schedule changes. You can mute non-critical messages from Settings -> Notifications." },
    @{ name = "refund_faq"; phrases = @("How do refunds work?","When will I get my refund?","Refund policy","How to request a refund"); resp = "Refunds: if your payment is verified and the tutor cancels or support approves a refund request, we process it to your original payment method within 5-10 business days." },
    @{ name = "account_faq"; phrases = @("How do I update my profile?","Change phone number","Update email","Edit profile information"); resp = "Update your profile from Profile -> Edit. You can change name, grade and area. Email changes require re-verification; phone changes require OTP." },
    @{ name = "approval_faq"; phrases = @("How are tutors approved?","How are classes approved?","Why is my class still pending approval?"); resp = "Tutor and class approvals: admins review documents for authenticity and schedule conflicts. Class status changes from Draft to Published once approved." },
    @{ name = "announcement_faq"; phrases = @("How are announcements sent?","Broadcast announcements","Where can I read announcements?"); resp = "Admins and tutors can broadcast announcements. You can read all recent announcements from Home -> Announcements and receive push notifications." },
    @{ name = "reschedule_faq"; phrases = @("How to reschedule a class?","Class canceled","What if I miss a session?"); resp = "To reschedule, contact the tutor from the class page. If a session is canceled by the tutor, a new date/time will be posted and you will be notified." },
    @{ name = "support_faq"; phrases = @("How to contact support?","Help center","Get help"); resp = "Need help? Email support@classmate.lk or use Help -> Contact Support in the app. Include your user ID and the class/enrollment ID for faster assistance." }
)

# 4) Create intent files + training phrases
foreach ($it in $faq) {
    $intentDir = Join-Path $OutputRoot ("intents/" + $it.name)
    Ensure-Dir $intentDir
    Ensure-Dir (Join-Path $intentDir "trainingPhrases")

    $intentMeta = @{ displayName = $it.name; priority = 500000 }
    Write-JsonFile (Join-Path $intentDir ("" + $it.name + ".json")) $intentMeta

    $tp = @()
    foreach ($p in $it.phrases) {
        $tp += @{ parts = @(@{ text = $p; auto = $true }); repeatCount = 1; languageCode = $LanguageCode }
    }
    $tpObj = @{ trainingPhrases = $tp }
    Write-JsonFile (Join-Path $intentDir "trainingPhrases/en.json") $tpObj
}

# 4b) Default intents (match common export structure)
$welcomeDir = Join-Path $OutputRoot "intents/Default Welcome Intent"
Ensure-Dir $welcomeDir
Ensure-Dir (Join-Path $welcomeDir "trainingPhrases")
Write-JsonFile (Join-Path $welcomeDir "Default Welcome Intent.json") @{ displayName = "Default Welcome Intent"; priority = 500000 }
Write-JsonFile (Join-Path $welcomeDir "trainingPhrases/en.json") @{ trainingPhrases = @(
    @{ parts = @(@{ text = "hello"; auto = $true }); repeatCount = 1; languageCode = $LanguageCode },
    @{ parts = @(@{ text = "hi"; auto = $true }); repeatCount = 1; languageCode = $LanguageCode },
    @{ parts = @(@{ text = "hey"; auto = $true }); repeatCount = 1; languageCode = $LanguageCode }
) }

$negDir = Join-Path $OutputRoot "intents/Default Negative Intent"
Ensure-Dir $negDir
Write-JsonFile (Join-Path $negDir "Default Negative Intent.json") @{ displayName = "Default Negative Intent"; priority = 500000; isFallback = $true }

# 5) Build Default Start Flow with routes to intent display names
$routes = @()
foreach ($it in $faq) {
    $routes += @{ intent = $it.name; triggerFulfillment = @{ messages = @(@{ text = @{ text = @($it.resp) }; languageCode = $LanguageCode }) }; name = [guid]::NewGuid().ToString() }
}

$events = @(
    @{ event = "sys.no-match-default"; triggerFulfillment = @{ messages = @(@{ text = @{ text = @("Sorry, I did not catch that. Try asking about enrollment, payments, schedule, materials, notifications or refunds.") }; languageCode = $LanguageCode }) }; name = [guid]::NewGuid().ToString() },
    @{ event = "sys.no-input-default"; triggerFulfillment = @{ messages = @(@{ text = @{ text = @("Are you still there? You can ask me about enrollment, payments, schedule or materials.") }; languageCode = $LanguageCode }) }; name = [guid]::NewGuid().ToString() }
)

$flow = @{ name = "00000000-0000-0000-0000-000000000000"; displayName = "Default Start Flow"; description = "AI ClassMate FAQ start flow"; transitionRoutes = $routes; eventHandlers = $events; nluSettings = @{ modelType = "MODEL_TYPE_ADVANCED"; classificationThreshold = 0.3 } }

$flowDir = Join-Path $OutputRoot "flows/Default Start Flow"
Ensure-Dir $flowDir
Write-JsonFile (Join-Path $flowDir "Default Start Flow.json") $flow

# 6) Minimal generative and playbooks placeholders (optional but harmless)
Write-JsonFile (Join-Path $OutputRoot "generativeSettings/en.json") @{ languageCode = $LanguageCode }
Ensure-Dir (Join-Path $OutputRoot "playbooks/_")
Write-JsonFile (Join-Path $OutputRoot "playbooks/_/.json") @{ }

# flows underscore metadata similar to console export
Write-JsonFile (Join-Path $OutputRoot "flows/_/.json") @{ nluSettings = @{ modelType = "MODEL_TYPE_ADVANCED"; classificationThreshold = 0.3 } }

Write-Host "Bundle created at $OutputRoot"


