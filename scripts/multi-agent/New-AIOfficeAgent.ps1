param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$Role,
    [Parameter(Mandatory=$true)][string]$Department,
    [string]$CapabilitiesJson = "[]",
    [string]$PermissionsJson = "[]",
    [string]$MetadataJson = "{}"
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\multi-agent\AIOfficeMultiAgent.Common.ps1"

$Policy = Get-AIOfficeMultiAgentPolicy

if (@($Policy.roles) -notcontains $Role) {
    throw "Unsupported agent role: $Role"
}

try {
    $Capabilities = @((ConvertFrom-Json -InputObject $CapabilitiesJson) | ForEach-Object { $_ })
    $Permissions = @((ConvertFrom-Json -InputObject $PermissionsJson) | ForEach-Object { $_ })
    $Metadata = ConvertFrom-Json -InputObject $MetadataJson
}
catch {
    throw "CapabilitiesJson, PermissionsJson, or MetadataJson is invalid JSON."
}

$AgentId = New-AIOfficeAgentId
$Now = (Get-Date).ToString("o")

$Agent = [ordered]@{
    agent_id = $AgentId
    name = $Name
    role = $Role
    department = $Department
    status = [string]$Policy.default_agent_status
    capabilities = $Capabilities
    permissions = $Permissions
    metadata = $Metadata
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeMultiAgentJson `
    -Value $Agent `
    -Path "E:\AI\AI-Office\workspace\multi-agent\agents\$AgentId.json"

& "E:\AI\AI-Office\scripts\multi-agent\Update-AIOfficeAgentIndex.ps1" | Out-Null

Write-Host "Agent created: $AgentId | $Name | $Department" -ForegroundColor Green
return [pscustomobject]$Agent
