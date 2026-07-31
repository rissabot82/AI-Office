# ============================================================
# AI Office v1.1.4 - Part A
# Chief of Staff Architecture
# Repository: E:\AI\AI-Office
# Requires: AI Office v1.1.3 OpenClaw Bridge
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

$RequiredPrevious = @(
    ".\config\identity\office.json",
    ".\config\messaging\messaging-policy.json",
    ".\config\bridge\bridge-identity.json",
    ".\scripts\messaging\New-AIOfficeMessage.ps1",
    ".\scripts\messaging\Search-AIOfficeMessages.ps1",
    ".\scripts\bridge\New-AIOfficeBridgeRequest.ps1",
    ".\scripts\executive-os\Show-AIOfficeExecutiveStatus.ps1"
)

foreach ($RequiredPath in $RequiredPrevious) {
    if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
        throw "AI Office v1.1.3 is required. Missing: $RequiredPath"
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
    ".\config\chief-of-staff",
    ".\workspace\chief-of-staff",
    ".\workspace\chief-of-staff\inbox",
    ".\workspace\chief-of-staff\plans",
    ".\workspace\chief-of-staff\decisions",
    ".\workspace\chief-of-staff\delegations",
    ".\workspace\chief-of-staff\briefings",
    ".\workspace\chief-of-staff\history",
    ".\workspace\templates",
    ".\scripts\chief-of-staff",
    ".\docs",
    ".\Installers"
) | ForEach-Object { Ensure-Directory $_ }

$Now = (Get-Date).ToString("o")

$Identity = @"
{
  "schema_version": "1.0.0",
  "chief_of_staff_id": "COS-001",
  "name": "AI Office Chief of Staff",
  "version": "1.1.4",
  "part": "A",
  "status": "architecture_installed",
  "office_id": "AIOFFICE-RISSABOT82-001",
  "role": "executive_orchestrator",
  "reports_to": "Clarissa Schmidtberger",
  "execution_engine": "OpenClaw",
  "message_bus": "AI Office Internal Message Bus",
  "mission": "Translate executive intent into governed plans, prioritized work, delegated assignments, approval requests, and auditable execution.",
  "created_at": "$Now",
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\chief-of-staff\chief-of-staff-identity.json" $Identity

$Policy = @"
{
  "schema_version": "1.0.0",
  "version": "1.1.4",
  "part": "A",
  "operating_model": {
    "human_supervised": true,
    "default_owner": "chief-of-staff",
    "default_priority": "normal",
    "default_approval_status": "pending",
    "maximum_open_plans": 100,
    "maximum_active_delegations": 250
  },
  "planning": {
    "require_objective": true,
    "require_success_criteria": true,
    "require_owner": true,
    "require_priority": true,
    "require_risk_level": true,
    "require_approval_for_high_risk": true
  },
  "delegation": {
    "allowed_departments": [
      "executive",
      "marketing",
      "creative",
      "website",
      "analytics",
      "finance",
      "business",
      "side-hustles",
      "youtube",
      "personal-assistant",
      "openclaw-bridge"
    ],
    "allow_cross_department": true,
    "require_message_bus": true
  },
  "risk": {
    "levels": [
      "low",
      "medium",
      "high",
      "critical"
    ],
    "default": "medium",
    "approval_required": [
      "high",
      "critical"
    ]
  },
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\chief-of-staff\chief-of-staff-policy.json" $Policy

$PlanSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/chief-of-staff-plan-schema.json",
  "title": "AI Office Chief of Staff Plan",
  "type": "object",
  "required": [
    "plan_id",
    "title",
    "objective",
    "success_criteria",
    "priority",
    "risk_level",
    "approval_status",
    "status",
    "created_at",
    "updated_at",
    "owner",
    "steps",
    "history"
  ],
  "properties": {
    "plan_id": {
      "type": "string",
      "pattern": "^PLAN-[0-9]{8}-[0-9]{6}-[A-F0-9]{6}$"
    },
    "title": {
      "type": "string"
    },
    "objective": {
      "type": "string"
    },
    "success_criteria": {
      "type": "array"
    },
    "priority": {
      "type": "string"
    },
    "risk_level": {
      "type": "string"
    },
    "approval_status": {
      "type": "string"
    },
    "status": {
      "type": "string"
    },
    "created_at": {
      "type": "string"
    },
    "updated_at": {
      "type": "string"
    },
    "owner": {
      "type": "string"
    },
    "workflow_id": {
      "type": "string"
    },
    "conversation_id": {
      "type": "string"
    },
    "correlation_id": {
      "type": "string"
    },
    "steps": {
      "type": "array"
    },
    "history": {
      "type": "array"
    }
  }
}
'@

Write-NewFile ".\config\chief-of-staff\plan-schema.json" $PlanSchema

$DecisionSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/chief-of-staff-decision-schema.json",
  "title": "AI Office Chief of Staff Decision",
  "type": "object",
  "required": [
    "decision_id",
    "plan_id",
    "decision",
    "reason",
    "risk_level",
    "approval_required",
    "created_at",
    "created_by"
  ],
  "properties": {
    "decision_id": {
      "type": "string"
    },
    "plan_id": {
      "type": "string"
    },
    "decision": {
      "type": "string"
    },
    "reason": {
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
    },
    "created_by": {
      "type": "string"
    }
  }
}
'@

