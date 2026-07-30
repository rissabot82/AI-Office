param(
    [Parameter(Mandatory = $true)]
    [string]$TaskId,

    [Parameter(Mandatory = $false)]
    [string]$Reviewer = "chief-of-staff",

    [Parameter(Mandatory = $false)]
    [switch]$Apply,

    [Parameter(Mandatory = $false)]
    [switch]$PassManualChecks,

    [Parameter(Mandatory = $false)]
    [string]$Summary = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet(
        "approved",
        "approved-with-minor-corrections",
        "returned-for-revision",
        "rejected"
    )]
    [string]$Recommendation = "returned-for-revision"
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

function Find-TaskFolder {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RequestedTaskId
    )

    $workflowFolders = @(
        "inbox",
        "active",
        "review",
        "approved",
        "outbox",
        "completed",
        "failed",
        "archive"
    )

    foreach ($workflowFolder in $workflowFolders) {
        $candidate = Join-Path `
            ".\workspace\$workflowFolder" `
            $RequestedTaskId

        if (Test-Path -LiteralPath $candidate -PathType Container) {
            return (Resolve-Path $candidate).Path
        }
    }

    return $null
}

function Add-CheckResult {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.ArrayList]$List,

        [Parameter(Mandatory = $true)]
        [string]$Id,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [bool]$Passed,

        [Parameter(Mandatory = $false)]
        [string]$Details = ""
    )

    [void]$List.Add(
        [PSCustomObject]@{
            id = $Id
            name = $Name
            passed = $Passed
            details = $Details
        }
    )
}

$policyPath = ".\config\review\review-policy.json"
$checksPath = ".\config\review\review-checks.json"
$registerPath = ".\workspace\task-register.json"

foreach ($requiredFile in @($policyPath, $checksPath, $registerPath)) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Required file not found: $requiredFile"
    }
}

$policy = Get-Content -LiteralPath $policyPath -Raw | ConvertFrom-Json
$reviewChecks = Get-Content -LiteralPath $checksPath -Raw | ConvertFrom-Json

$taskFolder = Find-TaskFolder -RequestedTaskId $TaskId

if ([string]::IsNullOrWhiteSpace($taskFolder)) {
    throw "Task folder not found: $TaskId"
}

$taskJsonPath = Join-Path $taskFolder "task.json"
$briefPath = Join-Path $taskFolder "brief.md"

if (-not (Test-Path -LiteralPath $taskJsonPath -PathType Leaf)) {
    throw "task.json was not found for task $TaskId."
}

$task = $null
$jsonValid = $true
$jsonError = ""

try {
    $task = Get-Content -LiteralPath $taskJsonPath -Raw | ConvertFrom-Json
}
catch {
    $jsonValid = $false
    $jsonError = $_.Exception.Message
}

$automaticChecks = New-Object System.Collections.ArrayList
$issues = New-Object System.Collections.ArrayList

