param(
    [ValidateSet("inbox","outbox")]
    [string]$ReturnQueue = "inbox",
    [int]$Limit = 100
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMessaging.Common.ps1")

$Root = Get-AIOfficeMessagingRoot
Set-Location $Root

$Files = @(
    Get-ChildItem `
        -LiteralPath (Get-AIOfficeMessageQueuePath -Queue "failed") `
        -Filter "MSG-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime |
        Select-Object -First $Limit
)

$Results = New-Object System.Collections.Generic.List[object]

foreach ($File in $Files) {
    try {
        $Message = & ".\scripts\messaging\Retry-AIOfficeMessage.ps1" `
            -MessageId $File.BaseName `
            -ReturnQueue $ReturnQueue

        $Results.Add([pscustomobject]@{
            message_id = $File.BaseName
            result = [string]$Message.status
        })
    }
    catch {
        $Results.Add([pscustomobject]@{
            message_id = $File.BaseName
            result = "error: " + $_.Exception.Message
        })
    }
}

return @($Results | ForEach-Object { $_ })
