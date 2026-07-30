$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

$errorsFound = 0

Write-Host ""
Write-Host "Testing AI Office task system..." -ForegroundColor Cyan
Write-Host ""

$jsonFiles = @(
    ".\config\tasks\task-schema.json",
    ".\config\tasks\status-values.json",
    ".\config\tasks\priority-values.json",
    ".\config\tasks\routing-rules.json",
    ".\workspace\templates\task-template.json",
    ".\workspace\task-register.json"
)

foreach ($file in $jsonFiles) {
    try {
        Get-Content -LiteralPath $file -Raw |
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

$taskFiles = Get-ChildItem `
    -Path ".\workspace" `
    -Filter "task.json" `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue

foreach ($taskFile in $taskFiles) {
    try {
        $task = Get-Content -LiteralPath $taskFile.FullName -Raw |
            ConvertFrom-Json

        if ([string]::IsNullOrWhiteSpace($task.task_id)) {
            throw "Missing task_id."
        }

        if ([string]::IsNullOrWhiteSpace($task.status)) {
            throw "Missing status."
        }

        Write-Host "[VALID TASK] $($task.task_id)" -ForegroundColor Green
    }
    catch {
        Write-Host "[BAD TASK  ] $($taskFile.FullName)" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $errorsFound++
    }
}

Write-Host ""

if ($errorsFound -eq 0) {
    Write-Host "All task system checks passed." -ForegroundColor Green
}
else {
    Write-Host "$errorsFound error or errors were found." -ForegroundColor Red
    exit 1
}
