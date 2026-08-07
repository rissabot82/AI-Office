param(
    [Parameter(Mandatory=$true)][string]$EnterpriseWorkId,
    [Parameter(Mandatory=$true)][string]$StepsJson,
    [string]$ParticipatingDepartmentsJson = "[]",
    [string]$ParticipatingAgentsJson = "[]",
    [switch]$ApprovalRequired
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\autonomous-enterprise\AIOfficeEnterprise.Common.ps1"

$Work = Get-AIOfficeEnterpriseWorkById -EnterpriseWorkId $EnterpriseWorkId

try {
    $Steps = @((ConvertFrom-Json -InputObject $StepsJson) | ForEach-Object { $_ })
    $Departments = @((ConvertFrom-Json -InputObject $ParticipatingDepartmentsJson) | ForEach-Object { $_ })
    $Agents = @((ConvertFrom-Json -InputObject $ParticipatingAgentsJson) | ForEach-Object { $_ })
}
catch {
    throw "StepsJson, ParticipatingDepartmentsJson, or ParticipatingAgentsJson is invalid JSON."
}

if ($Steps.Count -lt 1) {
    throw "Enterprise plan requires at least one step."
}

$Id = New-AIOfficeEnterpriseId -Prefix "ENTPLAN"
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    enterprise_plan_id = $Id
    enterprise_work_id = $EnterpriseWorkId
    work_title = [string]$Work.title
    status = "planned"
    steps = $Steps
    participating_departments = $Departments
    participating_agents = $Agents
    approval_required = [bool]$ApprovalRequired
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeEnterpriseJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\autonomous-enterprise\plans\$Id.json"

$Work.status = "planned"
$Work.updated_at = (Get-Date).ToString("o")
Write-AIOfficeEnterpriseJson `
    -Value $Work `
    -Path "E:\AI\AI-Office\workspace\autonomous-enterprise\work-items\$EnterpriseWorkId.json"

& "E:\AI\AI-Office\scripts\autonomous-enterprise\Update-AIOfficeEnterpriseIndex.ps1" | Out-Null

Write-Host "Enterprise plan created: $Id | steps=$($Steps.Count)" -ForegroundColor Green
return [pscustomobject]$Record
