param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$JobType,
    [string]$Schedule = "",
    [string]$Handler = "",
    [string]$Department = "",
    [string]$MetadataJson = "{}"
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\operations-integrations\AIOfficeOperations.Common.ps1"

$Policy = Get-AIOfficeOperationsPolicy

if (@($Policy.job_types) -notcontains $JobType) {
    throw "Unsupported operational job type: $JobType"
}

try {
    $Metadata = ConvertFrom-Json -InputObject $MetadataJson
}
catch {
    throw "MetadataJson is invalid JSON."
}

$Id = New-AIOfficeOperationsId -Prefix "OPSJOB"
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    job_id = $Id
    name = $Name
    job_type = $JobType
    status = "configured"
    schedule = $Schedule
    handler = $Handler
    department = $Department
    metadata = $Metadata
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeOperationsJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\operations-integrations\jobs\$Id.json"

& "E:\AI\AI-Office\scripts\operations-integrations\Update-AIOfficeOperationsIndex.ps1" | Out-Null

Write-Host "Operational job created: $Id | $Name" -ForegroundColor Green
return [pscustomobject]$Record
