param()

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"
. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeLocalInference.Common.ps1"

$Response = Invoke-AIOfficeOllamaApi -Path "/api/tags"
$Models = @($Response.models)

$Providers = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\providers" `
    -Filter "SHPROV-*.json"

$Provider = @(
    $Providers |
    Where-Object { [string]$_.provider_type -eq "ollama" } |
    Select-Object -First 1
)

if ($Provider.Count -eq 0) {
    $Provider = @(
        & "E:\AI\AI-Office\scripts\self-hosting\New-AIOfficeSelfHostedProvider.ps1" `
            -Name "Local Ollama" `
            -ProviderType "ollama" `
            -Endpoint "http://127.0.0.1:11434" `
            -Status "connected"
    )
}

$Provider = $Provider[0]
$Provider.status = "connected"
$Provider.updated_at = (Get-Date).ToString("o")

Write-AIOfficeSelfHostingJson `
    -Value $Provider `
    -Path "E:\AI\AI-Office\workspace\self-hosting\providers\$($Provider.provider_id).json"

$ExistingProfiles = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\models" `
    -Filter "SHMODEL-*.json"

$Synced = New-Object System.Collections.Generic.List[object]

foreach ($Model in $Models) {
    $Name = [string]$Model.name

    $Existing = @(
        $ExistingProfiles |
        Where-Object {
            [string]$_.provider_id -eq [string]$Provider.provider_id -and
            [string]$_.model_name -eq $Name
        } |
        Select-Object -First 1
    )

    if ($Existing.Count -gt 0) {
        $Profile = $Existing[0]
        $Profile.status = "ready"
        $Profile.updated_at = (Get-Date).ToString("o")

        Write-AIOfficeSelfHostingJson `
            -Value $Profile `
            -Path "E:\AI\AI-Office\workspace\self-hosting\models\$($Profile.model_profile_id).json"
    }
    else {
        $SizeGb = if ($null -ne $Model.size) {
            [math]::Round(([double]$Model.size / 1GB),2)
        }
        else {
            0
        }

        $Profile = & "E:\AI\AI-Office\scripts\self-hosting\New-AIOfficeLocalModelProfile.ps1" `
            -ProviderId ([string]$Provider.provider_id) `
            -ModelName $Name `
            -Status "ready" `
            -CapabilitiesJson '["chat","generation","summarization","classification"]' `
            -ResourceProfileJson ('{"model_size_gb":' + $SizeGb.ToString([Globalization.CultureInfo]::InvariantCulture) + '}') `
            -MetadataJson '{"source":"ollama_inventory"}'
    }

    $Synced.Add($Profile)
}

& "E:\AI\AI-Office\scripts\self-hosting\Update-AIOfficeSelfHostingIndex.ps1" | Out-Null

Write-Host "Ollama model inventory synchronized: $($Synced.Count) model(s)." -ForegroundColor Green
return @($Synced | ForEach-Object { $_ })
