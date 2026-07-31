# ============================================================
# AI Office v1.1.4 - Part D
# Executive Review, Closed-Loop Completion, Certification, Release
# Repository: E:\AI\AI-Office
# Requires: v1.1.4 Parts A, B, and C
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

$RequiredPrevious = @(
    ".\config\chief-of-staff\chief-of-staff-policy.json",
    ".\config\chief-of-staff\inbox-policy.json",
    ".\config\chief-of-staff\delegation-policy.json",
    ".\scripts\chief-of-staff\AIOfficeChiefOfStaff.Common.ps1",
    ".\scripts\chief-of-staff\AIOfficeChiefOfStaffInbox.Common.ps1",
    ".\scripts\chief-of-staff\AIOfficeChiefOfStaffDelegation.Common.ps1",
    ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffInbox.ps1",
    ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffDispatch.ps1",
    ".\scripts\messaging\New-AIOfficeMessage.ps1",
    ".\scripts\messaging\Get-AIOfficeMessage.ps1",
    ".\scripts\messaging\Complete-AIOfficeMessage.ps1"
)

foreach ($RequiredPath in $RequiredPrevious) {
    if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
        throw "AI Office v1.1.4 Parts A, B, and C are required. Missing: $RequiredPath"
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
    ".\workspace\chief-of-staff\reviews",
    ".\workspace\chief-of-staff\approvals",
    ".\workspace\chief-of-staff\completed",
    ".\workspace\chief-of-staff\reports",
    ".\workspace\chief-of-staff\certification",
    ".\workspace\chief-of-staff\releases"
) | ForEach-Object { Ensure-Directory $_ }

$Now = (Get-Date).ToString("o")

$ReviewPolicy = @"
{
  "schema_version": "1.0.0",
  "version": "1.1.4",
  "part": "D",
  "review": {
    "require_result_message": true,
    "require_success_criteria_check": true,
    "allow_partial_completion": true,
    "allowed_outcomes": [
      "approved",
      "rejected",
      "needs_revision",
      "completed",
      "partially_completed"
    ]
  },
  "approval": {
    "allowed_statuses": [
      "pending",
      "approved",
      "rejected",
      "not_required"
    ],
    "approved_by_default_for_low_risk": true,
    "require_human_for_high_risk": true,
    "require_human_for_critical_risk": true
  },
  "completion": {
    "close_plan_when_all_delegations_complete": true,
    "close_plan_when_result_approved": true,
    "archive_completed_delegations": false,
    "publish_completion_message": true,
    "completion_recipient": "chief-of-staff"
  },
  "certification": {
    "require_parts_a_b_c": true,
    "require_message_bus": true,
    "require_bridge": true,
    "require_offline_end_to_end": true
  },
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\chief-of-staff\review-policy.json" $ReviewPolicy

$ReviewSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/chief-of-staff-review-schema.json",
  "title": "AI Office Chief of Staff Review",
  "type": "object",
  "required": [
    "review_id",
    "plan_id",
    "delegation_id",
    "message_id",
    "outcome",
    "summary",
    "criteria_results",
    "created_at",
    "created_by"
  ]
}
'@

Write-NewFile ".\config\chief-of-staff\review-schema.json" $ReviewSchema

$ApprovalSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/chief-of-staff-approval-schema.json",
  "title": "AI Office Chief of Staff Approval",
  "type": "object",
  "required": [
    "approval_id",
    "plan_id",
    "status",
    "decision",
    "reason",
    "created_at",
    "created_by"
  ]
}
'@

Write-NewFile ".\config\chief-of-staff\approval-schema.json" $ApprovalSchema

$ReleaseManifest = @"
{
  "product": "AI Office",
  "component": "Chief of Staff Integration",
  "version": "1.1.4",
  "release_name": "Chief of Staff Integration",
  "release_status": "installed",
  "installed_at": "$Now",
  "parts": {
    "A": "Chief of Staff Architecture",
    "B": "Executive Inbox and Planning",
    "C": "Delegation and Execution Dispatch",
    "D": "Executive Review and Closed-Loop Completion"
  },
  "capabilities": [
    "executive_inbox",
    "message_classification",
    "priority_assignment",
    "risk_assignment",
    "automatic_plan_generation",
    "department_routing",
    "work_package_generation",
    "delegation",
    "approval_gated_dispatch",
    "openclaw_dispatch",
    "execution_monitoring",
    "result_review",
    "approval_resolution",
    "closed_loop_completion",
    "executive_completion_messages",
    "certification"
  ],
  "next_planned_milestone": "1.2 Department Intelligence"
}
"@

