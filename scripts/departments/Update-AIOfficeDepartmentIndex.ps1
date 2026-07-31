param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartments.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$Policy = Get-AIOfficeDepartmentPolicy

if ($null -eq $Policy) {
    throw "Department Intelligence policy could not be loaded."
}

$DepartmentRecords = New-Object System.Collections.Generic.List[object]

$TotalInbox = 0
$TotalPlans = 0
$TotalWork = 0
$TotalKnowledge = 0
$ActiveDepartments = 0

foreach ($Department in @($Policy.departments)) {
    $Base = ".\workspace\departments\$Department"

    $Counts = [ordered]@{
        inbox = @(
            Get-ChildItem "$Base\inbox" -File -ErrorAction SilentlyContinue
        ).Count
        plans = @(
            Get-ChildItem "$Base\plans" -File -ErrorAction SilentlyContinue
        ).Count
        work = @(
            Get-ChildItem "$Base\work" -File -ErrorAction SilentlyContinue
        ).Count
        knowledge = @(
            Get-ChildItem "$Base\knowledge" -File -ErrorAction SilentlyContinue
        ).Count
        reports = @(
            Get-ChildItem "$Base\reports" -File -ErrorAction SilentlyContinue
        ).Count
    }

    $LatestWork = @(
        Get-ChildItem "$Base\work" -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
    )

    $Profile = Get-AIOfficeDepartmentProfile -Department $Department

    $Index = [ordered]@{
        schema_version = "1.0.0"
        department = $Department
        updated_at = (Get-Date).ToString("o")
        status = [string]$Profile.status
        inbox_count = [int]$Counts.inbox
        plan_count = [int]$Counts.plans
        active_work_count = [int]$Counts.work
        knowledge_item_count = [int]$Counts.knowledge
        report_count = [int]$Counts.reports
        latest_work_id = if ($LatestWork.Count -gt 0) {
            $LatestWork[0].BaseName
        }
        else {
            ""
        }
    }

    Write-AIOfficeDepartmentJson `
        -Value $Index `
        -Path "$Base\department-index.json"

    $DepartmentRecords.Add([pscustomobject]$Index)

    $TotalInbox += [int]$Counts.inbox
    $TotalPlans += [int]$Counts.plans
    $TotalWork += [int]$Counts.work
    $TotalKnowledge += [int]$Counts.knowledge

    if ([string]$Profile.status -eq "ready") {
        $ActiveDepartments++
    }
}

$Global = [ordered]@{
    schema_version = "1.0.0"
    version = "1.2.0"
    updated_at = (Get-Date).ToString("o")
    status = "ready"
    department_count = $DepartmentRecords.Count
    active_department_count = $ActiveDepartments
    total_inbox_count = $TotalInbox
    total_plan_count = $TotalPlans
    total_active_work_count = $TotalWork
    total_knowledge_item_count = $TotalKnowledge
    departments = @($DepartmentRecords | ForEach-Object { $_ })
}

Write-AIOfficeDepartmentJson `
    -Value $Global `
    -Path ".\workspace\departments\index\department-intelligence-index.json"

Write-Host (
    "Department Intelligence index updated: " +
    $DepartmentRecords.Count.ToString() +
    " department(s)"
) -ForegroundColor Green

return [pscustomobject]$Global
