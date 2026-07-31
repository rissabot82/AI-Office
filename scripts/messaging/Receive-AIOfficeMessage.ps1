param(
    [string]$Queue = "inbox",
    [string]$Recipient = "",
    [switch]$Peek
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMessaging.Common.ps1")

$Root = Get-AIOfficeMessagingRoot
Set-Location $Root

$QueuePath = Get-AIOfficeMessageQueuePath -Queue $Queue

$PriorityRank = @{
    critical = 1
    urgent = 2
    high = 3
    normal = 4
    low = 5
}

$Candidates = New-Object System.Collections.Generic.List[object]

foreach ($File in @(
    Get-ChildItem `
        -LiteralPath $QueuePath `
        -Filter "MSG-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)) {
    $Message = Read-AIOfficeMessagingJson -Path $File.FullName

    if ($null -eq $Message) {
        continue
    }

    if (-not [string]::IsNullOrWhiteSpace($Recipient) -and
        [string]$Message.to -ne $Recipient) {
        continue
    }

    $AvailableAt = Get-Date

    if (-not [string]::IsNullOrWhiteSpace([string]$Message.available_at)) {
        $AvailableAt = [datetime]$Message.available_at
    }

    if ($AvailableAt -gt (Get-Date)) {
        continue
    }

    $Rank = 99

    if ($PriorityRank.ContainsKey([string]$Message.priority)) {
        $Rank = [int]$PriorityRank[[string]$Message.priority]
    }

    $Candidates.Add([pscustomobject]@{
        file = $File
        message = $Message
        priority_rank = $Rank
        created_at = [datetime]$Message.created_at
    })
}

$Selected = $Candidates |
    Sort-Object priority_rank, created_at |
    Select-Object -First 1

if ($null -eq $Selected) {
    return $null
}

if (-not $Peek) {
    & ".\scripts\messaging\Move-AIOfficeMessage.ps1" `
        -MessageId ([string]$Selected.message.message_id) `
        -DestinationQueue "processing" `
        -Actor "message-receiver" `
        -Details "Message claimed for processing." |
        Out-Null
}

return & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
    -MessageId ([string]$Selected.message.message_id)
