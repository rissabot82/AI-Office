param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$GoalType,
    [Parameter(Mandatory=$true)][double]$TargetAmount,
    [double]$CurrentAmount = 0.0,
    [string]$TargetDate = "",
    [string]$Priority = "normal"
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\financial-office\AIOfficeFinancialOffice.Common.ps1"

$Policy = Get-AIOfficeFinancialPolicy

if (@($Policy.goal_types) -notcontains $GoalType) {
    throw "Unsupported financial goal type: $GoalType"
}

$Id = New-AIOfficeFinancialId -Prefix "FINGOAL"
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    goal_id = $Id
    name = $Name
    goal_type = $GoalType
    target_amount = [math]::Round([math]::Abs($TargetAmount),2)
    current_amount = [math]::Round([math]::Abs($CurrentAmount),2)
    target_date = $TargetDate
    priority = $Priority
    status = "active"
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeFinancialJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\financial-office\goals\$Id.json"

& "E:\AI\AI-Office\scripts\financial-office\Update-AIOfficeFinancialIndex.ps1" | Out-Null

Write-Host "Financial goal created: $Id | $Name" -ForegroundColor Green
return [pscustomobject]$Record
