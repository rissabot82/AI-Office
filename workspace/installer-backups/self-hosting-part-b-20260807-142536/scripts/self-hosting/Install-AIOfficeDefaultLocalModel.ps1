param(
    [string]$Model = ""
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeLocalInference.Common.ps1"

$Policy = Get-AIOfficeLocalInferencePolicy

if ([string]::IsNullOrWhiteSpace($Model)) {
    $Model = [string]$Policy.default_model
}

$Executable = Get-AIOfficeOllamaExecutable

if ($null -eq $Executable) {
    throw "Ollama executable is unavailable."
}

$Tags = Invoke-AIOfficeOllamaApi -Path "/api/tags"
$ExistingNames = @($Tags.models | ForEach-Object { [string]$_.name })

$AlreadyInstalled = $false

foreach ($ExistingName in $ExistingNames) {
    if (
        $ExistingName -eq $Model -or
        $ExistingName -eq ($Model + ":latest")
    ) {
        $AlreadyInstalled = $true
        break
    }
}

if (-not $AlreadyInstalled) {
    Write-Host "Pulling local model: $Model" -ForegroundColor Cyan
    Write-Host "This can take several minutes depending on download speed." -ForegroundColor DarkCyan

    & $Executable pull $Model

    if ($LASTEXITCODE -ne 0) {
        throw "Ollama model pull failed for $Model."
    }
}
else {
    Write-Host "Local model already installed: $Model" -ForegroundColor Yellow
}

& "E:\AI\AI-Office\scripts\self-hosting\Sync-AIOfficeOllamaModels.ps1" | Out-Null

Write-Host "Default local model ready: $Model" -ForegroundColor Green
return $Model
