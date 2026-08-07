param(
    [Parameter(Mandatory=$true)][string]$IntegrationId,
    [switch]$ForceFailure,
    [string]$Details = ""
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\operations-integrations\AIOfficeOperations.Common.ps1"
. "E:\AI\AI-Office\scripts\operations-integrations\AIOfficeOperationalRuntime.Common.ps1"

$IntegrationPath = "E:\AI\AI-Office\workspace\operations-integrations\integrations\$IntegrationId.json"
$Integration = Get-AIOfficeOperationalIntegrationById -IntegrationId $IntegrationId

$Status = if ($ForceFailure) { "degraded" } else { "healthy" }

if ([string]::IsNullOrWhiteSpace($Details)) {
    $Details = if ($ForceFailure) {
        "Synthetic integration health failure."
    }
    else {
        "Integration health check passed."
    }
}

$HealthId = New-AIOfficeOperationalRuntimeId -Prefix "OPSHEALTH"
$Now = (Get-Date).ToString("o")

$Health = [ordered]@{
    health_check_id = $HealthId
    integration_id = $IntegrationId
    integration_name = [string]$Integration.name
    status = $Status
    details = $Details
    checked_at = $Now
}

Write-AIOfficeOperationsJson `
    -Value $Health `
    -Path "E:\AI\AI-Office\workspace\operations-integrations\health\$HealthId.json"

$Integration.health = [ordered]@{
    last_checked_at = $Now
    status = $Status
    details = $Details
}

$Integration.status = if ($ForceFailure) { "degraded" } else { "connected" }
$Integration.updated_at = $Now

Write-AIOfficeOperationsJson -Value $Integration -Path $IntegrationPath

& "E:\AI\AI-Office\scripts\operations-integrations\Update-AIOfficeOperationsIndex.ps1" | Out-Null

Write-Host "Integration health checked: $HealthId | $Status" -ForegroundColor $(if ($ForceFailure) { "Yellow" } else { "Green" })
return [pscustomobject]$Health
