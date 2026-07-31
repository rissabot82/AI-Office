$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

Write-Host ""
Write-Host "Testing AI Office workflow engine..." -ForegroundColor Cyan
Write-Host ""

$errorsFound = 0

$jsonFiles = @(
    ".\config\workflows\workflow-policy.json",
    ".\config\workflows\workflow-schema.json",
    ".\config\workflows\workflow-status-values.json",
    ".\config\workflows\workflow-templates.json",
    ".\workspace\templates\workflow-template.json"
)

foreach ($file in $jsonFiles) {
    try {
        Get-Content `
            -LiteralPath $file `
            -Raw |
            ConvertFrom-Json |
            Out-Null

        Write-Host "[VALID JSON] $file" -ForegroundColor Green
    }
    catch {
        Write-Host "[INVALID   ] $file" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $errorsFound++
    }
}

$requiredScripts = @(
    ".\scripts\workflows\New-AIOfficeWorkflow.ps1",
    ".\scripts\workflows\Add-AIOfficeWorkflowTask.ps1",
    ".\scripts\workflows\Show-AIOfficeWorkflow.ps1",
    ".\scripts\workflows\Sync-AIOfficeWorkflow.ps1",
    ".\scripts\workflows\Complete-AIOfficeWorkflow.ps1"
)

foreach ($script in $requiredScripts) {
    if (Test-Path -LiteralPath $script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING     ] $script" -ForegroundColor Red
        $errorsFound++
    }
}

$policy = Get-Content `
    -LiteralPath ".\config\workflows\workflow-policy.json" `
    -Raw |
    ConvertFrom-Json

if (
    -not [string]::IsNullOrWhiteSpace(
        [string]$policy.default_owner
    )
) {
    Write-Host "[VALID OWNER ] Default workflow owner" -ForegroundColor Green
}
else {
    Write-Host "[BAD OWNER   ] Default workflow owner" -ForegroundColor Red
    $errorsFound++
}

$statusFile = Get-Content `
    -LiteralPath ".\config\workflows\workflow-status-values.json" `
    -Raw |
    ConvertFrom-Json

$requiredStatuses = @(
    "planning",
    "ready",
    "active",
    "blocked",
    "review",
    "approved",
    "completed",
    "cancelled",
    "failed",
    "archived"
)

foreach ($requiredStatus in $requiredStatuses) {
    $match = @(
        $statusFile.statuses | Where-Object {
            $_.id -eq $requiredStatus
        }
    )

    if ($match.Count -eq 1) {
        Write-Host (
            "[VALID STATUS] {0}" -f
            $requiredStatus
        ) -ForegroundColor Green
    }
    else {
        Write-Host (
            "[BAD STATUS  ] {0}" -f
            $requiredStatus
        ) -ForegroundColor Red

        $errorsFound++
    }
}

$workflowFiles = Get-ChildItem `
    -Path ".\workspace\workflows" `
    -Filter "workflow.json" `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue

foreach ($workflowFile in $workflowFiles) {
    try {
        $workflow = Get-Content `
            -LiteralPath $workflowFile.FullName `
            -Raw |
            ConvertFrom-Json

        if (
            [string]::IsNullOrWhiteSpace(
                [string]$workflow.workflow_id
            )
        ) {
            throw "workflow_id is missing."
        }

        if ($null -eq $workflow.tasks) {
            throw "tasks array is missing."
        }

        if ($null -eq $workflow.history) {
            throw "history array is missing."
        }

        Write-Host (
            "[VALID FLOW ] {0}" -f
            $workflow.workflow_id
        ) -ForegroundColor Green
    }
    catch {
        Write-Host (
            "[INVALID FLOW] {0}" -f
            $workflowFile.FullName
        ) -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Red
        $errorsFound++
    }
}

Write-Host ""

if ($errorsFound -eq 0) {
    Write-Host "All workflow engine checks passed." -ForegroundColor Green
}
else {
    Write-Host (
        "{0} workflow error or errors were found." -f
        $errorsFound
    ) -ForegroundColor Red

    exit 1
}
