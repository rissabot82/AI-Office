# ============================================================
# AI Office v1.2 - Part D
# Department Knowledge, Learning, Certification, and Release
# Repository: E:\AI\AI-Office
# Requires: AI Office v1.2 Parts A, B, and C
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
    ".\config\departments\department-execution-policy.json",
    ".\scripts\departments\AIOfficeDepartments.Common.ps1",
    ".\scripts\departments\AIOfficeDepartmentInbox.Common.ps1",
    ".\scripts\departments\AIOfficeDepartmentExecution.Common.ps1",
    ".\scripts\departments\Invoke-AIOfficeDepartmentInbox.ps1",
    ".\scripts\departments\Invoke-AIOfficeDepartmentExecution.ps1",
    ".\scripts\departments\Publish-AIOfficeDepartmentResult.ps1",
    ".\scripts\messaging\New-AIOfficeMessage.ps1"
)

foreach ($RequiredPath in $RequiredPrevious) {
    if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
        throw "AI Office v1.2 Parts A, B, and C are required. Missing: $RequiredPath"
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
        ".\workspace\departments\$Department\knowledge\lessons",
        ".\workspace\departments\$Department\knowledge\templates",
        ".\workspace\departments\$Department\knowledge\playbooks",
        ".\workspace\departments\$Department\knowledge\decisions",
        ".\workspace\departments\$Department\knowledge\metrics",
        ".\workspace\departments\$Department\learning"
    ) | ForEach-Object { Ensure-Directory $_ }
}

@(
    ".\workspace\departments\certification",
    ".\workspace\departments\releases"
) | ForEach-Object { Ensure-Directory $_ }

$Now = (Get-Date).ToString("o")

$KnowledgePolicy = @"
{
  "schema_version": "1.0.0",
  "version": "1.2.0",
  "part": "D",
  "knowledge_types": [
    "lesson",
    "template",
    "playbook",
    "decision",
    "metric"
  ],
  "capture": {
    "allow_manual_capture": true,
    "allow_result_capture": true,
    "require_source": true,
    "require_department": true,
    "require_title": true,
    "require_summary": true
  },
  "reuse": {
    "enabled": true,
    "minimum_confidence": 0.50,
    "maximum_results": 25,
    "prefer_same_department": true
  },
  "learning": {
    "record_success": true,
    "record_failure": true,
    "record_revision": true,
    "record_approval": true,
    "calculate_reuse_count": true,
    "calculate_success_rate": true
  },
  "retention": {
    "archive_instead_of_delete": true,
    "retain_history": true
  },
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\departments\department-knowledge-policy.json" $KnowledgePolicy

$KnowledgeSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/department-knowledge-item-schema.json",
  "title": "AI Office Department Knowledge Item",
  "type": "object",
  "required": [
    "knowledge_id",
    "department",
    "knowledge_type",
    "title",
    "summary",
    "content",
    "source",
    "confidence",
    "created_at",
    "updated_at",
    "reuse_count",
    "history"
  ]
}
'@

Write-NewFile ".\config\departments\department-knowledge-item-schema.json" $KnowledgeSchema

$LearningSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/department-learning-record-schema.json",
  "title": "AI Office Department Learning Record",
  "type": "object",
  "required": [
    "learning_id",
    "department",
    "event_type",
    "source_id",
    "outcome",
    "summary",
    "created_at"
  ]
}
'@

Write-NewFile ".\config\departments\department-learning-record-schema.json" $LearningSchema

$ReleaseManifest = @"
{
  "product": "AI Office",
  "component": "Department Intelligence",
  "version": "1.2.0",
  "release_name": "Department Intelligence",
  "release_status": "installed",
  "installed_at": "$Now",
  "parts": {
    "A": "Department Intelligence Architecture",
    "B": "Department Inbox and Work Intake",
    "C": "Department Planning and Execution",
    "D": "Department Knowledge and Learning"
  },
  "departments": [
    "marketing",
    "creative",
    "website",
    "analytics",
    "finance",
    "business",
    "side-hustles",
    "youtube",
    "personal-assistant"
  ],
  "capabilities": [
    "department_profiles",
    "capability_registries",
    "department_inboxes",
    "work_intake",
    "capability_matching",
    "department_planning",
    "execution_modes",
    "cross_department_handoffs",
    "openclaw_dispatch",
    "result_publication",
    "knowledge_capture",
    "knowledge_search",
    "learning_records",
    "reuse_metrics",
    "department_reports",
    "certification"
  ],
  "next_planned_milestone": "1.3 Long-Term Memory"
}
"@

