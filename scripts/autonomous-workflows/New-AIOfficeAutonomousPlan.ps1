param(
    [Parameter(Mandatory=$true)][string]$GoalId,
    [Parameter(Mandatory=$true)][string]$StepsJson
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousWorkflows.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

$Goal = Get-AIOfficeAutonomousGoal -GoalId $GoalId

try {
    $ParsedSteps = $StepsJson | ConvertFrom-Json
}
catch {
    throw "StepsJson is invalid: $($_.Exception.Message)"
}

$InputSteps = New-Object System.Collections.Generic.List[object]

foreach ($ParsedStep in $ParsedSteps) {
    $InputSteps.Add($ParsedStep)
}

if ($InputSteps.Count -lt 1) {
    throw "At least one workflow step is required."
}

$Policy = Get-AIOfficeAutonomousWorkflowPolicy

if ($InputSteps.Count -gt [int]$Policy.operating_model.maximum_steps_per_plan) {
    throw "Plan exceeds the maximum supported step count."
}

$Steps = New-Object System.Collections.Generic.List[object]
$StepNumber = 1

foreach ($Step in $InputSteps) {
    $StepType = [string]$Step.step_type

    if (@($Policy.execution.allowed_step_types) -notcontains $StepType) {
        throw "Unsupported autonomous workflow step type: $StepType"
    }

    $StepId = (
        "STEP-" +
        $StepNumber.ToString("000") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )

    $Owner = "chief-of-staff"
    $Department = ""
    $DependsOn = @()
    $Condition = ""

    $OwnerProperty = $Step.PSObject.Properties |
        Where-Object { $_.Name -eq "owner" } |
        Select-Object -First 1

    if ($null -ne $OwnerProperty) {
        $Owner = [string]$OwnerProperty.Value
    }

    $DepartmentProperty = $Step.PSObject.Properties |
        Where-Object { $_.Name -eq "department" } |
        Select-Object -First 1

    if ($null -ne $DepartmentProperty) {
        $Department = [string]$DepartmentProperty.Value
    }

    $DependsOnProperty = $Step.PSObject.Properties |
        Where-Object { $_.Name -eq "depends_on" } |
        Select-Object -First 1

    if ($null -ne $DependsOnProperty) {
        $DependsOn = @($DependsOnProperty.Value)
    }

    $ConditionProperty = $Step.PSObject.Properties |
        Where-Object { $_.Name -eq "condition" } |
        Select-Object -First 1

    if ($null -ne $ConditionProperty) {
        $Condition = [string]$ConditionProperty.Value
    }

    $StepRecord = [ordered]@{
        step_id = $StepId
        step_number = $StepNumber
        title = [string]$Step.title
        step_type = $StepType
        owner = $Owner
        department = $Department
        depends_on = $DependsOn
        condition = $Condition
        status = "pending"
        attempt_count = 0
        max_attempts = [int]$Policy.retry.default_max_attempts
        result = $null
    }

    $Steps.Add([pscustomobject]$StepRecord)
    $StepNumber++
}

$PlanId = New-AIOfficeAutonomousPlanId
$Now = (Get-Date).ToString("o")

$Plan = [ordered]@{
    autonomous_plan_id = $PlanId
    goal_id = $GoalId
    title = [string]$Goal.title
    objective = [string]$Goal.objective
    status = "draft"
    priority = [string]$Goal.priority
    risk_level = [string]$Goal.risk_level
    approval_status = [string]$Goal.approval_status
    steps = @($Steps | ForEach-Object { $_ })
    created_at = $Now
    updated_at = $Now
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = "chief-of-staff"
            details = "Autonomous workflow plan created."
        }
    )
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Plan `
    -Path ".\workspace\autonomous-workflows\plans\$PlanId.json"

$Goal.status = "planned"
$Goal.updated_at = $Now

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Goal `
    -Path ".\workspace\autonomous-workflows\goals\$GoalId.json"

& ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1" |
    Out-Null

Write-Host "Autonomous plan created: $PlanId" -ForegroundColor Green

return [pscustomobject]$Plan