Write-NewFile ".\config\chief-of-staff\decision-schema.json" $DecisionSchema

$Index = @'
{
  "schema_version": "1.0.0",
  "updated_at": "",
  "chief_of_staff_id": "COS-001",
  "status": "empty",
  "inbox_count": 0,
  "open_plan_count": 0,
  "pending_approval_count": 0,
  "active_delegation_count": 0,
  "decision_count": 0,
  "latest_plan_id": "",
  "latest_decision_id": ""
}
'@

Write-NewFile ".\workspace\chief-of-staff\chief-of-staff-index.json" $Index

$PlanTemplate = @'
{
  "plan_id": "PLAN-YYYYMMDD-HHMMSS-ABC123",
  "title": "",
  "objective": "",
  "success_criteria": [],
  "priority": "normal",
  "risk_level": "medium",
  "approval_status": "pending",
  "status": "draft",
  "created_at": "",
  "updated_at": "",
  "owner": "chief-of-staff",
  "workflow_id": "",
  "conversation_id": "",
  "correlation_id": "",
  "steps": [],
  "history": []
}
'@

Write-NewFile ".\workspace\templates\chief-of-staff-plan-template.json" $PlanTemplate

$DecisionTemplate = @'
{
  "decision_id": "DEC-YYYYMMDD-HHMMSS-ABC123",
  "plan_id": "PLAN-YYYYMMDD-HHMMSS-ABC123",
  "decision": "",
  "reason": "",
  "risk_level": "medium",
  "approval_required": false,
  "created_at": "",
  "created_by": "chief-of-staff"
}
'@

Write-NewFile ".\workspace\templates\chief-of-staff-decision-template.json" $DecisionTemplate

$Common = @'
$script:AIOfficeChiefOfStaffRoot = $null

function Get-AIOfficeChiefOfStaffRoot {
    if ($script:AIOfficeChiefOfStaffRoot) {
        return $script:AIOfficeChiefOfStaffRoot
    }

    $script:AIOfficeChiefOfStaffRoot = (
        Resolve-Path (Join-Path $PSScriptRoot "..\..")
    ).Path

    return $script:AIOfficeChiefOfStaffRoot
}

