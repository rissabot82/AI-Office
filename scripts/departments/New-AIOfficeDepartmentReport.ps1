param(
    [Parameter(Mandatory=$true)][string]$Department
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentKnowledge.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$Profile = Get-AIOfficeDepartmentProfile -Department $Department
$Index = Read-AIOfficeDepartmentJson `
    -Path ".\workspace\departments\$Department\department-index.json"

$Knowledge = @(
    & ".\scripts\departments\Search-AIOfficeDepartmentKnowledge.ps1" `
        -Department $Department `
        -Limit 1000
)

$LearningFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\departments\$Department\learning" `
        -Filter "DLR-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$Learning = @(
    foreach ($File in $LearningFiles) {
        Read-AIOfficeDepartmentJson -Path $File.FullName
    }
)

$SuccessCount = @(
    $Learning | Where-Object { $_.event_type -eq "success" }
).Count

$FailureCount = @(
    $Learning | Where-Object { $_.event_type -eq "failure" }
).Count

$TotalOutcomes = $SuccessCount + $FailureCount
$SuccessRate = if ($TotalOutcomes -gt 0) {
    [math]::Round(($SuccessCount / $TotalOutcomes) * 100, 2)
}
else {
    0
}

$Report = [ordered]@{
    report_id = (
        "DPR-" +
        $Department.ToUpperInvariant().Replace("-", "_") +
        "-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss")
    )
    department = $Department
    department_name = [string]$Profile.name
    generated_at = (Get-Date).ToString("o")
    status = [string]$Profile.status
    inbox_count = [int]$Index.inbox_count
    plan_count = [int]$Index.plan_count
    active_work_count = [int]$Index.active_work_count
    knowledge_item_count = $Knowledge.Count
    learning_event_count = $Learning.Count
    success_count = $SuccessCount
    failure_count = $FailureCount
    success_rate = $SuccessRate
    knowledge = $Knowledge
}

$Path = Join-Path `
    ".\workspace\departments\$Department\reports" `
    ([string]$Report.report_id + ".json")

Write-AIOfficeDepartmentJson -Value $Report -Path $Path

Write-Host "Department report created: $($Report.report_id)" `
    -ForegroundColor Green

return [pscustomobject]$Report
