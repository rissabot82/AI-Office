param(
    [Parameter(Mandatory=$true)][string]$DispatchId
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\operations-integrations\AIOfficeOperations.Common.ps1"
. "E:\AI\AI-Office\scripts\operations-integrations\AIOfficeOperationalRuntime.Common.ps1"

$Policy = Get-AIOfficeOperationalRuntimePolicy
$Path = "E:\AI\AI-Office\workspace\operations-integrations\dispatch\$DispatchId.json"
$Dispatch = Read-AIOfficeOperationsJson -Path $Path

if ($null -eq $Dispatch) {
    throw "Operational dispatch not found: $DispatchId"
}

if ([string]$Dispatch.status -eq "completed") {
    Write-Host "Operational dispatch already completed: $DispatchId" -ForegroundColor Yellow
    return $Dispatch
}

if ([int]$Dispatch.attempts -ge [int]$Policy.dispatch.maximum_retry_attempts) {
    throw "Operational dispatch has exhausted retry attempts: $DispatchId"
}

return & "E:\AI\AI-Office\scripts\operations-integrations\Invoke-AIOfficeOperationalDispatch.ps1" `
    -DispatchId $DispatchId
