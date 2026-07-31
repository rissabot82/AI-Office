# ============================================================
# AI Office v1.1.3 - Part C
# OpenClaw Result and Artifact Processing
# Repository: E:\AI\AI-Office
# Requires: v1.1.3 Parts A and B
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

$RequiredPrevious = @(
    ".\config\bridge\bridge-policy.json",
    ".\config\bridge\execution-policy.json",
    ".\scripts\bridge\AIOfficeBridge.Common.ps1",
    ".\scripts\bridge\AIOfficeOpenClaw.Transport.ps1",
    ".\scripts\bridge\Invoke-AIOfficeOpenClawExecution.ps1",
    ".\scripts\messaging\New-AIOfficeMessage.ps1",
    ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1"
)

foreach ($RequiredPath in $RequiredPrevious) {
    if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
        throw "AI Office v1.1.3 Parts A and B are required. Missing: $RequiredPath"
    }
}

function Ensure-Directory {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
    }
}

function Write-NewFile {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][AllowEmptyString()][string]$Content
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        $Parent = Split-Path -Parent $Path

        if ($Parent -and -not (Test-Path -LiteralPath $Parent -PathType Container)) {
            New-Item -ItemType Directory -Path $Parent -Force | Out-Null
        }

        Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
    }
}

@(
    ".\workspace\bridge\artifacts\manifests",
    ".\workspace\bridge\artifacts\files",
    ".\workspace\bridge\artifacts\screenshots",
    ".\workspace\bridge\artifacts\downloads",
    ".\workspace\bridge\artifacts\reports",
    ".\workspace\bridge\results\normalized",
    ".\workspace\bridge\results\published",
    ".\workspace\bridge\failed\results"
) | ForEach-Object { Ensure-Directory $_ }

$Now = (Get-Date).ToString("o")

$ResultPolicy = @"
{
  "schema_version": "1.0.0",
  "version": "1.1.3",
  "part": "C",
  "normalization": {
    "enabled": true,
    "preserve_raw_response": true,
    "extract_text": true,
    "extract_status": true,
    "extract_run_id": true,
    "extract_session_key": true
  },
  "artifact_handling": {
    "enabled": true,
    "allowed_types": [
      "screenshot",
      "download",
      "file",
      "report",
      "log",
      "json"
    ],
    "copy_local_files": true,
    "calculate_sha256": true,
    "maximum_artifact_size_mb": 100,
    "reject_missing_files": false
  },
  "publishing": {
    "publish_result_message": true,
    "result_message_type": "execution_result",
    "failure_message_type": "error",
    "default_recipient": "chief-of-staff",
    "queue": "inbox"
  },
  "retention": {
    "result_days": 90,
    "artifact_days": 90,
    "failed_result_days": 180
  },
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\bridge\result-policy.json" $ResultPolicy

$ArtifactSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/openclaw-artifact-manifest-schema.json",
  "title": "AI Office OpenClaw Artifact Manifest",
  "type": "object",
  "required": [
    "artifact_manifest_id",
    "execution_id",
    "bridge_request_id",
    "created_at",
    "artifact_count",
    "artifacts"
  ],
  "properties": {
    "artifact_manifest_id": {
      "type": "string"
    },
    "execution_id": {
      "type": "string"
    },
    "bridge_request_id": {
      "type": "string"
    },
    "created_at": {
      "type": "string"
    },
    "artifact_count": {
      "type": "integer"
    },
    "artifacts": {
      "type": "array"
    }
  }
}
'@

Write-NewFile ".\config\bridge\artifact-manifest-schema.json" $ArtifactSchema

$NormalizedSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/openclaw-normalized-result-schema.json",
  "title": "AI Office OpenClaw Normalized Result",
  "type": "object",
  "required": [
    "normalized_result_id",
    "execution_id",
    "bridge_request_id",
    "message_id",
    "status",
    "created_at",
    "summary",
    "data",
    "artifacts"
  ],
  "properties": {
    "normalized_result_id": {
      "type": "string"
    },
    "execution_id": {
      "type": "string"
    },
    "bridge_request_id": {
      "type": "string"
    },
    "message_id": {
      "type": "string"
    },
    "status": {
      "type": "string"
    },
    "created_at": {
      "type": "string"
    },
    "summary": {
      "type": "string"
    },
    "data": {
      "type": "object"
    },
    "artifacts": {
      "type": "array"
    }
  }
}
'@