Add-CheckResult `
    -List $automaticChecks `
    -Id "task-json-valid" `
    -Name "Task JSON is valid" `
    -Passed $jsonValid `
    -Details $jsonError

if (-not $jsonValid) {
    [void]$issues.Add(
        [PSCustomObject]@{
            severity = "critical"
            check_id = "task-json-valid"
            description = "The task JSON file is invalid."
            correction = "Repair task.json before continuing."
        }
    )
}
else {
    $taskIdPresent = -not [string]::IsNullOrWhiteSpace([string]$task.task_id)
    $titlePresent = -not [string]::IsNullOrWhiteSpace([string]$task.title)
    $descriptionPresent = -not [string]::IsNullOrWhiteSpace([string]$task.description)
    $agentPresent = -not [string]::IsNullOrWhiteSpace([string]$task.assigned_agent)
    $departmentPresent = -not [string]::IsNullOrWhiteSpace([string]$task.lead_department)
    $locationPresent = -not [string]::IsNullOrWhiteSpace([string]$task.workspace_location)

    $deliverablesPresent = (
        $null -ne $task.deliverables -and
        @($task.deliverables).Count -gt 0
    )

    $approvalStatusValid = @(
        "not-required",
        "pending",
        "approved",
        "rejected"
    ) -contains [string]$task.approval_status

    $normalizedFolder = $taskFolder.Replace("\", "/").ToLowerInvariant()
    $normalizedLocation = ([string]$task.workspace_location).ToLowerInvariant()

    $workspaceLocationValid = (
        $locationPresent -and
        $normalizedFolder.EndsWith($normalizedLocation)
    )

    Add-CheckResult $automaticChecks "task-id-present" "Task ID is present" $taskIdPresent
    Add-CheckResult $automaticChecks "title-present" "Task title is present" $titlePresent
    Add-CheckResult $automaticChecks "description-present" "Task description is present" $descriptionPresent
    Add-CheckResult $automaticChecks "assigned-agent-present" "Assigned agent is present" $agentPresent
    Add-CheckResult $automaticChecks "lead-department-present" "Lead department is present" $departmentPresent
    Add-CheckResult $automaticChecks "deliverables-present" "Deliverables are recorded" $deliverablesPresent
    Add-CheckResult $automaticChecks "approval-status-valid" "Approval status is valid" $approvalStatusValid
    Add-CheckResult $automaticChecks "workspace-location-valid" "Workspace location is valid" $workspaceLocationValid

    $completionCriteriaPresent = $false

    if (Test-Path -LiteralPath $briefPath -PathType Leaf) {
        $briefContent = Get-Content -LiteralPath $briefPath -Raw

        $completionCriteriaPresent = (
            $briefContent -match "(?im)^## Completion Criteria" -and
            $briefContent -notmatch (
                "(?im)^## Completion Criteria\s*" +
                "(\r?\n)+Describe how the task will be judged complete\."
            )
        )
    }

    Add-CheckResult `
        $automaticChecks `
        "completion-criteria-present" `
        "Completion criteria are documented" `
        $completionCriteriaPresent

    $automaticIssueMap = @(
        @{
            Passed = $taskIdPresent
            Severity = "critical"
            Id = "task-id-present"
            Description = "Task ID is missing."
            Correction = "Add a valid task_id."
        },
        @{
            Passed = $titlePresent
            Severity = "major"
            Id = "title-present"
            Description = "Task title is missing."
            Correction = "Add a clear task title."
        },
        @{
            Passed = $descriptionPresent
            Severity = "major"
            Id = "description-present"
            Description = "Task description is missing."
            Correction = "Add the requested outcome."
        },
        @{
            Passed = $agentPresent
            Severity = "major"
            Id = "assigned-agent-present"
            Description = "No agent is assigned."
            Correction = "Route or assign the task."
        },
        @{
            Passed = $departmentPresent
            Severity = "major"
            Id = "lead-department-present"
            Description = "No lead department is recorded."
            Correction = "Assign a lead department."
        },
        @{
            Passed = $deliverablesPresent
            Severity = "minor"
            Id = "deliverables-present"
            Description = "No deliverables are listed in task.json."
            Correction = "Record the expected or completed deliverables."
        },
        @{
            Passed = $completionCriteriaPresent
            Severity = "minor"
            Id = "completion-criteria-present"
            Description = "Completion criteria are missing or still contain placeholder text."
            Correction = "Complete the Completion Criteria section in brief.md."
        },
        @{
            Passed = $approvalStatusValid
            Severity = "major"
            Id = "approval-status-valid"
            Description = "Approval status is invalid."
            Correction = "Use an approved approval_status value."
        },
        @{
            Passed = $workspaceLocationValid
            Severity = "major"
            Id = "workspace-location-valid"
            Description = "The recorded workspace location does not match the task folder."
            Correction = "Correct workspace_location or move the task properly."
        }
    )

    foreach ($item in $automaticIssueMap) {
        if (-not $item.Passed) {
            [void]$issues.Add(
                [PSCustomObject]@{
                    severity = $item.Severity
                    check_id = $item.Id
                    description = $item.Description
                    correction = $item.Correction
                }
            )
        }
    }
}

$manualChecks = New-Object System.Collections.ArrayList

foreach ($check in $reviewChecks.checks) {
    $passed = $PassManualChecks.IsPresent

    [void]$manualChecks.Add(
        [PSCustomObject]@{
            id = [string]$check.id
            name = [string]$check.name
            category = [string]$check.category
            required = [bool]$check.required
            passed = $passed
            reviewer_notes = ""
        }
    )

    if ([bool]$check.required -and -not $passed) {
        [void]$issues.Add(
            [PSCustomObject]@{
                severity = "major"
                check_id = [string]$check.id
                description = "Required manual review check has not been passed: $($check.name)"
                correction = "Review this item and rerun with -PassManualChecks after confirmation."
            }
        )
    }
}

$totalPenalty = 0

foreach ($issue in $issues) {
    $severity = [string]$issue.severity
    $totalPenalty += [int]$policy.severity_weights.$severity
}

$score = [Math]::Max(0, 100 - $totalPenalty)

$criticalIssues = @(
    $issues | Where-Object { $_.severity -eq "critical" }
).Count

$majorIssues = @(
    $issues | Where-Object { $_.severity -eq "major" }
).Count

$minorIssues = @(
    $issues | Where-Object { $_.severity -eq "minor" }
).Count

if ($criticalIssues -gt 0 -or $majorIssues -gt 0) {
    $reviewStatus = "failed"
}
elseif ($minorIssues -gt 0) {
    $reviewStatus = "passed-with-issues"
}
elseif ($score -ge [int]$policy.minimum_passing_score) {
    $reviewStatus = "passed"
}
else {
    $reviewStatus = "failed"
}

$today = Get-Date -Format "yyyyMMdd"
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

$existingReviewFiles = Get-ChildItem `
    -Path $taskFolder `
    -Filter "review-REVIEW-$today-*.json" `
    -File `
    -ErrorAction SilentlyContinue

$highestReviewNumber = 0

foreach ($reviewFile in $existingReviewFiles) {
    if ($reviewFile.Name -match "review-REVIEW-$today-(\d{4})\.json") {
        $reviewNumber = [int]$Matches[1]

        if ($reviewNumber -gt $highestReviewNumber) {
            $highestReviewNumber = $reviewNumber
        }
    }
}

$reviewId = "REVIEW-$today-{0:D4}" -f ($highestReviewNumber + 1)

$reviewObject = [ordered]@{
    review_id = $reviewId
    task_id = $TaskId
    reviewer = $Reviewer
    reviewed_at = $timestamp
    status = $reviewStatus
    score = $score
    automatic_checks = @($automaticChecks)
    manual_checks = @($manualChecks)
    issues = @($issues)
    summary = $Summary
    recommendation = $Recommendation
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " AI Office Quality Review" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Task ID:          $TaskId"
Write-Host "Review ID:        $reviewId"
Write-Host "Reviewer:         $Reviewer"
Write-Host "Status:           $reviewStatus"
Write-Host "Score:            $score"
Write-Host "Critical issues:  $criticalIssues"
Write-Host "Major issues:     $majorIssues"
Write-Host "Minor issues:     $minorIssues"
Write-Host "Recommendation:   $Recommendation"
Write-Host ""

Write-Host "Automatic checks:" -ForegroundColor Cyan

foreach ($check in $automaticChecks) {
    if ($check.passed) {
        Write-Host "  [PASS] $($check.name)" -ForegroundColor Green
    }
    else {
        Write-Host "  [FAIL] $($check.name)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Manual checks:" -ForegroundColor Cyan

foreach ($check in $manualChecks) {
    if ($check.passed) {
        Write-Host "  [PASS] $($check.name)" -ForegroundColor Green
    }
    else {
        Write-Host "  [OPEN] $($check.name)" -ForegroundColor Yellow
    }
}

if ($issues.Count -gt 0) {
    Write-Host ""
    Write-Host "Issues:" -ForegroundColor Cyan

    foreach ($issue in $issues) {
        Write-Host (
            "  [{0}] {1}" -f
            $issue.severity.ToUpperInvariant(),
            $issue.description
        )
    }
}

if (-not $Apply) {
    Write-Host ""
    Write-Host "No changes were made." -ForegroundColor Yellow
    Write-Host "Use -Apply to save this review record."
    exit 0
}

$reviewPath = Join-Path $taskFolder "review-$reviewId.json"

$reviewObject |
    ConvertTo-Json -Depth 20 |
    Set-Content `
        -LiteralPath $reviewPath `
        -Encoding UTF8

if ($jsonValid) {
    $historyItems = @($task.history)

    $historyItems += [PSCustomObject]@{
        timestamp = $timestamp
        action = "quality-review"
        actor = $Reviewer
        details = (
            "Review $reviewId completed with status $reviewStatus, " +
            "score $score, and recommendation $Recommendation."
        )
    }

    $task.history = $historyItems
    $task.updated_at = $timestamp

    $task |
        ConvertTo-Json -Depth 20 |
        Set-Content `
            -LiteralPath $taskJsonPath `
            -Encoding UTF8
}

Write-Host ""
Write-Host "Review record saved." -ForegroundColor Green
Write-Host "File: $reviewPath"

