param(
    [Parameter(Mandatory=$true)][string]$Model,
    [switch]$Optional
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeLocalInference.Common.ps1"

$Executable = Get-AIOfficeOllamaExecutable

if ($null -eq $Executable) {
    throw "Ollama executable is unavailable."
}

$Tags = Invoke-AIOfficeOllamaApi -Path "/api/tags"
$Existing = @($Tags.models | ForEach-Object { [string]$_.name })

$Installed = $false
foreach ($Name in $Existing) {
    if ($Name -eq $Model -or $Name -eq ($Model + ":latest")) {
        $Installed = $true
        break
    }
}

if ($Installed) {
    Write-Host "Fleet model already installed: $Model" -ForegroundColor Yellow
    return [pscustomobject]@{ model=$Model; installed=$true; pulled=$false; optional=[bool]$Optional }
}

Write-Host "Pulling fleet model: $Model" -ForegroundColor Cyan
& $Executable pull $Model

if ($LASTEXITCODE -ne 0) {
    if ($Optional) {
        Write-Host "Optional fleet model pull failed: $Model" -ForegroundColor Yellow
        return [pscustomobject]@{ model=$Model; installed=$false; pulled=$false; optional=$true }
    }

    throw "Required fleet model pull failed: $Model"
}

return [pscustomobject]@{ model=$Model; installed=$true; pulled=$true; optional=[bool]$Optional }
