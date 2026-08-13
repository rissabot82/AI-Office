param(
    [Parameter(Mandatory=$true)][string]$ProviderId,
    [Parameter(Mandatory=$true)][string]$ModelName,
    [string]$Status = "configured",
    [string]$CapabilitiesJson = "[]",
    [string]$ResourceProfileJson = "{}",
    [string]$MetadataJson = "{}"
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"

$Provider = Read-AIOfficeSelfHostingJson `
    -Path "E:\AI\AI-Office\workspace\self-hosting\providers\$ProviderId.json"

if ($null -eq $Provider) {
    throw "Self-hosted provider not found: $ProviderId"
}

try {
    $Capabilities = @((ConvertFrom-Json -InputObject $CapabilitiesJson) | ForEach-Object { $_ })
    $ResourceProfile = ConvertFrom-Json -InputObject $ResourceProfileJson
    $Metadata = ConvertFrom-Json -InputObject $MetadataJson
}
catch {
    throw "CapabilitiesJson, ResourceProfileJson, or MetadataJson is invalid JSON."
}

$Id = New-AIOfficeSelfHostingId -Prefix "SHMODEL"
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    model_profile_id = $Id
    provider_id = $ProviderId
    provider_name = [string]$Provider.name
    model_name = $ModelName
    status = $Status
    capabilities = $Capabilities
    resource_profile = $ResourceProfile
    metadata = $Metadata
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeSelfHostingJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\self-hosting\models\$Id.json"

& "E:\AI\AI-Office\scripts\self-hosting\Update-AIOfficeSelfHostingIndex.ps1" | Out-Null

Write-Host "Local model profile created: $Id | $ModelName" -ForegroundColor Green
return [pscustomobject]$Record
