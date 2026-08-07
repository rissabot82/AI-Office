param(
    [Parameter(Mandatory=$true)][string]$EnterpriseRunId
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\autonomous-enterprise\AIOfficeEnterpriseRuntime.Common.ps1"

$Run = Get-AIOfficeEnterpriseRunById -EnterpriseRunId $EnterpriseRunId

if ([string]$Run.status -eq "completed") {
    Write-Host "Enterprise run already completed: $EnterpriseRunId" -ForegroundColor Yellow
    return $Run
}

return & "E:\AI\AI-Office\scripts\autonomous-enterprise\Invoke-AIOfficeEnterpriseRun.ps1" `
    -EnterpriseRunId $EnterpriseRunId
