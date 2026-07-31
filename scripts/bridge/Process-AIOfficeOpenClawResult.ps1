param(
    [Parameter(Mandatory=$true)][string]$ExecutionId,
    [string]$Recipient = "chief-of-staff"
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

try {
    $Published = & ".\scripts\bridge\Publish-AIOfficeOpenClawResult.ps1" `
        -ExecutionId $ExecutionId `
        -Recipient $Recipient

    & ".\scripts\bridge\Update-AIOfficeBridgeIndex.ps1" |
        Out-Null

    return $Published
}
catch {
    $Failure = [ordered]@{
        recorded_at = (Get-Date).ToString("o")
        execution_id = $ExecutionId
        error = $_.Exception.Message
        type = $_.Exception.GetType().FullName
    }

    $FailurePath = Join-Path `
        ".\workspace\bridge\failed\results" `
        ($ExecutionId + "-" + (Get-Date).ToString("yyyyMMdd-HHmmss") + ".json")

    $Failure |
        ConvertTo-Json -Depth 30 |
        Set-Content -LiteralPath $FailurePath -Encoding UTF8

    throw
}
