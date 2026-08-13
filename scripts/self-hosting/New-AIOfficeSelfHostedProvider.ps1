param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$ProviderType,
    [Parameter(Mandatory=$true)][string]$Endpoint,
    [string]$Status = "configured",
    [string]$MetadataJson = "{}"
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"

try {
    $Metadata = ConvertFrom-Json -InputObject $MetadataJson
}
catch {
    throw "MetadataJson is invalid JSON."
}

$Id = New-AIOfficeSelfHostingId -Prefix "SHPROV"
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    provider_id = $Id
    name = $Name
    provider_type = $ProviderType
    status = $Status
    endpoint = $Endpoint
    metadata = $Metadata
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeSelfHostingJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\self-hosting\providers\$Id.json"

& "E:\AI\AI-Office\scripts\self-hosting\Update-AIOfficeSelfHostingIndex.ps1" | Out-Null

Write-Host "Self-hosted provider created: $Id | $Name" -ForegroundColor Green
return [pscustomobject]$Record
