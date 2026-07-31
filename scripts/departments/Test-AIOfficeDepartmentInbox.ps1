param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.2 Part B Department Inbox and Work Intake..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\departments\department-inbox-policy.json",
    ".\config\departments\department-work-item-schema.json",
    ".\config\departments\department-intake-classification-schema.json",
    ".\workspace\templates\department-work-item-template.json"
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
    ".\scripts\departments\AIOfficeDepartmentInbox.Common.ps1",
    ".\scripts\departments\Test-AIOfficeDepartmentWorkAcceptance.ps1",
    ".\scripts\departments\New-AIOfficeDepartmentWorkItem.ps1",
    ".\scripts\departments\Invoke-AIOfficeDepartmentInbox.ps1",
    ".\scripts\departments\Search-AIOfficeDepartmentWork.ps1",
    ".\scripts\departments\Test-AIOfficeDepartmentInbox.ps1"
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

$MessageId = ""
$WorkItemId = ""

try {
    $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "chief-of-staff" `
        -To "marketing" `
        -MessageType "handoff" `
        -Priority "high" `
        -Subject "Create dealership campaign plan" `
        -ConversationTopic "DEPT-INBOX-TEST" `
        -Queue "outbox" `
        -PayloadJson '{"objective":"Create an August dealership campaign.","deliverables":["Campaign strategy","Offer structure"],"required_capabilities":["campaign_strategy","marketing_copy"],"risk_level":"low","approval_status":"not_required"}'

    $MessageId = [string]$Message.message_id

    $Results = @(
        & ".\scripts\departments\Invoke-AIOfficeDepartmentInbox.ps1" `
            -Department "marketing" `
            -Limit 1
    )

    if ($Results.Count -ne 1 -or
        [string]::IsNullOrWhiteSpace([string]$Results[0].work_item_id)) {
        throw "Department inbox did not create a work item."
    }

    $WorkItemId = [string]$Results[0].work_item_id

    Write-Host "[INBOX OK   ] $WorkItemId" -ForegroundColor Green
}
catch {
    Write-Host "[INBOX ERR  ] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Department inbox failed: " + $_.Exception.Message)
}

try {
    $Work = @(
        & ".\scripts\departments\Search-AIOfficeDepartmentWork.ps1" `
            -Department "marketing"
    )

    if ($Work.Count -lt 1) {
        throw "Department work search returned no records."
    }

    Write-Host (
        "[WORK OK    ] " +
        $Work.Count.ToString() +
        " work item(s)"
    ) -ForegroundColor Green
}
catch {
    Write-Host "[WORK ERR   ] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Department work search failed: " + $_.Exception.Message)
}

if ($WorkItemId) {
    $Path = ".\workspace\departments\marketing\work\$WorkItemId.json"

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

Get-ChildItem `
    -LiteralPath ".\workspace\departments\marketing\classifications" `
    -Filter "DCL-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    ForEach-Object {
        $Record = Get-Content -LiteralPath $_.FullName -Raw |
            ConvertFrom-Json

        if ([string]$Record.message_id -eq $MessageId) {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }

foreach ($Folder in @(
    ".\workspace\departments\marketing\processed-inbox",
    ".\workspace\departments\marketing\failed-inbox"
)) {
    $Path = Join-Path $Folder ($MessageId + ".json")

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

if ($MessageId) {
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
}

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
    Out-Null

& ".\scripts\departments\Update-AIOfficeDepartmentIndex.ps1" |
    Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Department Inbox and Work Intake error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.2 Part B Department Inbox and Work Intake checks passed." `
    -ForegroundColor Green
