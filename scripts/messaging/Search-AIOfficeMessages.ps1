param(
    [string]$Queue = "",
    [string]$From = "",
    [string]$To = "",
    [string]$MessageType = "",
    [string]$ConversationId = "",
    [string]$CorrelationId = "",
    [int]$Limit = 100
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

if (-not [string]::IsNullOrWhiteSpace($Queue)) {
    $Queues = @($Queue)
}

$Results = New-Object System.Collections.Generic.List[object]

foreach ($CurrentQueue in $Queues) {
    $Path = Get-AIOfficeMessageQueuePath -Queue $CurrentQueue

    foreach ($File in @(
        Get-ChildItem `
            -LiteralPath $Path `
            -Filter "MSG-*.json" `
            -File `
            -ErrorAction SilentlyContinue
    )) {
        $Message = Read-AIOfficeMessagingJson -Path $File.FullName

        if ($null -eq $Message) {
            continue
        }

        if ($From -and [string]$Message.from -ne $From) {
            continue
        }

        if ($To -and [string]$Message.to -ne $To) {
            continue
        }

        if ($MessageType -and [string]$Message.message_type -ne $MessageType) {
            continue
        }

        if ($ConversationId -and
            [string]$Message.conversation_id -ne $ConversationId) {
            continue
        }

        if ($CorrelationId -and
            [string]$Message.correlation_id -ne $CorrelationId) {
            continue
        }

        $Results.Add([pscustomobject]@{
            queue = $CurrentQueue
            message_id = [string]$Message.message_id
            correlation_id = [string]$Message.correlation_id
            conversation_id = [string]$Message.conversation_id
            from = [string]$Message.from
            to = [string]$Message.to
            message_type = [string]$Message.message_type
            priority = [string]$Message.priority
            status = [string]$Message.status
            subject = [string]$Message.subject
            created_at = [string]$Message.created_at
        })
    }
}

return @(
    $Results |
        Sort-Object created_at -Descending |
        Select-Object -First $Limit
)