Write-NewFile ".\config\departments\release-manifest.json" $ReleaseManifest

$KnowledgeTemplate = @'
{
  "knowledge_id": "DKI-YYYYMMDD-HHMMSS-ABC123",
  "department": "marketing",
  "knowledge_type": "lesson",
  "title": "",
  "summary": "",
  "content": {},
  "source": {},
  "confidence": 0.75,
  "created_at": "",
  "updated_at": "",
  "reuse_count": 0,
  "success_count": 0,
  "failure_count": 0,
  "history": []
}
'@

Write-NewFile ".\workspace\templates\department-knowledge-item-template.json" $KnowledgeTemplate

$LearningTemplate = @'
{
  "learning_id": "DLR-YYYYMMDD-HHMMSS-ABC123",
  "department": "marketing",
  "event_type": "success",
  "source_id": "",
  "outcome": "successful",
  "summary": "",
  "created_at": ""
}
'@

Write-NewFile ".\workspace\templates\department-learning-record-template.json" $LearningTemplate

$Common = @'
. (Join-Path $PSScriptRoot "AIOfficeDepartments.Common.ps1")

function Get-AIOfficeDepartmentKnowledgePolicy {
    $Root = Get-AIOfficeDepartmentRoot

    return Read-AIOfficeDepartmentJson `
        -Path (Join-Path $Root "config\departments\department-knowledge-policy.json")
}

function New-AIOfficeDepartmentKnowledgeId {
    return (
        "DKI-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeDepartmentLearningId {
    return (
        "DLR-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeDepartmentKnowledgeFolder {
    param(
        [Parameter(Mandatory=$true)][string]$Department,
        [Parameter(Mandatory=$true)][string]$KnowledgeType
    )

    $Root = Get-AIOfficeDepartmentRoot

    $FolderName = switch ($KnowledgeType) {
        "lesson" { "lessons" }
        "template" { "templates" }
        "playbook" { "playbooks" }
        "decision" { "decisions" }
        "metric" { "metrics" }
        default { "lessons" }
    }

    return Join-Path `
        $Root `
        ("workspace\departments\" + $Department + "\knowledge\" + $FolderName)
}

function Get-AIOfficeDepartmentKnowledgeItem {
    param(
        [Parameter(Mandatory=$true)][string]$Department,
        [Parameter(Mandatory=$true)][string]$KnowledgeId
    )

    $Base = Join-Path `
        (Get-AIOfficeDepartmentRoot) `
        ("workspace\departments\" + $Department + "\knowledge")

    foreach ($Folder in @(
        "lessons",
        "templates",
        "playbooks",
        "decisions",
        "metrics"
    )) {
        $Path = Join-Path $Base ($Folder + "\" + $KnowledgeId + ".json")
        $Record = Read-AIOfficeDepartmentJson -Path $Path

        if ($null -ne $Record) {
            return $Record
        }
    }

    throw "Department knowledge item not found: $KnowledgeId"
}
'@

Write-NewFile ".\scripts\departments\AIOfficeDepartmentKnowledge.Common.ps1" $Common

$NewKnowledge = @'
param(
    [Parameter(Mandatory=$true)][string]$Department,
    [ValidateSet("lesson","template","playbook","decision","metric")]
    [string]$KnowledgeType,
    [Parameter(Mandatory=$true)][string]$Title,
    [Parameter(Mandatory=$true)][string]$Summary,
    [Parameter(Mandatory=$true)][string]$ContentJson,
    [Parameter(Mandatory=$true)][string]$SourceJson,
    [ValidateRange(0.0,1.0)]
    [double]$Confidence = 0.75
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentKnowledge.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

Get-AIOfficeDepartmentProfile -Department $Department | Out-Null

try {
    $Content = $ContentJson | ConvertFrom-Json
}
catch {
    throw "ContentJson is invalid: $($_.Exception.Message)"
}

try {
    $Source = $SourceJson | ConvertFrom-Json
}
catch {
    throw "SourceJson is invalid: $($_.Exception.Message)"
}

$KnowledgeId = New-AIOfficeDepartmentKnowledgeId
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    knowledge_id = $KnowledgeId
    department = $Department
    knowledge_type = $KnowledgeType
    title = $Title
    summary = $Summary
    content = $Content
    source = $Source
    confidence = $Confidence
    created_at = $Now
    updated_at = $Now
    reuse_count = 0
    success_count = 0
    failure_count = 0
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = $Department
            details = "Department knowledge item created."
        }
    )
}

$Folder = Get-AIOfficeDepartmentKnowledgeFolder `
    -Department $Department `
    -KnowledgeType $KnowledgeType

$Path = Join-Path $Folder ($KnowledgeId + ".json")

Write-AIOfficeDepartmentJson -Value $Record -Path $Path

& ".\scripts\departments\Update-AIOfficeDepartmentIndex.ps1" |
    Out-Null

Write-Host "Department knowledge created: $KnowledgeId" `
    -ForegroundColor Green

return [pscustomobject]$Record
'@

Write-NewFile ".\scripts\departments\New-AIOfficeDepartmentKnowledge.ps1" $NewKnowledge

$SearchKnowledge = @'
param(
    [Parameter(Mandatory=$true)][string]$Department,
    [string]$Query = "",
    [string]$KnowledgeType = "",
    [double]$MinimumConfidence = 0.0,
    [int]$Limit = 25
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentKnowledge.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$Results = New-Object System.Collections.Generic.List[object]
$Base = ".\workspace\departments\$Department\knowledge"

foreach ($Folder in @(
    "lessons",
    "templates",
    "playbooks",
    "decisions",
    "metrics"
)) {
    foreach ($File in @(
        Get-ChildItem `
            -LiteralPath "$Base\$Folder" `
            -Filter "DKI-*.json" `
            -File `
            -ErrorAction SilentlyContinue
    )) {
        $Record = Read-AIOfficeDepartmentJson -Path $File.FullName

        if ($null -eq $Record) {
            continue
        }

        if ($KnowledgeType -and
            [string]$Record.knowledge_type -ne $KnowledgeType) {
            continue
        }

        if ([double]$Record.confidence -lt $MinimumConfidence) {
            continue
        }

        if ($Query) {
            $SearchText = (
                [string]$Record.title +
                " " +
                [string]$Record.summary +
                " " +
                ($Record.content | ConvertTo-Json -Depth 20 -Compress)
            ).ToLowerInvariant()

            if (-not $SearchText.Contains($Query.ToLowerInvariant())) {
                continue
            }
        }

        $Results.Add([pscustomobject]@{
            knowledge_id = [string]$Record.knowledge_id
            department = [string]$Record.department
            knowledge_type = [string]$Record.knowledge_type
            title = [string]$Record.title
            summary = [string]$Record.summary
            confidence = [double]$Record.confidence
            reuse_count = [int]$Record.reuse_count
            success_count = [int]$Record.success_count
            failure_count = [int]$Record.failure_count
            updated_at = [string]$Record.updated_at
        })
    }
}

return @(
    $Results |
        Sort-Object confidence, reuse_count, updated_at -Descending |
        Select-Object -First $Limit
)
'@

Write-NewFile ".\scripts\departments\Search-AIOfficeDepartmentKnowledge.ps1" $SearchKnowledge

$RecordLearning = @'
param(
    [Parameter(Mandatory=$true)][string]$Department,
    [ValidateSet("success","failure","revision","approval","reuse")]
    [string]$EventType,
    [Parameter(Mandatory=$true)][string]$SourceId,
    [Parameter(Mandatory=$true)][string]$Summary,
    [string]$KnowledgeId = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentKnowledge.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$LearningId = New-AIOfficeDepartmentLearningId
$Now = (Get-Date).ToString("o")

$Outcome = switch ($EventType) {
    "success" { "successful" }
    "failure" { "failed" }
    "revision" { "revised" }
    "approval" { "approved" }
    "reuse" { "reused" }
}

$Record = [ordered]@{
    learning_id = $LearningId
    department = $Department
    event_type = $EventType
    source_id = $SourceId
    knowledge_id = $KnowledgeId
    outcome = $Outcome
    summary = $Summary
    created_at = $Now
}

$Path = Join-Path `
    ".\workspace\departments\$Department\learning" `
    ($LearningId + ".json")

Write-AIOfficeDepartmentJson -Value $Record -Path $Path

if (-not [string]::IsNullOrWhiteSpace($KnowledgeId)) {
    $Knowledge = Get-AIOfficeDepartmentKnowledgeItem `
        -Department $Department `
        -KnowledgeId $KnowledgeId

    switch ($EventType) {
        "success" { $Knowledge.success_count = [int]$Knowledge.success_count + 1 }
        "failure" { $Knowledge.failure_count = [int]$Knowledge.failure_count + 1 }
        "reuse" { $Knowledge.reuse_count = [int]$Knowledge.reuse_count + 1 }
    }

    $Knowledge.updated_at = $Now

    $History = New-Object System.Collections.Generic.List[object]

    foreach ($Entry in @($Knowledge.history)) {
        $History.Add($Entry)
    }

    $History.Add([ordered]@{
        timestamp = $Now
        action = $EventType
        actor = $Department
        details = $Summary
    })

    $Knowledge.history = @($History | ForEach-Object { $_ })

    $Folder = Get-AIOfficeDepartmentKnowledgeFolder `
        -Department $Department `
        -KnowledgeType ([string]$Knowledge.knowledge_type)

    Write-AIOfficeDepartmentJson `
        -Value $Knowledge `
        -Path (Join-Path $Folder ($KnowledgeId + ".json"))
}

Write-Host "Department learning recorded: $LearningId" `
    -ForegroundColor Green

return [pscustomobject]$Record
'@

Write-NewFile ".\scripts\departments\Add-AIOfficeDepartmentLearning.ps1" $RecordLearning

$CaptureFromExecution = @'
param(
    [Parameter(Mandatory=$true)][string]$Department,
    [Parameter(Mandatory=$true)][string]$DepartmentExecutionId,
    [ValidateSet("lesson","template","playbook","decision","metric")]
    [string]$KnowledgeType = "lesson",
    [double]$Confidence = 0.80
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentKnowledge.Common.ps1")

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
    throw "Only completed department executions can create knowledge."
}

$Plan = & ".\scripts\departments\AIOfficeDepartmentExecution.Common.ps1"
$PlanRecord = Get-AIOfficeDepartmentPlan `
    -Department $Department `
    -DepartmentPlanId ([string]$Execution.department_plan_id)

$Content = [ordered]@{
    objective = [string]$PlanRecord.objective
    execution_mode = [string]$Execution.execution_mode
    steps = @($PlanRecord.steps)
    result = $Execution.result
}

$Source = [ordered]@{
    type = "department_execution"
    department_execution_id = $DepartmentExecutionId
    department_plan_id = [string]$Execution.department_plan_id
    work_item_id = [string]$Execution.work_item_id
}

$Knowledge = & ".\scripts\departments\New-AIOfficeDepartmentKnowledge.ps1" `
    -Department $Department `
    -KnowledgeType $KnowledgeType `
    -Title ([string]$PlanRecord.title) `
    -Summary ([string]$Execution.result.summary) `
    -ContentJson ($Content | ConvertTo-Json -Depth 30 -Compress) `
    -SourceJson ($Source | ConvertTo-Json -Depth 20 -Compress) `
    -Confidence $Confidence

& ".\scripts\departments\Add-AIOfficeDepartmentLearning.ps1" `
    -Department $Department `
    -EventType "success" `
    -SourceId $DepartmentExecutionId `
    -Summary "Knowledge captured from successful department execution." `
    -KnowledgeId ([string]$Knowledge.knowledge_id) |
    Out-Null

return $Knowledge
'@

# Replace the accidental script invocation with correct dot-sourcing.
$CaptureFromExecution = $CaptureFromExecution.Replace(
    '$Plan = & ".\scripts\departments\AIOfficeDepartmentExecution.Common.ps1"',
    '. ".\scripts\departments\AIOfficeDepartmentExecution.Common.ps1"'
)

Write-NewFile ".\scripts\departments\Convert-AIOfficeDepartmentExecutionToKnowledge.ps1" $CaptureFromExecution

$DepartmentReport = @'
param(
    [Parameter(Mandatory=$true)][string]$Department
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentKnowledge.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$Profile = Get-AIOfficeDepartmentProfile -Department $Department
$Index = Read-AIOfficeDepartmentJson `
    -Path ".\workspace\departments\$Department\department-index.json"

$Knowledge = @(
    & ".\scripts\departments\Search-AIOfficeDepartmentKnowledge.ps1" `
        -Department $Department `
        -Limit 1000
)

$LearningFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\departments\$Department\learning" `
        -Filter "DLR-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$Learning = @(
    foreach ($File in $LearningFiles) {
        Read-AIOfficeDepartmentJson -Path $File.FullName
    }
)

$SuccessCount = @(
    $Learning | Where-Object { $_.event_type -eq "success" }
).Count

$FailureCount = @(
    $Learning | Where-Object { $_.event_type -eq "failure" }
).Count

$TotalOutcomes = $SuccessCount + $FailureCount
$SuccessRate = if ($TotalOutcomes -gt 0) {
    [math]::Round(($SuccessCount / $TotalOutcomes) * 100, 2)
}
else {
    0
}

$Report = [ordered]@{
    report_id = (
        "DPR-" +
        $Department.ToUpperInvariant().Replace("-", "_") +
        "-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss")
    )
    department = $Department
    department_name = [string]$Profile.name
    generated_at = (Get-Date).ToString("o")
    status = [string]$Profile.status
    inbox_count = [int]$Index.inbox_count
    plan_count = [int]$Index.plan_count
    active_work_count = [int]$Index.active_work_count
    knowledge_item_count = $Knowledge.Count
    learning_event_count = $Learning.Count
    success_count = $SuccessCount
    failure_count = $FailureCount
    success_rate = $SuccessRate
    knowledge = $Knowledge
}

$Path = Join-Path `
    ".\workspace\departments\$Department\reports" `
    ([string]$Report.report_id + ".json")

Write-AIOfficeDepartmentJson -Value $Report -Path $Path

Write-Host "Department report created: $($Report.report_id)" `
    -ForegroundColor Green

return [pscustomobject]$Report
'@

Write-NewFile ".\scripts\departments\New-AIOfficeDepartmentReport.ps1" $DepartmentReport

$Certify = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentKnowledge.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$Checks = New-Object System.Collections.Generic.List[object]

function Add-DepartmentCheck {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Details
    )

    $Checks.Add([ordered]@{
        name = $Name
        passed = $Passed
        details = $Details
    })
}

$JsonFiles = @(
    ".\config\departments\department-intelligence-policy.json",
    ".\config\departments\department-inbox-policy.json",
    ".\config\departments\department-execution-policy.json",
    ".\config\departments\department-knowledge-policy.json",
    ".\config\departments\release-manifest.json"
)

foreach ($Path in $JsonFiles) {
    try {
        Get-Content -LiteralPath $Path -Raw |
            ConvertFrom-Json |
            Out-Null

        Add-DepartmentCheck `
            -Name ("Valid JSON: " + $Path) `
            -Passed $true `
            -Details "Parsed successfully."
    }
    catch {
        Add-DepartmentCheck `
            -Name ("Valid JSON: " + $Path) `
            -Passed $false `
            -Details $_.Exception.Message
    }
}

$Scripts = @(
    ".\scripts\departments\AIOfficeDepartments.Common.ps1",
    ".\scripts\departments\AIOfficeDepartmentInbox.Common.ps1",
    ".\scripts\departments\AIOfficeDepartmentExecution.Common.ps1",
    ".\scripts\departments\AIOfficeDepartmentKnowledge.Common.ps1",
    ".\scripts\departments\New-AIOfficeDepartmentWorkItem.ps1",
    ".\scripts\departments\New-AIOfficeDepartmentPlan.ps1",
    ".\scripts\departments\New-AIOfficeDepartmentExecution.ps1",
    ".\scripts\departments\Invoke-AIOfficeDepartmentExecution.ps1",
    ".\scripts\departments\Publish-AIOfficeDepartmentResult.ps1",
    ".\scripts\departments\New-AIOfficeDepartmentKnowledge.ps1",
    ".\scripts\departments\Search-AIOfficeDepartmentKnowledge.ps1",
    ".\scripts\departments\Add-AIOfficeDepartmentLearning.ps1",
    ".\scripts\departments\Convert-AIOfficeDepartmentExecutionToKnowledge.ps1",
    ".\scripts\departments\New-AIOfficeDepartmentReport.ps1",
    ".\scripts\departments\Certify-AIOfficeDepartmentIntelligence.ps1",
    ".\scripts\departments\Test-AIOfficeDepartmentIntelligence.ps1",
    ".\scripts\departments\Publish-AIOfficeDepartmentIntelligenceRelease.ps1"
)

foreach ($Path in $Scripts) {
    $Exists = Test-Path -LiteralPath $Path -PathType Leaf

    Add-DepartmentCheck `
        -Name ("Script exists: " + $Path) `
        -Passed $Exists `
        -Details $(if ($Exists) { "Found." } else { "Missing." })
}

