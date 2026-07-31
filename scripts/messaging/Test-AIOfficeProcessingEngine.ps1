param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.2 Part C Processing Engine..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$Required = @(
    ".\config\messaging\processing-policy.json",
    ".\scripts\messaging\Retry-AIOfficeMessage.ps1",
    ".\scripts\messaging\Move-AIOfficeMessageToDeadLetter.ps1",
    ".\scripts\messaging\Recover-AIOfficeDeadLetterMessage.ps1",
    ".\scripts\messaging\Archive-AIOfficeMessage.ps1",
    ".\scripts\messaging\Invoke-AIOfficeMessageMaintenance.ps1",
    ".\scripts\messaging\Invoke-AIOfficeMessageProcessor.ps1",
    ".\scripts\messaging\Retry-AIOfficeFailedMessages.ps1",
    ".\scripts\messaging\Test-AIOfficeProcessingEngine.ps1"
)

foreach ($Path in $Required) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Write-Host "[FOUND] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[MISS ] $Path" -ForegroundColor Red
        $Errors.Add("Missing file: " + $Path)
    }
}

try {
    Get-Content ".\config\messaging\processing-policy.json" -Raw |
        ConvertFrom-Json |
        Out-Null

    Write-Host "[VALID JSON] processing-policy.json" `
        -ForegroundColor Green
}
catch {
    Write-Host "[JSON ERROR] processing-policy.json" `
        -ForegroundColor Red
    $Errors.Add("Invalid processing-policy.json")
}

$TestIds = New-Object System.Collections.Generic.List[string]

try {
    $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "analytics" `
        -To "chief-of-staff" `
        -MessageType "error" `
        -Priority "high" `
        -Subject "Part C retry test" `
        -ConversationTopic "RETRY-TEST" `
        -Queue "processing" `
        -PayloadJson '{"test":"retry"}'

    $TestIds.Add([string]$Message.message_id)

    & ".\scripts\messaging\Fail-AIOfficeMessage.ps1" `
        -MessageId ([string]$Message.message_id) `
        -Reason "Retry validation" |
        Out-Null

    & ".\scripts\messaging\Retry-AIOfficeMessage.ps1" `
        -MessageId ([string]$Message.message_id) `
        -ReturnQueue "inbox" |
        Out-Null

    $Retried = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
        -MessageId ([string]$Message.message_id)

    if ([string]$Retried.current_queue -ne "inbox") {
        throw "Retry did not return message to inbox."
    }

    Write-Host "[RETRY OK  ] Retry scheduling passed." `
        -ForegroundColor Green
}
catch {
    Write-Host "[RETRY ERR ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Retry test failed: " + $_.Exception.Message)
}

try {
    $DeadMessage = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "bridge" `
        -To "chief-of-staff" `
        -MessageType "error" `
        -Priority "urgent" `
        -Subject "Part C dead-letter test" `
        -ConversationTopic "DEAD-LETTER-TEST" `
        -Queue "failed" `
        -PayloadJson '{"test":"dead-letter"}'

    $TestIds.Add([string]$DeadMessage.message_id)

    & ".\scripts\messaging\Move-AIOfficeMessageToDeadLetter.ps1" `
        -MessageId ([string]$DeadMessage.message_id) `
        -Reason "Validation dead-letter movement." |
        Out-Null

    $Dead = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
        -MessageId ([string]$DeadMessage.message_id)

    if ([string]$Dead.current_queue -ne "dead-letter") {
        throw "Message did not move to dead-letter."
    }

    & ".\scripts\messaging\Recover-AIOfficeDeadLetterMessage.ps1" `
        -MessageId ([string]$DeadMessage.message_id) `
        -DestinationQueue "outbox" |
        Out-Null

    $Recovered = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
        -MessageId ([string]$DeadMessage.message_id)

    if ([string]$Recovered.current_queue -ne "outbox" -or
        [int]$Recovered.delivery_attempts -ne 0) {
        throw "Dead-letter recovery state was incorrect."
    }

    Write-Host "[DEAD OK   ] Dead-letter and recovery passed." `
        -ForegroundColor Green
}
catch {
    Write-Host "[DEAD ERR  ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Dead-letter test failed: " + $_.Exception.Message)
}

try {
    $BatchOne = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "marketing" `
        -To "bridge" `
        -MessageType "execution_request" `
        -Priority "normal" `
        -Subject "Part C batch test 1" `
        -ConversationTopic "BATCH-TEST" `
        -Queue "outbox" `
        -PayloadJson '{"test":"batch1"}'

    $BatchTwo = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "creative" `
        -To "bridge" `
        -MessageType "execution_request" `
        -Priority "normal" `
        -Subject "Part C batch test 2" `
        -ConversationTopic "BATCH-TEST" `
        -Queue "outbox" `
        -PayloadJson '{"test":"batch2"}'

    $TestIds.Add([string]$BatchOne.message_id)
    $TestIds.Add([string]$BatchTwo.message_id)

    $BatchResults = @(
        & ".\scripts\messaging\Invoke-AIOfficeMessageProcessor.ps1" `
            -Queue "outbox" `
            -Recipient "bridge" `
            -BatchSize 2 `
            -AutoComplete
    )

    if ($BatchResults.Count -ne 2) {
        throw "Batch processor did not process two messages."
    }

    Write-Host "[BATCH OK  ] Batch processor passed." `
        -ForegroundColor Green
}
catch {
    Write-Host "[BATCH ERR ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Batch processor test failed: " + $_.Exception.Message)
}

try {
    $Maintenance = @(
        & ".\scripts\messaging\Invoke-AIOfficeMessageMaintenance.ps1"
    )

    Write-Host (
        "[MAINT OK  ] Preview returned " +
        $Maintenance.Count.ToString() +
        " action(s)."
    ) -ForegroundColor Green
}
catch {
    Write-Host "[MAINT ERR ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Maintenance test failed: " + $_.Exception.Message)
}

foreach ($MessageId in $TestIds) {
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

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " processing engine error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.2 Part C Processing Engine checks passed." `
    -ForegroundColor Green
