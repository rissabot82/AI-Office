param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.2 Internal Message Bus..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

function Invoke-TestScript {
    param(
        [string]$Name,
        [string]$Path
    )

    try {
        & $Path

        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            throw "$Name returned exit code $LASTEXITCODE."
        }

        Write-Host ("[PASS] " + $Name) -ForegroundColor Green
    }
    catch {
        Write-Host ("[FAIL] " + $Name) -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $Errors.Add($Name + ": " + $_.Exception.Message)
    }
}

Invoke-TestScript `
    -Name "Part A Messaging Foundation" `
    -Path ".\scripts\messaging\Test-AIOfficeMessagingFoundation.ps1"

Invoke-TestScript `
    -Name "Part B Queue Engine" `
    -Path ".\scripts\messaging\Test-AIOfficeQueueEngine.ps1"

Invoke-TestScript `
    -Name "Part C Processing Engine" `
    -Path ".\scripts\messaging\Test-AIOfficeProcessingEngine.ps1"

try {
    . ".\scripts\messaging\AIOfficeMessaging.Common.ps1"

    $Conversation = & ".\scripts\messaging\New-AIOfficeSampleConversation.ps1"

    if ($null -eq $Conversation -or
        [int]$Conversation.message_count -ne 5 -or
        [string]::IsNullOrWhiteSpace([string]$Conversation.conversation_id) -or
        [string]::IsNullOrWhiteSpace([string]$Conversation.correlation_id)) {
        throw "Sample conversation did not contain expected values."
    }

    Write-Host (
        "[PASS] End-to-end conversation: " +
        [string]$Conversation.conversation_id
    ) -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] End-to-end conversation" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("End-to-end conversation: " + $_.Exception.Message)
}

try {
    $Certification = & ".\scripts\messaging\Certify-AIOfficeMessageBus.ps1"

    if ($null -eq $Certification -or
        [string]$Certification.status -ne "certified" -or
        [int]$Certification.failed_checks -ne 0) {
        throw "Message Bus certification failed."
    }

    Write-Host (
        "[PASS] Certification: " +
        [string]$Certification.certification_id
    ) -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Certification" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Certification: " + $_.Exception.Message)
}

try {
    $Index = & ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1"

    if ($null -eq $Index) {
        throw "Message index was not returned."
    }

    Write-Host (
        "[PASS] Final index: " +
        [string]$Index.total_messages +
        " message(s)"
    ) -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Final message index" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Final index: " + $_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " complete Message Bus error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.2 Internal Message Bus checks passed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "AI Office v1.1.2 Message Bus is operational." `
    -ForegroundColor Cyan
