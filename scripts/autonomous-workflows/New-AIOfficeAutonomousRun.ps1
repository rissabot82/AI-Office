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
