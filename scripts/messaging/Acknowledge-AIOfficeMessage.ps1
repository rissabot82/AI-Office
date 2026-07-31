param(
    [Parameter(Mandatory=$true)][string]$MessageId,
    [string]$Actor = "recipient"
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

$Now = (Get-Date).ToString("o")
$Message.status = "acknowledged"
$Message.acknowledged_at = $Now
$Message.updated_at = $Now

$History = New-Object System.Collections.Generic.List[object]

foreach ($Entry in (ConvertTo-AIOfficeMessageArray $Message.history)) {
    $History.Add($Entry)
}

$History.Add([ordered]@{
    timestamp = $Now
    action = "acknowledged"
    actor = $Actor
    details = "Message acknowledged."
})

$Message.history = @($History | ForEach-Object { $_ })

if ($null -ne $Message.PSObject.Properties["current_queue"]) {
    $Message.PSObject.Properties.Remove("current_queue")
}

Write-AIOfficeMessagingJson -Value $Message -Path $Path

Write-Host "Message acknowledged: $MessageId" -ForegroundColor Green
return $Message
