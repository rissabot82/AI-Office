param(
    [Parameter(Mandatory=$true)][string]$SourceProvider,
    [Parameter(Mandatory=$true)][string]$TargetProvider,
    [Parameter(Mandatory=$true)][string]$Reason,
    [string]$Status = "completed"
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"

$Id = New-AIOfficeSelfHostingId -Prefix "SHFAIL"

$Record = [ordered]@{
    failover_event_id = $Id
    source_provider = $SourceProvider
    target_provider = $TargetProvider
    reason = $Reason
    status = $Status
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeSelfHostingJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\self-hosting\failover-events\$Id.json"

Write-Host "Failover event recorded: $Id | $SourceProvider -> $TargetProvider" -ForegroundColor Yellow
return [pscustomobject]$Record
