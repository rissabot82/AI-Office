param()

$ErrorActionPreference = "Stop"

$Checks = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Details
    )
    $Checks.Add([pscustomobject]@{
        name = $Name
        passed = $Passed
        details = $Details
    })
}

$TokenPresent = -not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable("AI_OFFICE_DISCORD_BOT_TOKEN","Process")) -or
                -not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable("AI_OFFICE_DISCORD_BOT_TOKEN","User")) -or
                -not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable("AI_OFFICE_DISCORD_BOT_TOKEN","Machine"))

Add-Check -Name "bot_token" -Passed $TokenPresent -Details $(if ($TokenPresent) { "Discord bot token is configured." } else { "AI_OFFICE_DISCORD_BOT_TOKEN is not configured." })

foreach ($Item in @(
    @{ Name="allowlist"; Path="E:\AI\AI-Office\config\discord-office\allowlist.json" },
    @{ Name="worker_policy"; Path="E:\AI\AI-Office\config\discord-office\worker-policy.json" },
    @{ Name="routing_policy"; Path="E:\AI\AI-Office\config\discord-office\routing-policy.json" },
    @{ Name="safety_policy"; Path="E:\AI\AI-Office\config\discord-office\safety-policy.json" }
)) {
    $Exists = Test-Path -LiteralPath $Item.Path
    Add-Check -Name $Item.Name -Passed $Exists -Details $(if ($Exists) { "$($Item.Name) is present." } else { "Missing $($Item.Path)" })
}

$ConnectionPassed = $false
$ConnectionDetails = "Discord connection status unavailable."

try {
    $Connection = & "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordStatus.ps1"
    $ConnectionPassed = [bool]$Connection.connected
    $ConnectionDetails = "Discord connected=$($Connection.connected); status=$($Connection.status)"
}
catch {
    $ConnectionDetails = $_.Exception.Message
}

Add-Check -Name "discord_connection" -Passed $ConnectionPassed -Details $ConnectionDetails

$PassedCount = @($Checks | Where-Object { $_.passed }).Count
$FailedCount = @($Checks | Where-Object { -not $_.passed }).Count

return [pscustomobject]@{
    ready = ($FailedCount -eq 0)
    passed = $PassedCount
    failed = $FailedCount
    checks = $Checks.ToArray()
    checked_at = (Get-Date).ToString("o")
}
