param(
    [Parameter(Mandatory=$true)][string]$Title,
    [Parameter(Mandatory=$true)][string]$Domain,
    [Parameter(Mandatory=$true)][string]$Objective,
    [string]$Priority = "normal",
    [string]$RequestedBy = "",
    [string]$SourceRef = "",
    [string]$ContextRefsJson = "[]",
    [string]$MetadataJson = "{}"
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\autonomous-enterprise\AIOfficeEnterprise.Common.ps1"

$Policy = Get-AIOfficeEnterprisePolicy

if (@($Policy.enterprise_domains) -notcontains $Domain) {
    throw "Unsupported enterprise domain: $Domain"
}

if (@($Policy.enterprise_priorities) -notcontains $Priority) {
    throw "Unsupported enterprise priority: $Priority"
}

try {
    $ContextRefs = @((ConvertFrom-Json -InputObject $ContextRefsJson) | ForEach-Object { $_ })
    $Metadata = ConvertFrom-Json -InputObject $MetadataJson
}
catch {
    throw "ContextRefsJson or MetadataJson is invalid JSON."
}

$Id = New-AIOfficeEnterpriseId -Prefix "ENTWORK"
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    enterprise_work_id = $Id
    title = $Title
    domain = $Domain
    priority = $Priority
    status = "captured"
    objective = $Objective
    requested_by = $RequestedBy
    source_ref = $SourceRef
    context_refs = $ContextRefs
    metadata = $Metadata
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeEnterpriseJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\autonomous-enterprise\work-items\$Id.json"

& "E:\AI\AI-Office\scripts\autonomous-enterprise\Update-AIOfficeEnterpriseIndex.ps1" | Out-Null

Write-Host "Enterprise work item created: $Id | $Title" -ForegroundColor Green
return [pscustomobject]$Record
