param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.3 Part C Result Processing..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\bridge\result-policy.json",
    ".\config\bridge\artifact-manifest-schema.json",
    ".\config\bridge\normalized-result-schema.json",
    ".\workspace\templates\openclaw-artifact-manifest-template.json",
    ".\workspace\templates\openclaw-normalized-result-template.json"
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
    ".\scripts\bridge\AIOfficeBridgeResults.Common.ps1",
    ".\scripts\bridge\New-AIOfficeArtifactManifest.ps1",
    ".\scripts\bridge\ConvertTo-AIOfficeNormalizedResult.ps1",
    ".\scripts\bridge\Publish-AIOfficeOpenClawResult.ps1",
    ".\scripts\bridge\Process-AIOfficeOpenClawResult.ps1",
    ".\scripts\bridge\Search-AIOfficeBridgeArtifacts.ps1",
    ".\scripts\bridge\Test-AIOfficeResultProcessing.ps1"
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

$TempArtifact = ""
$MessageId = ""
$RequestId = ""
$ExecutionId = ""
$PublishedMessageId = ""

try {
    $TempArtifact = Join-Path `
        $env:TEMP `
        ("ai-office-result-test-" + [guid]::NewGuid().ToString("N") + ".txt")

    Set-Content `
        -LiteralPath $TempArtifact `
        -Value "AI Office v1.1.3 Part C validation artifact." `
        -Encoding UTF8

    $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "chief-of-staff" `
        -To "bridge" `
        -MessageType "execution_request" `
        -Priority "high" `
        -Subject "Part C validation request" `
        -ConversationTopic "RESULT-VALIDATION" `
        -Queue "processing" `
        -PayloadJson '{"action_type":"result_validation","risk_level":"low","approval_status":"not_required"}'

    $MessageId = [string]$Message.message_id

    $Request = & ".\scripts\bridge\New-AIOfficeBridgeRequest.ps1" `
        -MessageId $MessageId `
        -RequestedBy "chief-of-staff" `
        -ActionType "result_validation" `
        -RiskLevel "low" `
        -ApprovalStatus "not_required" `
        -PayloadJson '{"prompt":"Validate result processing."}'

    $RequestId = [string]$Request.bridge_request_id

    . ".\scripts\bridge\AIOfficeOpenClaw.Transport.ps1"

    $ExecutionId = New-AIOfficeExecutionId
    $Now = (Get-Date).ToString("o")

    $Execution = [ordered]@{
        execution_id = $ExecutionId
        bridge_request_id = $RequestId
        message_id = $MessageId
        status = "completed"
        gateway_url = "ws://localhost:18789"
        method = "validation"
        run_id = "RUN-VALIDATION"
        session_key = "ai-office-bridge"
        created_at = $Now
        updated_at = $Now
        started_at = $Now
        completed_at = $Now
        request_payload = [ordered]@{
            validation = $true
        }
        response_payload = [ordered]@{
            summary = "Part C validation completed."
            artifact_path = $TempArtifact
            status = "success"
        }
        error = $null
        history = @(
            [ordered]@{
                timestamp = $Now
                action = "validation_execution_created"
                actor = "validation-suite"
                details = "Synthetic completed execution created."
            }
        )
    }

    $Execution |
        ConvertTo-Json -Depth 40 |
        Set-Content `
            -LiteralPath ".\workspace\bridge\executions\$ExecutionId.json" `
            -Encoding UTF8

    Write-Host "[EXECUTION OK] $ExecutionId" -ForegroundColor Green
}
catch {
    Write-Host "[EXECUTION ER] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Synthetic execution failed: " + $_.Exception.Message)
}

