param(
    [Parameter(Mandatory=$true)][string]$MessageId,
    [Parameter(Mandatory=$true)][string]$Reason,
    [string]$Actor = "message-processor"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMessaging.Common.ps1")

$Root = Get-AIOfficeMessagingRoot
Set-Location $Root

$Message = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
    -MessageId $MessageId

$Queue = [string]$Message.current_queue
$Path = Join-Path `
    (Get-AIOfficeMessageQueuePath -Queue $Queue) `
    ($MessageId + ".json")

$Message.delivery_attempts = [int]$Message.delivery_attempts + 1
$Message.updated_at = (Get-Date).ToString("o")

if ($null -eq $Message.metadata) {
    $Message.metadata = [pscustomobject]@{}
}

if ($null -ne $Message.metadata.PSObject.Properties["last_error"]) {
    $Message.metadata.last_error = $Reason
}
else {
    $Message.metadata | Add-Member `
        -MemberType NoteProperty `
        -Name "last_error" `
        -Value $Reason
}

if ($null -ne $Message.PSObject.Properties["current_queue"]) {
    $Message.PSObject.Properties.Remove("current_queue")
}

Write-AIOfficeMessagingJson -Value $Message -Path $Path

return & ".\scripts\messaging\Move-AIOfficeMessage.ps1" `
    -MessageId $MessageId `
    -DestinationQueue "failed" `
    -Actor $Actor `
    -Details ("Message failed: " + $Reason)
