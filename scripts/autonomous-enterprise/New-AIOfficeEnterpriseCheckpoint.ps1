param(
    [Parameter(Mandatory=$true)][string]$EnterpriseRunId
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\autonomous-enterprise\AIOfficeEnterprise.Common.ps1"
. "E:\AI\AI-Office\scripts\autonomous-enterprise\AIOfficeEnterpriseRuntime.Common.ps1"

$Run = Get-AIOfficeEnterpriseRunById -EnterpriseRunId $EnterpriseRunId
$Id = New-AIOfficeEnterpriseRuntimeId -Prefix "ENTCHK"

$Record = [ordered]@{
    checkpoint_id = $Id
    enterprise_run_id = $EnterpriseRunId
    status = [string]$Run.status
    current_step = [string]$Run.current_step
    completed_steps = @($Run.completed_steps)
    failed_steps = @($Run.failed_steps)
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeEnterpriseJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\autonomous-enterprise\checkpoints\$Id.json"

Write-Host "Enterprise checkpoint created: $Id" -ForegroundColor DarkGreen
return [pscustomobject]$Record
