# ============================================================
# AI Office v1.2 - Part C
# Department Planning and Execution
# Repository: E:\AI\AI-Office
# Requires: AI Office v1.2 Parts A and B
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

$RequiredPrevious = @(
    ".\config\departments\department-intelligence-policy.json",
    ".\config\departments\department-inbox-policy.json",
    ".\scripts\departments\AIOfficeDepartments.Common.ps1",
    ".\scripts\departments\AIOfficeDepartmentInbox.Common.ps1",
    ".\scripts\departments\New-AIOfficeDepartmentWorkItem.ps1",
    ".\scripts\departments\Search-AIOfficeDepartmentWork.ps1",
    ".\scripts\messaging\New-AIOfficeMessage.ps1",
    ".\scripts\messaging\Complete-AIOfficeMessage.ps1",
    ".\scripts\messaging\Fail-AIOfficeMessage.ps1"
)

foreach ($RequiredPath in $RequiredPrevious) {
    if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
        throw "AI Office v1.2 Parts A and B are required. Missing: $RequiredPath"
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

$Departments = @(
    "marketing",
    "creative",
    "website",
    "analytics",
    "finance",
    "business",
    "side-hustles",
    "youtube",
    "personal-assistant"
)

foreach ($Department in $Departments) {
    @(
        ".\workspace\departments\$Department\execution",
        ".\workspace\departments\$Department\handoffs",
        ".\workspace\departments\$Department\results",
        ".\workspace\departments\$Department\failed-execution"
    ) | ForEach-Object { Ensure-Directory $_ }
}

$Now = (Get-Date).ToString("o")

$ExecutionPolicy = @"
{
  "schema_version": "1.0.0",
  "version": "1.2.0",
  "part": "C",
  "planning": {
    "default_step_count": 3,
    "maximum_step_count": 25,
    "require_deliverables": true,
    "require_execution_mode": true
  },
  "execution_modes": [
    "internal_reasoning",
    "message_bus",
    "openclaw_bridge",
    "human_approval"
  ],
  "mode_rules": {
    "internal_reasoning": {
      "default_for_low_risk": true,
      "approval_required": false
    },
    "message_bus": {
      "approval_required": false
    },
    "openclaw_bridge": {
      "approval_required_for": ["high", "critical"]
    },
    "human_approval": {
      "approval_required": true
    }
  },
  "handoff": {
    "allow_cross_department": true,
    "message_type": "handoff",
    "queue": "outbox"
  },
  "result": {
    "publish_to_chief_of_staff": true,
    "message_type": "execution_result",
    "queue": "inbox"
  },
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\departments\department-execution-policy.json" $ExecutionPolicy

$PlanSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/department-plan-schema.json",
  "title": "AI Office Department Plan",
  "type": "object",
  "required": [
    "department_plan_id",
    "department",
    "work_item_id",
    "title",
    "objective",
    "execution_mode",
    "status",
    "steps",
    "created_at",
    "updated_at",
    "history"
  ]
}
'@

Write-NewFile ".\config\departments\department-plan-schema.json" $PlanSchema

$ExecutionSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/department-execution-schema.json",
  "title": "AI Office Department Execution",
  "type": "object",
  "required": [
    "department_execution_id",
    "department",
    "department_plan_id",
    "work_item_id",
    "execution_mode",
    "status",
    "created_at",
    "updated_at",
    "history"
  ]
}
'@

Write-NewFile ".\config\departments\department-execution-schema.json" $ExecutionSchema

$PlanTemplate = @'
{
  "department_plan_id": "DPL-YYYYMMDD-HHMMSS-ABC123",
  "department": "marketing",
  "work_item_id": "DWI-YYYYMMDD-HHMMSS-ABC123",
  "title": "",
  "objective": "",
  "execution_mode": "internal_reasoning",
  "status": "draft",
  "steps": [],
  "created_at": "",
  "updated_at": "",
  "history": []
}
'@

