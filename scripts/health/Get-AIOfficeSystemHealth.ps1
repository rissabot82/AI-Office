param(
    [switch]$StartDashboardIfStopped
)

$ErrorActionPreference = "Stop"
$Root = "E:\AI\AI-Office"
Set-Location $Root

$Policy = Get-Content -LiteralPath "E:\AI\AI-Office\config\health\health-policy.json" -Raw | ConvertFrom-Json
$Checks = New-Object System.Collections.Generic.List[object]

function Add-HealthCheck {
    param([string]$Component,[string]$Status,[string]$Details)
    $Checks.Add([pscustomobject]@{ Component=$Component; Status=$Status; Details=$Details })
}

function Test-LocalPort {
    param([int]$Port)
    try {
        $Client = New-Object System.Net.Sockets.TcpClient
        $Async = $Client.BeginConnect("127.0.0.1",$Port,$null,$null)
        $Connected = $Async.AsyncWaitHandle.WaitOne(700,$false)
        if ($Connected) { $Client.EndConnect($Async) }
        $Client.Close()
        return $Connected
    } catch { return $false }
}

Add-HealthCheck "Repository" "PASS" $Root

try {
    $Branch = (git rev-parse --abbrev-ref HEAD 2>$null).Trim()
    $Dirty = git status --porcelain
    $Head = (git log -1 --pretty=format:"%h %s").Trim()
    $Tag = (git describe --tags --exact-match 2>$null | Select-Object -First 1)
    $Status = if ([string]::IsNullOrWhiteSpace(($Dirty | Out-String))) { "PASS" } else { "WARN" }
    $TagText = if ($Tag) { [string]$Tag } else { "no exact tag" }
    Add-HealthCheck "Git" $Status ("branch=$Branch; tag=$TagText; $Head")
} catch {
    Add-HealthCheck "Git" "FAIL" $_.Exception.Message
}

try {
    $DistributionNames = @(
        & wsl.exe -l -q 2>$null |
            ForEach-Object {
                ([string]$_).Trim([char]0).Trim()
            } |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            }
    )

    $ExpectedDistribution = [string]$Policy.wsl_distribution

    if ($DistributionNames -contains $ExpectedDistribution) {
        Add-HealthCheck "WSL" "PASS" "$ExpectedDistribution available"
    }
    else {
        Add-HealthCheck `
            "WSL" `
            "FAIL" `
            ("Expected " + $ExpectedDistribution + "; found: " + ($DistributionNames -join ", "))
    }
}
catch {
    Add-HealthCheck "WSL" "FAIL" $_.Exception.Message
}

try {
    $State = & wsl.exe -d ([string]$Policy.wsl_distribution) -- systemctl --user is-active ([string]$Policy.openclaw_service) 2>&1
    $State = ([string]($State | Select-Object -First 1)).Trim()
    if ($State -eq "active") {
        Add-HealthCheck "OpenClaw Gateway" "PASS" "systemd service active"
    } else {
        Add-HealthCheck "OpenClaw Gateway" "FAIL" $State
    }
} catch {
    Add-HealthCheck "OpenClaw Gateway" "FAIL" $_.Exception.Message
}

if (Test-LocalPort ([int]$Policy.gateway_port)) {
    Add-HealthCheck "Gateway Port" "PASS" "localhost:$($Policy.gateway_port)"
} else {
    Add-HealthCheck "Gateway Port" "FAIL" "not reachable"
}

try {
    $Token = & "E:\AI\AI-Office\scripts\health\Get-AIOfficeGatewayToken.ps1"
    $env:OPENCLAW_GATEWAY_TOKEN = $Token
    $Bridge = & "E:\AI\AI-Office\scripts\bridge\Test-AIOfficeOpenClawConnection.ps1" -Authenticated
    if ($Bridge.authenticated -eq $true) {
        Add-HealthCheck "Bridge Authentication" "PASS" "protocol=$($Bridge.protocol); server=$($Bridge.server_version)"
    } else {
        Add-HealthCheck "Bridge Authentication" "FAIL" ([string]$Bridge.error)
    }
} catch {
    Add-HealthCheck "Bridge Authentication" "FAIL" $_.Exception.Message
}

$DashboardRunning = Test-LocalPort ([int]$Policy.dashboard_port)

if (-not $DashboardRunning -and $StartDashboardIfStopped) {
    try {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "E:\AI\AI-Office\scripts\dashboard\Start-AIOfficeDashboard.ps1"
        Start-Sleep -Seconds 1
        $DashboardRunning = Test-LocalPort ([int]$Policy.dashboard_port)
    } catch {}
}

if ($DashboardRunning) {
    Add-HealthCheck "Dashboard" "PASS" "http://127.0.0.1:$($Policy.dashboard_port)/"
} else {
    Add-HealthCheck "Dashboard" "WARN" "not running"
}

try {
    $DockerVersion = & docker version --format "{{.Server.Version}}" 2>$null
    if ($LASTEXITCODE -eq 0 -and $DockerVersion) {
        Add-HealthCheck "Docker" "PASS" ("server=" + ([string]$DockerVersion).Trim())
    } else {
        Add-HealthCheck "Docker" "WARN" "Docker engine unavailable"
    }
} catch {
    Add-HealthCheck "Docker" "WARN" "Docker engine unavailable"
}

foreach ($Item in @(
    @{ Name="Chief of Staff"; Path="E:\AI\AI-Office\workspace\chief-of-staff" },
    @{ Name="Long-Term Memory"; Path="E:\AI\AI-Office\workspace\memory" },
    @{ Name="Autonomous Workflows"; Path="E:\AI\AI-Office\workspace\autonomous-workflows" },
    @{ Name="Message Bus"; Path="E:\AI\AI-Office\workspace\messages" }
)) {
    if (Test-Path -LiteralPath $Item.Path -PathType Container) {
        Add-HealthCheck $Item.Name "PASS" "workspace present"
    } else {
        Add-HealthCheck $Item.Name "FAIL" "workspace missing"
    }
}

$FailCount = @($Checks | Where-Object {$_.Status -eq "FAIL"}).Count
$WarnCount = @($Checks | Where-Object {$_.Status -eq "WARN"}).Count
$Overall = if ($FailCount -gt 0) { "DEGRADED" } elseif ($WarnCount -gt 0) { "OPERATIONAL WITH WARNINGS" } else { "OPERATIONAL" }

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "AI OFFICE SYSTEM HEALTH" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
$Checks | Format-Table -AutoSize
Write-Host "Overall Status: $Overall" -ForegroundColor $(if ($FailCount -gt 0) {"Red"} elseif ($WarnCount -gt 0) {"Yellow"} else {"Green"})
Write-Host "============================================================" -ForegroundColor Cyan

$HealthResult = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    overall_status = $Overall
    failed_checks = $FailCount
    warning_checks = $WarnCount
    checks = @($Checks | ForEach-Object { $_ })
}

return [pscustomobject]$HealthResult


