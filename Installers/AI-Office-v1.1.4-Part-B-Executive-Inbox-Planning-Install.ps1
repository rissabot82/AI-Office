# ============================================================
# AI Office v1.1.4 - Part B
# Executive Inbox and Planning
# Repository: E:\AI\AI-Office
# Requires: v1.1.4 Part A
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

$RequiredPrevious = @(
    ".\config\chief-of-staff\chief-of-staff-identity.json",
    ".\config\chief-of-staff\chief-of-staff-policy.json",
    ".\scripts\chief-of-staff\AIOfficeChiefOfStaff.Common.ps1",
    ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffPlan.ps1",
    ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1",
    ".\scripts\messaging\Receive-AIOfficeMessage.ps1",
    ".\scripts\messaging\Get-AIOfficeMessage.ps1",
    ".\scripts\messaging\Complete-AIOfficeMessage.ps1",
    ".\scripts\messaging\Fail-AIOfficeMessage.ps1"
)

foreach ($RequiredPath in $RequiredPrevious) {
    if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
        throw "AI Office v1.1.4 Part A is required. Missing: $RequiredPath"
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
    ".\workspace\chief-of-staff\classifications",
    ".\workspace\chief-of-staff\priorities",
    ".\workspace\chief-of-staff\processed-inbox",
    ".\workspace\chief-of-staff\failed-inbox"
) | ForEach-Object { Ensure-Directory $_ }

$Now = (Get-Date).ToString("o")

$InboxPolicy = @"
{
  "schema_version": "1.0.0",
  "version": "1.1.4",
  "part": "B",
  "recipient": "chief-of-staff",
  "accepted_message_types": [
    "request",
    "approval_request",
    "execution_result",
    "status",
    "error",
    "event",
    "handoff",
    "information"
  ],
  "classification_rules": [
    {
      "classification": "approval",
      "message_types": ["approval_request"],
      "default_priority": "high",
      "default_risk": "high"
    },
    {
      "classification": "execution_result",
      "message_types": ["execution_result"],
      "default_priority": "normal",
      "default_risk": "low"
    },
    {
      "classification": "incident",
      "message_types": ["error"],
      "default_priority": "urgent",
      "default_risk": "high"
    },
    {
      "classification": "status",
      "message_types": ["status","event","information"],
      "default_priority": "normal",
      "default_risk": "low"
    },
    {
      "classification": "work_request",
      "message_types": ["request","handoff"],
      "default_priority": "normal",
      "default_risk": "medium"
    }
  ],
  "planning": {
    "auto_create_plan_for": [
      "work_request",
      "approval",
      "incident"
    ],
    "default_success_criteria": [
      "Request is reviewed",
      "Appropriate owner is assigned",
      "Required approval is recorded",
      "Completion is reported"
    ]
  },
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\chief-of-staff\inbox-policy.json" $InboxPolicy

$ClassificationSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/chief-of-staff-classification-schema.json",
  "title": "AI Office Chief of Staff Classification",
  "type": "object",
  "required": [
    "classification_id",
    "message_id",
    "classification",
    "priority",
    "risk_level",
    "approval_required",
    "created_at"
  ],
  "properties": {
    "classification_id": {
      "type": "string"
    },
    "message_id": {
      "type": "string"
    },
    "classification": {
      "type": "string"
    },
    "priority": {
      "type": "string"
    },
    "risk_level": {
      "type": "string"
    },
    "approval_required": {
      "type": "boolean"
    },
    "created_at": {
      "type": "string"
    }
  }
}
'@

Write-NewFile ".\config\chief-of-staff\classification-schema.json" $ClassificationSchema

$ClassificationTemplate = @'
{
  "classification_id": "CLS-YYYYMMDD-HHMMSS-ABC123",
  "message_id": "MSG-YYYYMMDD-HHMMSS-ABC123",
  "classification": "work_request",
  "priority": "normal",
  "risk_level": "medium",
  "approval_required": false,
  "created_at": ""
}
'@

Write-NewFile ".\workspace\templates\chief-of-staff-classification-template.json" $ClassificationTemplate

$CommonExtension = @'
. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaff.Common.ps1")

