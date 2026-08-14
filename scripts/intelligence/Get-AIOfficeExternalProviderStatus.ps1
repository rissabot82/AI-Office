param()

$ErrorActionPreference = "Stop"

$Policy = Get-Content `
    -LiteralPath "E:\AI\AI-Office\config\intelligence\external-provider-policy.json" `
    -Raw | ConvertFrom-Json

$Results = New-Object System.Collections.Generic.List[object]

foreach ($Name in @("openai","anthropic")) {
    $Provider = $Policy.providers.$Name
    $EnvironmentName = [string]$Provider.api_key_environment_variable
    $Credential = [Environment]::GetEnvironmentVariable($EnvironmentName, "Process")

    if ([string]::IsNullOrWhiteSpace($Credential)) {
        $Credential = [Environment]::GetEnvironmentVariable($EnvironmentName, "User")
    }

    if ([string]::IsNullOrWhiteSpace($Credential)) {
        $Credential = [Environment]::GetEnvironmentVariable($EnvironmentName, "Machine")
    }

    $CredentialConfigured = -not [string]::IsNullOrWhiteSpace($Credential)
    $ModelConfigured = -not [string]::IsNullOrWhiteSpace([string]$Provider.default_model)

    $Results.Add([pscustomobject]@{
        provider = $Name
        supported = [bool]$Provider.supported
        enabled = [bool]$Provider.enabled
        credential_environment_variable = $EnvironmentName
        credential_configured = $CredentialConfigured
        model = [string]$Provider.default_model
        model_configured = $ModelConfigured
        activation_ready = (
            [bool]$Provider.supported -and
            [bool]$Provider.enabled -and
            $CredentialConfigured -and
            $ModelConfigured -and
            [bool]$Policy.enabled
        )
        checked_at = (Get-Date).ToString("o")
    })
}

return $Results.ToArray()
