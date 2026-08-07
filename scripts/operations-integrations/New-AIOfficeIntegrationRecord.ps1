param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$IntegrationType,
    [string]$Status = "configured",
    [string]$CapabilitiesJson = "[]",
    [string]$EndpointReference = "",
    [string]$MetadataJson = "{}"
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\operations-integrations\AIOfficeOperations.Common.ps1"

$Policy = Get-AIOfficeOperationsPolicy

if (@($Policy.integration_statuses) -notcontains $Status) {
    throw "Unsupported integration status: $Status"
}

try {
    $Capabilities = @((ConvertFrom-Json -InputObject $CapabilitiesJson) | ForEach-Object { $_ })
    $Metadata = ConvertFrom-Json -InputObject $MetadataJson
}
catch {
    throw "CapabilitiesJson or MetadataJson is invalid JSON."
}

$Id = New-AIOfficeOperationsId -Prefix "OPSINTG"
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    integration_id = $Id
    name = $Name
    integration_type = $IntegrationType
    status = $Status
    capabilities = $Capabilities
    endpoint_reference = $EndpointReference
    health = [ordered]@{
        last_checked_at = ""
        status = "unknown"
        details = ""
    }
    metadata = $Metadata
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeOperationsJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\operations-integrations\integrations\$Id.json"

& "E:\AI\AI-Office\scripts\operations-integrations\Update-AIOfficeOperationsIndex.ps1" | Out-Null

Write-Host "Integration record created: $Id | $Name | $Status" -ForegroundColor Green
return [pscustomobject]$Record
