param(
    [string]$Model = "",
    [switch]$SkipInstall,
    [switch]$SkipModelPull
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeLocalInference.Common.ps1"

$Policy = Get-AIOfficeLocalInferencePolicy

if ([string]::IsNullOrWhiteSpace($Model)) {
    $Model = [string]$Policy.default_model
}

& "E:\AI\AI-Office\scripts\self-hosting\Install-AIOfficeOllamaRuntime.ps1" `
    -SkipInstall:$SkipInstall | Out-Null

if (-not $SkipModelPull) {
    & "E:\AI\AI-Office\scripts\self-hosting\Install-AIOfficeDefaultLocalModel.ps1" `
        -Model $Model | Out-Null
}

$Profiles = & "E:\AI\AI-Office\scripts\self-hosting\Sync-AIOfficeOllamaModels.ps1"
$Health = & "E:\AI\AI-Office\scripts\self-hosting\Test-AIOfficeLocalInferenceHealth.ps1"

if ([string]$Health.status -ne "healthy") {
    throw "Local inference runtime health validation failed."
}

Write-Host "Local inference runtime initialized: $Model" -ForegroundColor Green

return [pscustomobject]@{
    model = $Model
    health = $Health
    profiles = @($Profiles)
}
