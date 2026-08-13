param()

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"
. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeLocalInference.Common.ps1"

$Id = New-AIOfficeSelfHostingId -Prefix "SHHEALTH"
$Policy = Get-AIOfficeLocalInferencePolicy
$Status = "unreachable"
$ModelNames = @()
$Details = ""

try {
    $Tags = Invoke-AIOfficeOllamaApi -Path "/api/tags"
    $ModelNames = @($Tags.models | ForEach-Object { [string]$_.name })
    $Status = "healthy"
    $Details = "Ollama API reachable."
}
catch {
    $Status = "unreachable"
    $Details = $_.Exception.Message
}

$Record = [ordered]@{
    health_id = $Id
    provider_type = "ollama"
    endpoint = [string]$Policy.endpoint
    status = $Status
    models = $ModelNames
    details = $Details
    checked_at = (Get-Date).ToString("o")
}

Write-AIOfficeSelfHostingJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\self-hosting\health\$Id.json"

Write-Host "Local inference health: $Status | models=$($ModelNames.Count)" `
    -ForegroundColor $(if ($Status -eq "healthy") { "Green" } else { "Red" })

return [pscustomobject]$Record