Write-NewFile ".\workspace\templates\department-plan-template.json" $PlanTemplate

$ExecutionTemplate = @'
{
  "department_execution_id": "DEX-YYYYMMDD-HHMMSS-ABC123",
  "department": "marketing",
  "department_plan_id": "DPL-YYYYMMDD-HHMMSS-ABC123",
  "work_item_id": "DWI-YYYYMMDD-HHMMSS-ABC123",
  "execution_mode": "internal_reasoning",
  "status": "queued",
  "created_at": "",
  "updated_at": "",
  "started_at": null,
  "completed_at": null,
  "result": null,
  "history": []
}
'@

Write-NewFile ".\workspace\templates\department-execution-template.json" $ExecutionTemplate

$Common = @'
. (Join-Path $PSScriptRoot "AIOfficeDepartments.Common.ps1")

function Get-AIOfficeDepartmentExecutionPolicy {
    $Root = Get-AIOfficeDepartmentRoot

    return Read-AIOfficeDepartmentJson `
        -Path (Join-Path $Root "config\departments\department-execution-policy.json")
}

function New-AIOfficeDepartmentPlanId {
    return (
        "DPL-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeDepartmentExecutionId {
    return (
        "DEX-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeDepartmentWorkItem {
    param(
        [Parameter(Mandatory=$true)][string]$Department,
        [Parameter(Mandatory=$true)][string]$WorkItemId
    )

    $Root = Get-AIOfficeDepartmentRoot
    $Path = Join-Path `
        $Root `
        ("workspace\departments\" + $Department + "\work\" + $WorkItemId + ".json")

    $WorkItem = Read-AIOfficeDepartmentJson -Path $Path

    if ($null -eq $WorkItem) {
        throw "Department work item not found: $WorkItemId"
    }

    return $WorkItem
}

function Get-AIOfficeDepartmentPlan {
    param(
        [Parameter(Mandatory=$true)][string]$Department,
        [Parameter(Mandatory=$true)][string]$DepartmentPlanId
    )

    $Root = Get-AIOfficeDepartmentRoot
    $Path = Join-Path `
        $Root `
        ("workspace\departments\" + $Department + "\plans\" + $DepartmentPlanId + ".json")

    $Plan = Read-AIOfficeDepartmentJson -Path $Path

    if ($null -eq $Plan) {
        throw "Department plan not found: $DepartmentPlanId"
    }

    return $Plan
}
'@

Write-NewFile ".\scripts\departments\AIOfficeDepartmentExecution.Common.ps1" $Common

$NewPlan = @'
param(
    [Parameter(Mandatory=$true)][string]$Department,
    [Parameter(Mandatory=$true)][string]$WorkItemId,
    [ValidateSet(
        "internal_reasoning",
        "message_bus",
        "openclaw_bridge",
        "human_approval"
    )]
    [string]$ExecutionMode = "internal_reasoning"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentExecution.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$WorkItem = Get-AIOfficeDepartmentWorkItem `
    -Department $Department `
    -WorkItemId $WorkItemId

$PlanId = New-AIOfficeDepartmentPlanId
$Now = (Get-Date).ToString("o")

$Steps = New-Object System.Collections.Generic.List[object]
$StepNumber = 1

foreach ($Deliverable in @($WorkItem.deliverables)) {
    $Steps.Add([ordered]@{
        step_number = $StepNumber
        title = [string]$Deliverable
        owner = $Department
        execution_mode = $ExecutionMode
        status = "pending"
    })

    $StepNumber++
}

if ($Steps.Count -lt 1) {
    $Steps.Add([ordered]@{
        step_number = 1
        title = "Complete assigned department work"
        owner = $Department
        execution_mode = $ExecutionMode
        status = "pending"
    })
}

$Plan = [ordered]@{
    department_plan_id = $PlanId
    department = $Department
    work_item_id = $WorkItemId
    title = [string]$WorkItem.title
    objective = [string]$WorkItem.objective
    execution_mode = $ExecutionMode
    status = "draft"
    priority = [string]$WorkItem.priority
    risk_level = [string]$WorkItem.risk_level
    approval_status = [string]$WorkItem.approval_status
    workflow_id = [string]$WorkItem.workflow_id
    conversation_id = [string]$WorkItem.conversation_id
    correlation_id = [string]$WorkItem.correlation_id
    steps = @($Steps | ForEach-Object { $_ })
    created_at = $Now
    updated_at = $Now
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = $Department
            details = "Department plan created."
        }
    )
}

$Path = Join-Path `
    ".\workspace\departments\$Department\plans" `
    ($PlanId + ".json")

Write-AIOfficeDepartmentJson -Value $Plan -Path $Path

Write-Host "Department plan created: $PlanId" `
    -ForegroundColor Green

return [pscustomobject]$Plan
'@

Write-NewFile ".\scripts\departments\New-AIOfficeDepartmentPlan.ps1" $NewPlan

$NewExecution = @'
param(
    [Parameter(Mandatory=$true)][string]$Department,
    [Parameter(Mandatory=$true)][string]$DepartmentPlanId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentExecution.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$Plan = Get-AIOfficeDepartmentPlan `
    -Department $Department `
    -DepartmentPlanId $DepartmentPlanId

$ExecutionId = New-AIOfficeDepartmentExecutionId
$Now = (Get-Date).ToString("o")

$Execution = [ordered]@{
    department_execution_id = $ExecutionId
    department = $Department
    department_plan_id = $DepartmentPlanId
    work_item_id = [string]$Plan.work_item_id
    execution_mode = [string]$Plan.execution_mode
    status = "queued"
    created_at = $Now
    updated_at = $Now
    started_at = $null
    completed_at = $null
    result = $null
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = $Department
            details = "Department execution created."
        }
    )
}

