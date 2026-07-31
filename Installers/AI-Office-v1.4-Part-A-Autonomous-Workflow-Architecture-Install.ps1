# ============================================================
# AI Office v1.4 - Part A
# Autonomous Workflow Architecture
# Repository: E:\AI\AI-Office
# Requires: AI Office v1.3 Long-Term Memory
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

$RequiredPrevious = @(
    ".\config\memory\release-manifest.json",
    ".\config\chief-of-staff\release-manifest.json",
    ".\config\departments\release-manifest.json",
    ".\scripts\memory\New-AIOfficeMemoryContextPacket.ps1",
    ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffDispatch.ps1",
    ".\scripts\departments\Invoke-AIOfficeDepartmentExecution.ps1",
    ".\scripts\automation\AIOfficeAutomation.Common.ps1"
)

foreach ($RequiredPath in $RequiredPrevious) {
    if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
        throw "AI Office v1.3 is required. Missing: $RequiredPath"
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
    ".\config\autonomous-workflows",
    ".\workspace\autonomous-workflows",
    ".\workspace\autonomous-workflows\goals",
    ".\workspace\autonomous-workflows\plans",
    ".\workspace\autonomous-workflows\runs",
    ".\workspace\autonomous-workflows\checkpoints",
    ".\workspace\autonomous-workflows\approvals",
    ".\workspace\autonomous-workflows\retries",
    ".\workspace\autonomous-workflows\failures",
    ".\workspace\autonomous-workflows\archive",
    ".\workspace\autonomous-workflows\indexes",
    ".\workspace\templates",
    ".\scripts\autonomous-workflows",
    ".\docs",
    ".\Installers"
) | ForEach-Object { Ensure-Directory $_ }

$Now = (Get-Date).ToString("o")

$Policy = @"
{
  "schema_version": "1.0.0",
  "version": "1.4.0",
  "part": "A",
  "operating_model": {
    "human_supervised": true,
    "resume_after_restart": true,
    "persist_every_transition": true,
    "default_owner": "chief-of-staff",
    "default_priority": "normal",
    "maximum_active_runs": 100,
    "maximum_steps_per_plan": 100
  },
  "goal_management": {
    "require_title": true,
    "require_objective": true,
    "require_success_criteria": true,
    "require_owner": true,
    "require_priority": true,
    "require_risk_level": true
  },
  "execution": {
    "allowed_step_types": [
      "chief_of_staff",
      "department",
      "message_bus",
      "openclaw_bridge",
      "human_approval",
      "memory_recall",
      "wait",
      "report"
    ],
    "default_step_timeout_minutes": 60,
    "allow_parallel_steps": true,
    "allow_conditional_steps": true
  },
  "approval": {
    "required_for_risk_levels": [
      "high",
      "critical"
    ],
    "required_for_step_types": [
      "human_approval"
    ]
  },
  "retry": {
    "enabled": true,
    "default_max_attempts": 3,
    "default_delay_seconds": 30,
    "backoff_multiplier": 2.0
  },
  "checkpoint": {
    "enabled": true,
    "create_before_step": true,
    "create_after_step": true,
    "retain_completed_checkpoints": true
  },
  "recovery": {
    "resume_queued_runs": true,
    "resume_running_runs": true,
    "fail_orphaned_steps_after_hours": 24
  },
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\autonomous-workflows\autonomous-workflow-policy.json" $Policy

$GoalSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/autonomous-goal-schema.json",
  "title": "AI Office Autonomous Goal",
  "type": "object",
  "required": [
    "goal_id",
    "title",
    "objective",
    "success_criteria",
    "owner",
    "priority",
    "risk_level",
    "approval_status",
    "status",
    "created_at",
    "updated_at",
    "history"
  ]
}
'@

Write-NewFile ".\config\autonomous-workflows\goal-schema.json" $GoalSchema

$PlanSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/autonomous-plan-schema.json",
  "title": "AI Office Autonomous Plan",
  "type": "object",
  "required": [
    "autonomous_plan_id",
    "goal_id",
    "title",
    "status",
    "steps",
    "created_at",
    "updated_at",
    "history"
  ]
}
'@

Write-NewFile ".\config\autonomous-workflows\plan-schema.json" $PlanSchema

$RunSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/autonomous-run-schema.json",
  "title": "AI Office Autonomous Workflow Run",
  "type": "object",
  "required": [
    "run_id",
    "autonomous_plan_id",
    "goal_id",
    "status",
    "current_step",
    "created_at",
    "updated_at",
    "history"
  ]
}
'@

Write-NewFile ".\config\autonomous-workflows\run-schema.json" $RunSchema

$CheckpointSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/autonomous-checkpoint-schema.json",
  "title": "AI Office Autonomous Workflow Checkpoint",
  "type": "object",
  "required": [
    "checkpoint_id",
    "run_id",
    "step_id",
    "stage",
    "state",
    "created_at"
  ]
}
'@

Write-NewFile ".\config\autonomous-workflows\checkpoint-schema.json" $CheckpointSchema

$GoalTemplate = @'
{
  "goal_id": "GOAL-YYYYMMDD-HHMMSS-ABC123",
  "title": "",
  "objective": "",
  "success_criteria": [],
  "owner": "chief-of-staff",
  "priority": "normal",
  "risk_level": "medium",
  "approval_status": "pending",
  "status": "draft",
  "created_at": "",
  "updated_at": "",
  "history": []
}
'@

Write-NewFile ".\workspace\templates\autonomous-goal-template.json" $GoalTemplate

$PlanTemplate = @'
{
  "autonomous_plan_id": "APL-YYYYMMDD-HHMMSS-ABC123",
  "goal_id": "GOAL-YYYYMMDD-HHMMSS-ABC123",
  "title": "",
  "status": "draft",
  "steps": [],
  "created_at": "",
  "updated_at": "",
  "history": []
}
'@

Write-NewFile ".\workspace\templates\autonomous-plan-template.json" $PlanTemplate

$RunTemplate = @'
{
  "run_id": "RUN-YYYYMMDD-HHMMSS-ABC123",
  "autonomous_plan_id": "APL-YYYYMMDD-HHMMSS-ABC123",
  "goal_id": "GOAL-YYYYMMDD-HHMMSS-ABC123",
  "status": "queued",
  "current_step": 0,
  "created_at": "",
  "updated_at": "",
  "started_at": null,
  "completed_at": null,
  "history": []
}
'@

Write-NewFile ".\workspace\templates\autonomous-run-template.json" $RunTemplate

$Index = @'
{
  "schema_version": "1.0.0",
  "version": "1.4.0",
  "updated_at": "",
  "status": "ready",
  "goal_count": 0,
  "open_goal_count": 0,
  "plan_count": 0,
  "active_run_count": 0,
  "waiting_approval_count": 0,
  "failed_run_count": 0,
  "latest_goal_id": "",
  "latest_run_id": ""
}
'@

Write-NewFile ".\workspace\autonomous-workflows\indexes\autonomous-workflow-index.json" $Index

$Common = @'
$script:AIOfficeAutonomousWorkflowRoot = $null

function Get-AIOfficeAutonomousWorkflowRoot {
    if ($script:AIOfficeAutonomousWorkflowRoot) {
        return $script:AIOfficeAutonomousWorkflowRoot
    }

    $script:AIOfficeAutonomousWorkflowRoot = (
        Resolve-Path (Join-Path $PSScriptRoot "..\..")
    ).Path

    return $script:AIOfficeAutonomousWorkflowRoot
}

