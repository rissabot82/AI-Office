param(
    [Parameter(Mandatory=$true)][string]$MessageId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMessaging.Common.ps1")

$Root = Get-AIOfficeMessagingRoot
Set-Location $Root

$Queues = @(
    "inbox",
    "outbox",
    "processing",
    "processed",
    "failed",
    "dead-letter",
    "archive"
)

foreach ($Queue in $Queues) {
    $Path = Join-Path `
        (Get-AIOfficeMessageQueuePath -Queue $Queue) `
        ($MessageId + ".json")

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $Message = Read-AIOfficeMessagingJson -Path $Path

        if ($null -eq $Message) {
            throw "Message exists but could not be parsed: $MessageId"
        }

        $Message | Add-Member `
            -MemberType NoteProperty `
            -Name "current_queue" `
            -Value $Queue `
            -Force

        return $Message
    }
}

throw "Message not found: $MessageId"
