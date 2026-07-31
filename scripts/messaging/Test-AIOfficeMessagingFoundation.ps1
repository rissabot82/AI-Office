param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.2 Part A Messaging Foundation..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\messaging\messaging-policy.json",
    ".\config\messaging\message-schema.json",
    ".\config\messaging\routing-policy.json",
    ".\workspace\messages\message-index.json",
    ".\workspace\templates\message-template.json"
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
    ".\scripts\messaging\AIOfficeMessaging.Common.ps1",
    ".\scripts\messaging\New-AIOfficeMessage.ps1",
    ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1",
    ".\scripts\messaging\Show-AIOfficeMessageStatus.ps1",
    ".\scripts\messaging\Test-AIOfficeMessagingFoundation.ps1"
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

$TestMessageId = ""

try {
    $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "chief-of-staff" `
        -To "bridge" `
        -MessageType "execution_request" `
        -Subject "Part A validation message" `
        -Priority "normal" `
        -ConversationTopic "VALIDATION" `
        -Queue "outbox" `
        -PayloadJson '{"validation":true,"milestone":"1.1.2-A"}'

    $TestMessageId = [string]$Message.message_id

    if ([string]::IsNullOrWhiteSpace($TestMessageId)) {
        throw "Validation message did not contain a message ID."
    }

    . ".\scripts\messaging\AIOfficeMessaging.Common.ps1"

    if (-not (Test-AIOfficeMessageShape -Message $Message)) {
        throw "Validation message did not match the expected shape."
    }

    Write-Host "[MESSAGE OK ] $TestMessageId" -ForegroundColor Green
}
catch {
    Write-Host "[MESSAGE ERR] Message creation failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Message creation failed: " + $_.Exception.Message)
}

try {
    $Index = & ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1"

    if ($null -eq $Index -or [int]$Index.outbox_count -lt 1) {
        throw "Message index did not contain the validation message."
    }

    Write-Host (
        "[INDEX OK   ] " +
        [string]$Index.total_messages +
        " message(s)"
    ) -ForegroundColor Green
}
catch {
    Write-Host "[INDEX ERR  ] Message indexing failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Message indexing failed: " + $_.Exception.Message)
}

if (-not [string]::IsNullOrWhiteSpace($TestMessageId)) {
    $Path = ".\workspace\messages\outbox\$TestMessageId.json"

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }

    & ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
        Out-Null
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " messaging foundation error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.2 Part A Messaging Foundation checks passed." `
    -ForegroundColor Green
