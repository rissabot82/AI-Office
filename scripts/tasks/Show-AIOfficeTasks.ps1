param(
    [Parameter(Mandatory = $false)]
    [string]$Status,

    [Parameter(Mandatory = $false)]
    [string]$Agent
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

$registerPath = ".\workspace\task-register.json"

if (-not (Test-Path -LiteralPath $registerPath)) {
    throw "Task register was not found."
}

$register = Get-Content -LiteralPath $registerPath -Raw | ConvertFrom-Json
$tasks = @($register.tasks)

if (-not [string]::IsNullOrWhiteSpace($Status)) {
    $tasks = $tasks | Where-Object {
        $_.status -eq $Status
    }
}

if (-not [string]::IsNullOrWhiteSpace($Agent)) {
    $tasks = $tasks | Where-Object {
        $_.assigned_agent -eq $Agent
    }
}

if (-not $tasks -or $tasks.Count -eq 0) {
    Write-Host "No matching tasks found." -ForegroundColor Yellow
    exit 0
}

$tasks |
    Sort-Object priority, updated_at |
    Format-Table `
        task_id,
        title,
        status,
        priority,
        assigned_agent,
        due_date `
        -AutoSize
