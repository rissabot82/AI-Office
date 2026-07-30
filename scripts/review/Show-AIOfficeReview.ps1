param(
    [Parameter(Mandatory = $true)]
    [string]$TaskId
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

$taskFolder = Get-ChildItem `
    -Path ".\workspace" `
    -Directory `
    -Recurse `
    -Filter $TaskId `
    -ErrorAction SilentlyContinue |
    Select-Object -First 1

if (-not $taskFolder) {
    throw "Task folder not found: $TaskId"
}

$reviewFiles = Get-ChildItem `
    -Path $taskFolder.FullName `
    -Filter "review-REVIEW-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending

$approvalFiles = Get-ChildItem `
    -Path $taskFolder.FullName `
    -Filter "approval-APPROVAL-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " AI Office Review History" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Task ID: $TaskId"
Write-Host ""

if ($reviewFiles.Count -eq 0) {
    Write-Host "No review records found." -ForegroundColor Yellow
}
else {
    Write-Host "Reviews:" -ForegroundColor Cyan

    foreach ($reviewFile in $reviewFiles) {
        $review = Get-Content `
            -LiteralPath $reviewFile.FullName `
            -Raw |
            ConvertFrom-Json

        Write-Host ""
        Write-Host "  Review ID:      $($review.review_id)"
        Write-Host "  Reviewer:       $($review.reviewer)"
        Write-Host "  Date:           $($review.reviewed_at)"
        Write-Host "  Status:         $($review.status)"
        Write-Host "  Score:          $($review.score)"
        Write-Host "  Recommendation: $($review.recommendation)"
        Write-Host "  Issues:         $(@($review.issues).Count)"
    }
}

Write-Host ""

if ($approvalFiles.Count -eq 0) {
    Write-Host "No approval records found." -ForegroundColor Yellow
}
else {
    Write-Host "Approvals:" -ForegroundColor Cyan

    foreach ($approvalFile in $approvalFiles) {
        $approval = Get-Content `
            -LiteralPath $approvalFile.FullName `
            -Raw |
            ConvertFrom-Json

        Write-Host ""
        Write-Host "  Approval ID: $($approval.approval_id)"
        Write-Host "  Decision:    $($approval.decision)"
        Write-Host "  Approved By: $($approval.approved_by)"
        Write-Host "  Date:        $($approval.approved_at)"
        Write-Host "  Review ID:   $($approval.review_id)"
    }
}
