param(
    [Parameter(Mandatory=$true)][string]$GoalId,
    [Parameter(Mandatory=$true)][double]$MonthlyContribution
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\financial-office\AIOfficeFinancialOffice.Common.ps1"
. "E:\AI\AI-Office\scripts\financial-office\AIOfficeFinancialPlanning.Common.ps1"

$GoalPath = "E:\AI\AI-Office\workspace\financial-office\goals\$GoalId.json"
$Goal = Read-AIOfficeFinancialJson -Path $GoalPath

if ($null -eq $Goal) {
    throw "Financial goal not found: $GoalId"
}

if ($MonthlyContribution -le 0) {
    throw "Monthly contribution must be greater than zero."
}

$Remaining = [math]::Max(0.0, ([double]$Goal.target_amount - [double]$Goal.current_amount))
$Months = if ($Remaining -le 0) { 0 } else { [math]::Ceiling($Remaining / $MonthlyContribution) }

$ProjectionId = New-AIOfficeFinancialPlanningId -Prefix "FINGP"

$Record = [ordered]@{
    projection_id = $ProjectionId
    goal_id = $GoalId
    goal_name = [string]$Goal.name
    remaining_amount = [math]::Round($Remaining,2)
    monthly_contribution = [math]::Round($MonthlyContribution,2)
    months_to_goal = [int]$Months
    projected_completion_date = if ($Months -gt 0) { (Get-Date).AddMonths([int]$Months).ToString("yyyy-MM-dd") } else { (Get-Date).ToString("yyyy-MM-dd") }
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeFinancialJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\financial-office\goal-projections\$ProjectionId.json"

Write-Host "Goal projection created: $ProjectionId | months=$Months" -ForegroundColor Green
return [pscustomobject]$Record