Write-NewFile ".\config\bridge\normalized-result-schema.json" $NormalizedSchema

$ArtifactTemplate = @'
{
  "artifact_manifest_id": "AMF-YYYYMMDD-HHMMSS-ABC123",
  "execution_id": "EXE-YYYYMMDD-HHMMSS-ABC123",
  "bridge_request_id": "BRQ-YYYYMMDD-HHMMSS-ABC123",
  "created_at": "",
  "artifact_count": 0,
  "artifacts": []
}
'@

Write-NewFile ".\workspace\templates\openclaw-artifact-manifest-template.json" $ArtifactTemplate

$NormalizedTemplate = @'
{
  "normalized_result_id": "NRR-YYYYMMDD-HHMMSS-ABC123",
  "execution_id": "EXE-YYYYMMDD-HHMMSS-ABC123",
  "bridge_request_id": "BRQ-YYYYMMDD-HHMMSS-ABC123",
  "message_id": "MSG-YYYYMMDD-HHMMSS-ABC123",
  "status": "completed",
  "created_at": "",
  "summary": "",
  "data": {},
  "artifacts": []
}
'@

Write-NewFile ".\workspace\templates\openclaw-normalized-result-template.json" $NormalizedTemplate

$Common = @'
. (Join-Path $PSScriptRoot "AIOfficeBridge.Common.ps1")

function Get-AIOfficeBridgeResultPolicy {
    $Root = Get-AIOfficeBridgeRoot

    return Read-AIOfficeBridgeJson `
        -Path (Join-Path $Root "config\bridge\result-policy.json")
}

function New-AIOfficeNormalizedResultId {
    return (
        "NRR-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeArtifactManifestId {
    return (
        "AMF-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeFileSha256 {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return ""
    }

    return [string](
        Get-FileHash -LiteralPath $Path -Algorithm SHA256
    ).Hash
}

function Get-AIOfficeArtifactType {
    param([Parameter(Mandatory=$true)][string]$Path)

    $Extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()

    switch ($Extension) {
        ".png" { return "screenshot" }
        ".jpg" { return "screenshot" }
        ".jpeg" { return "screenshot" }
        ".webp" { return "screenshot" }
        ".pdf" { return "report" }
        ".json" { return "json" }
        ".log" { return "log" }
        ".txt" { return "log" }
        default { return "file" }
    }
}

function Get-AIOfficeArtifactDestinationFolder {
    param([Parameter(Mandatory=$true)][string]$ArtifactType)

    $Root = Get-AIOfficeBridgeRoot

    switch ($ArtifactType) {
        "screenshot" {
            return Join-Path $Root "workspace\bridge\artifacts\screenshots"
        }
        "download" {
            return Join-Path $Root "workspace\bridge\artifacts\downloads"
        }
        "report" {
            return Join-Path $Root "workspace\bridge\artifacts\reports"
        }
        default {
            return Join-Path $Root "workspace\bridge\artifacts\files"
        }
    }
}

function ConvertTo-AIOfficeArtifactArray {
    param([AllowNull()]$Value)

    if ($null -eq $Value) {
        return @()
    }

    return @($Value | ForEach-Object { $_ })
}

function Find-AIOfficeArtifactCandidates {
    param([AllowNull()]$Value)

    $Results = New-Object System.Collections.Generic.List[object]

    function Visit-AIOValue {
        param(
            [AllowNull()]$Current,
            [string]$PropertyName = ""
        )

        if ($null -eq $Current) {
            return
        }

        if ($Current -is [string]) {
            $Text = [string]$Current

            if (Test-Path -LiteralPath $Text -PathType Leaf) {
                $Results.Add([pscustomobject]@{
                    path = (Resolve-Path -LiteralPath $Text).Path
                    source_property = $PropertyName
                })
            }

            return
        }

        if ($Current -is [System.Collections.IDictionary]) {
            foreach ($Key in $Current.Keys) {
                Visit-AIOValue `
                    -Current $Current[$Key] `
                    -PropertyName ([string]$Key)
            }

            return
        }

        if ($Current -is [System.Collections.IEnumerable] -and
            -not ($Current -is [string])) {
            foreach ($Item in $Current) {
                Visit-AIOValue `
                    -Current $Item `
                    -PropertyName $PropertyName
            }

            return
        }

        foreach ($Property in $Current.PSObject.Properties) {
            Visit-AIOValue `
                -Current $Property.Value `
                -PropertyName ([string]$Property.Name)
        }
    }

    Visit-AIOValue -Current $Value

    return @(
        $Results |
            Sort-Object path -Unique
    )
}

function Get-AIOfficeResultSummary {
    param(
        [Parameter(Mandatory=$true)]$Execution
    )

    if ([string]$Execution.status -eq "failed") {
        if ($null -ne $Execution.error -and
            -not [string]::IsNullOrWhiteSpace([string]$Execution.error.message)) {
            return [string]$Execution.error.message
        }

        return "OpenClaw execution failed."
    }

    $Payload = $Execution.response_payload

    if ($null -eq $Payload) {
        return "OpenClaw execution completed without a response payload."
    }

    foreach ($PropertyName in @(
        "summary",
        "text",
        "message",
        "result",
        "output",
        "content"
    )) {
        $Property = $Payload.PSObject.Properties[$PropertyName]

        if ($null -ne $Property -and
            $Property.Value -is [string] -and
            -not [string]::IsNullOrWhiteSpace([string]$Property.Value)) {
            return [string]$Property.Value
        }
    }

    return "OpenClaw execution completed successfully."
}
'@

Write-NewFile ".\scripts\bridge\AIOfficeBridgeResults.Common.ps1" $Common

$ManifestScript = @'
param(
    [Parameter(Mandatory=$true)][string]$ExecutionId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeBridgeResults.Common.ps1")

$Root = Get-AIOfficeBridgeRoot
Set-Location $Root

$ExecutionPath = Join-Path `
    ".\workspace\bridge\executions" `
    ($ExecutionId + ".json")

$Execution = Read-AIOfficeBridgeJson -Path $ExecutionPath

if ($null -eq $Execution) {
    throw "Execution record not found: $ExecutionId"
}

$Policy = Get-AIOfficeBridgeResultPolicy

if ($null -eq $Policy) {
    throw "Bridge result policy could not be loaded."
}

$Candidates = @(
    Find-AIOfficeArtifactCandidates `
        -Value $Execution.response_payload
)

