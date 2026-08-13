param()

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"

$Policy = & "E:\AI\AI-Office\scripts\self-hosting\Get-AIOfficeModelFleetPolicy.ps1"

$Models = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\models" `
    -Filter "SHMODEL-*.json"

$FleetModels = @(
    foreach ($Definition in @($Policy.profiles)) {
        $Match = @(
            $Models |
            Where-Object {
                [string]$_.model_name -eq [string]$Definition.model -or
                [string]$_.model_name -eq ([string]$Definition.model + ":latest")
            } |
            Select-Object -First 1
        )

        [ordered]@{
            role = [string]$Definition.role
            configured_model = [string]$Definition.model
            required = [bool]$Definition.required
            installed = ($Match.Count -gt 0)
            model_profile_id = if ($Match.Count -gt 0) { [string]$Match[0].model_profile_id } else { "" }
            status = if ($Match.Count -gt 0) { [string]$Match[0].status } else { "missing" }
            capabilities = @($Definition.capabilities)
            workloads = @($Definition.workloads)
        }
    }
)

$Id = New-AIOfficeSelfHostingId -Prefix "SHFLEET"

$Snapshot = [ordered]@{
    fleet_id = $Id
    provider = "ollama"
    status = if (@($FleetModels | Where-Object { $_.required -and -not $_.installed }).Count -eq 0) { "ready" } else { "degraded" }
    models = $FleetModels
    created_at = (Get-Date).ToString("o")
    updated_at = (Get-Date).ToString("o")
}

Write-AIOfficeSelfHostingJson `
    -Value $Snapshot `
    -Path "E:\AI\AI-Office\workspace\self-hosting\fleets\$Id.json"

Write-Host "Model fleet snapshot created: $Id | $($Snapshot.status)" -ForegroundColor Green
return [pscustomobject]$Snapshot