function Read-AIOfficeChiefOfStaffJson {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function Write-AIOfficeChiefOfStaffJson {
    param(
        [Parameter(Mandatory=$true)]$Value,
        [Parameter(Mandatory=$true)][string]$Path
    )

    $Parent = Split-Path -Parent $Path

    if ($Parent -and -not (Test-Path -LiteralPath $Parent -PathType Container)) {
        New-Item -ItemType Directory -Path $Parent -Force | Out-Null
    }

    $Value |
        ConvertTo-Json -Depth 50 |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function New-AIOfficeChiefOfStaffPlanId {
    return (
        "PLAN-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeChiefOfStaffDecisionId {
    return (
        "DEC-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeChiefOfStaffPolicy {
    $Root = Get-AIOfficeChiefOfStaffRoot

    return Read-AIOfficeChiefOfStaffJson `
        -Path (Join-Path $Root "config\chief-of-staff\chief-of-staff-policy.json")
}

function Test-AIOfficeChiefOfStaffApprovalRequired {
    param([Parameter(Mandatory=$true)][string]$RiskLevel)

    $Policy = Get-AIOfficeChiefOfStaffPolicy

    if ($null -eq $Policy) {
        throw "Chief of Staff policy could not be loaded."
    }

    return @($Policy.risk.approval_required) -contains $RiskLevel
}
'@

Write-NewFile ".\scripts\chief-of-staff\AIOfficeChiefOfStaff.Common.ps1" $Common

$NewPlan = @'
param(
    [Parameter(Mandatory=$true)][string]$Title,
    [Parameter(Mandatory=$true)][string]$Objective,
    [Parameter(Mandatory=$true)][string]$SuccessCriteriaJson,
    [ValidateSet("low","normal","high","urgent","critical")]
    [string]$Priority = "normal",
    [ValidateSet("low","medium","high","critical")]
    [string]$RiskLevel = "medium",
    [ValidateSet("pending","approved","rejected","not_required")]
    [string]$ApprovalStatus = "pending",
    [string]$WorkflowId = "",
    [string]$ConversationId = "",
    [string]$CorrelationId = "",
    [string]$Owner = "chief-of-staff"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaff.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

try {
    $SuccessCriteria = @(
        $SuccessCriteriaJson | ConvertFrom-Json
    )
}
catch {
    throw "SuccessCriteriaJson is invalid: $($_.Exception.Message)"
}

if ($SuccessCriteria.Count -lt 1) {
    throw "At least one success criterion is required."
}

$ApprovalRequired = Test-AIOfficeChiefOfStaffApprovalRequired `
    -RiskLevel $RiskLevel

if (-not $ApprovalRequired -and $ApprovalStatus -eq "pending") {
    $ApprovalStatus = "not_required"
}

$Now = (Get-Date).ToString("o")
$PlanId = New-AIOfficeChiefOfStaffPlanId

$Plan = [ordered]@{
    plan_id = $PlanId
    title = $Title
    objective = $Objective
    success_criteria = $SuccessCriteria
    priority = $Priority
    risk_level = $RiskLevel
    approval_status = $ApprovalStatus
    status = "draft"
    created_at = $Now
    updated_at = $Now
    owner = $Owner
    workflow_id = $WorkflowId
    conversation_id = $ConversationId
    correlation_id = $CorrelationId
    steps = @()
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = $Owner
            details = "Chief of Staff plan created."
        }
    )
}

$Path = Join-Path `
    ".\workspace\chief-of-staff\plans" `
    ($PlanId + ".json")

Write-AIOfficeChiefOfStaffJson -Value $Plan -Path $Path

& ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1" |
    Out-Null

Write-Host "Chief of Staff plan created: $PlanId" -ForegroundColor Green
return [pscustomobject]$Plan
'@

Write-NewFile ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffPlan.ps1" $NewPlan

$NewDecision = @'
param(
    [Parameter(Mandatory=$true)][string]$PlanId,
    [Parameter(Mandatory=$true)][string]$Decision,
    [Parameter(Mandatory=$true)][string]$Reason,
    [ValidateSet("low","medium","high","critical")]
    [string]$RiskLevel = "medium",
    [string]$CreatedBy = "chief-of-staff"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaff.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$PlanPath = Join-Path `
    ".\workspace\chief-of-staff\plans" `
    ($PlanId + ".json")

if (-not (Test-Path -LiteralPath $PlanPath -PathType Leaf)) {
    throw "Plan not found: $PlanId"
}

$DecisionId = New-AIOfficeChiefOfStaffDecisionId
$ApprovalRequired = Test-AIOfficeChiefOfStaffApprovalRequired `
    -RiskLevel $RiskLevel

$Record = [ordered]@{
    decision_id = $DecisionId
    plan_id = $PlanId
    decision = $Decision
    reason = $Reason
    risk_level = $RiskLevel
    approval_required = $ApprovalRequired
    created_at = (Get-Date).ToString("o")
    created_by = $CreatedBy
}

$Path = Join-Path `
    ".\workspace\chief-of-staff\decisions" `
    ($DecisionId + ".json")

Write-AIOfficeChiefOfStaffJson -Value $Record -Path $Path

& ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1" |
    Out-Null

Write-Host "Chief of Staff decision recorded: $DecisionId" `
    -ForegroundColor Green

return [pscustomobject]$Record
'@

Write-NewFile ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffDecision.ps1" $NewDecision

$UpdateIndex = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaff.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$PlanFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\chief-of-staff\plans" `
        -Filter "PLAN-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$DecisionFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\chief-of-staff\decisions" `
        -Filter "DEC-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$DelegationFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\chief-of-staff\delegations" `
        -Filter "*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$InboxFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\chief-of-staff\inbox" `
        -Filter "*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$OpenPlans = 0
$PendingApprovals = 0

foreach ($File in $PlanFiles) {
    $Plan = Read-AIOfficeChiefOfStaffJson -Path $File.FullName

    if ($null -eq $Plan) {
        continue
    }

    if (@("completed","cancelled","archived") -notcontains [string]$Plan.status) {
        $OpenPlans++
    }

    if ([string]$Plan.approval_status -eq "pending") {
        $PendingApprovals++
    }
}

$LatestPlan = $PlanFiles |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

$LatestDecision = $DecisionFiles |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

$Index = [ordered]@{
    schema_version = "1.0.0"
    updated_at = (Get-Date).ToString("o")
    chief_of_staff_id = "COS-001"
    status = if ($OpenPlans -gt 0) { "active" } else { "ready" }
    inbox_count = [int]$InboxFiles.Count
    open_plan_count = [int]$OpenPlans
    pending_approval_count = [int]$PendingApprovals
    active_delegation_count = [int]$DelegationFiles.Count
    decision_count = [int]$DecisionFiles.Count
    latest_plan_id = if ($null -ne $LatestPlan) { $LatestPlan.BaseName } else { "" }
    latest_decision_id = if ($null -ne $LatestDecision) { $LatestDecision.BaseName } else { "" }
}

Write-AIOfficeChiefOfStaffJson `
    -Value $Index `
    -Path ".\workspace\chief-of-staff\chief-of-staff-index.json"

Write-Host (
    "Chief of Staff index updated: " +
    $OpenPlans.ToString() +
    " open plan(s)"
) -ForegroundColor Green

return [pscustomobject]$Index
'@

Write-NewFile ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1" $UpdateIndex

$ShowStatus = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$Index = & ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1"

Write-Host ""
Write-Host "AI OFFICE CHIEF OF STAFF STATUS" -ForegroundColor Cyan
Write-Host ("=" * 72)
Write-Host ("Status              : " + [string]$Index.status)
Write-Host ("Inbox               : " + [string]$Index.inbox_count)
Write-Host ("Open plans          : " + [string]$Index.open_plan_count)
Write-Host ("Pending approvals   : " + [string]$Index.pending_approval_count)
Write-Host ("Active delegations  : " + [string]$Index.active_delegation_count)
Write-Host ("Decisions           : " + [string]$Index.decision_count)
Write-Host ("Latest plan         : " + [string]$Index.latest_plan_id)
Write-Host ("Latest decision     : " + [string]$Index.latest_decision_id)
Write-Host ""

return $Index
'@

Write-NewFile ".\scripts\chief-of-staff\Show-AIOfficeChiefOfStaffStatus.ps1" $ShowStatus

$Test = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.4 Part A Chief of Staff Architecture..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\chief-of-staff\chief-of-staff-identity.json",
    ".\config\chief-of-staff\chief-of-staff-policy.json",
    ".\config\chief-of-staff\plan-schema.json",
    ".\config\chief-of-staff\decision-schema.json",
    ".\workspace\chief-of-staff\chief-of-staff-index.json",
    ".\workspace\templates\chief-of-staff-plan-template.json",
    ".\workspace\templates\chief-of-staff-decision-template.json"
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
    ".\scripts\chief-of-staff\AIOfficeChiefOfStaff.Common.ps1",
    ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffPlan.ps1",
    ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffDecision.ps1",
    ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1",
    ".\scripts\chief-of-staff\Show-AIOfficeChiefOfStaffStatus.ps1",
    ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaffArchitecture.ps1"
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

$PlanId = ""
$DecisionId = ""

try {
    $Plan = & ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffPlan.ps1" `
        -Title "Chief of Staff architecture validation" `
        -Objective "Confirm planning, approval, and decision records work." `
        -SuccessCriteriaJson '["Plan created","Approval policy evaluated","Decision recorded"]' `
        -Priority "high" `
        -RiskLevel "low" `
        -ApprovalStatus "not_required"

    $PlanId = [string]$Plan.plan_id

    if ([string]::IsNullOrWhiteSpace($PlanId)) {
        throw "Plan ID was not created."
    }

    Write-Host "[PLAN OK    ] $PlanId" -ForegroundColor Green
}
catch {
    Write-Host "[PLAN ERR   ] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Plan creation failed: " + $_.Exception.Message)
}

try {
    $Decision = & ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffDecision.ps1" `
        -PlanId $PlanId `
        -Decision "Proceed with Chief of Staff integration." `
        -Reason "Architecture validation passed." `
        -RiskLevel "low"

    $DecisionId = [string]$Decision.decision_id

    if ([string]::IsNullOrWhiteSpace($DecisionId)) {
        throw "Decision ID was not created."
    }

    Write-Host "[DECISION OK] $DecisionId" -ForegroundColor Green
}
catch {
    Write-Host "[DECISION ER] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Decision creation failed: " + $_.Exception.Message)
}

try {
    $Index = & ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1"

    if ($null -eq $Index -or [int]$Index.open_plan_count -lt 1) {
        throw "Chief of Staff index did not contain the test plan."
    }

    Write-Host (
        "[INDEX OK   ] " +
        [string]$Index.open_plan_count +
        " open plan(s)"
    ) -ForegroundColor Green
}
catch {
    Write-Host "[INDEX ERR  ] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Index validation failed: " + $_.Exception.Message)
}

if ($PlanId) {
    $Path = ".\workspace\chief-of-staff\plans\$PlanId.json"

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

if ($DecisionId) {
    $Path = ".\workspace\chief-of-staff\decisions\$DecisionId.json"

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

& ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1" |
    Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Chief of Staff architecture error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.4 Part A Chief of Staff Architecture checks passed." `
    -ForegroundColor Green
'@

Write-NewFile ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaffArchitecture.ps1" $Test

$Guide = @'
# AI Office v1.1.4 Part A — Chief of Staff Architecture

Part A establishes the Chief of Staff identity, governance policy, plan model, decision model, index, and validation suite.

## Added

- Chief of Staff identity
- Executive operating policy
- Plan schema
- Decision schema
- Plan and decision templates
- Plan creation
- Decision records
- Risk-based approval evaluation
- Chief of Staff status index
- Full architecture validation

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaffArchitecture.ps1"
```

Expected result:

```text
All AI Office v1.1.4 Part A Chief of Staff Architecture checks passed.
```

## Show status

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\chief-of-staff\Show-AIOfficeChiefOfStaffStatus.ps1"
```

## Next

Part B will add executive inbox processing, request classification, priority assignment, and plan generation from Message Bus requests.
'@

Write-NewFile ".\docs\AI-Office-v1.1.4-Part-A-Chief-of-Staff-Architecture.md" $Guide

$ReleaseNotes = @'
# AI Office v1.1.4 Part A Release Notes

## Release

Chief of Staff Architecture

## Added

- Chief of Staff identity
- Governance and planning policy
- Executive plan records
- Executive decision records
- Risk-based approval evaluation
- Status index
- Validation suite

## Next

v1.1.4 Part B — Executive Inbox and Planning
'@

Write-NewFile ".\docs\AI-Office-v1.1.4-Part-A-Release-Notes.md" $ReleaseNotes

$IdentityPath = ".\config\identity\office.json"

if (Test-Path -LiteralPath $IdentityPath -PathType Leaf) {
    $Office = Get-Content -LiteralPath $IdentityPath -Raw |
        ConvertFrom-Json

    $Office.version = "1.1.4"
    $Office.codename = "Chief of Staff"
    $Office.updated_at = (Get-Date).ToString("o")

    $Office |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $IdentityPath -Encoding UTF8

    Write-Host "[UPDATED] AI Office identity version set to 1.1.4" `
        -ForegroundColor Green
}

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw |
        ConvertFrom-Json

    $Version.version = "1.1.4"
    $Version.release_name = "Chief of Staff Integration"
    $Version.status = "part_a_installed"
    $Version.installed_at = (Get-Date).ToString("o")
    $Version.previous_version = "1.1.3"
    $Version.next_planned_milestone = "1.1.4 Part B Executive Inbox and Planning"

    $Version |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $VersionPath -Encoding UTF8

    Write-Host "[UPDATED] Identity release metadata set to v1.1.4 Part A" `
        -ForegroundColor Green
}

Write-Host ""
Write-Host "Validating Part A JSON files..." -ForegroundColor Cyan

@(
    ".\config\chief-of-staff\chief-of-staff-identity.json",
    ".\config\chief-of-staff\chief-of-staff-policy.json",
    ".\config\chief-of-staff\plan-schema.json",
    ".\config\chief-of-staff\decision-schema.json",
    ".\workspace\chief-of-staff\chief-of-staff-index.json",
    ".\workspace\templates\chief-of-staff-plan-template.json",
    ".\workspace\templates\chief-of-staff-decision-template.json"
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
        "Installers\AI-Office-v1.1.4-Part-A-Chief-of-Staff-Architecture-Install.ps1"

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
Write-Host "AI Office v1.1.4 Part A installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaffArchitecture.ps1"'
Write-Host ""