Write-NewFile ".\config\chief-of-staff\release-manifest.json" $ReleaseManifest

$ReviewTemplate = @'
{
  "review_id": "REV-YYYYMMDD-HHMMSS-ABC123",
  "plan_id": "PLAN-YYYYMMDD-HHMMSS-ABC123",
  "delegation_id": "DLG-YYYYMMDD-HHMMSS-ABC123",
  "message_id": "MSG-YYYYMMDD-HHMMSS-ABC123",
  "outcome": "completed",
  "summary": "",
  "criteria_results": [],
  "created_at": "",
  "created_by": "chief-of-staff"
}
'@

Write-NewFile ".\workspace\templates\chief-of-staff-review-template.json" $ReviewTemplate

$ApprovalTemplate = @'
{
  "approval_id": "APR-YYYYMMDD-HHMMSS-ABC123",
  "plan_id": "PLAN-YYYYMMDD-HHMMSS-ABC123",
  "status": "approved",
  "decision": "",
  "reason": "",
  "created_at": "",
  "created_by": "Clarissa Schmidtberger"
}
'@

Write-NewFile ".\workspace\templates\chief-of-staff-approval-template.json" $ApprovalTemplate

$Common = @'
. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaff.Common.ps1")

function Get-AIOfficeChiefOfStaffReviewPolicy {
    $Root = Get-AIOfficeChiefOfStaffRoot

    return Read-AIOfficeChiefOfStaffJson `
        -Path (Join-Path $Root "config\chief-of-staff\review-policy.json")
}

function New-AIOfficeChiefOfStaffReviewId {
    return (
        "REV-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeChiefOfStaffApprovalId {
    return (
        "APR-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeChiefOfStaffDelegation {
    param([Parameter(Mandatory=$true)][string]$DelegationId)

    $Root = Get-AIOfficeChiefOfStaffRoot
    $Path = Join-Path `
        $Root `
        ("workspace\chief-of-staff\delegations\" + $DelegationId + ".json")

    $Delegation = Read-AIOfficeChiefOfStaffJson -Path $Path

    if ($null -eq $Delegation) {
        throw "Delegation not found: $DelegationId"
    }

    return $Delegation
}
'@

Write-NewFile ".\scripts\chief-of-staff\AIOfficeChiefOfStaffReview.Common.ps1" $Common

$ApprovalScript = @'
param(
    [Parameter(Mandatory=$true)][string]$PlanId,
    [ValidateSet("approved","rejected","pending","not_required")]
    [string]$Status,
    [Parameter(Mandatory=$true)][string]$Decision,
    [Parameter(Mandatory=$true)][string]$Reason,
    [string]$CreatedBy = "Clarissa Schmidtberger"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffReview.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Plan = Get-AIOfficeChiefOfStaffPlan -PlanId $PlanId

$ApprovalId = New-AIOfficeChiefOfStaffApprovalId
$Now = (Get-Date).ToString("o")

$Approval = [ordered]@{
    approval_id = $ApprovalId
    plan_id = $PlanId
    status = $Status
    decision = $Decision
    reason = $Reason
    created_at = $Now
    created_by = $CreatedBy
}

$Path = Join-Path `
    ".\workspace\chief-of-staff\approvals" `
    ($ApprovalId + ".json")

Write-AIOfficeChiefOfStaffJson -Value $Approval -Path $Path

$Plan.approval_status = $Status
$Plan.updated_at = $Now

$History = New-Object System.Collections.Generic.List[object]

foreach ($Entry in @($Plan.history)) {
    $History.Add($Entry)
}

$History.Add([ordered]@{
    timestamp = $Now
    action = "approval_updated"
    actor = $CreatedBy
    details = (
        "Approval status set to " +
        $Status +
        "."
    )
})

$Plan.history = @($History | ForEach-Object { $_ })

Write-AIOfficeChiefOfStaffJson `
    -Value $Plan `
    -Path ".\workspace\chief-of-staff\plans\$PlanId.json"

& ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1" |
    Out-Null

Write-Host (
    "Plan approval updated: " +
    $PlanId +
    " -> " +
    $Status
) -ForegroundColor Green

return [pscustomobject]$Approval
'@

Write-NewFile ".\scripts\chief-of-staff\Set-AIOfficeChiefOfStaffApproval.ps1" $ApprovalScript

$ReviewResultScript = @'
param(
    [Parameter(Mandatory=$true)][string]$DelegationId,
    [Parameter(Mandatory=$true)][string]$MessageId,
    [ValidateSet(
        "approved",
        "rejected",
        "needs_revision",
        "completed",
        "partially_completed"
    )]
    [string]$Outcome,
    [Parameter(Mandatory=$true)][string]$Summary,
    [string]$CreatedBy = "chief-of-staff"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffReview.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Delegation = Get-AIOfficeChiefOfStaffDelegation `
    -DelegationId $DelegationId

$Plan = Get-AIOfficeChiefOfStaffPlan `
    -PlanId ([string]$Delegation.plan_id)

$Message = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
    -MessageId $MessageId

$CriteriaResults = New-Object System.Collections.Generic.List[object]

foreach ($Criterion in @($Plan.success_criteria)) {
    $CriteriaResults.Add([ordered]@{
        criterion = [string]$Criterion
        met = ($Outcome -in @("approved","completed"))
        notes = if ($Outcome -in @("approved","completed")) {
            "Marked complete during executive review."
        }
        else {
            "Requires additional work or review."
        }
    })
}

$ReviewId = New-AIOfficeChiefOfStaffReviewId
$Now = (Get-Date).ToString("o")

$Review = [ordered]@{
    review_id = $ReviewId
    plan_id = [string]$Plan.plan_id
    delegation_id = $DelegationId
    message_id = $MessageId
    outcome = $Outcome
    summary = $Summary
    criteria_results = @($CriteriaResults | ForEach-Object { $_ })
    created_at = $Now
    created_by = $CreatedBy
}

$Path = Join-Path `
    ".\workspace\chief-of-staff\reviews" `
    ($ReviewId + ".json")

Write-AIOfficeChiefOfStaffJson -Value $Review -Path $Path

$Delegation.status = switch ($Outcome) {
    "approved" { "completed" }
    "completed" { "completed" }
    "partially_completed" { "partially_completed" }
    "needs_revision" { "revision_required" }
    "rejected" { "rejected" }
}

$Delegation.updated_at = $Now

$DelegationHistory = New-Object System.Collections.Generic.List[object]

foreach ($Entry in @($Delegation.history)) {
    $DelegationHistory.Add($Entry)
}

$DelegationHistory.Add([ordered]@{
    timestamp = $Now
    action = "reviewed"
    actor = $CreatedBy
    details = (
        "Review outcome: " +
        $Outcome +
        "."
    )
})

$Delegation.history = @(
    $DelegationHistory | ForEach-Object { $_ }
)

Write-AIOfficeChiefOfStaffJson `
    -Value $Delegation `
    -Path ".\workspace\chief-of-staff\delegations\$DelegationId.json"

Write-Host "Executive review recorded: $ReviewId" `
    -ForegroundColor Green

return [pscustomobject]$Review
'@

Write-NewFile ".\scripts\chief-of-staff\Review-AIOfficeChiefOfStaffResult.ps1" $ReviewResultScript

$CompletePlanScript = @'
param(
    [Parameter(Mandatory=$true)][string]$PlanId,
    [string]$Summary = "",
    [string]$CompletedBy = "chief-of-staff"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffReview.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Plan = Get-AIOfficeChiefOfStaffPlan -PlanId $PlanId

$Delegations = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\chief-of-staff\delegations" `
        -Filter "DLG-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        ForEach-Object {
            $Delegation = Read-AIOfficeChiefOfStaffJson `
                -Path $_.FullName

            if ($null -ne $Delegation -and
                [string]$Delegation.plan_id -eq $PlanId) {
                $Delegation
            }
        }
)

$Incomplete = @(
    $Delegations |
        Where-Object {
            @("completed","partially_completed") -notcontains
            [string]$_.status
        }
)

if ($Incomplete.Count -gt 0) {
    throw (
        "Plan cannot be completed. " +
        $Incomplete.Count.ToString() +
        " delegation(s) remain incomplete."
    )
}

$Now = (Get-Date).ToString("o")
$Plan.status = "completed"
$Plan.updated_at = $Now
$Plan.completed_at = $Now
$Plan.completed_by = $CompletedBy
$Plan.completion_summary = $Summary

$History = New-Object System.Collections.Generic.List[object]

foreach ($Entry in @($Plan.history)) {
    $History.Add($Entry)
}

$History.Add([ordered]@{
    timestamp = $Now
    action = "completed"
    actor = $CompletedBy
    details = if ([string]::IsNullOrWhiteSpace($Summary)) {
        "Chief of Staff plan completed."
    }
    else {
        $Summary
    }
})

$Plan.history = @($History | ForEach-Object { $_ })

$PlanPath = ".\workspace\chief-of-staff\plans\$PlanId.json"

Write-AIOfficeChiefOfStaffJson `
    -Value $Plan `
    -Path $PlanPath

$CompletedPath = Join-Path `
    ".\workspace\chief-of-staff\completed" `
    ($PlanId + ".json")

Write-AIOfficeChiefOfStaffJson `
    -Value $Plan `
    -Path $CompletedPath

$Payload = [ordered]@{
    plan_id = $PlanId
    status = "completed"
    title = [string]$Plan.title
    objective = [string]$Plan.objective
    summary = $Summary
    completed_at = $Now
    delegation_count = $Delegations.Count
}

$Arguments = @{
    From = "chief-of-staff"
    To = "chief-of-staff"
    MessageType = "status"
    Subject = ("Plan completed: " + [string]$Plan.title)
    Priority = "normal"
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

& ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1" |
    Out-Null

Write-Host (
    "Chief of Staff plan completed: " +
    $PlanId
) -ForegroundColor Green

return [pscustomobject]@{
    plan = $Plan
    completion_message = $Message
}
'@

Write-NewFile ".\scripts\chief-of-staff\Complete-AIOfficeChiefOfStaffPlan.ps1" $CompletePlanScript

$CloseLoopScript = @'
param(
    [Parameter(Mandatory=$true)][string]$DelegationId,
    [Parameter(Mandatory=$true)][string]$ResultMessageId,
    [ValidateSet(
        "approved",
        "rejected",
        "needs_revision",
        "completed",
        "partially_completed"
    )]
    [string]$Outcome = "completed",
    [Parameter(Mandatory=$true)][string]$Summary,
    [switch]$CompletePlan
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$Review = & `
    ".\scripts\chief-of-staff\Review-AIOfficeChiefOfStaffResult.ps1" `
    -DelegationId $DelegationId `
    -MessageId $ResultMessageId `
    -Outcome $Outcome `
    -Summary $Summary

$Delegation = & `
    ".\scripts\chief-of-staff\AIOfficeChiefOfStaffReview.Common.ps1"

$DelegationRecord = Get-AIOfficeChiefOfStaffDelegation `
    -DelegationId $DelegationId

$Completion = $null

if ($CompletePlan -and
    $Outcome -in @("approved","completed","partially_completed")) {
    $Completion = & `
        ".\scripts\chief-of-staff\Complete-AIOfficeChiefOfStaffPlan.ps1" `
        -PlanId ([string]$DelegationRecord.plan_id) `
        -Summary $Summary
}

return [pscustomobject]@{
    review = $Review
    completion = $Completion
}
'@

# The inline dot-source command above is intentionally corrected below by
# replacing the script with a clean implementation after creation.
Write-NewFile ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffClosedLoop.ps1" $CloseLoopScript

$CloseLoopRepair = @'
param(
    [Parameter(Mandatory=$true)][string]$DelegationId,
    [Parameter(Mandatory=$true)][string]$ResultMessageId,
    [ValidateSet(
        "approved",
        "rejected",
        "needs_revision",
        "completed",
        "partially_completed"
    )]
    [string]$Outcome = "completed",
    [Parameter(Mandatory=$true)][string]$Summary,
    [switch]$CompletePlan
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffReview.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Review = & `
    ".\scripts\chief-of-staff\Review-AIOfficeChiefOfStaffResult.ps1" `
    -DelegationId $DelegationId `
    -MessageId $ResultMessageId `
    -Outcome $Outcome `
    -Summary $Summary

$DelegationRecord = Get-AIOfficeChiefOfStaffDelegation `
    -DelegationId $DelegationId

$Completion = $null

if ($CompletePlan -and
    $Outcome -in @("approved","completed","partially_completed")) {
    $Completion = & `
        ".\scripts\chief-of-staff\Complete-AIOfficeChiefOfStaffPlan.ps1" `
        -PlanId ([string]$DelegationRecord.plan_id) `
        -Summary $Summary
}

return [pscustomobject]@{
    review = $Review
    completion = $Completion
}
'@

Set-Content `
    -LiteralPath ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffClosedLoop.ps1" `
    -Value $CloseLoopRepair `
    -Encoding UTF8

$ExecutiveReport = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffReview.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Index = & ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1"

$Delegations = @(
    & ".\scripts\chief-of-staff\Show-AIOfficeChiefOfStaffDelegations.ps1" `
        -IncludeCompleted
)

$Plans = @(
    & ".\scripts\chief-of-staff\Search-AIOfficeChiefOfStaffPlans.ps1"
)

$Report = [ordered]@{
    report_id = (
        "COS-REPORT-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss")
    )
    generated_at = (Get-Date).ToString("o")
    status = [string]$Index.status
    inbox_count = [int]$Index.inbox_count
    open_plan_count = [int]$Index.open_plan_count
    pending_approval_count = [int]$Index.pending_approval_count
    active_delegation_count = [int]$Index.active_delegation_count
    decision_count = [int]$Index.decision_count
    plan_count = $Plans.Count
    delegation_count = $Delegations.Count
    stale_delegation_count = @(
        $Delegations | Where-Object { $_.stale -eq $true }
    ).Count
    escalation_count = @(
        $Delegations | Where-Object { $_.escalate -eq $true }
    ).Count
    plans = $Plans
    delegations = $Delegations
}

