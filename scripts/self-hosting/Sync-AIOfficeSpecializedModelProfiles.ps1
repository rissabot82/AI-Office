param()

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"

$Policy = & "E:\AI\AI-Office\scripts\self-hosting\Get-AIOfficeModelFleetPolicy.ps1"

$Providers = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\providers" `
    -Filter "SHPROV-*.json"

$Provider = @(
    $Providers |
    Where-Object { [string]$_.provider_type -eq "ollama" } |
    Select-Object -First 1
)

if ($Provider.Count -eq 0) {
    throw "Ollama provider is not registered in AI Office."
}

$Provider = $Provider[0]

$Tags = Invoke-RestMethod `
    -Uri "http://127.0.0.1:11434/api/tags" `
    -Method Get `
    -TimeoutSec 30

$InstalledNames = @($Tags.models | ForEach-Object { [string]$_.name })

$ExistingProfiles = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\models" `
    -Filter "SHMODEL-*.json"

$Synced = New-Object System.Collections.Generic.List[object]

foreach ($Definition in @($Policy.profiles)) {
    $ModelName = [string]$Definition.model
    $InstalledName = $null

    foreach ($Name in $InstalledNames) {
        if ($Name -eq $ModelName -or $Name -eq ($ModelName + ":latest")) {
            $InstalledName = $Name
            break
        }
    }

    if ($null -eq $InstalledName) {
        continue
    }

    $Existing = @(
        $ExistingProfiles |
        Where-Object {
            [string]$_.provider_id -eq [string]$Provider.provider_id -and
            (
                [string]$_.model_name -eq $InstalledName -or
                [string]$_.model_name -eq $ModelName
            )
        } |
        Select-Object -First 1
    )

    if ($Existing.Count -gt 0) {
        $Profile = $Existing[0]
        $Profile.status = "ready"
        $Profile.capabilities = @($Definition.capabilities)
        $Profile.metadata = [ordered]@{
            fleet_role = [string]$Definition.role
            workloads = @($Definition.workloads)
            managed_by = "self-hosting-part-f"
        }
        $Profile.updated_at = (Get-Date).ToString("o")

        Write-AIOfficeSelfHostingJson `
            -Value $Profile `
            -Path "E:\AI\AI-Office\workspace\self-hosting\models\$($Profile.model_profile_id).json"
    }
    else {
        $Profile = & "E:\AI\AI-Office\scripts\self-hosting\New-AIOfficeLocalModelProfile.ps1" `
            -ProviderId ([string]$Provider.provider_id) `
            -ModelName $InstalledName `
            -Status "ready" `
            -CapabilitiesJson (@($Definition.capabilities) | ConvertTo-Json -Compress) `
            -MetadataJson (
                [ordered]@{
                    fleet_role = [string]$Definition.role
                    workloads = @($Definition.workloads)
                    managed_by = "self-hosting-part-f"
                } | ConvertTo-Json -Compress
            )
    }

    $Synced.Add($Profile)
}

& "E:\AI\AI-Office\scripts\self-hosting\Update-AIOfficeSelfHostingIndex.ps1" | Out-Null

Write-Host "Specialized model profiles synchronized: $($Synced.Count)" -ForegroundColor Green
return @($Synced | ForEach-Object { $_ })