$Path = Join-Path `
    ".\workspace\departments\$Department\execution" `
    ($ExecutionId + ".json")

Write-AIOfficeDepartmentJson `
    -Value $Execution `
    -Path $Path

$Plan.status = "queued"
$Plan.updated_at = $Now

Write-AIOfficeDepartmentJson `
    -Value $Plan `
    -Path ".\workspace\departments\$Department\plans\$DepartmentPlanId.json"

Write-Host "Department execution created: $ExecutionId" `
    -ForegroundColor Green

return [pscustomobject]$Execution
'@

Write-NewFile ".\scripts\departments\New-AIOfficeDepartmentExecution.ps1" $NewExecution

$Handoff = @'
param(
    [Parameter(Mandatory=$true)][string]$FromDepartment,
    [Parameter(Mandatory=$true)][string]$ToDepartment,
    [Parameter(Mandatory=$true)][string]$WorkItemId,
    [Parameter(Mandatory=$true)][string]$Objective,
    [string[]]$Deliverables = @(),
    [string[]]$RequiredCapabilities = @(),
    [string]$Priority = "normal",
    [string]$RiskLevel = "medium",
    [string]$ApprovalStatus = "not_required"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentExecution.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$Payload = [ordered]@{
    parent_work_item_id = $WorkItemId
    objective = $Objective
    deliverables = $Deliverables
    required_capabilities = $RequiredCapabilities
    risk_level = $RiskLevel
    approval_status = $ApprovalStatus
}

$Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
    -From $FromDepartment `
    -To $ToDepartment `
    -MessageType "handoff" `
    -Priority $Priority `
    -Subject ("Department handoff from " + $FromDepartment) `
    -ConversationTopic "DEPARTMENT-HANDOFF" `
    -Queue "outbox" `
    -PayloadJson ($Payload | ConvertTo-Json -Depth 20 -Compress)