function Read-AIOfficeAutonomousWorkflowJson {
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

function Write-AIOfficeAutonomousWorkflowJson {
    param(
        [Parameter(Mandatory=$true)]$Value,
        [Parameter(Mandatory=$true)][string]$Path
    )

    $Parent = Split-Path -Parent $Path

    if ($Parent -and -not (Test-Path -LiteralPath $Parent -PathType Container)) {
        New-Item -ItemType Directory -Path $Parent -Force | Out-Null
    }

    $Value |
        ConvertTo-Json -Depth 80 |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-AIOfficeAutonomousWorkflowPolicy {
    $Root = Get-AIOfficeAutonomousWorkflowRoot

    return Read-AIOfficeAutonomousWorkflowJson `
        -Path (
            Join-Path `
                $Root `
                "config\autonomous-workflows\autonomous-workflow-policy.json"
        )
}

function New-AIOfficeAutonomousGoalId {
    return (
        "GOAL-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeAutonomousPlanId {
    return (
        "APL-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeAutonomousRunId {
    return (
        "RUN-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeAutonomousCheckpointId {
    return (
        "CHK-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeAutonomousGoal {
    param([Parameter(Mandatory=$true)][string]$GoalId)

    $Root = Get-AIOfficeAutonomousWorkflowRoot
    $Path = Join-Path `
        $Root `
        ("workspace\autonomous-workflows\goals\" + $GoalId + ".json")

    $Goal = Read-AIOfficeAutonomousWorkflowJson -Path $Path

    if ($null -eq $Goal) {
        throw "Autonomous goal not found: $GoalId"
    }

    return $Goal
}

function Get-AIOfficeAutonomousPlan {
    param([Parameter(Mandatory=$true)][string]$AutonomousPlanId)

    $Root = Get-AIOfficeAutonomousWorkflowRoot
    $Path = Join-Path `
        $Root `
        (
            "workspace\autonomous-workflows\plans\" +
            $AutonomousPlanId +
            ".json"
        )

    $Plan = Read-AIOfficeAutonomousWorkflowJson -Path $Path

    if ($null -eq $Plan) {
        throw "Autonomous plan not found: $AutonomousPlanId"
    }

    return $Plan
}
'@

Write-NewFile ".\scripts\autonomous-workflows\AIOfficeAutonomousWorkflows.Common.ps1" $Common

$NewGoal = @'
param(
    [Parameter(Mandatory=$true)][string]$Title,
    [Parameter(Mandatory=$true)][string]$Objective,
    [Parameter(Mandatory=$true)][string]$SuccessCriteriaJson,
    [string]$Owner = "chief-of-staff",
    [ValidateSet("low","normal","high","urgent","critical")]
    [string]$Priority = "normal",
    [ValidateSet("low","medium","high","critical")]
    [string]$RiskLevel = "medium",
    [ValidateSet("pending","approved","rejected","not_required")]
    [string]$ApprovalStatus = "pending"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousWorkflows.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

try {
    $SuccessCriteria = @($SuccessCriteriaJson | ConvertFrom-Json)
}
catch {
    throw "SuccessCriteriaJson is invalid: $($_.Exception.Message)"
}

if ($SuccessCriteria.Count -lt 1) {
    throw "At least one success criterion is required."
}

if ($RiskLevel -in @("low","medium") -and $ApprovalStatus -eq "pending") {
    $ApprovalStatus = "not_required"
}

$GoalId = New-AIOfficeAutonomousGoalId
$Now = (Get-Date).ToString("o")

$Goal = [ordered]@{
    goal_id = $GoalId
    title = $Title
    objective = $Objective
    success_criteria = $SuccessCriteria
    owner = $Owner
    priority = $Priority
    risk_level = $RiskLevel
    approval_status = $ApprovalStatus
    status = "draft"
    created_at = $Now
    updated_at = $Now
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = $Owner
            details = "Autonomous goal created."
        }
    )
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Goal `
    -Path ".\workspace\autonomous-workflows\goals\$GoalId.json"

& ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1" |
    Out-Null

Write-Host "Autonomous goal created: $GoalId" -ForegroundColor Green
return [pscustomobject]$Goal
'@

Write-NewFile ".\scripts\autonomous-workflows\New-AIOfficeAutonomousGoal.ps1" $NewGoal

$NewPlan = @'
param(
    [Parameter(Mandatory=$true)][string]$GoalId,
    [Parameter(Mandatory=$true)][string]$StepsJson
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousWorkflows.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

$Goal = Get-AIOfficeAutonomousGoal -GoalId $GoalId

try {
    $InputSteps = @($StepsJson | ConvertFrom-Json)
}
catch {
    throw "StepsJson is invalid: $($_.Exception.Message)"
}

if ($InputSteps.Count -lt 1) {
    throw "At least one workflow step is required."
}

$Policy = Get-AIOfficeAutonomousWorkflowPolicy

if ($InputSteps.Count -gt [int]$Policy.operating_model.maximum_steps_per_plan) {
    throw "Plan exceeds the maximum supported step count."
}

$Steps = New-Object System.Collections.Generic.List[object]
$StepNumber = 1

foreach ($Step in $InputSteps) {
    $StepType = [string]$Step.step_type

    if (@($Policy.execution.allowed_step_types) -notcontains $StepType) {
        throw "Unsupported autonomous workflow step type: $StepType"
    }

    $StepId = (
        "STEP-" +
        $StepNumber.ToString("000") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )

    $Steps.Add([ordered]@{
        step_id = $StepId
        step_number = $StepNumber
        title = [string]$Step.title
        step_type = $StepType
        owner = if ($null -ne $Step.PSObject.Properties["owner"]) {
            [string]$Step.owner
        }
        else {
            "chief-of-staff"
        }
        department = if ($null -ne $Step.PSObject.Properties["department"]) {
            [string]$Step.department
        }
        else {
            ""
        }
        depends_on = if ($null -ne $Step.PSObject.Properties["depends_on"]) {
            @($Step.depends_on)
        }
        else {
            @()
        }
        condition = if ($null -ne $Step.PSObject.Properties["condition"]) {
            [string]$Step.condition
        }
        else {
            ""
        }
        status = "pending"
        attempt_count = 0
        max_attempts = [int]$Policy.retry.default_max_attempts
        result = $null
    })

    $StepNumber++
}

$PlanId = New-AIOfficeAutonomousPlanId
$Now = (Get-Date).ToString("o")

$Plan = [ordered]@{
    autonomous_plan_id = $PlanId
    goal_id = $GoalId
    title = [string]$Goal.title
    objective = [string]$Goal.objective
    status = "draft"
    priority = [string]$Goal.priority
    risk_level = [string]$Goal.risk_level
    approval_status = [string]$Goal.approval_status
    steps = @($Steps | ForEach-Object { $_ })
    created_at = $Now
    updated_at = $Now
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = "chief-of-staff"
            details = "Autonomous workflow plan created."
        }
    )
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Plan `
    -Path ".\workspace\autonomous-workflows\plans\$PlanId.json"

$Goal.status = "planned"
$Goal.updated_at = $Now

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Goal `
    -Path ".\workspace\autonomous-workflows\goals\$GoalId.json"

& ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1" |
    Out-Null

Write-Host "Autonomous plan created: $PlanId" -ForegroundColor Green
return [pscustomobject]$Plan
'@

Write-NewFile ".\scripts\autonomous-workflows\New-AIOfficeAutonomousPlan.ps1" $NewPlan

$NewRun = @'
param(
    [Parameter(Mandatory=$true)][string]$AutonomousPlanId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousWorkflows.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

$Plan = Get-AIOfficeAutonomousPlan `
    -AutonomousPlanId $AutonomousPlanId

$RunId = New-AIOfficeAutonomousRunId
$Now = (Get-Date).ToString("o")

$Run = [ordered]@{
    run_id = $RunId
    autonomous_plan_id = $AutonomousPlanId
    goal_id = [string]$Plan.goal_id
    status = "queued"
    current_step = 0
    created_at = $Now
    updated_at = $Now
    started_at = $null
    completed_at = $null
    last_checkpoint_id = ""
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = "workflow-engine"
            details = "Autonomous workflow run created."
        }
    )
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Run `
    -Path ".\workspace\autonomous-workflows\runs\$RunId.json"

$Plan.status = "queued"
$Plan.updated_at = $Now

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Plan `
    -Path ".\workspace\autonomous-workflows\plans\$AutonomousPlanId.json"

& ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1" |
    Out-Null

Write-Host "Autonomous workflow run created: $RunId" -ForegroundColor Green
return [pscustomobject]$Run
'@

Write-NewFile ".\scripts\autonomous-workflows\New-AIOfficeAutonomousRun.ps1" $NewRun

$Checkpoint = @'
param(
    [Parameter(Mandatory=$true)][string]$RunId,
    [Parameter(Mandatory=$true)][string]$StepId,
    [ValidateSet("before","after","recovery","failure")]
    [string]$Stage,
    [Parameter(Mandatory=$true)][string]$StateJson
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousWorkflows.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

try {
    $State = $StateJson | ConvertFrom-Json
}
catch {
    throw "StateJson is invalid: $($_.Exception.Message)"
}

$RunPath = ".\workspace\autonomous-workflows\runs\$RunId.json"
$Run = Read-AIOfficeAutonomousWorkflowJson -Path $RunPath

if ($null -eq $Run) {
    throw "Autonomous workflow run not found: $RunId"
}

$CheckpointId = New-AIOfficeAutonomousCheckpointId

$Checkpoint = [ordered]@{
    checkpoint_id = $CheckpointId
    run_id = $RunId
    step_id = $StepId
    stage = $Stage
    state = $State
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Checkpoint `
    -Path ".\workspace\autonomous-workflows\checkpoints\$CheckpointId.json"

$Run.last_checkpoint_id = $CheckpointId
$Run.updated_at = (Get-Date).ToString("o")

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Run `
    -Path $RunPath

Write-Host "Workflow checkpoint created: $CheckpointId" -ForegroundColor Green
return [pscustomobject]$Checkpoint
'@

Write-NewFile ".\scripts\autonomous-workflows\New-AIOfficeAutonomousCheckpoint.ps1" $Checkpoint

$UpdateIndex = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousWorkflows.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

$GoalFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\autonomous-workflows\goals" `
        -Filter "GOAL-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$PlanFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\autonomous-workflows\plans" `
        -Filter "APL-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$RunFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\autonomous-workflows\runs" `
        -Filter "RUN-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$Goals = @(
    foreach ($File in $GoalFiles) {
        Read-AIOfficeAutonomousWorkflowJson -Path $File.FullName
    }
)

$Runs = @(
    foreach ($File in $RunFiles) {
        Read-AIOfficeAutonomousWorkflowJson -Path $File.FullName
    }
)

$LatestGoal = @(
    $Goals |
        Sort-Object updated_at -Descending |
        Select-Object -First 1
)

$LatestRun = @(
    $Runs |
        Sort-Object updated_at -Descending |
        Select-Object -First 1
)

$Index = [ordered]@{
    schema_version = "1.0.0"
    version = "1.4.0"
    updated_at = (Get-Date).ToString("o")
    status = "ready"
    goal_count = $Goals.Count
    open_goal_count = @(
        $Goals |
            Where-Object {
                @("completed","cancelled","archived") -notcontains
                [string]$_.status
            }
    ).Count
    plan_count = $PlanFiles.Count
    active_run_count = @(
        $Runs |
            Where-Object {
                @("queued","running","waiting","waiting_approval") -contains
                [string]$_.status
            }
    ).Count
    waiting_approval_count = @(
        $Runs |
            Where-Object { [string]$_.status -eq "waiting_approval" }
    ).Count
    failed_run_count = @(
        $Runs |
            Where-Object { [string]$_.status -eq "failed" }
    ).Count
    latest_goal_id = if ($LatestGoal.Count -gt 0) {
        [string]$LatestGoal[0].goal_id
    }
    else {
        ""
    }
    latest_run_id = if ($LatestRun.Count -gt 0) {
        [string]$LatestRun[0].run_id
    }
    else {
        ""
    }
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Index `
    -Path ".\workspace\autonomous-workflows\indexes\autonomous-workflow-index.json"

Write-Host (
    "Autonomous Workflow index updated: " +
    $Goals.Count.ToString() +
    " goal(s), " +
    $Runs.Count.ToString() +
    " run(s)"
) -ForegroundColor Green

return [pscustomobject]$Index
'@

Write-NewFile ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1" $UpdateIndex

$ShowStatus = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$Index = & ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1"

Write-Host ""
Write-Host "AI OFFICE AUTONOMOUS WORKFLOW STATUS" -ForegroundColor Cyan
Write-Host ("=" * 72)
Write-Host ("Goals              : " + [string]$Index.goal_count)
Write-Host ("Open goals         : " + [string]$Index.open_goal_count)
Write-Host ("Plans              : " + [string]$Index.plan_count)
Write-Host ("Active runs        : " + [string]$Index.active_run_count)
Write-Host ("Waiting approvals  : " + [string]$Index.waiting_approval_count)
Write-Host ("Failed runs        : " + [string]$Index.failed_run_count)
Write-Host ("Latest goal        : " + [string]$Index.latest_goal_id)
Write-Host ("Latest run         : " + [string]$Index.latest_run_id)
Write-Host ""

return $Index
'@

Write-NewFile ".\scripts\autonomous-workflows\Show-AIOfficeAutonomousWorkflowStatus.ps1" $ShowStatus

$Test = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.4 Part A Autonomous Workflow Architecture..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\autonomous-workflows\autonomous-workflow-policy.json",
    ".\config\autonomous-workflows\goal-schema.json",
    ".\config\autonomous-workflows\plan-schema.json",
    ".\config\autonomous-workflows\run-schema.json",
    ".\config\autonomous-workflows\checkpoint-schema.json",
    ".\workspace\templates\autonomous-goal-template.json",
    ".\workspace\templates\autonomous-plan-template.json",
    ".\workspace\templates\autonomous-run-template.json",
    ".\workspace\autonomous-workflows\indexes\autonomous-workflow-index.json"
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
    ".\scripts\autonomous-workflows\AIOfficeAutonomousWorkflows.Common.ps1",
    ".\scripts\autonomous-workflows\New-AIOfficeAutonomousGoal.ps1",
    ".\scripts\autonomous-workflows\New-AIOfficeAutonomousPlan.ps1",
    ".\scripts\autonomous-workflows\New-AIOfficeAutonomousRun.ps1",
    ".\scripts\autonomous-workflows\New-AIOfficeAutonomousCheckpoint.ps1",
    ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1",
    ".\scripts\autonomous-workflows\Show-AIOfficeAutonomousWorkflowStatus.ps1",
    ".\scripts\autonomous-workflows\Test-AIOfficeAutonomousWorkflowArchitecture.ps1"
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

$GoalId = ""
$PlanId = ""
$RunId = ""
$CheckpointId = ""

try {
    $Goal = & ".\scripts\autonomous-workflows\New-AIOfficeAutonomousGoal.ps1" `
        -Title "Autonomous workflow validation" `
        -Objective "Validate goal, plan, run, and checkpoint persistence." `
        -SuccessCriteriaJson '["Goal created","Plan created","Run created","Checkpoint created"]' `
        -Priority "high" `
        -RiskLevel "low" `
        -ApprovalStatus "not_required"

    $GoalId = [string]$Goal.goal_id

    $Steps = @(
        [ordered]@{
            title = "Recall relevant memory"
            step_type = "memory_recall"
            owner = "chief-of-staff"
        },
        [ordered]@{
            title = "Execute marketing work"
            step_type = "department"
            owner = "marketing"
            department = "marketing"
        },
        [ordered]@{
            title = "Generate final report"
            step_type = "report"
            owner = "chief-of-staff"
        }
    )

    $Plan = & ".\scripts\autonomous-workflows\New-AIOfficeAutonomousPlan.ps1" `
        -GoalId $GoalId `
        -StepsJson ($Steps | ConvertTo-Json -Depth 20 -Compress)

    $PlanId = [string]$Plan.autonomous_plan_id

    $Run = & ".\scripts\autonomous-workflows\New-AIOfficeAutonomousRun.ps1" `
        -AutonomousPlanId $PlanId

    $RunId = [string]$Run.run_id

    $Checkpoint = & `
        ".\scripts\autonomous-workflows\New-AIOfficeAutonomousCheckpoint.ps1" `
        -RunId $RunId `
        -StepId ([string]$Plan.steps[0].step_id) `
        -Stage "before" `
        -StateJson '{"status":"ready","current_step":1}'

    $CheckpointId = [string]$Checkpoint.checkpoint_id

    if (
        [string]::IsNullOrWhiteSpace($GoalId) -or
        [string]::IsNullOrWhiteSpace($PlanId) -or
        [string]::IsNullOrWhiteSpace($RunId) -or
        [string]::IsNullOrWhiteSpace($CheckpointId)
    ) {
        throw "One or more autonomous workflow IDs were not created."
    }

    Write-Host (
        "[WORKFLOW OK] " +
        $GoalId +
        " | " +
        $PlanId +
        " | " +
        $RunId
    ) -ForegroundColor Green
}
catch {
    Write-Host "[WORKFLOW ER] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Autonomous workflow creation failed: " + $_.Exception.Message)
}

try {
    $Index = & `
        ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1"

    if (
        $null -eq $Index -or
        [int]$Index.goal_count -lt 1 -or
        [int]$Index.plan_count -lt 1 -or
        [int]$Index.active_run_count -lt 1
    ) {
        throw "Autonomous Workflow index did not contain validation records."
    }

    Write-Host "[INDEX OK   ] Workflow index validation passed." `
        -ForegroundColor Green
}
catch {
    Write-Host "[INDEX ERR  ] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Autonomous Workflow index failed: " + $_.Exception.Message)
}

foreach ($Path in @(
    ".\workspace\autonomous-workflows\goals\$GoalId.json",
    ".\workspace\autonomous-workflows\plans\$PlanId.json",
    ".\workspace\autonomous-workflows\runs\$RunId.json",
    ".\workspace\autonomous-workflows\checkpoints\$CheckpointId.json"
)) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

& ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1" |
    Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Autonomous Workflow architecture error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.4 Part A Autonomous Workflow Architecture checks passed." `
    -ForegroundColor Green
'@

Write-NewFile ".\scripts\autonomous-workflows\Test-AIOfficeAutonomousWorkflowArchitecture.ps1" $Test

$Guide = @'
# AI Office v1.4 Part A — Autonomous Workflow Architecture

Part A creates the persistent autonomous workflow foundation.

## Added

- Executive goals
- Autonomous plans
- Persistent workflow runs
- Workflow steps and dependencies
- Conditional and parallel step support
- Approval gates
- Retry policy
- Checkpoint policy
- Restart recovery policy
- Persistent run state
- Workflow indexes
- Full architecture validation

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\autonomous-workflows\Test-AIOfficeAutonomousWorkflowArchitecture.ps1"
```

Expected result:

```text
All AI Office v1.4 Part A Autonomous Workflow Architecture checks passed.
```

## Show status

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\autonomous-workflows\Show-AIOfficeAutonomousWorkflowStatus.ps1"
```

## Next

Part B will add the execution engine, step dispatch, approvals, retries, checkpoints, recovery, and reboot-safe continuation.
'@

Write-NewFile ".\docs\AI-Office-v1.4-Part-A-Autonomous-Workflow-Architecture.md" $Guide

$ReleaseNotes = @'
# AI Office v1.4 Part A Release Notes

## Release

Autonomous Workflow Architecture

## Added

- Goal records
- Autonomous plans
- Persistent runs
- Workflow steps
- Dependencies
- Approval gates
- Retry and checkpoint policy
- Recovery architecture
- Workflow status index
- Validation suite

## Next

v1.4 Part B — Autonomous Execution and Recovery
'@

Write-NewFile ".\docs\AI-Office-v1.4-Part-A-Release-Notes.md" $ReleaseNotes

$IdentityPath = ".\config\identity\office.json"

if (Test-Path -LiteralPath $IdentityPath -PathType Leaf) {
    $Identity = Get-Content -LiteralPath $IdentityPath -Raw |
        ConvertFrom-Json

    $Identity.version = "1.4.0"
    $Identity.codename = "Autonomous Workflows"
    $Identity.updated_at = (Get-Date).ToString("o")

    $Identity |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $IdentityPath -Encoding UTF8

    Write-Host "[UPDATED] AI Office identity version set to 1.4.0" `
        -ForegroundColor Green
}

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw |
        ConvertFrom-Json

    $Version.version = "1.4.0"
    $Version.release_name = "Autonomous Workflows"
    $Version.status = "part_a_installed"
    $Version.installed_at = (Get-Date).ToString("o")
    $Version.previous_version = "1.3.0"
    $Version.next_planned_milestone = "1.4 Part B Autonomous Execution and Recovery"

    $Version |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $VersionPath -Encoding UTF8

    Write-Host "[UPDATED] Identity release metadata set to v1.4 Part A" `
        -ForegroundColor Green
}

Write-Host ""
Write-Host "Validating Part A JSON files..." -ForegroundColor Cyan

@(
    ".\config\autonomous-workflows\autonomous-workflow-policy.json",
    ".\config\autonomous-workflows\goal-schema.json",
    ".\config\autonomous-workflows\plan-schema.json",
    ".\config\autonomous-workflows\run-schema.json",
    ".\config\autonomous-workflows\checkpoint-schema.json",
    ".\workspace\templates\autonomous-goal-template.json",
    ".\workspace\templates\autonomous-plan-template.json",
    ".\workspace\templates\autonomous-run-template.json",
    ".\workspace\autonomous-workflows\indexes\autonomous-workflow-index.json"
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
        "Installers\AI-Office-v1.4-Part-A-Autonomous-Workflow-Architecture-Install.ps1"

    if (
        $Source -and
        (Test-Path -LiteralPath $Source -PathType Leaf) -and
        [System.IO.Path]::GetFullPath($Source) -ne
        [System.IO.Path]::GetFullPath($Destination)
    ) {
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
Write-Host "AI Office v1.4 Part A installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\autonomous-workflows\Test-AIOfficeAutonomousWorkflowArchitecture.ps1"'
Write-Host ""
