param(
    [Parameter(Mandatory=$true)][bool]$RequiresEscalation
)

$ErrorActionPreference = "Stop"

$Policy = Get-Content `
    -LiteralPath "E:\AI\AI-Office\config\intelligence\external-provider-policy.json" `
    -Raw | ConvertFrom-Json

if (-not $RequiresEscalation) {
    return [pscustomobject]@{
        route = "local"
        provider = ""
        model = ""
        reason = "Quality escalation is not required."
        executable = $true
    }
}

if (-not [bool]$Policy.enabled) {
    return [pscustomobject]@{
        route = "external_advisory"
        provider = ""
        model = ""
        reason = "Escalation is recommended, but external intelligence is not activated."
        executable = $false
    }
}

$Providers = @(& "E:\AI\AI-Office\scripts\intelligence\Get-AIOfficeExternalProviderStatus.ps1")
$Ready = $Providers | Where-Object { $_.activation_ready } | Select-Object -First 1

if ($null -eq $Ready) {
    return [pscustomobject]@{
        route = "external_unavailable"
        provider = ""
        model = ""
        reason = "External intelligence is enabled, but no provider is activation-ready."
        executable = $false
    }
}

return [pscustomobject]@{
    route = "external"
    provider = [string]$Ready.provider
    model = [string]$Ready.model
    reason = "Escalation required and provider is activation-ready."
    executable = [bool]$Policy.automatic_paid_inference
}
