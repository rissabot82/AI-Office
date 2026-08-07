param(
    [Parameter(Mandatory=$true)][string]$Channel,
    [Parameter(Mandatory=$true)][string]$Title,
    [string]$Description = "",
    [string]$Priority = "normal",
    [string]$RequestedDepartment = "",
    [string]$RequestedAgent = "",
    [string]$SourceRef = "",
    [string]$MetadataJson = "{}"
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\operations-integrations\AIOfficeOperations.Common.ps1"

$Policy = Get-AIOfficeOperationsPolicy

if (@($Policy.intake_channels) -notcontains $Channel) {
    throw "Unsupported intake channel: $Channel"
}

if (@($Policy.notification_priorities) -notcontains $Priority) {
    throw "Unsupported intake priority: $Priority"
}

try {
    $Metadata = ConvertFrom-Json -InputObject $MetadataJson
}
catch {
    throw "MetadataJson is invalid JSON."
}

$Id = New-AIOfficeOperationsId -Prefix "OPSINT"
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    intake_id = $Id
    channel = $Channel
    title = $Title
    description = $Description
    status = "queued"
    priority = $Priority
    requested_department = $RequestedDepartment
    requested_agent = $RequestedAgent
    source_ref = $SourceRef
    metadata = $Metadata
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeOperationsJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\operations-integrations\intake\$Id.json"

& "E:\AI\AI-Office\scripts\operations-integrations\Update-AIOfficeOperationsIndex.ps1" | Out-Null

Write-Host "Operational intake created: $Id | $Channel | $Title" -ForegroundColor Green
return [pscustomobject]$Record
