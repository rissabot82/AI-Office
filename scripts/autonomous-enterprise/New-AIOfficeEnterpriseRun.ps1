param(
    [Parameter(Mandatory=$true)][string]$EnterprisePlanId
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\autonomous-enterprise\AIOfficeEnterprise.Common.ps1"
. "E:\AI\AI-Office\scripts\autonomous-enterprise\AIOfficeEnterpriseRuntime.Common.ps1"

$Plan = Get-AIOfficeEnterprisePlanById -EnterprisePlanId $EnterprisePlanId
$Work = Get-AIOfficeEnterpriseWorkById -EnterpriseWorkId ([string]$Plan.enterprise_work_id)

$Id = New-AIOfficeEnterpriseRuntimeId -Prefix "ENTRUN"
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    enterprise_run_id = $Id
    enterprise_plan_id = $EnterprisePlanId
    enterprise_work_id = [string]$Plan.enterprise_work_id
    work_title = [string]$Work.title
    status = "queued"
    current_step = ""
    completed_steps = @()
    failed_steps = @()
    context = [ordered]@{}
    created_at = $Now
    updated_at = $Now
    completed_at = ""
}

Write-AIOfficeEnterpriseJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\autonomous-enterprise\runs\$Id.json"

Write-Host "Enterprise run created: $Id" -ForegroundColor Green
return [pscustomobject]$Record
