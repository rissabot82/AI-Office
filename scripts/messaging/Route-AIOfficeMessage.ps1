param(
    [Parameter(Mandatory=$true)][string]$MessageId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMessaging.Common.ps1")

$Root = Get-AIOfficeMessagingRoot
Set-Location $Root

$Message = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
    -MessageId $MessageId

$Routing = Read-AIOfficeMessagingJson `
    -Path ".\config\messaging\routing-policy.json"

if ($null -eq $Routing) {
    throw "Routing policy could not be loaded."
}

$Destination = [string]$Routing.default_route

foreach ($Route in @($Routing.routes)) {
    $TypeMatches = [string]$Route.message_type -eq [string]$Message.message_type
    $TargetMatches = [string]$Route.target -eq [string]$Message.to

    if ($TypeMatches -and $TargetMatches) {
        $Destination = [string]$Route.queue
        break
    }
}

return & ".\scripts\messaging\Move-AIOfficeMessage.ps1" `
    -MessageId $MessageId `
    -DestinationQueue $Destination `
    -Actor "message-router" `
    -Details (
        "Message routed by policy to " +
        $Destination +
        "."
    )