$Artifacts = New-Object System.Collections.Generic.List[object]

foreach ($Candidate in $Candidates) {
    $SourcePath = [string]$Candidate.path
    $Type = Get-AIOfficeArtifactType -Path $SourcePath
    $DestinationFolder = Get-AIOfficeArtifactDestinationFolder `
        -ArtifactType $Type

    $FileInfo = Get-Item -LiteralPath $SourcePath
    $MaxBytes = [int64]$Policy.artifact_handling.maximum_artifact_size_mb * 1MB

    if ($FileInfo.Length -gt $MaxBytes) {
        continue
    }

    $DestinationPath = $SourcePath

    if ([bool]$Policy.artifact_handling.copy_local_files) {
        $DestinationName = (
            $ExecutionId +
            "-" +
            [guid]::NewGuid().ToString("N").Substring(0,8) +
            "-" +
            $FileInfo.Name
        )

        $DestinationPath = Join-Path $DestinationFolder $DestinationName

        Copy-Item `
            -LiteralPath $SourcePath `
            -Destination $DestinationPath `
            -Force
    }

    $Hash = ""

    if ([bool]$Policy.artifact_handling.calculate_sha256) {
        $Hash = Get-AIOfficeFileSha256 -Path $DestinationPath
    }

    $Artifacts.Add([ordered]@{
        artifact_id = (
            "ART-" +
            ([guid]::NewGuid().ToString("N").Substring(0,12)).ToUpperInvariant()
        )
        type = $Type
        source_path = $SourcePath
        stored_path = $DestinationPath
        file_name = [System.IO.Path]::GetFileName($DestinationPath)
        extension = [System.IO.Path]::GetExtension($DestinationPath)
        size_bytes = (Get-Item -LiteralPath $DestinationPath).Length
        sha256 = $Hash
        source_property = [string]$Candidate.source_property
        created_at = (Get-Date).ToString("o")
    })
}

$ManifestId = New-AIOfficeArtifactManifestId

