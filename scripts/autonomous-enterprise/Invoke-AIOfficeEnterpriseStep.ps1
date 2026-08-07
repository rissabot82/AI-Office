param(
    [Parameter(Mandatory=$true)][string]$EnterpriseRunId,
    [Parameter(Mandatory=$true)][string]$StepId
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\autonomous-enterprise\AIOfficeEnterprise.Common.ps1"
. "E:\AI\AI-Office\scripts\autonomous-enterprise\AIOfficeEnterpriseRuntime.Common.ps1"

$RunPath = "E:\AI\AI-Office\workspace\autonomous-enterprise\runs\$EnterpriseRunId.json"
$Run = Get-AIOfficeEnterpriseRunById -EnterpriseRunId $EnterpriseRunId
$Plan = Get-AIOfficeEnterprisePlanById -EnterprisePlanId ([string]$Run.enterprise_plan_id)

$Step = @(
    $Plan.steps |
    Where-Object { [string]$_.step_id -eq $StepId }
)

if ($Step.Count -ne 1) {
    throw "Enterprise step not found or ambiguous: $StepId"
}

$Step = $Step[0]

foreach ($Dependency in @($Step.depends_on)) {
    if (@($Run.completed_steps) -notcontains [string]$Dependency) {
        throw "Enterprise step dependency not completed: $Dependency"
    }
}

$Run.status = "running"
$Run.current_step = $StepId
$Run.updated_at = (Get-Date).ToString("o")
Write-AIOfficeEnterpriseJson -Value $Run -Path $RunPath

$ResultId = New-AIOfficeEnterpriseRuntimeId -Prefix "ENTSTEP"
$ResultPath = "E:\AI\AI-Office\workspace\autonomous-enterprise\step-results\$ResultId.json"

try {
    $Payload = [ordered]@{
        department = [string]$Step.department
        action = [string]$Step.action
        routed = $true
        execution_mode = "enterprise-runtime"
    }

    if ([string]$Step.department -eq "operations-integrations") {
        $Payload["operations_bridge_available"] = (
            Test-Path -LiteralPath "E:\AI\AI-Office\scripts\operations-integrations\New-AIOfficeOperationalDispatch.ps1"
        )
    }

    if ([string]$Step.department -eq "financial-office") {
        $Payload["financial_office_available"] = (
            Test-Path -LiteralPath "E:\AI\AI-Office\scripts\financial-office\Update-AIOfficeFinancialIndex.ps1"
        )
    }

    if ([string]$Step.department -eq "business-incubator") {
        $Payload["business_incubator_available"] = (
            Test-Path -LiteralPath "E:\AI\AI-Office\scripts\business-incubator\Update-AIOfficeBusinessIncubatorIndex.ps1"
        )
    }

    $Result = [ordered]@{
        step_result_id = $ResultId
        enterprise_run_id = $EnterpriseRunId
        step_id = $StepId
        department = [string]$Step.department
        action = [string]$Step.action
        status = "completed"
        result = $Payload
        error = ""
        created_at = (Get-Date).ToString("o")
    }

    $Completed = @($Run.completed_steps)
    if ($Completed -notcontains $StepId) {
        $Completed += $StepId
    }

    $Run.completed_steps = $Completed
    $Run.current_step = $StepId
    $Run.updated_at = (Get-Date).ToString("o")

    Write-AIOfficeEnterpriseJson -Value $Result -Path $ResultPath
    Write-AIOfficeEnterpriseJson -Value $Run -Path $RunPath

    & "E:\AI\AI-Office\scripts\autonomous-enterprise\New-AIOfficeEnterpriseCheckpoint.ps1" `
        -EnterpriseRunId $EnterpriseRunId | Out-Null

    Write-Host "Enterprise step completed: $StepId | $($Step.department) | $($Step.action)" -ForegroundColor Green
    return [pscustomobject]$Result
}
catch {
    $Failed = @($Run.failed_steps)
    if ($Failed -notcontains $StepId) {
        $Failed += $StepId
    }

    $Run.failed_steps = $Failed
    $Run.status = "failed"
    $Run.updated_at = (Get-Date).ToString("o")

    $Result = [ordered]@{
        step_result_id = $ResultId
        enterprise_run_id = $EnterpriseRunId
        step_id = $StepId
        department = [string]$Step.department
        action = [string]$Step.action
        status = "failed"
        result = [ordered]@{}
        error = $_.Exception.Message
        created_at = (Get-Date).ToString("o")
    }

    Write-AIOfficeEnterpriseJson -Value $Result -Path $ResultPath
    Write-AIOfficeEnterpriseJson -Value $Run -Path $RunPath

    throw
}
