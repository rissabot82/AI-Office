param(
    [Parameter(Mandatory=$true)][string]$Name,
    [string]$CapabilitiesJson = "[]",
    [string]$AgentIdsJson = "[]",
    [string]$MetadataJson = "{}"
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\autonomous-enterprise\AIOfficeEnterprise.Common.ps1"

try {
    $Capabilities = @((ConvertFrom-Json -InputObject $CapabilitiesJson) | ForEach-Object { $_ })
    $AgentIds = @((ConvertFrom-Json -InputObject $AgentIdsJson) | ForEach-Object { $_ })
    $Metadata = ConvertFrom-Json -InputObject $MetadataJson
}
catch {
    throw "CapabilitiesJson, AgentIdsJson, or MetadataJson is invalid JSON."
}

$Existing = @(
    Get-AIOfficeEnterpriseCollection `
        -Directory "E:\AI\AI-Office\workspace\autonomous-enterprise\departments" `
        -Filter "ENTDEPT-*.json" |
    Where-Object { [string]$_.name -eq $Name }
)

if ($Existing.Count -gt 0) {
    Write-Host "Enterprise department already exists: $($Existing[0].department_id) | $Name" -ForegroundColor Yellow
    return $Existing[0]
}

$Id = New-AIOfficeEnterpriseId -Prefix "ENTDEPT"
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    department_id = $Id
    name = $Name
    status = "active"
    capabilities = $Capabilities
    agent_ids = $AgentIds
    metadata = $Metadata
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeEnterpriseJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\autonomous-enterprise\departments\$Id.json"

& "E:\AI\AI-Office\scripts\autonomous-enterprise\Update-AIOfficeEnterpriseIndex.ps1" | Out-Null

Write-Host "Enterprise department created: $Id | $Name" -ForegroundColor Green
return [pscustomobject]$Record