$Path = Join-Path `
    ".\workspace\chief-of-staff\reports" `
    ([string]$Report.report_id + ".json")

Write-AIOfficeChiefOfStaffJson -Value $Report -Path $Path

Write-Host (
    "Chief of Staff executive report created: " +
    [string]$Report.report_id
) -ForegroundColor Green

return [pscustomobject]$Report
'@

Write-NewFile ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffExecutiveReport.ps1" $ExecutiveReport

$CertifyScript = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffReview.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Checks = New-Object System.Collections.Generic.List[object]

function Add-COSCheck {
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
    ".\config\chief-of-staff\chief-of-staff-identity.json",
    ".\config\chief-of-staff\chief-of-staff-policy.json",
    ".\config\chief-of-staff\inbox-policy.json",
    ".\config\chief-of-staff\delegation-policy.json",
    ".\config\chief-of-staff\review-policy.json",
    ".\config\chief-of-staff\release-manifest.json"
)

foreach ($Path in $JsonFiles) {
    try {
        Get-Content -LiteralPath $Path -Raw |
            ConvertFrom-Json |
            Out-Null

        Add-COSCheck `
            -Name ("Valid JSON: " + $Path) `
            -Passed $true `
            -Details "Parsed successfully."
    }
    catch {
        Add-COSCheck `
            -Name ("Valid JSON: " + $Path) `
            -Passed $false `
            -Details $_.Exception.Message
    }
}