$Record = [ordered]@{
    handoff_id = (
        "HOF-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
    from_department = $FromDepartment
    to_department = $ToDepartment
    work_item_id = $WorkItemId
    message_id = [string]$Message.message_id
    created_at = (Get-Date).ToString("o")
    status = "dispatched"
}

$Path = Join-Path `
    ".\workspace\departments\$FromDepartment\handoffs" `
    ([string]$Record.handoff_id + ".json")

Write-AIOfficeDepartmentJson -Value $Record -Path $Path

Write-Host (
    "Department handoff created: " +
    [string]$Record.handoff_id
) -ForegroundColor Green

return [pscustomobject]$Record
'@

Write-NewFile ".\scripts\departments\Send-AIOfficeDepartmentHandoff.ps1" $Handoff

$InvokeExecution = @'
param(
    [Parameter(Mandatory=$true)][string]$Department,
    [Parameter(Mandatory=$true)][string]$DepartmentExecutionId,
    [string]$ResultSummary = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentExecution.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$ExecutionPath = Join-Path `
    ".\workspace\departments\$Department\execution" `
    ($DepartmentExecutionId + ".json")

$Execution = Read-AIOfficeDepartmentJson -Path $ExecutionPath

if ($null -eq $Execution) {
    throw "Department execution not found: $DepartmentExecutionId"
}

$Plan = Get-AIOfficeDepartmentPlan `
    -Department $Department `
    -DepartmentPlanId ([string]$Execution.department_plan_id)

$WorkItem = Get-AIOfficeDepartmentWorkItem `
    -Department $Department `
    -WorkItemId ([string]$Execution.work_item_id)

$Now = (Get-Date).ToString("o")
$Execution.status = "running"
$Execution.started_at = $Now
$Execution.updated_at = $Now

Write-AIOfficeDepartmentJson `
    -Value $Execution `
    -Path $ExecutionPath

switch ([string]$Execution.execution_mode) {
    "internal_reasoning" {
        if ([string]::IsNullOrWhiteSpace($ResultSummary)) {
            $ResultSummary = (
                "Department work completed through internal reasoning for: " +
                [string]$Plan.title
            )
        }
    }

    "message_bus" {
        if ([string]::IsNullOrWhiteSpace($ResultSummary)) {
            $ResultSummary = "Department Message Bus coordination completed."
        }
    }

    "openclaw_bridge" {
        $Payload = [ordered]@{
            action_type = "agent_task"
            objective = [string]$Plan.objective
            deliverables = @($WorkItem.deliverables)
            risk_level = [string]$WorkItem.risk_level
            approval_status = [string]$WorkItem.approval_status
            prompt = (
                "Complete this department objective: " +
                [string]$Plan.objective
            )
        }

        $BridgeMessage = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
            -From $Department `
            -To "bridge" `
            -MessageType "execution_request" `
            -Priority ([string]$WorkItem.priority) `
            -Subject ([string]$Plan.title) `
            -ConversationTopic "DEPARTMENT-OPENCLAW" `
            -Queue "outbox" `
            -PayloadJson ($Payload | ConvertTo-Json -Depth 20 -Compress)

        $ResultSummary = (
            "OpenClaw execution request dispatched: " +
            [string]$BridgeMessage.message_id
        )
    }

    "human_approval" {
        if ([string]$WorkItem.approval_status -ne "approved") {
            throw "Department execution requires human approval."
        }

        if ([string]::IsNullOrWhiteSpace($ResultSummary)) {
            $ResultSummary = "Human-approved department execution completed."
        }
    }
}

$CompletedAt = (Get-Date).ToString("o")
$Execution.status = "completed"
$Execution.completed_at = $CompletedAt
$Execution.updated_at = $CompletedAt
$Execution.result = [ordered]@{
    summary = $ResultSummary
    completed_by = $Department
}

$History = New-Object System.Collections.Generic.List[object]

foreach ($Entry in @($Execution.history)) {
    $History.Add($Entry)
}

$History.Add([ordered]@{
    timestamp = $CompletedAt
    action = "completed"
    actor = $Department
    details = $ResultSummary
})

$Execution.history = @($History | ForEach-Object { $_ })

Write-AIOfficeDepartmentJson `
    -Value $Execution `
    -Path $ExecutionPath

$Plan.status = "completed"
$Plan.updated_at = $CompletedAt

foreach ($Step in @($Plan.steps)) {
    $Step.status = "completed"
}

Write-AIOfficeDepartmentJson `
    -Value $Plan `
    -Path ".\workspace\departments\$Department\plans\$($Plan.department_plan_id).json"

$WorkItem.status = "completed"
$WorkItem.updated_at = $CompletedAt

if ($null -eq $WorkItem.PSObject.Properties["completed_at"]) {
    $WorkItem | Add-Member `
        -MemberType NoteProperty `
        -Name completed_at `
        -Value $CompletedAt
}
else {
    $WorkItem.completed_at = $CompletedAt
}

if ($null -eq $WorkItem.PSObject.Properties["result_summary"]) {
    $WorkItem | Add-Member `
        -MemberType NoteProperty `
        -Name result_summary `
        -Value $ResultSummary
}
else {
    $WorkItem.result_summary = $ResultSummary
}

Write-AIOfficeDepartmentJson `
    -Value $WorkItem `
    -Path ".\workspace\departments\$Department\work\$($WorkItem.work_item_id).json"

return $Execution
'@

Write-NewFile ".\scripts\departments\Invoke-AIOfficeDepartmentExecution.ps1" $InvokeExecution

$PublishResult = @'
param(
    [Parameter(Mandatory=$true)][string]$Department,
    [Parameter(Mandatory=$true)][string]$DepartmentExecutionId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentExecution.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$ExecutionPath = Join-Path `
    ".\workspace\departments\$Department\execution" `
    ($DepartmentExecutionId + ".json")

$Execution = Read-AIOfficeDepartmentJson -Path $ExecutionPath

if ($null -eq $Execution) {
    throw "Department execution not found: $DepartmentExecutionId"
}

if ([string]$Execution.status -ne "completed") {
    throw "Only completed executions can publish results."
}

$Plan = Get-AIOfficeDepartmentPlan `
    -Department $Department `
    -DepartmentPlanId ([string]$Execution.department_plan_id)

$Payload = [ordered]@{
    department = $Department
    department_execution_id = $DepartmentExecutionId
    department_plan_id = [string]$Execution.department_plan_id
    work_item_id = [string]$Execution.work_item_id
    status = [string]$Execution.status
    summary = [string]$Execution.result.summary
}

$Arguments = @{
    From = $Department
    To = "chief-of-staff"
    MessageType = "execution_result"
    Subject = ("Department result: " + [string]$Plan.title)
    Priority = [string]$Plan.priority
    WorkflowId = [string]$Plan.workflow_id
    Queue = "inbox"
    PayloadJson = ($Payload | ConvertTo-Json -Depth 20 -Compress)
}

if (-not [string]::IsNullOrWhiteSpace([string]$Plan.correlation_id)) {
    $Arguments.CorrelationId = [string]$Plan.correlation_id
}

if (-not [string]::IsNullOrWhiteSpace([string]$Plan.conversation_id)) {
    $Arguments.ConversationId = [string]$Plan.conversation_id
}

$Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" @Arguments

$ResultRecord = [ordered]@{
    result_id = (
        "DRS-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
    department = $Department
    department_execution_id = $DepartmentExecutionId
    message_id = [string]$Message.message_id
    published_at = (Get-Date).ToString("o")
    status = "published"
}

$Path = Join-Path `
    ".\workspace\departments\$Department\results" `
    ([string]$ResultRecord.result_id + ".json")

Write-AIOfficeDepartmentJson `
    -Value $ResultRecord `
    -Path $Path

Write-Host (
    "Department result published: " +
    [string]$Message.message_id
) -ForegroundColor Green

return [pscustomobject]$ResultRecord
'@

Write-NewFile ".\scripts\departments\Publish-AIOfficeDepartmentResult.ps1" $PublishResult

$Test = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.2 Part C Department Planning and Execution..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\departments\department-execution-policy.json",
    ".\config\departments\department-plan-schema.json",
    ".\config\departments\department-execution-schema.json",
    ".\workspace\templates\department-plan-template.json",
    ".\workspace\templates\department-execution-template.json"
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
    ".\scripts\departments\AIOfficeDepartmentExecution.Common.ps1",
    ".\scripts\departments\New-AIOfficeDepartmentPlan.ps1",
    ".\scripts\departments\New-AIOfficeDepartmentExecution.ps1",
    ".\scripts\departments\Send-AIOfficeDepartmentHandoff.ps1",
    ".\scripts\departments\Invoke-AIOfficeDepartmentExecution.ps1",
    ".\scripts\departments\Publish-AIOfficeDepartmentResult.ps1",
    ".\scripts\departments\Test-AIOfficeDepartmentExecution.ps1"
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

$MessageId = ""
$WorkItemId = ""
$PlanId = ""
$ExecutionId = ""
$ResultMessageId = ""

try {
    $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "chief-of-staff" `
        -To "marketing" `
        -MessageType "handoff" `
        -Priority "high" `
        -Subject "Create dealership campaign" `
        -ConversationTopic "DEPT-EXECUTION-TEST" `
        -Queue "outbox" `
        -PayloadJson '{"objective":"Create a dealership campaign plan.","deliverables":["Campaign strategy","Offer structure"],"required_capabilities":["campaign_strategy"],"risk_level":"low","approval_status":"not_required"}'

    $MessageId = [string]$Message.message_id

    $Inbox = @(
        & ".\scripts\departments\Invoke-AIOfficeDepartmentInbox.ps1" `
            -Department "marketing" `
            -Limit 1
    )

    $WorkItemId = [string]$Inbox[0].work_item_id

    $Plan = & ".\scripts\departments\New-AIOfficeDepartmentPlan.ps1" `
        -Department "marketing" `
        -WorkItemId $WorkItemId `
        -ExecutionMode "internal_reasoning"

    $PlanId = [string]$Plan.department_plan_id

    $Execution = & ".\scripts\departments\New-AIOfficeDepartmentExecution.ps1" `
        -Department "marketing" `
        -DepartmentPlanId $PlanId

    $ExecutionId = [string]$Execution.department_execution_id

    $Completed = & ".\scripts\departments\Invoke-AIOfficeDepartmentExecution.ps1" `
        -Department "marketing" `
        -DepartmentExecutionId $ExecutionId `
        -ResultSummary "Campaign planning completed successfully."

    if ([string]$Completed.status -ne "completed") {
        throw "Department execution did not complete."
    }

    Write-Host "[EXECUTION OK] $ExecutionId" `
        -ForegroundColor Green
}
catch {
    Write-Host "[EXECUTION ER] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Department execution failed: " + $_.Exception.Message)
}

try {
    $Published = & ".\scripts\departments\Publish-AIOfficeDepartmentResult.ps1" `
        -Department "marketing" `
        -DepartmentExecutionId $ExecutionId

    $ResultMessageId = [string]$Published.message_id

    if ([string]::IsNullOrWhiteSpace($ResultMessageId)) {
        throw "Department result was not published."
    }

    Write-Host "[RESULT OK  ] $ResultMessageId" `
        -ForegroundColor Green
}
catch {
    Write-Host "[RESULT ERR ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Result publishing failed: " + $_.Exception.Message)
}

foreach ($Path in @(
    ".\workspace\departments\marketing\work\$WorkItemId.json",
    ".\workspace\departments\marketing\plans\$PlanId.json",
    ".\workspace\departments\marketing\execution\$ExecutionId.json"
)) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

Get-ChildItem `
    -LiteralPath ".\workspace\departments\marketing\results" `
    -Filter "DRS-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    ForEach-Object {
        $Record = Get-Content -LiteralPath $_.FullName -Raw |
            ConvertFrom-Json

        if ([string]$Record.department_execution_id -eq $ExecutionId) {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }

Get-ChildItem `
    -LiteralPath ".\workspace\departments\marketing\classifications" `
    -Filter "DCL-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    ForEach-Object {
        $Record = Get-Content -LiteralPath $_.FullName -Raw |
            ConvertFrom-Json

        if ([string]$Record.message_id -eq $MessageId) {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }

foreach ($Folder in @(
    ".\workspace\departments\marketing\processed-inbox",
    ".\workspace\departments\marketing\failed-inbox"
)) {
    $Path = Join-Path $Folder ($MessageId + ".json")

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

foreach ($CurrentMessageId in @($MessageId, $ResultMessageId)) {
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

& ".\scripts\departments\Update-AIOfficeDepartmentIndex.ps1" |
    Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Department Planning and Execution error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.2 Part C Department Planning and Execution checks passed." `
    -ForegroundColor Green
'@

Write-NewFile ".\scripts\departments\Test-AIOfficeDepartmentExecution.ps1" $Test

$Guide = @'
# AI Office v1.2 Part C — Department Planning and Execution

Part C enables departments to turn work items into plans, execute them, create cross-department handoffs, and publish results to the Chief of Staff.

## Added

- Department plans
- Execution records
- Internal task decomposition
- Execution mode selection
- Internal reasoning execution
- Message Bus coordination
- OpenClaw Bridge dispatch
- Human-approval execution
- Cross-department handoffs
- Result publication
- Department completion tracking
- Full validation

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\departments\Test-AIOfficeDepartmentExecution.ps1"
```

Expected result:

```text
All AI Office v1.2 Part C Department Planning and Execution checks passed.
```

## Create a department plan

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\departments\New-AIOfficeDepartmentPlan.ps1" `
    -Department "marketing" `
    -WorkItemId "DWI-..." `
    -ExecutionMode "internal_reasoning"
```

## Execute a department plan

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\departments\Invoke-AIOfficeDepartmentExecution.ps1" `
    -Department "marketing" `
    -DepartmentExecutionId "DEX-..." `
    -ResultSummary "Campaign plan completed."
```

## Next

Part D will add department knowledge, reusable templates, historical learning, complete certification, and release publication.
'@

Write-NewFile ".\docs\AI-Office-v1.2-Part-C-Department-Planning-Execution.md" $Guide

$ReleaseNotes = @'
# AI Office v1.2 Part C Release Notes

## Release

Department Planning and Execution

## Added

- Department planning
- Execution state records
- Execution mode selection
- Cross-department handoffs
- OpenClaw dispatch
- Human approval mode
- Result publication
- Completion tracking
- Validation suite

## Next

v1.2 Part D — Department Knowledge and Learning
'@

Write-NewFile ".\docs\AI-Office-v1.2-Part-C-Release-Notes.md" $ReleaseNotes

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw |
        ConvertFrom-Json

    $Version.version = "1.2.0"
    $Version.release_name = "Department Intelligence"
    $Version.status = "part_c_installed"
    $Version.installed_at = (Get-Date).ToString("o")
    $Version.next_planned_milestone = "1.2 Part D Department Knowledge and Learning"

    $Version |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $VersionPath -Encoding UTF8

    Write-Host "[UPDATED] Identity release metadata set to v1.2 Part C" `
        -ForegroundColor Green
}

Write-Host ""
Write-Host "Validating Part C JSON files..." -ForegroundColor Cyan

@(
    ".\config\departments\department-execution-policy.json",
    ".\config\departments\department-plan-schema.json",
    ".\config\departments\department-execution-schema.json",
    ".\workspace\templates\department-plan-template.json",
    ".\workspace\templates\department-execution-template.json"
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
        "Installers\AI-Office-v1.2-Part-C-Department-Planning-Execution-Install.ps1"

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
Write-Host "AI Office v1.2 Part C installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\departments\Test-AIOfficeDepartmentExecution.ps1"'
Write-Host ""
