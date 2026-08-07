param()

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\operations-integrations\AIOfficeOperations.Common.ps1"

$Intake = Get-AIOfficeOperationsCollection `
    -Directory "E:\AI\AI-Office\workspace\operations-integrations\intake" `
    -Filter "OPSINT-*.json"

$Integrations = Get-AIOfficeOperationsCollection `
    -Directory "E:\AI\AI-Office\workspace\operations-integrations\integrations" `
    -Filter "OPSINTG-*.json"

$Jobs = Get-AIOfficeOperationsCollection `
    -Directory "E:\AI\AI-Office\workspace\operations-integrations\jobs" `
    -Filter "OPSJOB-*.json"

$Notifications = Get-AIOfficeOperationsCollection `
    -Directory "E:\AI\AI-Office\workspace\operations-integrations\notifications" `
    -Filter "OPSNOT-*.json"

$ChannelCounts = [ordered]@{}
foreach ($Item in $Intake) {
    $Key = [string]$Item.channel
    if (-not $ChannelCounts.Contains($Key)) { $ChannelCounts[$Key] = 0 }
    $ChannelCounts[$Key]++
}

$IntegrationTypeCounts = [ordered]@{}
foreach ($Item in $Integrations) {
    $Key = [string]$Item.integration_type
    if (-not $IntegrationTypeCounts.Contains($Key)) { $IntegrationTypeCounts[$Key] = 0 }
    $IntegrationTypeCounts[$Key]++
}

$Index = [ordered]@{
    version = "1.9.0"
    updated_at = (Get-Date).ToString("o")
    status = "ready"
    intake_count = @($Intake).Count
    queued_intake_count = @(
        $Intake | Where-Object { [string]$_.status -eq "queued" }
    ).Count
    integration_count = @($Integrations).Count
    connected_integration_count = @(
        $Integrations | Where-Object { [string]$_.status -eq "connected" }
    ).Count
    job_count = @($Jobs).Count
    active_job_count = @(
        $Jobs | Where-Object {
            [string]$_.status -eq "configured" -or
            [string]$_.status -eq "running"
        }
    ).Count
    notification_count = @($Notifications).Count
    unread_notification_count = @(
        $Notifications | Where-Object { [string]$_.status -eq "unread" }
    ).Count
    channel_counts = $ChannelCounts
    integration_type_counts = $IntegrationTypeCounts
}

Write-AIOfficeOperationsJson `
    -Value $Index `
    -Path "E:\AI\AI-Office\workspace\operations-integrations\indexes\operations-index.json"

Write-Host (
    "Operations index updated: " +
    $Index.intake_count +
    " intake | " +
    $Index.integration_count +
    " integrations | " +
    $Index.job_count +
    " jobs | " +
    $Index.notification_count +
    " notifications"
) -ForegroundColor Green

return [pscustomobject]$Index