$MessageId = ""
$WorkItemId = ""
$PlanId = ""
$ExecutionId = ""
$ResultMessageId = ""
$KnowledgeId = ""
$LearningId = ""

try {
    $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "chief-of-staff" `
        -To "marketing" `
        -MessageType "handoff" `
        -Priority "high" `
        -Subject "Department Intelligence certification" `
        -ConversationTopic "DEPARTMENT-CERTIFICATION" `
        -Queue "outbox" `
        -PayloadJson '{"objective":"Create a reusable dealership campaign lesson.","deliverables":["Campaign strategy","Reusable lesson"],"required_capabilities":["campaign_strategy"],"risk_level":"low","approval_status":"not_required"}'

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

    $Execution = & ".\scripts\departments\Invoke-AIOfficeDepartmentExecution.ps1" `
        -Department "marketing" `
        -DepartmentExecutionId $ExecutionId `
        -ResultSummary "Reusable campaign planning lesson completed."

    $Published = & ".\scripts\departments\Publish-AIOfficeDepartmentResult.ps1" `
        -Department "marketing" `
        -DepartmentExecutionId $ExecutionId

    $ResultMessageId = [string]$Published.message_id

    Add-DepartmentCheck `
        -Name "Inbox through execution and result" `
        -Passed (
            [string]$Execution.status -eq "completed" -and
            -not [string]::IsNullOrWhiteSpace($ResultMessageId)
        ) `
        -Details (
            $ExecutionId +
            " | result " +
            $ResultMessageId
        )

    $Knowledge = & `
        ".\scripts\departments\Convert-AIOfficeDepartmentExecutionToKnowledge.ps1" `
        -Department "marketing" `
        -DepartmentExecutionId $ExecutionId `
        -KnowledgeType "lesson" `
        -Confidence 0.90

    $KnowledgeId = [string]$Knowledge.knowledge_id

    Add-DepartmentCheck `
        -Name "Execution to knowledge capture" `
        -Passed (-not [string]::IsNullOrWhiteSpace($KnowledgeId)) `
        -Details $KnowledgeId

    $Search = @(
        & ".\scripts\departments\Search-AIOfficeDepartmentKnowledge.ps1" `
            -Department "marketing" `
            -Query "campaign" `
            -MinimumConfidence 0.50
    )

    Add-DepartmentCheck `
        -Name "Department knowledge search" `
        -Passed ($Search.Count -gt 0) `
        -Details ($Search.Count.ToString() + " result(s)")

    $Learning = & ".\scripts\departments\Add-AIOfficeDepartmentLearning.ps1" `
        -Department "marketing" `
        -EventType "reuse" `
        -SourceId $WorkItemId `
        -Summary "Certification knowledge item reused." `
        -KnowledgeId $KnowledgeId

    $LearningId = [string]$Learning.learning_id

    Add-DepartmentCheck `
        -Name "Department learning record" `
        -Passed (-not [string]::IsNullOrWhiteSpace($LearningId)) `
        -Details $LearningId

    $Report = & ".\scripts\departments\New-AIOfficeDepartmentReport.ps1" `
        -Department "marketing"

    Add-DepartmentCheck `
        -Name "Department report generation" `
        -Passed ($null -ne $Report) `
        -Details ([string]$Report.report_id)
}
catch {
    Add-DepartmentCheck `
        -Name "Offline end-to-end Department Intelligence workflow" `
        -Passed $false `
        -Details $_.Exception.Message
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

