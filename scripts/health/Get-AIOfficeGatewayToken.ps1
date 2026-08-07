param(
    [string]$WslDistribution = "OpenClawGateway",
    [string]$OpenClawConfigPath = "/home/openclaw/.openclaw/openclaw.json"
)

$ErrorActionPreference = "Stop"

$Output = & wsl.exe -d $WslDistribution -- python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['gateway']['auth']['token'])" $OpenClawConfigPath 2>&1

if ($LASTEXITCODE -ne 0) {
    throw ($Output -join [Environment]::NewLine)
}

$Token = ([string]($Output | Select-Object -First 1)).Trim()

if ([string]::IsNullOrWhiteSpace($Token)) {
    throw "OpenClaw Gateway token could not be read."
}

return $Token
