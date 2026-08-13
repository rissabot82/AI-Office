$script:AIOfficeLocalInferenceRoot = "E:\AI\AI-Office"

function Get-AIOfficeLocalInferencePolicy {
    return Get-Content `
        -LiteralPath "E:\AI\AI-Office\config\self-hosting\runtime-policy.json" `
        -Raw |
        ConvertFrom-Json
}

function Get-AIOfficeOllamaExecutable {
    $Candidates = New-Object System.Collections.Generic.List[string]

    try {
        $Command = Get-Command ollama -ErrorAction Stop
        if ($null -ne $Command -and -not [string]::IsNullOrWhiteSpace([string]$Command.Source)) {
            $Candidates.Add([string]$Command.Source)
        }
    }
    catch {
    }

    foreach ($Candidate in @(
        "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe",
        "$env:ProgramFiles\Ollama\ollama.exe",
        "${env:ProgramFiles(x86)}\Ollama\ollama.exe"
    )) {
        if (-not [string]::IsNullOrWhiteSpace($Candidate)) {
            $Candidates.Add($Candidate)
        }
    }

    foreach ($Candidate in @($Candidates | Select-Object -Unique)) {
        if (Test-Path -LiteralPath $Candidate -PathType Leaf) {
            return $Candidate
        }
    }

    return $null
}

function Test-AIOfficeOllamaPort {
    param([string]$ComputerName = "127.0.0.1", [int]$Port = 11434)

    try {
        $Client = New-Object System.Net.Sockets.TcpClient
        $Async = $Client.BeginConnect($ComputerName, $Port, $null, $null)
        $Ready = $Async.AsyncWaitHandle.WaitOne(1000, $false)

        if (-not $Ready) {
            $Client.Close()
            return $false
        }

        $Client.EndConnect($Async)
        $Client.Close()
        return $true
    }
    catch {
        return $false
    }
}

function Wait-AIOfficeOllamaReady {
    param([int]$TimeoutSeconds = 45)

    $Deadline = (Get-Date).AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $Deadline) {
        if (Test-AIOfficeOllamaPort) {
            return $true
        }

        Start-Sleep -Seconds 1
    }

    return $false
}

function Invoke-AIOfficeOllamaApi {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [string]$Method = "GET",
        $Body = $null,
        [int]$TimeoutSeconds = 180
    )

    $Policy = Get-AIOfficeLocalInferencePolicy
    $Uri = ([string]$Policy.endpoint).TrimEnd("/") + $Path

    $Parameters = @{
        Uri = $Uri
        Method = $Method
        TimeoutSec = $TimeoutSeconds
        ErrorAction = "Stop"
    }

    if ($null -ne $Body) {
        $Parameters["ContentType"] = "application/json"
        $Parameters["Body"] = ($Body | ConvertTo-Json -Depth 50)
    }

    return Invoke-RestMethod @Parameters
}
