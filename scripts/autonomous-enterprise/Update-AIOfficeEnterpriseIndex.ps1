param()

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\autonomous-enterprise\AIOfficeEnterprise.Common.ps1"

$WorkItems = Get-AIOfficeEnterpriseCollection `
    -Directory "E:\AI\AI-Office\workspace\autonomous-enterprise\work-items" `
    -Filter "ENTWORK-*.json"

$Plans = Get-AIOfficeEnterpriseCollection `
    -Directory "E:\AI\AI-Office\workspace\autonomous-enterprise\plans" `
    -Filter "ENTPLAN-*.json"

$Departments = Get-AIOfficeEnterpriseCollection `
    -Directory "E:\AI\AI-Office\workspace\autonomous-enterprise\departments" `
    -Filter "ENTDEPT-*.json"

$Capabilities = Get-AIOfficeEnterpriseCollection `
    -Directory "E:\AI\AI-Office\workspace\autonomous-enterprise\capabilities" `
    -Filter "ENTCAP-*.json"

$DomainCounts = [ordered]@{}
$StatusCounts = [ordered]@{}

foreach ($Work in $WorkItems) {
    $Domain = [string]$Work.domain
    $Status = [string]$Work.status

    if (-not $DomainCounts.Contains($Domain)) { $DomainCounts[$Domain] = 0 }
    if (-not $StatusCounts.Contains($Status)) { $StatusCounts[$Status] = 0 }

    $DomainCounts[$Domain]++
    $StatusCounts[$Status]++
}

$ActiveStatuses = @("captured","planned","approved","running","waiting","review")

$Index = [ordered]@{
    version = "2.0.0"
    updated_at = (Get-Date).ToString("o")
    status = "ready"
    work_item_count = @($WorkItems).Count
    active_work_item_count = @(
        $WorkItems |
        Where-Object { @($ActiveStatuses) -contains [string]$_.status }
    ).Count
    plan_count = @($Plans).Count
    active_plan_count = @(
        $Plans |
        Where-Object {
            [string]$_.status -eq "planned" -or
            [string]$_.status -eq "running" -or
            [string]$_.status -eq "waiting"
        }
    ).Count
    department_count = @($Departments).Count
    capability_count = @($Capabilities).Count
    domain_counts = $DomainCounts
    status_counts = $StatusCounts
}

Write-AIOfficeEnterpriseJson `
    -Value $Index `
    -Path "E:\AI\AI-Office\workspace\autonomous-enterprise\indexes\enterprise-index.json"

Write-Host (
    "Enterprise index updated: " +
    $Index.work_item_count +
    " work | " +
    $Index.plan_count +
    " plans | " +
    $Index.department_count +
    " departments | " +
    $Index.capability_count +
    " capabilities"
) -ForegroundColor Green

return [pscustomobject]$Index