try {
    $Normalized = & ".\scripts\bridge\ConvertTo-AIOfficeNormalizedResult.ps1" `
        -ExecutionId $ExecutionId

    if ($null -eq $Normalized -or
        [string]$Normalized.summary -ne "Part C validation completed." -or
        @($Normalized.artifacts).Count -lt 1) {
        throw "Normalized result did not contain expected values."
    }

    Write-Host (
        "[NORMALIZE OK] " +
        [string]$Normalized.normalized_result_id
    ) -ForegroundColor Green
}
catch {
    Write-Host "[NORMALIZE ER] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Normalization failed: " + $_.Exception.Message)
}

try {
    $Published = & ".\scripts\bridge\Publish-AIOfficeOpenClawResult.ps1" `
        -ExecutionId $ExecutionId `
        -Recipient "chief-of-staff"

    $PublishedMessageId = [string]$Published.message_id

    if ([string]::IsNullOrWhiteSpace($PublishedMessageId)) {
        throw "Result message was not published."
    }

    Write-Host "[PUBLISH OK ] $PublishedMessageId" `
        -ForegroundColor Green
}
catch {
    Write-Host "[PUBLISH ERR] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Publishing failed: " + $_.Exception.Message)
}

try {
    $Artifacts = @(
        & ".\scripts\bridge\Search-AIOfficeBridgeArtifacts.ps1" `
            -ExecutionId $ExecutionId
    )

    if ($Artifacts.Count -lt 1) {
        throw "Artifact search returned no results."
    }

    Write-Host (
        "[ARTIFACT OK] " +
        $Artifacts.Count.ToString() +
        " artifact(s)"
    ) -ForegroundColor Green
}
catch {
    Write-Host "[ARTIFACT ER] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Artifact search failed: " + $_.Exception.Message)
}

if ($TempArtifact -and
    (Test-Path -LiteralPath $TempArtifact -PathType Leaf)) {
    Remove-Item -LiteralPath $TempArtifact -Force
}

if ($ExecutionId) {
    foreach ($Path in @(
        ".\workspace\bridge\executions\$ExecutionId.json"
    )) {
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            Remove-Item -LiteralPath $Path -Force
        }
    }

    Get-ChildItem `
        -LiteralPath ".\workspace\bridge\results\normalized" `
        -Filter "NRR-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        ForEach-Object {
            $Record = Get-Content -LiteralPath $_.FullName -Raw |
                ConvertFrom-Json

            if ([string]$Record.execution_id -eq $ExecutionId) {
                Remove-Item -LiteralPath $_.FullName -Force
            }
        }

    Get-ChildItem `
        -LiteralPath ".\workspace\bridge\results\published" `
        -Filter "NRR-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        ForEach-Object {
            $Record = Get-Content -LiteralPath $_.FullName -Raw |
                ConvertFrom-Json

            if ([string]$Record.execution_id -eq $ExecutionId) {
                Remove-Item -LiteralPath $_.FullName -Force
            }
        }

    Get-ChildItem `
        -LiteralPath ".\workspace\bridge\artifacts\manifests" `
        -Filter "AMF-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        ForEach-Object {
            $Manifest = Get-Content -LiteralPath $_.FullName -Raw |
                ConvertFrom-Json

            if ([string]$Manifest.execution_id -eq $ExecutionId) {
                foreach ($Artifact in @($Manifest.artifacts)) {
                    if ($Artifact.stored_path -and
                        (Test-Path -LiteralPath $Artifact.stored_path -PathType Leaf)) {
                        Remove-Item -LiteralPath $Artifact.stored_path -Force
                    }
                }

                Remove-Item -LiteralPath $_.FullName -Force
            }
        }
}

if ($RequestId) {
    $Path = ".\workspace\bridge\requests\$RequestId.json"

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

foreach ($CurrentMessageId in @($MessageId, $PublishedMessageId)) {
    if ([string]::IsNullOrWhiteSpace($CurrentMessageId)) {
        continue
    }

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

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
    Out-Null

& ".\scripts\bridge\Update-AIOfficeBridgeIndex.ps1" |
    Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " result-processing error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.3 Part C Result Processing checks passed." `
    -ForegroundColor Green