function Get-AIOfficeChiefOfStaffInboxPolicy {
    $Root = Get-AIOfficeChiefOfStaffRoot

    return Read-AIOfficeChiefOfStaffJson `
        -Path (Join-Path $Root "config\chief-of-staff\inbox-policy.json")
}

function New-AIOfficeChiefOfStaffClassificationId {
    return (
        "CLS-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeChiefOfStaffClassificationRule {
    param(
        [Parameter(Mandatory=$true)][string]$MessageType
    )

    $Policy = Get-AIOfficeChiefOfStaffInboxPolicy

    if ($null -eq $Policy) {
        throw "Chief of Staff inbox policy could not be loaded."
    }

    $Rule = @(
        $Policy.classification_rules |
            Where-Object {
                @($_.message_types) -contains $MessageType
            }
    ) | Select-Object -First 1

    return $Rule
}
'@

Write-NewFile ".\scripts\chief-of-staff\AIOfficeChiefOfStaffInbox.Common.ps1" $CommonExtension

$ClassifyScript = @'
param(
    [Parameter(Mandatory=$true)][string]$MessageId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffInbox.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Message = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
    -MessageId $MessageId

$Rule = Get-AIOfficeChiefOfStaffClassificationRule `
    -MessageType ([string]$Message.message_type)

if ($null -eq $Rule) {
    $Rule = [pscustomobject]@{
        classification = "general"
        default_priority = "normal"
        default_risk = "medium"
    }
}

$Priority = [string]$Rule.default_priority
$Risk = [string]$Rule.default_risk

if (-not [string]::IsNullOrWhiteSpace([string]$Message.priority)) {
    $Priority = [string]$Message.priority
}

$ApprovalRequired = Test-AIOfficeChiefOfStaffApprovalRequired `
    -RiskLevel $Risk

$ClassificationId = New-AIOfficeChiefOfStaffClassificationId

$Record = [ordered]@{
    classification_id = $ClassificationId
    message_id = $MessageId
    classification = [string]$Rule.classification
    priority = $Priority
    risk_level = $Risk
    approval_required = $ApprovalRequired
    created_at = (Get-Date).ToString("o")
}

$Path = Join-Path `
    ".\workspace\chief-of-staff\classifications" `
    ($ClassificationId + ".json")

Write-AIOfficeChiefOfStaffJson `
    -Value $Record `
    -Path $Path

Write-Host (
    "Message classified: " +
    $MessageId +
    " -> " +
    [string]$Record.classification
) -ForegroundColor Green

return [pscustomobject]$Record
'@

Write-NewFile ".\scripts\chief-of-staff\Classify-AIOfficeChiefOfStaffMessage.ps1" $ClassifyScript

$PlanFromMessage = @'
param(
    [Parameter(Mandatory=$true)][string]$MessageId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffInbox.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Message = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
    -MessageId $MessageId

$Classification = & `
    ".\scripts\chief-of-staff\Classify-AIOfficeChiefOfStaffMessage.ps1" `
    -MessageId $MessageId

$Policy = Get-AIOfficeChiefOfStaffInboxPolicy

$Title = [string]$Message.subject

if ([string]::IsNullOrWhiteSpace($Title)) {
    $Title = (
        [string]$Classification.classification +
        " from " +
        [string]$Message.from
    )
}

$Objective = ""

foreach ($PropertyName in @(
    "objective",
    "request",
    "instruction",
    "summary",
    "message"
)) {
    if ($null -ne $Message.payload.PSObject.Properties[$PropertyName] -and
        -not [string]::IsNullOrWhiteSpace(
            [string]$Message.payload.$PropertyName
        )) {
        $Objective = [string]$Message.payload.$PropertyName
        break
    }
}

if ([string]::IsNullOrWhiteSpace($Objective)) {
    $Objective = (
        "Review and resolve Chief of Staff message " +
        $MessageId +
        "."
    )
}

$SuccessCriteria = @($Policy.planning.default_success_criteria)

if ($null -ne $Message.payload.PSObject.Properties["success_criteria"]) {
    $Provided = @($Message.payload.success_criteria)

    if ($Provided.Count -gt 0) {
        $SuccessCriteria = $Provided
    }
}

$ApprovalStatus = if ([bool]$Classification.approval_required) {
    "pending"
}
else {
    "not_required"
}

$Plan = & ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffPlan.ps1" `
    -Title $Title `
    -Objective $Objective `
    -SuccessCriteriaJson (
        $SuccessCriteria | ConvertTo-Json -Depth 10 -Compress
    ) `
    -Priority ([string]$Classification.priority) `
    -RiskLevel ([string]$Classification.risk_level) `
    -ApprovalStatus $ApprovalStatus `
    -WorkflowId ([string]$Message.workflow_id) `
    -ConversationId ([string]$Message.conversation_id) `
    -CorrelationId ([string]$Message.correlation_id)

$PlanPath = Join-Path `
    ".\workspace\chief-of-staff\plans" `
    ([string]$Plan.plan_id + ".json")

$StoredPlan = Read-AIOfficeChiefOfStaffJson -Path $PlanPath

$StoredPlan.steps = @(
    [ordered]@{
        step_number = 1
        title = "Review request"
        owner = "chief-of-staff"
        department = "executive"
        status = "pending"
    },
    [ordered]@{
        step_number = 2
        title = "Assign responsible department"
        owner = "chief-of-staff"
        department = "executive"
        status = "pending"
    },
    [ordered]@{
        step_number = 3
        title = "Execute or delegate work"
        owner = "unassigned"
        department = "unassigned"
        status = "pending"
    },
    [ordered]@{
        step_number = 4
        title = "Report outcome"
        owner = "chief-of-staff"
        department = "executive"
        status = "pending"
    }
)

$StoredPlan.updated_at = (Get-Date).ToString("o")

Write-AIOfficeChiefOfStaffJson `
    -Value $StoredPlan `
    -Path $PlanPath

Write-Host (
    "Chief of Staff plan generated from message: " +
    [string]$Plan.plan_id
) -ForegroundColor Green

return $StoredPlan
'@

Write-NewFile ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffPlanFromMessage.ps1" $PlanFromMessage

$ProcessInbox = @'
param(
    [int]$Limit = 10,
    [switch]$CreatePlans
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffInbox.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Results = New-Object System.Collections.Generic.List[object]

for ($Index = 0; $Index -lt $Limit; $Index++) {
    $Message = & ".\scripts\messaging\Receive-AIOfficeMessage.ps1" `
        -Queue "inbox" `
        -Recipient "chief-of-staff"

    if ($null -eq $Message) {
        break
    }

    try {
        $Classification = & `
            ".\scripts\chief-of-staff\Classify-AIOfficeChiefOfStaffMessage.ps1" `
            -MessageId ([string]$Message.message_id)

        $PlanId = ""

        if ($CreatePlans) {
            $InboxPolicy = Get-AIOfficeChiefOfStaffInboxPolicy

            if (@($InboxPolicy.planning.auto_create_plan_for) -contains
                [string]$Classification.classification) {
                $Plan = & `
                    ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffPlanFromMessage.ps1" `
                    -MessageId ([string]$Message.message_id)

                $PlanId = [string]$Plan.plan_id
            }
        }

        $Record = [ordered]@{
            processed_at = (Get-Date).ToString("o")
            message_id = [string]$Message.message_id
            classification_id = [string]$Classification.classification_id
            classification = [string]$Classification.classification
            priority = [string]$Classification.priority
            risk_level = [string]$Classification.risk_level
            plan_id = $PlanId
            status = "processed"
        }

        $Path = Join-Path `
            ".\workspace\chief-of-staff\processed-inbox" `
            ([string]$Message.message_id + ".json")

        Write-AIOfficeChiefOfStaffJson -Value $Record -Path $Path

        & ".\scripts\messaging\Complete-AIOfficeMessage.ps1" `
            -MessageId ([string]$Message.message_id) `
            -Actor "chief-of-staff" `
            -Details "Chief of Staff inbox message processed." |
            Out-Null

        $Results.Add([pscustomobject]$Record)
    }
    catch {
        $Failure = [ordered]@{
            failed_at = (Get-Date).ToString("o")
            message_id = [string]$Message.message_id
            error = $_.Exception.Message
        }

        $FailurePath = Join-Path `
            ".\workspace\chief-of-staff\failed-inbox" `
            ([string]$Message.message_id + ".json")

        Write-AIOfficeChiefOfStaffJson `
            -Value $Failure `
            -Path $FailurePath

        try {
            & ".\scripts\messaging\Fail-AIOfficeMessage.ps1" `
                -MessageId ([string]$Message.message_id) `
                -Reason $_.Exception.Message `
                -Actor "chief-of-staff" |
                Out-Null
        }
        catch {
        }

        $Results.Add([pscustomobject]@{
            processed_at = (Get-Date).ToString("o")
            message_id = [string]$Message.message_id
            classification_id = ""
            classification = ""
            priority = ""
            risk_level = ""
            plan_id = ""
            status = "failed"
        })
    }
}

& ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1" |
    Out-Null

return @($Results | ForEach-Object { $_ })
'@

Write-NewFile ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffInbox.ps1" $ProcessInbox

$SearchPlans = @'
param(
    [string]$Status = "",
    [string]$Priority = "",
    [string]$RiskLevel = "",
    [string]$ApprovalStatus = "",
    [int]$Limit = 100
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaff.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Results = New-Object System.Collections.Generic.List[object]

foreach ($File in @(
    Get-ChildItem `
        -LiteralPath ".\workspace\chief-of-staff\plans" `
        -Filter "PLAN-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)) {
    $Plan = Read-AIOfficeChiefOfStaffJson -Path $File.FullName

    if ($null -eq $Plan) {
        continue
    }

    if ($Status -and [string]$Plan.status -ne $Status) {
        continue
    }

    if ($Priority -and [string]$Plan.priority -ne $Priority) {
        continue
    }

    if ($RiskLevel -and [string]$Plan.risk_level -ne $RiskLevel) {
        continue
    }

    if ($ApprovalStatus -and
        [string]$Plan.approval_status -ne $ApprovalStatus) {
        continue
    }

    $Results.Add([pscustomobject]@{
        plan_id = [string]$Plan.plan_id
        title = [string]$Plan.title
        priority = [string]$Plan.priority
        risk_level = [string]$Plan.risk_level
        approval_status = [string]$Plan.approval_status
        status = [string]$Plan.status
        owner = [string]$Plan.owner
        workflow_id = [string]$Plan.workflow_id
        created_at = [string]$Plan.created_at
    })
}

return @(
    $Results |
        Sort-Object created_at -Descending |
        Select-Object -First $Limit
)
'@

Write-NewFile ".\scripts\chief-of-staff\Search-AIOfficeChiefOfStaffPlans.ps1" $SearchPlans

$Test = @'
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
'@

Write-NewFile ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaffInbox.ps1" $Test

$Guide = @'
# AI Office v1.1.4 Part B — Executive Inbox and Planning

Part B connects the Chief of Staff to the AI Office Message Bus.

## Added

- Executive inbox policy
- Message classification
- Priority assignment
- Risk assignment
- Approval requirement detection
- Plan generation from messages
- Inbox batch processing
- Processed and failed inbox records
- Plan search
- Full validation

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaffInbox.ps1"
```

Expected result:

```text
All AI Office v1.1.4 Part B Executive Inbox and Planning checks passed.
```

## Process the executive inbox

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffInbox.ps1" `
    -Limit 10 `
    -CreatePlans
```

## Search plans

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\chief-of-staff\Search-AIOfficeChiefOfStaffPlans.ps1"
```

## Next

Part C will add delegation, department routing, approvals, and OpenClaw Bridge dispatch.
'@

Write-NewFile ".\docs\AI-Office-v1.1.4-Part-B-Executive-Inbox-Planning.md" $Guide

$ReleaseNotes = @'
# AI Office v1.1.4 Part B Release Notes

## Release

Executive Inbox and Planning

## Added

- Chief of Staff Message Bus inbox
- Message classification
- Priority and risk assignment
- Approval detection
- Plan generation from messages
- Inbox batch processing
- Plan search
- Validation suite

## Next

v1.1.4 Part C — Delegation and Execution Dispatch
'@

Write-NewFile ".\docs\AI-Office-v1.1.4-Part-B-Release-Notes.md" $ReleaseNotes

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw |
        ConvertFrom-Json

    $Version.version = "1.1.4"
    $Version.release_name = "Chief of Staff Integration"
    $Version.status = "part_b_installed"
    $Version.installed_at = (Get-Date).ToString("o")
    $Version.next_planned_milestone = "1.1.4 Part C Delegation and Execution Dispatch"

    $Version |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $VersionPath -Encoding UTF8

    Write-Host "[UPDATED] Identity release metadata set to v1.1.4 Part B" `
        -ForegroundColor Green
}

Write-Host ""
Write-Host "Validating Part B JSON files..." -ForegroundColor Cyan

@(
    ".\config\chief-of-staff\inbox-policy.json",
    ".\config\chief-of-staff\classification-schema.json",
    ".\workspace\templates\chief-of-staff-classification-template.json"
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
        "Installers\AI-Office-v1.1.4-Part-B-Executive-Inbox-Planning-Install.ps1"

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
Write-Host "AI Office v1.1.4 Part B installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaffInbox.ps1"'
Write-Host ""
