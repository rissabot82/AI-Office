param(
    [switch]$AuthenticatedConnectionTest,
    [switch]$LiveExecutionTest
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeBridge.Common.ps1")

$Root = Get-AIOfficeBridgeRoot
Set-Location $Root

$Checks = New-Object System.Collections.Generic.List[object]

function Add-BridgeCertificationCheck {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][bool]$Passed,
        [Parameter(Mandatory=$true)][string]$Details
    )

    $Checks.Add([ordered]@{
        name = $Name
        passed = $Passed
        details = $Details
    })
}

$JsonFiles = @(
    ".\config\bridge\bridge-identity.json",
    ".\config\bridge\bridge-policy.json",
    ".\config\bridge\bridge-capabilities.json",
    ".\config\bridge\approval-policy.json",
    ".\config\bridge\execution-policy.json",
    ".\config\bridge\result-policy.json",
    ".\config\bridge\release-manifest.json",
    ".\config\bridge\certification-schema.json",
    ".\config\bridge\live-certification-policy.json"
)

foreach ($Path in $JsonFiles) {
    try {
        Get-Content -LiteralPath $Path -Raw |
            ConvertFrom-Json |
            Out-Null

        Add-BridgeCertificationCheck `
            -Name ("Valid JSON: " + $Path) `
            -Passed $true `
            -Details "Parsed successfully."
    }
    catch {
        Add-BridgeCertificationCheck `
            -Name ("Valid JSON: " + $Path) `
            -Passed $false `
            -Details $_.Exception.Message
    }
}

$RequiredScripts = @(
    ".\scripts\bridge\AIOfficeBridge.Common.ps1",
    ".\scripts\bridge\AIOfficeOpenClaw.Transport.ps1",
    ".\scripts\bridge\AIOfficeBridgeResults.Common.ps1",
    ".\scripts\bridge\New-AIOfficeBridgeRequest.ps1",
    ".\scripts\bridge\Test-AIOfficeBridgeRequest.ps1",
    ".\scripts\bridge\Test-AIOfficeOpenClawConnection.ps1",
    ".\scripts\bridge\Invoke-AIOfficeOpenClawExecution.ps1",
    ".\scripts\bridge\Receive-AIOfficeBridgeWork.ps1",
    ".\scripts\bridge\New-AIOfficeArtifactManifest.ps1",
    ".\scripts\bridge\ConvertTo-AIOfficeNormalizedResult.ps1",
    ".\scripts\bridge\Publish-AIOfficeOpenClawResult.ps1",
    ".\scripts\bridge\Process-AIOfficeOpenClawResult.ps1",
    ".\scripts\bridge\Search-AIOfficeBridgeArtifacts.ps1",
    ".\scripts\bridge\Certify-AIOfficeOpenClawBridge.ps1",
    ".\scripts\bridge\Test-AIOfficeOpenClawBridge.ps1",
    ".\scripts\bridge\Publish-AIOfficeOpenClawBridgeRelease.ps1"
)

