$intents = @(
    @{ name = "payment_faq"; phrases = @("How do I pay?","Payment methods","Where to upload payment proof?","How long does payment verification take?","How to view my invoice?") },
    @{ name = "schedule_faq"; phrases = @("What is the class schedule?","Weekly timetable","When is the next session?","Will I get notified if a class is canceled?") },
    @{ name = "materials_faq"; phrases = @("Where to find class materials?","How to download notes?","How to access recordings?","I cannot download materials") },
    @{ name = "notifications_faq"; phrases = @("How do notifications work?","Why did I get an enrollment notification?","How to stop notifications?","Turn off notifications") },
    @{ name = "refund_faq"; phrases = @("How do refunds work?","When will I get my refund?","Refund policy","How to request a refund") },
    @{ name = "account_faq"; phrases = @("How do I update my profile?","Change phone number","Update email","Edit profile information") },
    @{ name = "approval_faq"; phrases = @("How are tutors approved?","How are classes approved?","Why is my class still pending approval?") },
    @{ name = "announcement_faq"; phrases = @("How are announcements sent?","Broadcast announcements","Where can I read announcements?") },
    @{ name = "reschedule_faq"; phrases = @("How to reschedule a class?","Class canceled","What if I miss a session?") },
    @{ name = "support_faq"; phrases = @("How to contact support?","Help center","Get help") }
)

foreach ($intent in $intents) {
    $intentDir = "dialogflow\import_bundle\intents\$($intent.name)"
    
    # Create intent JSON
    $intentJson = @{
        displayName = $intent.name
        priority = 500000
    } | ConvertTo-Json -Depth 10
    $intentJson | Set-Content -Path "$intentDir\$($intent.name).json" -Encoding UTF8
    
    # Create training phrases
    $trainingPhrases = @()
    foreach ($phrase in $intent.phrases) {
        $trainingPhrases += @{
            parts = @(@{ text = $phrase; auto = $true })
            repeatCount = 1
            languageCode = "en"
        }
    }
    
    $tpJson = @{
        trainingPhrases = $trainingPhrases
    } | ConvertTo-Json -Depth 10
    $tpJson | Set-Content -Path "$intentDir\trainingPhrases\en.json" -Encoding UTF8
    
    Write-Host "Created $($intent.name)"
}