$Scripts = @(
    ".\scripts\chief-of-staff\AIOfficeChiefOfStaff.Common.ps1",
    ".\scripts\chief-of-staff\AIOfficeChiefOfStaffInbox.Common.ps1",
    ".\scripts\chief-of-staff\AIOfficeChiefOfStaffDelegation.Common.ps1",
    ".\scripts\chief-of-staff\AIOfficeChiefOfStaffReview.Common.ps1",
    ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffPlan.ps1",
    ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffInbox.ps1",
    ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffDispatch.ps1",
    ".\scripts\chief-of-staff\Review-AIOfficeChiefOfStaffResult.ps1",
    ".\scripts\chief-of-staff\Complete-AIOfficeChiefOfStaffPlan.ps1",
    ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffClosedLoop.ps1",
    ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffExecutiveReport.ps1",
    ".\scripts\chief-of-staff\Certify-AIOfficeChiefOfStaff.ps1",
    ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaff.ps1",
    ".\scripts\chief-of-staff\Publish-AIOfficeChiefOfStaffRelease.ps1"
)

foreach ($Path in $Scripts) {
    $Exists = Test-Path -LiteralPath $Path -PathType Leaf

    Add-COSCheck `
        -Name ("Script exists: " + $Path) `
        -Passed $Exists `
        -Details $(if ($Exists) { "Found." } else { "Missing." })
}

$MessageId = ""
$PlanId = ""
$DelegationId = ""
$WorkPackageId = ""
$DispatchMessageId = ""
$ResultMessageId = ""
$CompletionMessageId = ""

try {
    $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "marketing" `
        -To "chief-of-staff" `
        -MessageType "request" `
        -Priority "high" `
        -Subject "Chief of Staff certification campaign" `
        -ConversationTopic "COS-CERTIFICATION" `
        -Queue "inbox" `
        -PayloadJson '{"objective":"Create and complete a certification campaign plan.","success_criteria":["Plan created","Delegation dispatched","Result reviewed","Plan completed"]}'

    $MessageId = [string]$Message.message_id

    $InboxResults = @(
        & ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffInbox.ps1" `
            -Limit 1 `
            -CreatePlans
    )

    if ($InboxResults.Count -ne 1 -or
        [string]::IsNullOrWhiteSpace([string]$InboxResults[0].plan_id)) {
        throw "Inbox processing did not create a plan."
    }

    $PlanId = [string]$InboxResults[0].plan_id

    Add-COSCheck `
        -Name "Executive inbox to plan" `
        -Passed $true `
        -Details $PlanId

    $Dispatch = & `
        ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffDispatch.ps1" `
        -PlanId $PlanId

    $DelegationId = [string]$Dispatch.delegation.delegation_id
    $WorkPackageId = [string]$Dispatch.work_package.work_package_id
    $DispatchMessageId = [string]$Dispatch.message.message_id

    Add-COSCheck `
        -Name "Plan to delegation dispatch" `
        -Passed (
            -not [string]::IsNullOrWhiteSpace($DelegationId) -and
            -not [string]::IsNullOrWhiteSpace($DispatchMessageId)
        ) `
        -Details (
            $DelegationId +
            " | " +
            $DispatchMessageId
        )

    $ResultPayload = [ordered]@{
        delegation_id = $DelegationId
        plan_id = $PlanId
        status = "completed"
        summary = "Certification work completed."
    }

    $ResultMessage = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From ([string]$Dispatch.delegation.department) `
        -To "chief-of-staff" `
        -MessageType "execution_result" `
        -Priority "normal" `
        -Subject "Certification result" `
        -ConversationId ([string]$Dispatch.message.conversation_id) `
        -CorrelationId ([string]$Dispatch.message.correlation_id) `
        -Queue "inbox" `
        -PayloadJson (
            $ResultPayload |
                ConvertTo-Json -Depth 10 -Compress
        )

    $ResultMessageId = [string]$ResultMessage.message_id

    $ClosedLoop = & `
        ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffClosedLoop.ps1" `
        -DelegationId $DelegationId `
        -ResultMessageId $ResultMessageId `
        -Outcome "completed" `
        -Summary "Certification result reviewed and approved." `
        -CompletePlan

    if ($null -eq $ClosedLoop.completion -or
        [string]$ClosedLoop.completion.plan.status -ne "completed") {
        throw "Closed-loop completion did not complete the plan."
    }

    $CompletionMessageId = [string](
        $ClosedLoop.completion.completion_message.message_id
    )

    Add-COSCheck `
        -Name "Closed-loop completion" `
        -Passed $true `
        -Details (
            $PlanId +
            " completed | message " +
            $CompletionMessageId
        )

    $Report = & `
        ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffExecutiveReport.ps1"

    Add-COSCheck `
        -Name "Executive report generation" `
        -Passed ($null -ne $Report) `
        -Details ([string]$Report.report_id)
}
catch {
    Add-COSCheck `
        -Name "Offline end-to-end Chief of Staff workflow" `
        -Passed $false `
        -Details $_.Exception.Message
}

# Cleanup certification-generated runtime records.
foreach ($CurrentMessageId in @(
    $MessageId,
    $DispatchMessageId,
    $ResultMessageId,
    $CompletionMessageId
)) {
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

    foreach ($Folder in @(
        ".\workspace\chief-of-staff\processed-inbox",
        ".\workspace\chief-of-staff\failed-inbox"
    )) {
        $Path = Join-Path $Folder ($CurrentMessageId + ".json")

        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            Remove-Item -LiteralPath $Path -Force
        }
    }
}

