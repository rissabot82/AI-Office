param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.2 Part B Queue Engine..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$Required = @(
    ".\config\messaging\queue-policy.json",
    ".\scripts\messaging\Move-AIOfficeMessage.ps1",
    ".\scripts\messaging\Get-AIOfficeMessage.ps1",
    ".\scripts\messaging\Receive-AIOfficeMessage.ps1",
    ".\scripts\messaging\Acknowledge-AIOfficeMessage.ps1",
    ".\scripts\messaging\Route-AIOfficeMessage.ps1",
    ".\scripts\messaging\Search-AIOfficeMessages.ps1",
    ".\scripts\messaging\Complete-AIOfficeMessage.ps1",
    ".\scripts\messaging\Fail-AIOfficeMessage.ps1",
    ".\scripts\messaging\Test-AIOfficeQueueEngine.ps1"
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
    Get-Content ".\config\messaging\queue-policy.json" -Raw |
        ConvertFrom-Json |
        Out-Null

    Write-Host "[VALID JSON] queue-policy.json" -ForegroundColor Green
}
catch {
    Write-Host "[JSON ERROR] queue-policy.json" -ForegroundColor Red
    $Errors.Add("Invalid queue policy JSON.")
}

$TestIds = New-Object System.Collections.Generic.List[string]

try {
    $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "marketing" `
        -To "bridge" `
        -MessageType "execution_request" `
        -Priority "high" `
        -Subject "Part B routing test" `
        -ConversationTopic "QUEUE-TEST" `
        -Queue "inbox" `
        -PayloadJson '{"test":"route"}'

    $TestIds.Add([string]$Message.message_id)

    & ".\scripts\messaging\Route-AIOfficeMessage.ps1" `
        -MessageId ([string]$Message.message_id) |
        Out-Null

    $Routed = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
        -MessageId ([string]$Message.message_id)

    if ([string]$Routed.current_queue -ne "outbox") {
        throw "Message was not routed to outbox."
    }

    Write-Host "[ROUTE OK ] Message routed to outbox." `
        -ForegroundColor Green
}
catch {
    Write-Host "[ROUTE ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Routing failed: " + $_.Exception.Message)
}

try {
    $Received = & ".\scripts\messaging\Receive-AIOfficeMessage.ps1" `
        -Queue "outbox" `
        -Recipient "bridge"

    if ($null -eq $Received -or
        [string]$Received.current_queue -ne "processing") {
        throw "Message was not claimed into processing."
    }

    & ".\scripts\messaging\Acknowledge-AIOfficeMessage.ps1" `
        -MessageId ([string]$Received.message_id) `
        -Actor "bridge" |
        Out-Null

    & ".\scripts\messaging\Complete-AIOfficeMessage.ps1" `
        -MessageId ([string]$Received.message_id) `
        -Actor "bridge" |
        Out-Null

    $Completed = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
        -MessageId ([string]$Received.message_id)

    if ([string]$Completed.current_queue -ne "processed") {
        throw "Message was not completed into processed."
    }

    Write-Host "[PROCESS OK] Receive, acknowledge, complete passed." `
        -ForegroundColor Green
}
catch {
    Write-Host "[PROCESS ER] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Processing failed: " + $_.Exception.Message)
}

try {
    $FailedMessage = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "analytics" `
        -To "chief-of-staff" `
        -MessageType "error" `
        -Priority "urgent" `
        -Subject "Part B failure test" `
        -ConversationTopic "FAIL-TEST" `
        -Queue "processing" `
        -PayloadJson '{"test":"failure"}'

    $TestIds.Add([string]$FailedMessage.message_id)

    & ".\scripts\messaging\Fail-AIOfficeMessage.ps1" `
        -MessageId ([string]$FailedMessage.message_id) `
        -Reason "Validation failure" |
        Out-Null

    $Failed = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
        -MessageId ([string]$FailedMessage.message_id)

    if ([string]$Failed.current_queue -ne "failed" -or
        [int]$Failed.delivery_attempts -ne 1) {
        throw "Failed message state was incorrect."
    }

    Write-Host "[FAIL OK   ] Failure handling passed." `
        -ForegroundColor Green
}
catch {
    Write-Host "[FAIL ERR  ] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Failure handling failed: " + $_.Exception.Message)
}

try {
    $Search = @(
        & ".\scripts\messaging\Search-AIOfficeMessages.ps1" `
            -ConversationId ([string]$Message.conversation_id)
    )

    if ($Search.Count -lt 1) {
        throw "Search did not return the test message."
    }

    Write-Host "[SEARCH OK ] Search returned message(s)." `
        -ForegroundColor Green
}
catch {
    Write-Host "[SEARCH ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Search failed: " + $_.Exception.Message)
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
        " queue engine error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.2 Part B Queue Engine checks passed." `
    -ForegroundColor Green
