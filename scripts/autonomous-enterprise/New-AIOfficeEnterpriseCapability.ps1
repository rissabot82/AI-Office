param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$OwnerDepartment,
    [string]$Description = "",
    [switch]$RequiresApproval,
    [string]$MetadataJson = "{}"
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\autonomous-enterprise\AIOfficeEnterprise.Common.ps1"

try {
    $Metadata = ConvertFrom-Json -InputObject $MetadataJson
}
catch {
    throw "MetadataJson is invalid JSON."
}

$Id = New-AIOfficeEnterpriseId -Prefix "ENTCAP"
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    capability_id = $Id
    name = $Name
    owner_department = $OwnerDepartment
    status = "active"
    description = $Description
    requires_approval = [bool]$RequiresApproval
    metadata = $Metadata
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeEnterpriseJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\autonomous-enterprise\capabilities\$Id.json"

& "E:\AI\AI-Office\scripts\autonomous-enterprise\Update-AIOfficeEnterpriseIndex.ps1" | Out-Null

Write-Host "Enterprise capability created: $Id | $Name" -ForegroundColor Green
return [pscustomobject]$Record