foreach ($Path in @(
    ".\workspace\chief-of-staff\plans\$PlanId.json",
    ".\workspace\chief-of-staff\completed\$PlanId.json",
    ".\workspace\chief-of-staff\delegations\$DelegationId.json",
    ".\workspace\chief-of-staff\work-packages\$WorkPackageId.json"
)) {
    if (-not [string]::IsNullOrWhiteSpace($Path) -and
        (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Remove-Item -LiteralPath $Path -Force
    }
}

foreach ($Folder in @(
    ".\workspace\chief-of-staff\classifications",
    ".\workspace\chief-of-staff\routing",
    ".\workspace\chief-of-staff\reviews",
    ".\workspace\chief-of-staff\approvals"
)) {
    Get-ChildItem `
        -LiteralPath $Folder `
        -Filter "*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        ForEach-Object {
            $Record = Read-AIOfficeChiefOfStaffJson -Path $_.FullName

            if ($null -ne $Record -and
                (
                    [string]$Record.plan_id -eq $PlanId -or
                    [string]$Record.message_id -eq $MessageId -or
                    [string]$Record.delegation_id -eq $DelegationId
                )) {
                Remove-Item -LiteralPath $_.FullName -Force
            }
        }
}

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
    Out-Null

& ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1" |
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
    "CERT-COS-" +
    (Get-Date).ToString("yyyyMMdd-HHmmss")
)