foreach ($Path in $RequiredScripts) {
    $Exists = Test-Path -LiteralPath $Path -PathType Leaf

    Add-BridgeCertificationCheck `
        -Name ("Script exists: " + $Path) `
        -Passed $Exists `
        -Details $(if ($Exists) { "Found." } else { "Missing." })
}

try {
    $Index = & ".\scripts\bridge\Update-AIOfficeBridgeIndex.ps1"

    Add-BridgeCertificationCheck `
        -Name "Gateway port reachable" `
        -Passed ([bool]$Index.gateway_reachable) `
        -Details (
            [string]$Index.gateway_url +
            " | reachable=" +
            [string]$Index.gateway_reachable
        )
}
catch {
    Add-BridgeCertificationCheck `
        -Name "Gateway port reachable" `
        -Passed $false `
        -Details $_.Exception.Message
}

if ($AuthenticatedConnectionTest -or $LiveExecutionTest) {
    try {
        $Health = & ".\scripts\bridge\Test-AIOfficeOpenClawConnection.ps1" `
            -Authenticated

        Add-BridgeCertificationCheck `
            -Name "Authenticated Gateway connection" `
            -Passed ([bool]$Health.authenticated) `
            -Details $(if ([bool]$Health.authenticated) {
                "Server " +
                [string]$Health.server_version +
                " | protocol " +
                [string]$Health.protocol
            }
            else {
                [string]$Health.error
            })
    }
    catch {
        Add-BridgeCertificationCheck `
            -Name "Authenticated Gateway connection" `
            -Passed $false `
            -Details $_.Exception.Message
    }
}
else {
    Add-BridgeCertificationCheck `
        -Name "Authenticated Gateway connection" `
        -Passed $true `
        -Details "Skipped by design. Run with -AuthenticatedConnectionTest."
}

$Mode = "offline"
$MessageId = ""
$RequestId = ""
$ExecutionId = ""
$PublishedMessageId = ""

if ($LiveExecutionTest) {
    $Mode = "live"

    try {
        $LivePolicy = Read-AIOfficeBridgeJson `
            -Path ".\config\bridge\live-certification-policy.json"

        if ($null -eq $LivePolicy) {
            throw "Live certification policy could not be loaded."
        }

        $Payload = [ordered]@{
            action_type = "agent_task"
            risk_level = "low"
            approval_status = "not_required"
            prompt = [string]$LivePolicy.live_test.prompt
        }

        $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
            -From "chief-of-staff" `
            -To "bridge" `
            -MessageType "execution_request" `
            -Priority "high" `
            -Subject "OpenClaw Bridge live certification" `
            -ConversationTopic "BRIDGE-LIVE-CERTIFICATION" `
            -Queue "processing" `
            -PayloadJson ($Payload | ConvertTo-Json -Depth 10 -Compress)

        $MessageId = [string]$Message.message_id

        $Request = & ".\scripts\bridge\New-AIOfficeBridgeRequest.ps1" `
            -MessageId $MessageId `
            -RequestedBy "chief-of-staff" `
            -ActionType "agent_task" `
            -RiskLevel "low" `
            -ApprovalStatus "not_required" `
            -PayloadJson ($Payload | ConvertTo-Json -Depth 10 -Compress)

        $RequestId = [string]$Request.bridge_request_id

        $Execution = & ".\scripts\bridge\Invoke-AIOfficeOpenClawExecution.ps1" `
            -BridgeRequestId $RequestId `
            -SessionKey ([string]$LivePolicy.live_test.default_session_key) `
            -TimeoutSeconds ([int]$LivePolicy.live_test.default_timeout_seconds)

        $ExecutionId = [string]$Execution.execution_id

        $Published = & ".\scripts\bridge\Process-AIOfficeOpenClawResult.ps1" `
            -ExecutionId $ExecutionId `
            -Recipient "chief-of-staff"

        $PublishedMessageId = [string]$Published.message_id

        $NormalizedFiles = @(
            Get-ChildItem `
                -LiteralPath ".\workspace\bridge\results\normalized" `
                -Filter "NRR-*.json" `
                -File `
                -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending
        )

        $Normalized = $null

        foreach ($File in $NormalizedFiles) {
            $Record = Read-AIOfficeBridgeJson -Path $File.FullName

            if ($null -ne $Record -and
                [string]$Record.execution_id -eq $ExecutionId) {
                $Normalized = $Record
                break
            }
        }

        if ($null -eq $Normalized) {
            throw "Normalized live result was not found."
        }

        $ExpectedText = [string]$LivePolicy.live_test.expected_text
        $Summary = [string]$Normalized.summary
        $TextMatched = $Summary -like ("*" + $ExpectedText + "*")

        Add-BridgeCertificationCheck `
            -Name "Live OpenClaw execution" `
            -Passed (
                [string]$Execution.status -eq "completed" -and
                -not [string]::IsNullOrWhiteSpace($PublishedMessageId)
            ) `
            -Details (
                "Execution " +
                $ExecutionId +
                " | result message " +
                $PublishedMessageId
            )

        Add-BridgeCertificationCheck `
            -Name "Live response text" `
            -Passed $TextMatched `
            -Details $Summary
    }
    catch {
        Add-BridgeCertificationCheck `
            -Name "Live OpenClaw execution" `
            -Passed $false `
            -Details $_.Exception.Message
    }
}
else {
    Add-BridgeCertificationCheck `
        -Name "Live OpenClaw execution" `
        -Passed $true `
        -Details "Skipped by design. Run with -LiveExecutionTest."
}

