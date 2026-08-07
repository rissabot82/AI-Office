param(
    [Parameter(Mandatory=$true)][string]$EnterpriseRunId
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\autonomous-enterprise\AIOfficeEnterprise.Common.ps1"
. "E:\AI\AI-Office\scripts\autonomous-enterprise\AIOfficeEnterpriseRuntime.Common.ps1"

$RunPath = "E:\AI\AI-Office\workspace\autonomous-enterprise\runs\$EnterpriseRunId.json"
$Run = Get-AIOfficeEnterpriseRunById -EnterpriseRunId $EnterpriseRunId
$Plan = Get-AIOfficeEnterprisePlanById -EnterprisePlanId ([string]$Run.enterprise_plan_id)
$WorkPath = "E:\AI\AI-Office\workspace\autonomous-enterprise\work-items\$($Run.enterprise_work_id).json"
$Work = Get-AIOfficeEnterpriseWorkById -EnterpriseWorkId ([string]$Run.enterprise_work_id)

$Context = & "E:\AI\AI-Office\scripts\autonomous-enterprise\Get-AIOfficeEnterpriseContext.ps1" `
    -EnterpriseWorkId ([string]$Run.enterprise_work_id)

$Run.context = $Context
$Run.status = "running"
$Run.updated_at = (Get-Date).ToString("o")
Write-AIOfficeEnterpriseJson -Value $Run -Path $RunPath

$Remaining = @($Plan.steps)

$SafetyCounter = 0

while ($Remaining.Count -gt 0) {
    $SafetyCounter++

    if ($SafetyCounter -gt 100) {
        throw "Enterprise runtime safety limit exceeded."
    }

    $Progress = $false

    foreach ($Step in @($Remaining)) {
        $Dependencies = @($Step.depends_on)
        $Completed = @($Run.completed_steps)

        $Ready = $true
        foreach ($Dependency in $Dependencies) {
            if ($Completed -notcontains [string]$Dependency) {
                $Ready = $false
                break
            }
        }

        if (-not $Ready) {
            continue
        }

        & "E:\AI\AI-Office\scripts\autonomous-enterprise\Invoke-AIOfficeEnterpriseStep.ps1" `
            -EnterpriseRunId $EnterpriseRunId `
            -StepId ([string]$Step.step_id) | Out-Null

        $Run = Get-AIOfficeEnterpriseRunById -EnterpriseRunId $EnterpriseRunId
        $Remaining = @(
            $Remaining |
            Where-Object { [string]$_.step_id -ne [string]$Step.step_id }
        )

        $Progress = $true
        break
    }

    if (-not $Progress) {
        throw "Enterprise runtime could not resolve remaining step dependencies."
    }
}

$Run.status = "completed"
$Run.current_step = ""
$Run.completed_at = (Get-Date).ToString("o")
$Run.updated_at = $Run.completed_at

$Work.status = "completed"
$Work.updated_at = $Run.completed_at

Write-AIOfficeEnterpriseJson -Value $Run -Path $RunPath
Write-AIOfficeEnterpriseJson -Value $Work -Path $WorkPath

& "E:\AI\AI-Office\scripts\autonomous-enterprise\New-AIOfficeEnterpriseCheckpoint.ps1" `
    -EnterpriseRunId $EnterpriseRunId | Out-Null

& "E:\AI\AI-Office\scripts\autonomous-enterprise\Update-AIOfficeEnterpriseIndex.ps1" | Out-Null

Write-Host "Enterprise run completed: $EnterpriseRunId | $(@($Run.completed_steps).Count) steps" -ForegroundColor Green
return $Run