$Certification = [ordered]@{
    certification_id = $CertificationId
    version = "1.1.4"
    certified_at = (Get-Date).ToString("o")
    status = $Status
    passed_checks = $PassedCount
    failed_checks = $FailedCount
    checks = @($Checks | ForEach-Object { $_ })
}

$Path = Join-Path `
    ".\workspace\chief-of-staff\certification" `
    ($CertificationId + ".json")

Write-AIOfficeChiefOfStaffJson `
    -Value $Certification `
    -Path $Path

Write-Host (
    "Chief of Staff certification: " +
    $Status +
    " | " +
    $PassedCount.ToString() +
    " passed, " +
    $FailedCount.ToString() +
    " failed"
) -ForegroundColor $(if ($FailedCount -eq 0) { "Green" } else { "Red" })

return [pscustomobject]$Certification
'@

Write-NewFile ".\scripts\chief-of-staff\Certify-AIOfficeChiefOfStaff.ps1" $CertifyScript

$CompleteTest = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.4 Chief of Staff Integration..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

function Invoke-COSTest {
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

Invoke-COSTest `
    -Name "Part A Chief of Staff Architecture" `
    -Path ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaffArchitecture.ps1"

Invoke-COSTest `
    -Name "Part B Executive Inbox and Planning" `
    -Path ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaffInbox.ps1"

Invoke-COSTest `
    -Name "Part C Delegation and Dispatch" `
    -Path ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaffDelegation.ps1"

try {
    $Certification = & `
        ".\scripts\chief-of-staff\Certify-AIOfficeChiefOfStaff.ps1"

    if ($null -eq $Certification -or
        [string]$Certification.status -ne "certified" -or
        [int]$Certification.failed_checks -ne 0) {
        throw "Chief of Staff certification failed."
    }

    Write-Host (
        "[PASS] Chief of Staff certification: " +
        [string]$Certification.certification_id
    ) -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Chief of Staff certification" `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Chief of Staff certification: " + $_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Chief of Staff Integration error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.4 Chief of Staff Integration checks passed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "AI Office v1.1.4 Chief of Staff Integration is operational." `
    -ForegroundColor Cyan
'@

Write-NewFile ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaff.ps1" $CompleteTest

$PublishRelease = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffReview.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$CertificationFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\chief-of-staff\certification" `
        -Filter "CERT-COS-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending
)

if ($CertificationFiles.Count -lt 1) {
    throw "No Chief of Staff certification record exists."
}

$Certification = Read-AIOfficeChiefOfStaffJson `
    -Path $CertificationFiles[0].FullName

if ($null -eq $Certification -or
    [string]$Certification.status -ne "certified") {
    throw "Latest Chief of Staff certification did not pass."
}

$ManifestPath = ".\config\chief-of-staff\release-manifest.json"
$Manifest = Read-AIOfficeChiefOfStaffJson -Path $ManifestPath

if ($null -eq $Manifest) {
    throw "Chief of Staff release manifest could not be loaded."
}

$ReleasedAt = (Get-Date).ToString("o")
$Manifest.release_status = "released"
$Manifest.released_at = $ReleasedAt
$Manifest.certification_id = [string]$Certification.certification_id

Write-AIOfficeChiefOfStaffJson `
    -Value $Manifest `
    -Path $ManifestPath

$ReleaseRecord = [ordered]@{
    product = "AI Office"
    component = "Chief of Staff Integration"
    version = "1.1.4"
    released_at = $ReleasedAt
    status = "released"
    certification_id = [string]$Certification.certification_id
    next_milestone = "1.2 Department Intelligence"
}

$ReleasePath = Join-Path `
    ".\workspace\chief-of-staff\releases" `
    ("AI-Office-v1.1.4-" + (Get-Date).ToString("yyyyMMdd-HHmmss") + ".json")

Write-AIOfficeChiefOfStaffJson `
    -Value $ReleaseRecord `
    -Path $ReleasePath

$IdentityPath = ".\config\identity\office.json"

if (Test-Path -LiteralPath $IdentityPath -PathType Leaf) {
    $Identity = Read-AIOfficeChiefOfStaffJson -Path $IdentityPath
    $Identity.version = "1.1.4"
    $Identity.codename = "Chief of Staff"
    $Identity.updated_at = $ReleasedAt

    Write-AIOfficeChiefOfStaffJson `
        -Value $Identity `
        -Path $IdentityPath
}

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Read-AIOfficeChiefOfStaffJson -Path $VersionPath
    $Version.version = "1.1.4"
    $Version.release_name = "Chief of Staff Integration"
    $Version.status = "released"
    $Version.installed_at = $ReleasedAt
    $Version.previous_version = "1.1.3"
    $Version.next_planned_milestone = "1.2 Department Intelligence"

    Write-AIOfficeChiefOfStaffJson `
        -Value $Version `
        -Path $VersionPath
}

Write-Host (
    "AI Office v1.1.4 Chief of Staff release recorded: " +
    [string]$Certification.certification_id
) -ForegroundColor Green

return [pscustomobject]$ReleaseRecord
'@

Write-NewFile ".\scripts\chief-of-staff\Publish-AIOfficeChiefOfStaffRelease.ps1" $PublishRelease

$Guide = @'
# AI Office v1.1.4 — Chief of Staff Integration

AI Office v1.1.4 turns executive requests into governed plans, department work packages, delegations, approvals, execution dispatches, result reviews, and closed-loop completion.

## Delivered

### Part A — Architecture
- Chief of Staff identity
- Planning policy
- Plan and decision records
- Risk-based approval model

### Part B — Executive Inbox and Planning
- Message Bus inbox
- Classification
- Priority and risk assignment
- Automatic plan creation

### Part C — Delegation and Execution Dispatch
- Department routing
- Work packages
- Delegation records
- Approval-gated dispatch
- OpenClaw execution requests
- Monitoring and escalation

### Part D — Review and Completion
- Approval resolution
- Result review
- Success-criteria evaluation
- Delegation completion
- Plan completion
- Completion messages
- Executive reports
- Certification and release

## Complete validation

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaff.ps1"
```

Expected ending:

```text
All AI Office v1.1.4 Chief of Staff Integration checks passed.
AI Office v1.1.4 Chief of Staff Integration is operational.
```

## Publish release

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\chief-of-staff\Publish-AIOfficeChiefOfStaffRelease.ps1"
```

## Set approval

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\chief-of-staff\Set-AIOfficeChiefOfStaffApproval.ps1" `
    -PlanId "PLAN-..." `
    -Status "approved" `
    -Decision "Proceed" `
    -Reason "Executive approval granted."
```

## Run closed-loop review

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffClosedLoop.ps1" `
    -DelegationId "DLG-..." `
    -ResultMessageId "MSG-..." `
    -Outcome "completed" `
    -Summary "Work reviewed and accepted." `
    -CompletePlan
```

## Next milestone

AI Office v1.2 will introduce Department Intelligence.
'@

Write-NewFile ".\docs\AI-Office-v1.1.4-Chief-of-Staff-Guide.md" $Guide

$ReleaseNotes = @'
# AI Office v1.1.4 Release Notes

## Release name

Chief of Staff Integration

## Added

- Executive inbox processing
- Automatic planning
- Risk and priority assignment
- Department routing
- Work packages
- Delegation
- Approval-gated dispatch
- OpenClaw dispatch preparation
- Result review
- Success-criteria evaluation
- Closed-loop plan completion
- Executive reports
- Certification
- Release publication

## Next

AI Office v1.2 — Department Intelligence
'@

Write-NewFile ".\docs\AI-Office-v1.1.4-Release-Notes.md" $ReleaseNotes

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw |
        ConvertFrom-Json

    $Version.version = "1.1.4"
    $Version.release_name = "Chief of Staff Integration"
    $Version.status = "part_d_installed"
    $Version.installed_at = (Get-Date).ToString("o")
    $Version.next_planned_milestone = "1.2 Department Intelligence"

    $Version |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $VersionPath -Encoding UTF8

    Write-Host "[UPDATED] Identity release metadata set to v1.1.4 Part D" `
        -ForegroundColor Green
}

Write-Host ""
Write-Host "Validating Part D JSON files..." -ForegroundColor Cyan

@(
    ".\config\chief-of-staff\review-policy.json",
    ".\config\chief-of-staff\review-schema.json",
    ".\config\chief-of-staff\approval-schema.json",
    ".\config\chief-of-staff\release-manifest.json",
    ".\workspace\templates\chief-of-staff-review-template.json",
    ".\workspace\templates\chief-of-staff-approval-template.json"
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
        "Installers\AI-Office-v1.1.4-Part-D-Executive-Review-Completion-Install.ps1"

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
Write-Host "AI Office v1.1.4 Part D installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run complete validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaff.ps1"'
Write-Host ""
