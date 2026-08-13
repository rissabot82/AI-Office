param(
    [switch]$RecoverOllama,
    [switch]$RecoverDashboard
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"
. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeResilience.Common.ps1"

$Records = New-Object System.Collections.Generic.List[object]

if ($RecoverOllama) {
    $Status = "completed"
    $Details = ""

    try {
        if (-not (Test-AIOfficeTcpPort -ComputerName "127.0.0.1" -Port 11434)) {
            $Executable = Get-Command ollama -ErrorAction Stop
            Start-Process -FilePath $Executable.Source -ArgumentList "serve" -WindowStyle Hidden

            $Deadline = (Get-Date).AddSeconds(30)
            while ((Get-Date) -lt $Deadline -and -not (Test-AIOfficeTcpPort -ComputerName "127.0.0.1" -Port 11434)) {
                Start-Sleep -Seconds 1
            }

            if (-not (Test-AIOfficeTcpPort -ComputerName "127.0.0.1" -Port 11434)) {
                throw "Ollama did not recover within timeout."
            }

            $Details = "Ollama runtime restarted."
        }
        else {
            $Details = "Ollama runtime already healthy."
        }
    }
    catch {
        $Status = "failed"
        $Details = $_.Exception.Message
    }

    $Id = New-AIOfficeSelfHostingId -Prefix "SHREC"
    $Record = [ordered]@{
        recovery_id = $Id
        component = "ollama"
        action = "ensure_running"
        status = $Status
        details = $Details
        created_at = (Get-Date).ToString("o")
    }

    Write-AIOfficeSelfHostingJson `
        -Value $Record `
        -Path "E:\AI\AI-Office\workspace\self-hosting\recovery\$Id.json"

    $Records.Add([pscustomobject]$Record)
}

if ($RecoverDashboard) {
    $Status = "completed"
    $Details = ""

    try {
        if (-not (Test-AIOfficeTcpPort -ComputerName "127.0.0.1" -Port 18880)) {
            $Script = "E:\AI\AI-Office\scripts\dashboard\Start-AIOfficeDashboard.ps1"

            if (-not (Test-Path -LiteralPath $Script -PathType Leaf)) {
                throw "Dashboard startup script not found."
            }

            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Script | Out-Null
            Start-Sleep -Seconds 2

            if (-not (Test-AIOfficeTcpPort -ComputerName "127.0.0.1" -Port 18880)) {
                throw "Dashboard did not recover."
            }

            $Details = "Dashboard restarted."
        }
        else {
            $Details = "Dashboard already healthy."
        }
    }
    catch {
        $Status = "failed"
        $Details = $_.Exception.Message
    }

    $Id = New-AIOfficeSelfHostingId -Prefix "SHREC"
    $Record = [ordered]@{
        recovery_id = $Id
        component = "dashboard"
        action = "ensure_running"
        status = $Status
        details = $Details
        created_at = (Get-Date).ToString("o")
    }

    Write-AIOfficeSelfHostingJson `
        -Value $Record `
        -Path "E:\AI\AI-Office\workspace\self-hosting\recovery\$Id.json"

    $Records.Add([pscustomobject]$Record)
}

return @($Records | ForEach-Object { $_ })
