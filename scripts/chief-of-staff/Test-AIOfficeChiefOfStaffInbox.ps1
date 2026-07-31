param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.4 Part B Executive Inbox and Planning..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\chief-of-staff\inbox-policy.json",
    ".\config\chief-of-staff\classification-schema.json",
    ".\workspace\templates\chief-of-staff-classification-template.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw |
            ConvertFrom-Json |
            Out-Null

        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $File" -ForegroundColor Red
        $Errors.Add("Invalid JSON: " + $File)
    }
}

$Scripts = @(
    ".\scripts\chief-of-staff\AIOfficeChiefOfStaffInbox.Common.ps1",
    ".\scripts\chief-of-staff\Classify-AIOfficeChiefOfStaffMessage.ps1",
    ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffPlanFromMessage.ps1",
    ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffInbox.ps1",
    ".\scripts\chief-of-staff\Search-AIOfficeChiefOfStaffPlans.ps1",
    ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaffInbox.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING    ] $Script" -ForegroundColor Red
        $Errors.Add("Missing script: " + $Script)
    }
}

$MessageIds = New-Object System.Collections.Generic.List[string]
$PlanIds = New-Object System.Collections.Generic.List[string]

try {
    $Request = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "marketing" `
        -To "chief-of-staff" `
        -MessageType "request" `
        -Priority "high" `
        -Subject "Prepare August campaign" `
        -ConversationTopic "COS-INBOX-TEST" `
        -Queue "inbox" `
        -PayloadJson '{"objective":"Prepare an August campaign plan.","success_criteria":["Plan exists","Owner assigned"]}'

    $ErrorMessage = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "analytics" `
        -To "chief-of-staff" `
        -MessageType "error" `
        -Priority "urgent" `
        -Subject "Tracking failure" `
        -ConversationTopic "COS-INBOX-TEST" `
        -Queue "inbox" `
        -PayloadJson '{"summary":"Conversion tracking failed."}'

    $MessageIds.Add([string]$Request.message_id)
    $MessageIds.Add([string]$ErrorMessage.message_id)

    $Results = @(
        & ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffInbox.ps1" `
            -Limit 2 `
            -CreatePlans
    )

    if ($Results.Count -ne 2) {
        throw "Chief of Staff inbox did not process two messages."
    }

    foreach ($Result in $Results) {
        if (-not [string]::IsNullOrWhiteSpace([string]$Result.plan_id)) {
            $PlanIds.Add([string]$Result.plan_id)
        }
    }

    Write-Host (
        "[INBOX OK   ] " +
        $Results.Count.ToString() +
        " message(s) processed"
    ) -ForegroundColor Green
}
catch {
    Write-Host "[INBOX ERR  ] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Inbox processing failed: " + $_.Exception.Message)
}

try {
    $Plans = @(
        & ".\scripts\chief-of-staff\Search-AIOfficeChiefOfStaffPlans.ps1"
    )

    if ($Plans.Count -lt 2) {
        throw "Expected at least two generated plans."
    }

    Write-Host (
        "[PLAN OK    ] " +
        $Plans.Count.ToString() +
        " plan(s) available"
    ) -ForegroundColor Green
}
catch {
    Write-Host "[PLAN ERR   ] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Plan search failed: " + $_.Exception.Message)
}

foreach ($PlanId in $PlanIds) {
    $Path = ".\workspace\chief-of-staff\plans\$PlanId.json"

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

Get-ChildItem `
    -LiteralPath ".\workspace\chief-of-staff\classifications" `
    -Filter "CLS-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    ForEach-Object {
        $Classification = Get-Content -LiteralPath $_.FullName -Raw |
            ConvertFrom-Json

        if ($MessageIds -contains [string]$Classification.message_id) {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }

foreach ($MessageId in $MessageIds) {
    foreach ($Queue in @(
        "inbox",
        "outbox",
        "processing",
        "processed",
        "failed",
        "dead-letter",
        "archive"
    )) {
        $Path = ".\workspace\messages\$Queue\$MessageId.json"

        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            Remove-Item -LiteralPath $Path -Force
        }
    }

    foreach ($Folder in @(
        ".\workspace\chief-of-staff\processed-inbox",
        ".\workspace\chief-of-staff\failed-inbox"
    )) {
        $Path = Join-Path $Folder ($MessageId + ".json")

        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            Remove-Item -LiteralPath $Path -Force
        }
    }
}

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
    Out-Null

& ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1" |
    Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Executive Inbox and Planning error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.4 Part B Executive Inbox and Planning checks passed." `
    -ForegroundColor Green
