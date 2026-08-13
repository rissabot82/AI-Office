param(
    [Parameter(Mandatory=$true)][string]$Name,
    [int]$Priority = 100,
    [Parameter(Mandatory=$true)][string]$ConditionsJson,
    [Parameter(Mandatory=$true)][string]$DestinationJson
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"

try {
    $Conditions = ConvertFrom-Json -InputObject $ConditionsJson
    $Destination = ConvertFrom-Json -InputObject $DestinationJson
}
catch {
    throw "ConditionsJson or DestinationJson is invalid JSON."
}

$Id = New-AIOfficeSelfHostingId -Prefix "SHROUTE"
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    routing_rule_id = $Id
    name = $Name
    priority = $Priority
    conditions = $Conditions
    destination = $Destination
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeSelfHostingJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\self-hosting\routing-rules\$Id.json"

& "E:\AI\AI-Office\scripts\self-hosting\Update-AIOfficeSelfHostingIndex.ps1" | Out-Null

Write-Host "Model routing rule created: $Id | $Name" -ForegroundColor Green
return [pscustomobject]$Record