foreach ($Path in @(
    ".\workspace\departments\marketing\work\$WorkItemId.json",
    ".\workspace\departments\marketing\plans\$PlanId.json",
    ".\workspace\departments\marketing\execution\$ExecutionId.json"
)) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
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

Get-ChildItem `
    -LiteralPath ".\workspace\departments\marketing\classifications" `
    -Filter "DCL-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    ForEach-Object {
        $Record = Read-AIOfficeDepartmentJson -Path $_.FullName

        if ($null -ne $Record -and
            [string]$Record.message_id -eq $MessageId) {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }

Get-ChildItem `
    -LiteralPath ".\workspace\departments\marketing\results" `
    -Filter "DRS-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    ForEach-Object {
        $Record = Read-AIOfficeDepartmentJson -Path $_.FullName

        if ($null -ne $Record -and
            [string]$Record.department_execution_id -eq $ExecutionId) {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }

foreach ($Folder in @(
    "lessons",
    "templates",
    "playbooks",
    "decisions",
    "metrics"
)) {
    $Path = ".\workspace\departments\marketing\knowledge\$Folder\$KnowledgeId.json"

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

if ($LearningId) {
    $Path = ".\workspace\departments\marketing\learning\$LearningId.json"

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

Get-ChildItem `
    -LiteralPath ".\workspace\departments\marketing\learning" `
    -Filter "DLR-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    ForEach-Object {
        $Record = Read-AIOfficeDepartmentJson -Path $_.FullName

        if ($null -ne $Record -and
            [string]$Record.knowledge_id -eq $KnowledgeId) {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
    Out-Null

& ".\scripts\departments\Update-AIOfficeDepartmentIndex.ps1" |
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
    "CERT-DEPT-" +
    (Get-Date).ToString("yyyyMMdd-HHmmss")
)

$Certification = [ordered]@{
    certification_id = $CertificationId
    version = "1.2.0"
    certified_at = (Get-Date).ToString("o")
    status = $Status
    passed_checks = $PassedCount
    failed_checks = $FailedCount
    checks = @($Checks | ForEach-Object { $_ })
}

$Path = Join-Path `
    ".\workspace\departments\certification" `
    ($CertificationId + ".json")

Write-AIOfficeDepartmentJson `
    -Value $Certification `
    -Path $Path

Write-Host (
    "Department Intelligence certification: " +
    $Status +
    " | " +
    $PassedCount.ToString() +
    " passed, " +
    $FailedCount.ToString() +
    " failed"
) -ForegroundColor $(if ($FailedCount -eq 0) { "Green" } else { "Red" })

return [pscustomobject]$Certification
'@

Write-NewFile ".\scripts\departments\Certify-AIOfficeDepartmentIntelligence.ps1" $Certify

$CompleteTest = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.2 Department Intelligence..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

function Invoke-DepartmentTest {
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

Invoke-DepartmentTest `
    -Name "Part A Department Architecture" `
    -Path ".\scripts\departments\Test-AIOfficeDepartmentArchitecture.ps1"

Invoke-DepartmentTest `
    -Name "Part B Department Inbox" `
    -Path ".\scripts\departments\Test-AIOfficeDepartmentInbox.ps1"

Invoke-DepartmentTest `
    -Name "Part C Department Execution" `
    -Path ".\scripts\departments\Test-AIOfficeDepartmentExecution.ps1"

try {
    $Certification = & `
        ".\scripts\departments\Certify-AIOfficeDepartmentIntelligence.ps1"

    if ($null -eq $Certification -or
        [string]$Certification.status -ne "certified" -or
        [int]$Certification.failed_checks -ne 0) {
        throw "Department Intelligence certification failed."
    }

    Write-Host (
        "[PASS] Department Intelligence certification: " +
        [string]$Certification.certification_id
    ) -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Department Intelligence certification" `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Department Intelligence certification: " + $_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Department Intelligence error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.2 Department Intelligence checks passed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "AI Office v1.2 Department Intelligence is operational." `
    -ForegroundColor Cyan
'@

Write-NewFile ".\scripts\departments\Test-AIOfficeDepartmentIntelligence.ps1" $CompleteTest

$PublishRelease = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentKnowledge.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$CertificationFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\departments\certification" `
        -Filter "CERT-DEPT-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending
)

if ($CertificationFiles.Count -lt 1) {
    throw "No Department Intelligence certification record exists."
}

$Certification = Read-AIOfficeDepartmentJson `
    -Path $CertificationFiles[0].FullName

if ($null -eq $Certification -or
    [string]$Certification.status -ne "certified") {
    throw "Latest Department Intelligence certification did not pass."
}

$ManifestPath = ".\config\departments\release-manifest.json"
$Manifest = Read-AIOfficeDepartmentJson -Path $ManifestPath

if ($null -eq $Manifest) {
    throw "Department Intelligence release manifest could not be loaded."
}

$ReleasedAt = (Get-Date).ToString("o")
$Manifest.release_status = "released"
$Manifest.released_at = $ReleasedAt
$Manifest.certification_id = [string]$Certification.certification_id

Write-AIOfficeDepartmentJson `
    -Value $Manifest `
    -Path $ManifestPath

$ReleaseRecord = [ordered]@{
    product = "AI Office"
    component = "Department Intelligence"
    version = "1.2.0"
    released_at = $ReleasedAt
    status = "released"
    certification_id = [string]$Certification.certification_id
    next_milestone = "1.3 Long-Term Memory"
}

$ReleasePath = Join-Path `
    ".\workspace\departments\releases" `
    ("AI-Office-v1.2-" + (Get-Date).ToString("yyyyMMdd-HHmmss") + ".json")

Write-AIOfficeDepartmentJson `
    -Value $ReleaseRecord `
    -Path $ReleasePath

$IdentityPath = ".\config\identity\office.json"

if (Test-Path -LiteralPath $IdentityPath -PathType Leaf) {
    $Identity = Read-AIOfficeDepartmentJson -Path $IdentityPath
    $Identity.version = "1.2.0"
    $Identity.codename = "Department Intelligence"
    $Identity.updated_at = $ReleasedAt

    Write-AIOfficeDepartmentJson `
        -Value $Identity `
        -Path $IdentityPath
}

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Read-AIOfficeDepartmentJson -Path $VersionPath
    $Version.version = "1.2.0"
    $Version.release_name = "Department Intelligence"
    $Version.status = "released"
    $Version.installed_at = $ReleasedAt
    $Version.previous_version = "1.1.4"
    $Version.next_planned_milestone = "1.3 Long-Term Memory"

    Write-AIOfficeDepartmentJson `
        -Value $Version `
        -Path $VersionPath
}

Write-Host (
    "AI Office v1.2 Department Intelligence release recorded: " +
    [string]$Certification.certification_id
) -ForegroundColor Green

return [pscustomobject]$ReleaseRecord
'@

Write-NewFile ".\scripts\departments\Publish-AIOfficeDepartmentIntelligenceRelease.ps1" $PublishRelease

$Guide = @'
# AI Office v1.2 — Department Intelligence

AI Office v1.2 creates nine specialized departments that can receive work, plan, execute, collaborate, publish results, and retain reusable knowledge.

## Delivered

### Part A — Architecture
- Department profiles
- Capabilities
- Responsibilities
- KPIs
- Workspaces
- Department indexes

### Part B — Inbox and Work Intake
- Message Bus inboxes
- Capability matching
- Intake classification
- Persistent work items

### Part C — Planning and Execution
- Department plans
- Execution modes
- Cross-department handoffs
- OpenClaw dispatch
- Result publication

### Part D — Knowledge and Learning
- Lessons
- Templates
- Playbooks
- Decisions
- Metrics
- Knowledge search
- Learning records
- Reuse counts
- Success and failure tracking
- Department reports
- Complete certification
- Release publication

## Complete validation

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\departments\Test-AIOfficeDepartmentIntelligence.ps1"
```

Expected ending:

```text
All AI Office v1.2 Department Intelligence checks passed.
AI Office v1.2 Department Intelligence is operational.
```

## Publish release

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\departments\Publish-AIOfficeDepartmentIntelligenceRelease.ps1"
```

## Create department knowledge

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\departments\New-AIOfficeDepartmentKnowledge.ps1" `
    -Department "marketing" `
    -KnowledgeType "lesson" `
    -Title "Successful dealership campaign structure" `
    -Summary "Reusable structure for a multi-offer dealership campaign." `
    -ContentJson '{"steps":["Define offer","Create creative","Build page","Launch ads","Validate tracking"]}' `
    -SourceJson '{"type":"manual","project":"Elite Auto Sales"}' `
    -Confidence 0.90
```

## Search department knowledge

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\departments\Search-AIOfficeDepartmentKnowledge.ps1" `
    -Department "marketing" `
    -Query "campaign"
```

## Next milestone

AI Office v1.3 will introduce Long-Term Memory across the entire office.
'@

Write-NewFile ".\docs\AI-Office-v1.2-Department-Intelligence-Guide.md" $Guide

$ReleaseNotes = @'
# AI Office v1.2 Release Notes

## Release name

Department Intelligence

## Added

- Nine specialized AI departments
- Department capability registries
- Message Bus work intake
- Capability-based acceptance
- Department planning
- Execution modes
- Cross-department collaboration
- OpenClaw dispatch
- Result publication
- Department knowledge stores
- Reusable lessons, templates, and playbooks
- Learning records
- Reuse and success metrics
- Department reporting
- Certification and release publication

## Next

AI Office v1.3 — Long-Term Memory
'@

Write-NewFile ".\docs\AI-Office-v1.2-Release-Notes.md" $ReleaseNotes

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw |
        ConvertFrom-Json

    $Version.version = "1.2.0"
    $Version.release_name = "Department Intelligence"
    $Version.status = "part_d_installed"
    $Version.installed_at = (Get-Date).ToString("o")
    $Version.next_planned_milestone = "1.3 Long-Term Memory"

    $Version |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $VersionPath -Encoding UTF8

    Write-Host "[UPDATED] Identity release metadata set to v1.2 Part D" `
        -ForegroundColor Green
}

Write-Host ""
Write-Host "Validating Part D JSON files..." -ForegroundColor Cyan

@(
    ".\config\departments\department-knowledge-policy.json",
    ".\config\departments\department-knowledge-item-schema.json",
    ".\config\departments\department-learning-record-schema.json",
    ".\config\departments\release-manifest.json",
    ".\workspace\templates\department-knowledge-item-template.json",
    ".\workspace\templates\department-learning-record-template.json"
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
        "Installers\AI-Office-v1.2-Part-D-Department-Knowledge-Learning-Release-Install.ps1"

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
Write-Host "AI Office v1.2 Part D installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run complete validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\departments\Test-AIOfficeDepartmentIntelligence.ps1"'
Write-Host ""
