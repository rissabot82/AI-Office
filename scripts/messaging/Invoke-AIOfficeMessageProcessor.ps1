param(
    [ValidateSet("inbox","outbox")]
    [string]$Queue = "inbox",
    [string]$Recipient = "",
    [int]$BatchSize = 10,
    [switch]$AutoComplete,
    [switch]$StopOnError
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMessaging.Common.ps1")

$Root = Get-AIOfficeMessagingRoot
Set-Location $Root

$Policy = Read-AIOfficeMessagingJson `
    -Path ".\config\messaging\processing-policy.json"

if ($null -eq $Policy) {
    throw "Processing policy could not be loaded."
}

$MaximumBatch = [int]$Policy.processor.maximum_batch_size

if ($BatchSize -lt 1) {
    $BatchSize = 1
}

if ($BatchSize -gt $MaximumBatch) {
    $BatchSize = $MaximumBatch
}

$Results = New-Object System.Collections.Generic.List[object]

for ($Index = 0; $Index -lt $BatchSize; $Index++) {
    try {
        $Message = & ".\scripts\messaging\Receive-AIOfficeMessage.ps1" `
            -Queue $Queue `
            -Recipient $Recipient

        if ($null -eq $Message) {
            break
        }

        $Result = [ordered]@{
            message_id = [string]$Message.message_id
            status = "claimed"
            queue = "processing"
            error = ""
        }

        if ($AutoComplete) {
            & ".\scripts\messaging\Acknowledge-AIOfficeMessage.ps1" `
                -MessageId ([string]$Message.message_id) `
                -Actor "batch-processor" |
                Out-Null

            & ".\scripts\messaging\Complete-AIOfficeMessage.ps1" `
                -MessageId ([string]$Message.message_id) `
                -Actor "batch-processor" `
                -Details "Message automatically completed by batch processor." |
                Out-Null

            $Result.status = "completed"
            $Result.queue = "processed"
        }

        $Results.Add([pscustomobject]$Result)
    }
    catch {
        $Results.Add([pscustomobject]@{
            message_id = ""
            status = "error"
            queue = $Queue
            error = $_.Exception.Message
        })

        if ($StopOnError) {
            break
        }
    }
}

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
    Out-Null

Write-Host (
    "Processor handled " +
    $Results.Count.ToString() +
    " message(s)."
) -ForegroundColor Green

return @($Results | ForEach-Object { $_ })