# Offline end-to-end request/result certification.
try {
    $OfflineMessage = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "chief-of-staff" `
        -To "bridge" `
        -MessageType "execution_request" `
        -Priority "normal" `
        -Subject "Offline bridge certification" `
        -ConversationTopic "BRIDGE-OFFLINE-CERTIFICATION" `
        -Queue "processing" `
        -PayloadJson '{"action_type":"certification","risk_level":"low","approval_status":"not_required"}'

    $OfflineMessageId = [string]$OfflineMessage.message_id

    $OfflineRequest = & ".\scripts\bridge\New-AIOfficeBridgeRequest.ps1" `
        -MessageId $OfflineMessageId `
        -RequestedBy "chief-of-staff" `
        -ActionType "certification" `
        -RiskLevel "low" `
        -ApprovalStatus "not_required" `
        -PayloadJson '{"prompt":"Offline certification."}'

    $OfflineRequestId = [string]$OfflineRequest.bridge_request_id

    . ".\scripts\bridge\AIOfficeOpenClaw.Transport.ps1"

    $OfflineExecutionId = New-AIOfficeExecutionId
    $Current = (Get-Date).ToString("o")

    $OfflineExecution = [ordered]@{
        execution_id = $OfflineExecutionId
        bridge_request_id = $OfflineRequestId
        message_id = $OfflineMessageId
        status = "completed"
        gateway_url = "ws://localhost:18789"
        method = "offline-certification"
        run_id = "RUN-OFFLINE-CERTIFICATION"
        session_key = "ai-office-bridge-certification"
        created_at = $Current
        updated_at = $Current
        started_at = $Current
        completed_at = $Current
        request_payload = [ordered]@{
            certification = $true
        }
        response_payload = [ordered]@{
            summary = "Offline OpenClaw Bridge certification completed."
            status = "success"
        }
        error = $null
        history = @(
            [ordered]@{
                timestamp = $Current
                action = "offline_certification"
                actor = "bridge-certification"
                details = "Synthetic execution used to validate result pipeline."
            }
        )
    }

    $OfflineExecution |
        ConvertTo-Json -Depth 40 |
        Set-Content `
            -LiteralPath ".\workspace\bridge\executions\$OfflineExecutionId.json" `
            -Encoding UTF8

    $OfflinePublished = & ".\scripts\bridge\Process-AIOfficeOpenClawResult.ps1" `
        -ExecutionId $OfflineExecutionId `
        -Recipient "chief-of-staff"

    Add-BridgeCertificationCheck `
        -Name "Offline end-to-end pipeline" `
        -Passed (
            -not [string]::IsNullOrWhiteSpace(
                [string]$OfflinePublished.message_id
            )
        ) `
        -Details (
            "Execution " +
            $OfflineExecutionId +
            " published as " +
            [string]$OfflinePublished.message_id
        )

    # Clean only the temporary offline message/request/result-message.
    foreach ($CurrentMessageId in @(
        $OfflineMessageId,
        [string]$OfflinePublished.message_id
    )) {
        foreach ($Queue in @(
            "inbox",
            "outbox",
            "processing",
            "processed",
            "failed",
            "dead-letter",
            "archive"
        )) {
            $Path = ".\workspace\messages\$Queue\$CurrentMessageId.json"

            if (Test-Path -LiteralPath $Path -PathType Leaf) {
                Remove-Item -LiteralPath $Path -Force
            }
        }
    }

    $OfflineRequestPath = ".\workspace\bridge\requests\$OfflineRequestId.json"

    if (Test-Path -LiteralPath $OfflineRequestPath -PathType Leaf) {
        Remove-Item -LiteralPath $OfflineRequestPath -Force
    }
}
catch {
    Add-BridgeCertificationCheck `
        -Name "Offline end-to-end pipeline" `
        -Passed $false `
        -Details $_.Exception.Message
}

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
    Out-Null

& ".\scripts\bridge\Update-AIOfficeBridgeIndex.ps1" |
    Out-Null

$PassedCount = @(
    $Checks | Where-Object { $_.passed -eq $true }
).Count

$FailedCount = @(
    $Checks | Where-Object { $_.passed -eq $false }
).Count

$Status = if ($FailedCount -eq 0) {
    "certified"
}
else {
    "failed"
}

$CertificationId = (
    "CERT-BRIDGE-" +
    (Get-Date).ToString("yyyyMMdd-HHmmss")
)

$Certification = [ordered]@{
    certification_id = $CertificationId
    version = "1.1.3"
    certified_at = (Get-Date).ToString("o")
    mode = $Mode
    status = $Status
    passed_checks = $PassedCount
    failed_checks = $FailedCount
    live_execution_id = $ExecutionId
    live_result_message_id = $PublishedMessageId
    checks = @($Checks | ForEach-Object { $_ })
}

$CertificationPath = Join-Path `
    ".\workspace\bridge\certification" `
    ($CertificationId + ".json")

Write-AIOfficeBridgeJson `
    -Value $Certification `
    -Path $CertificationPath

Write-Host (
    "OpenClaw Bridge certification: " +
    $Status +
    " | " +
    $PassedCount.ToString() +
    " passed, " +
    $FailedCount.ToString() +
    " failed"
) -ForegroundColor $(if ($FailedCount -eq 0) { "Green" } else { "Red" })

return [pscustomobject]$Certification
