param(
    [switch]$Persist
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"
. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeResilience.Common.ps1"

$Policy = Get-AIOfficeResiliencePolicy

$Ollama = Test-AIOfficeTcpPort -ComputerName "127.0.0.1" -Port 11434
$Gateway = $false

foreach ($Attempt in 1..5) {
    if (
        (Test-AIOfficeTcpPort -ComputerName "127.0.0.1" -Port ([int]$Policy.health.gateway_port) -TimeoutMilliseconds 3000) -or
        (Test-AIOfficeTcpPort -ComputerName "localhost" -Port ([int]$Policy.health.gateway_port) -TimeoutMilliseconds 3000)
    ) {
        $Gateway = $true
        break
    }

    Start-Sleep -Milliseconds 500
}
$Dashboard = Test-AIOfficeTcpPort -ComputerName "127.0.0.1" -Port ([int]$Policy.health.dashboard_port)

$Overall = if ($Ollama -and $Gateway -and $Dashboard) { "healthy" } elseif ($Ollama -or $Gateway -or $Dashboard) { "degraded" } else { "failed" }

$Record = [ordered]@{
    health_id = New-AIOfficeSelfHostingId -Prefix "SHSVC"
    status = $Overall
    ollama = $Ollama
    openclaw_gateway = $Gateway
    dashboard = $Dashboard
    checked_at = (Get-Date).ToString("o")
}

if ($Persist) {
    Write-AIOfficeSelfHostingJson `
        -Value $Record `
        -Path "E:\AI\AI-Office\workspace\self-hosting\service-health\$($Record.health_id).json"
}

Write-Host "Service health: $Overall | Ollama=$Ollama | Gateway=$Gateway | Dashboard=$Dashboard" `
    -ForegroundColor $(if ($Overall -eq "healthy") { "Green" } elseif ($Overall -eq "degraded") { "Yellow" } else { "Red" })

return [pscustomobject]$Record

