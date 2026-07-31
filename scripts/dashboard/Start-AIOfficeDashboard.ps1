param(
    [switch]$Foreground,
    [switch]$OpenBrowser
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$Config = Get-Content `
    -LiteralPath ".\config\dashboard\dashboard-config.json" `
    -Raw |
    ConvertFrom-Json

$Url = "http://" + [string]$Config.host + ":" + [string]$Config.port + "/"
$ServerScript = Join-Path `
    $Root `
    "scripts\dashboard\Start-AIOfficeDashboardServer.ps1"

if ($Foreground) {
    & powershell.exe `
        -NoProfile `
        -ExecutionPolicy Bypass `
        -File $ServerScript `
        -HostAddress ([string]$Config.host) `
        -Port ([int]$Config.port)

    exit
}

$ExistingPidPath = Join-Path $Root "dashboard\runtime\dashboard.pid"

if (Test-Path -LiteralPath $ExistingPidPath -PathType Leaf) {
    $ExistingPid = Get-Content -LiteralPath $ExistingPidPath -Raw

    if ($ExistingPid -match "^\d+$") {
        $ExistingProcess = Get-Process `
            -Id ([int]$ExistingPid) `
            -ErrorAction SilentlyContinue

        if ($null -ne $ExistingProcess) {
            Write-Host "Dashboard is already running at $Url" `
                -ForegroundColor Yellow

            if ($OpenBrowser) {
                Start-Process $Url
            }

            return
        }
    }
}

$Process = Start-Process `
    -FilePath "powershell.exe" `
    -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", ('"' + $ServerScript + '"'),
        "-HostAddress", ([string]$Config.host),
        "-Port", ([string]$Config.port)
    ) `
    -WindowStyle Hidden `
    -PassThru

$Ready = $false

for ($Attempt = 1; $Attempt -le 20; $Attempt++) {
    Start-Sleep -Milliseconds 500

    try {
        $Response = Invoke-WebRequest `
            -Uri ($Url + "api/health") `
            -UseBasicParsing `
            -TimeoutSec 2

        if ($Response.StatusCode -eq 200) {
            $Ready = $true
            break
        }
    }
    catch {
    }
}

if (-not $Ready) {
    Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
    throw "Dashboard server did not become ready."
}

Write-Host "AI Office Dashboard started: $Url" -ForegroundColor Green

if ($OpenBrowser) {
    Start-Process $Url
}
