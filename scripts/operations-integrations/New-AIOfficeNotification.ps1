param(
    [Parameter(Mandatory=$true)][string]$Title,
    [Parameter(Mandatory=$true)][string]$Message,
    [string]$Priority = "normal",
    [string]$Channel = "dashboard",
    [string]$SourceRef = ""
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\operations-integrations\AIOfficeOperations.Common.ps1"

$Policy = Get-AIOfficeOperationsPolicy

if (@($Policy.notification_priorities) -notcontains $Priority) {
    throw "Unsupported notification priority: $Priority"
}

$Id = New-AIOfficeOperationsId -Prefix "OPSNOT"

$Record = [ordered]@{
    notification_id = $Id
    title = $Title
    message = $Message
    priority = $Priority
    status = "unread"
    channel = $Channel
    source_ref = $SourceRef
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeOperationsJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\operations-integrations\notifications\$Id.json"

& "E:\AI\AI-Office\scripts\operations-integrations\Update-AIOfficeOperationsIndex.ps1" | Out-Null

Write-Host "Notification created: $Id | $Priority | $Title" -ForegroundColor Green
return [pscustomobject]$Record