$Manifest = [ordered]@{
    artifact_manifest_id = $ManifestId
    execution_id = $ExecutionId
    bridge_request_id = [string]$Execution.bridge_request_id
    created_at = (Get-Date).ToString("o")
    artifact_count = $Artifacts.Count
    artifacts = @($Artifacts | ForEach-Object { $_ })
}

$ManifestPath = Join-Path `
    ".\workspace\bridge\artifacts\manifests" `
    ($ManifestId + ".json")

Write-AIOfficeBridgeJson -Value $Manifest -Path $ManifestPath

Write-Host (
    "Artifact manifest created: " +
    $ManifestId +
    " | " +
    $Artifacts.Count.ToString() +
    " artifact(s)"
) -ForegroundColor Green

return [pscustomobject]$Manifest
'@

Write-NewFile ".\scripts\bridge\New-AIOfficeArtifactManifest.ps1" $ManifestScript

$NormalizeScript = @'
param(
    [Parameter(Mandatory=$true)][string]$ExecutionId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeBridgeResults.Common.ps1")

$Root = Get-AIOfficeBridgeRoot
Set-Location $Root

$ExecutionPath = Join-Path `
    ".\workspace\bridge\executions" `
    ($ExecutionId + ".json")

$Execution = Read-AIOfficeBridgeJson -Path $ExecutionPath

if ($null -eq $Execution) {
    throw "Execution record not found: $ExecutionId"
}

$Manifest = & ".\scripts\bridge\New-AIOfficeArtifactManifest.ps1" `
    -ExecutionId $ExecutionId

$Summary = Get-AIOfficeResultSummary -Execution $Execution
$NormalizedId = New-AIOfficeNormalizedResultId

$Normalized = [ordered]@{
    normalized_result_id = $NormalizedId
    execution_id = $ExecutionId
    bridge_request_id = [string]$Execution.bridge_request_id
    message_id = [string]$Execution.message_id
    status = [string]$Execution.status
    created_at = (Get-Date).ToString("o")
    summary = $Summary
    data = [ordered]@{
        run_id = [string]$Execution.run_id
        session_key = [string]$Execution.session_key
        gateway_url = [string]$Execution.gateway_url
        started_at = $Execution.started_at
        completed_at = $Execution.completed_at
        response_payload = $Execution.response_payload
        error = $Execution.error
    }
    artifacts = @($Manifest.artifacts)
}

$Path = Join-Path `
    ".\workspace\bridge\results\normalized" `
    ($NormalizedId + ".json")

Write-AIOfficeBridgeJson -Value $Normalized -Path $Path

Write-Host "Normalized result created: $NormalizedId" `
    -ForegroundColor Green

return [pscustomobject]$Normalized
'@

Write-NewFile ".\scripts\bridge\ConvertTo-AIOfficeNormalizedResult.ps1" $NormalizeScript

$PublishScript = @'
param(
    [Parameter(Mandatory=$true)][string]$ExecutionId,
    [string]$Recipient = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeBridgeResults.Common.ps1")

$Root = Get-AIOfficeBridgeRoot
Set-Location $Root

$Policy = Get-AIOfficeBridgeResultPolicy

if ($null -eq $Policy) {
    throw "Bridge result policy could not be loaded."
}

if ([string]::IsNullOrWhiteSpace($Recipient)) {
    $Recipient = [string]$Policy.publishing.default_recipient
}

$Normalized = & ".\scripts\bridge\ConvertTo-AIOfficeNormalizedResult.ps1" `
    -ExecutionId $ExecutionId

$RequestPath = Join-Path `
    ".\workspace\bridge\requests" `
    ([string]$Normalized.bridge_request_id + ".json")

$Request = Read-AIOfficeBridgeJson -Path $RequestPath

$From = "bridge"
$CorrelationId = ""
$ConversationId = ""
$WorkflowId = ""

if ($null -ne $Request) {
    $CorrelationId = [string]$Request.correlation_id
    $ConversationId = [string]$Request.conversation_id
    $WorkflowId = [string]$Request.workflow_id
}

$MessageType = [string]$Policy.publishing.result_message_type
$Priority = "normal"
$Subject = "OpenClaw execution completed"

if ([string]$Normalized.status -eq "failed") {
    $MessageType = [string]$Policy.publishing.failure_message_type
    $Priority = "high"
    $Subject = "OpenClaw execution failed"
}

$Payload = [ordered]@{
    execution_id = [string]$Normalized.execution_id
    bridge_request_id = [string]$Normalized.bridge_request_id
    normalized_result_id = [string]$Normalized.normalized_result_id
    status = [string]$Normalized.status
    summary = [string]$Normalized.summary
    artifacts = @($Normalized.artifacts)
}

$PayloadJson = $Payload |
    ConvertTo-Json -Depth 40 -Compress

$Arguments = @{
    From = $From
    To = $Recipient
    MessageType = $MessageType
    Subject = $Subject
    Priority = $Priority
    WorkflowId = $WorkflowId
    Queue = [string]$Policy.publishing.queue
    PayloadJson = $PayloadJson
}

if (-not [string]::IsNullOrWhiteSpace($CorrelationId)) {
    $Arguments.CorrelationId = $CorrelationId
}

if (-not [string]::IsNullOrWhiteSpace($ConversationId)) {
    $Arguments.ConversationId = $ConversationId
}

$Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" @Arguments

$PublishedRecord = [ordered]@{
    published_at = (Get-Date).ToString("o")
    execution_id = [string]$Normalized.execution_id
    normalized_result_id = [string]$Normalized.normalized_result_id
    message_id = [string]$Message.message_id
    recipient = $Recipient
    message_type = $MessageType
    status = "published"
}

$PublishedPath = Join-Path `
    ".\workspace\bridge\results\published" `
    ([string]$Normalized.normalized_result_id + ".json")

Write-AIOfficeBridgeJson `
    -Value $PublishedRecord `
    -Path $PublishedPath

Write-Host (
    "Execution result published: " +
    [string]$Message.message_id
) -ForegroundColor Green

return [pscustomobject]$PublishedRecord
'@

Write-NewFile ".\scripts\bridge\Publish-AIOfficeOpenClawResult.ps1" $PublishScript

$ProcessScript = @'
param(
    [Parameter(Mandatory=$true)][string]$ExecutionId,
    [string]$Recipient = "chief-of-staff"
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

try {
    $Published = & ".\scripts\bridge\Publish-AIOfficeOpenClawResult.ps1" `
        -ExecutionId $ExecutionId `
        -Recipient $Recipient

    & ".\scripts\bridge\Update-AIOfficeBridgeIndex.ps1" |
        Out-Null

    return $Published
}
catch {
    $Failure = [ordered]@{
        recorded_at = (Get-Date).ToString("o")
        execution_id = $ExecutionId
        error = $_.Exception.Message
        type = $_.Exception.GetType().FullName
    }

    $FailurePath = Join-Path `
        ".\workspace\bridge\failed\results" `
        ($ExecutionId + "-" + (Get-Date).ToString("yyyyMMdd-HHmmss") + ".json")

    $Failure |
        ConvertTo-Json -Depth 30 |
        Set-Content -LiteralPath $FailurePath -Encoding UTF8

    throw
}
'@

Write-NewFile ".\scripts\bridge\Process-AIOfficeOpenClawResult.ps1" $ProcessScript

$ListArtifacts = @'
param(
    [string]$ExecutionId = "",
    [string]$ArtifactType = "",
    [int]$Limit = 100
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeBridgeResults.Common.ps1")

$Root = Get-AIOfficeBridgeRoot
Set-Location $Root

$Results = New-Object System.Collections.Generic.List[object]

foreach ($File in @(
    Get-ChildItem `
        -LiteralPath ".\workspace\bridge\artifacts\manifests" `
        -Filter "AMF-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)) {
    $Manifest = Read-AIOfficeBridgeJson -Path $File.FullName

    if ($null -eq $Manifest) {
        continue
    }

    if ($ExecutionId -and
        [string]$Manifest.execution_id -ne $ExecutionId) {
        continue
    }

    foreach ($Artifact in @($Manifest.artifacts)) {
        if ($ArtifactType -and
            [string]$Artifact.type -ne $ArtifactType) {
            continue
        }

        $Results.Add([pscustomobject]@{
            manifest_id = [string]$Manifest.artifact_manifest_id
            execution_id = [string]$Manifest.execution_id
            artifact_id = [string]$Artifact.artifact_id
            type = [string]$Artifact.type
            file_name = [string]$Artifact.file_name
            stored_path = [string]$Artifact.stored_path
            size_bytes = [int64]$Artifact.size_bytes
            sha256 = [string]$Artifact.sha256
            created_at = [string]$Artifact.created_at
        })
    }
}

return @(
    $Results |
        Sort-Object created_at -Descending |
        Select-Object -First $Limit
)
'@

Write-NewFile ".\scripts\bridge\Search-AIOfficeBridgeArtifacts.ps1" $ListArtifacts

$Test = @'
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
'@

Write-NewFile ".\scripts\bridge\Test-AIOfficeResultProcessing.ps1" $Test

$Guide = @'
# AI Office v1.1.3 Part C — Result and Artifact Processing

Part C converts raw OpenClaw execution records into structured AI Office results, captures local artifacts, and publishes result messages back to the Message Bus.

## Added

- Result normalization
- Raw response preservation
- Result summaries
- Artifact discovery
- Artifact copying
- Artifact type classification
- SHA-256 hashing
- Artifact manifests
- Normalized result records
- Result-message publishing
- Failure-result recording
- Artifact search
- Full validation

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\bridge\Test-AIOfficeResultProcessing.ps1"
```

Expected result:

```text
All AI Office v1.1.3 Part C Result Processing checks passed.
```

## Process a completed execution

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\bridge\Process-AIOfficeOpenClawResult.ps1" `
    -ExecutionId "EXE-..."
```

## Search captured artifacts

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\bridge\Search-AIOfficeBridgeArtifacts.ps1" `
    -ExecutionId "EXE-..."
```

## Next

Part D will run the complete live bridge certification, including authenticated Gateway connectivity, a real OpenClaw agent task, result publication, and release finalization.
'@

Write-NewFile ".\docs\AI-Office-v1.1.3-Part-C-Result-Artifact-Processing.md" $Guide

$ReleaseNotes = @'
# AI Office v1.1.3 Part C Release Notes

## Release

OpenClaw Result and Artifact Processing

## Added

- Raw-response normalization
- Structured execution summaries
- Artifact candidate discovery
- Local artifact copying
- Artifact classification
- SHA-256 integrity hashes
- Artifact manifests
- Normalized result records
- Message Bus result publishing
- Failure-result capture
- Artifact search
- Validation suite

## Next

v1.1.3 Part D — Live Bridge Certification and Release
'@

Write-NewFile ".\docs\AI-Office-v1.1.3-Part-C-Release-Notes.md" $ReleaseNotes

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw |
        ConvertFrom-Json

    $Version.version = "1.1.3"
    $Version.release_name = "OpenClaw Bridge"
    $Version.status = "part_c_installed"
    $Version.installed_at = (Get-Date).ToString("o")
    $Version.next_planned_milestone = "1.1.3 Part D Live Certification"

    $Version |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $VersionPath -Encoding UTF8

    Write-Host "[UPDATED] Identity release metadata set to Part C" `
        -ForegroundColor Green
}

Write-Host ""
Write-Host "Validating Part C JSON files..." -ForegroundColor Cyan

@(
    ".\config\bridge\result-policy.json",
    ".\config\bridge\artifact-manifest-schema.json",
    ".\config\bridge\normalized-result-schema.json",
    ".\workspace\templates\openclaw-artifact-manifest-template.json",
    ".\workspace\templates\openclaw-normalized-result-template.json"
) | ForEach-Object {
    Get-Content -LiteralPath $_ -Raw |
        ConvertFrom-Json |
        Out-Null

    Write-Host "[VALID JSON] $_" -ForegroundColor Green
}

try {
    $Source = $MyInvocation.MyCommand.Path
    $Destination = Join-Path `
        $Repository `
        "Installers\AI-Office-v1.1.3-Part-C-Result-Artifact-Processing-Install.ps1"

    if ($Source -and
        (Test-Path -LiteralPath $Source -PathType Leaf) -and
        [System.IO.Path]::GetFullPath($Source) -ne
        [System.IO.Path]::GetFullPath($Destination)) {
        Copy-Item `
            -LiteralPath $Source `
            -Destination $Destination `
            -Force

        Write-Host "[COPIED ] Installer saved to $Destination" `
            -ForegroundColor Green
    }
}
catch {
    Write-Host (
        "[WARNING] Installer copy was not completed: " +
        $_.Exception.Message
    ) -ForegroundColor Yellow
}

Write-Host ""
Write-Host "AI Office v1.1.3 Part C installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\bridge\Test-AIOfficeResultProcessing.ps1"'
Write-Host ""
