param(
    [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeLocalInference.Common.ps1"

$Executable = Get-AIOfficeOllamaExecutable

if ($null -eq $Executable -and -not $SkipInstall) {
    Write-Host "Ollama is not installed. Installing with winget..." -ForegroundColor Cyan

    $Winget = Get-Command winget -ErrorAction SilentlyContinue

    if ($null -eq $Winget) {
        throw "Ollama is not installed and winget is unavailable."
    }

    & winget install `
        --id Ollama.Ollama `
        --exact `
        --accept-package-agreements `
        --accept-source-agreements `
        --silent

    if ($LASTEXITCODE -ne 0) {
        throw "winget failed to install Ollama. Exit code: $LASTEXITCODE"
    }

    Start-Sleep -Seconds 3
    $Executable = Get-AIOfficeOllamaExecutable
}

if ($null -eq $Executable) {
    throw "Ollama executable could not be located."
}

Write-Host "Ollama executable: $Executable" -ForegroundColor Green

if (-not (Test-AIOfficeOllamaPort)) {
    Write-Host "Starting Ollama local inference server..." -ForegroundColor Cyan

    Start-Process `
        -FilePath $Executable `
        -ArgumentList "serve" `
        -WindowStyle Hidden

    $Policy = Get-AIOfficeLocalInferencePolicy

    if (-not (Wait-AIOfficeOllamaReady -TimeoutSeconds ([int]$Policy.runtime.startup_timeout_seconds))) {
        throw "Ollama did not become ready on 127.0.0.1:11434."
    }
}

Write-Host "Ollama runtime is reachable on 127.0.0.1:11434." -ForegroundColor Green

return [pscustomobject]@{
    executable = $Executable
    endpoint = "http://127.0.0.1:11434"
    reachable = $true
}
