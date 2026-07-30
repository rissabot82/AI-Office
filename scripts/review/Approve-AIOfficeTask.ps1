param(
    [Parameter(Mandatory = $true)]
    [string]$TaskId,

    [Parameter(Mandatory = $true)]
    [ValidateSet(
        "approved",
        "approved-with-minor-corrections",
        "returned-for-revision",
        "rejected"
    )]
    [string]$Decision,

    [Parameter(Mandatory = $false)]
    [string]$ApprovedBy = "Clarissa",

    [Parameter(Mandatory = $false)]
    [string]$Notes = "",

    [Parameter(Mandatory = $false)]
    [switch]$Force
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

$policy = Get-Content `
    -LiteralPath ".\config\review\review-policy.json" `
    -Raw |
    ConvertFrom-Json

$taskFolder = Find-TaskFolder -RequestedTaskId $TaskId

if ([string]::IsNullOrWhiteSpace($taskFolder)) {
    throw "Task folder not found: $TaskId"
}

$taskJsonPath = Join-Path $taskFolder "task.json"

if (-not (Test-Path -LiteralPath $taskJsonPath -PathType Leaf)) {
    throw "task.json was not found for task $TaskId."
}

$task = Get-Content -LiteralPath $taskJsonPath -Raw | ConvertFrom-Json

$reviewFiles = Get-ChildItem `
    -Path $taskFolder `
    -Filter "review-REVIEW-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending

$latestReview = $null
$latestReviewFile = $null

if ($reviewFiles.Count -gt 0) {
    $latestReviewFile = $reviewFiles[0]
    $latestReview = Get-Content `
        -LiteralPath $latestReviewFile.FullName `
        -Raw |
        ConvertFrom-Json
}

$approvalDecision = @(
    "approved",
    "approved-with-minor-corrections"
) -contains $Decision

if (
    $approvalDecision -and
    $policy.require_review_before_approval -and
    $null -eq $latestReview -and
    -not $Force
) {
    throw "No saved quality review was found. Review the task before approval."
}

if ($approvalDecision -and $null -ne $latestReview -and -not $Force) {
    if (
        $policy.block_approval_on_major_issues -and
        @($latestReview.issues | Where-Object {
            $_.severity -eq "major"
        }).Count -gt 0
    ) {
        throw "The latest review contains major issues. Use revision or -Force."
    }

    if (
        $policy.block_approval_on_critical_issues -and
        @($latestReview.issues | Where-Object {
            $_.severity -eq "critical"
        }).Count -gt 0
    ) {
        throw "The latest review contains critical issues. Use revision or -Force."
    }

    if (
        [int]$latestReview.score -lt
        [int]$policy.minimum_passing_score
    ) {
        throw "The latest review score is below the passing requirement."
    }
}

$today = Get-Date -Format "yyyyMMdd"
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

$existingApprovalFiles = Get-ChildItem `
    -Path $taskFolder `
    -Filter "approval-APPROVAL-$today-*.json" `
    -File `
    -ErrorAction SilentlyContinue

$highestApprovalNumber = 0

foreach ($approvalFile in $existingApprovalFiles) {
    if ($approvalFile.Name -match "approval-APPROVAL-$today-(\d{4})\.json") {
        $approvalNumber = [int]$Matches[1]

        if ($approvalNumber -gt $highestApprovalNumber) {
            $highestApprovalNumber = $approvalNumber
        }
    }
}

$approvalId = "APPROVAL-$today-{0:D4}" -f ($highestApprovalNumber + 1)

if ($latestReview) {
    $reviewId = [string]$latestReview.review_id
}
else {
    $reviewId = $null
}

$approvalObject = [ordered]@{
    approval_id = $approvalId
    task_id = $TaskId
    review_id = $reviewId
    decision = $Decision
    approved_by = $ApprovedBy
    approved_at = $timestamp
    notes = $Notes
    conditions = @()
}

$approvalPath = Join-Path $taskFolder "approval-$approvalId.json"

$approvalObject |
    ConvertTo-Json -Depth 15 |
    Set-Content `
        -LiteralPath $approvalPath `
        -Encoding UTF8

switch ($Decision) {
    "approved" {
        $task.approval_status = "approved"
    }

    "approved-with-minor-corrections" {
        $task.approval_status = "approved"
    }

    "returned-for-revision" {
        $task.approval_status = "pending"
    }

    "rejected" {
        $task.approval_status = "rejected"
    }
}

$historyItems = @($task.history)

$historyItems += [PSCustomObject]@{
    timestamp = $timestamp
    action = "approval-decision"
    actor = $ApprovedBy
    details = (
        "Approval $approvalId recorded with decision $Decision. $Notes"
    ).Trim()
}

$task.history = $historyItems
$task.updated_at = $timestamp

$task |
    ConvertTo-Json -Depth 20 |
    Set-Content `
        -LiteralPath $taskJsonPath `
        -Encoding UTF8

$registerPath = ".\workspace\task-register.json"
$register = Get-Content -LiteralPath $registerPath -Raw | ConvertFrom-Json

foreach ($registerTask in @($register.tasks)) {
    if ($registerTask.task_id -eq $TaskId) {
        $registerTask.updated_at = $timestamp
    }
}

$register.updated_at = $timestamp

$register |
    ConvertTo-Json -Depth 15 |
    Set-Content `
        -LiteralPath $registerPath `
        -Encoding UTF8

Write-Host ""
Write-Host "Approval decision recorded." -ForegroundColor Green
Write-Host "Task ID:       $TaskId"
Write-Host "Approval ID:   $approvalId"
Write-Host "Decision:      $Decision"
Write-Host "Approval state: $($task.approval_status)"
Write-Host "File:          $approvalPath"
