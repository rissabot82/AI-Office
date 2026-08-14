param()

$ErrorActionPreference = "Stop"

$PolicyPath = "E:\AI\AI-Office\config\discord-office\safety-policy.json"
$AllowlistPath = "E:\AI\AI-Office\config\discord-office\allowlist.json"
$AuditDirectory = "E:\AI\AI-Office\workspace\discord-office\audit"

$Policy = Get-Content -LiteralPath $PolicyPath -Raw | ConvertFrom-Json
$AllowlistExists = Test-Path -LiteralPath $AllowlistPath
$AuditCount = @(
    Get-ChildItem -LiteralPath $AuditDirectory -Filter "DCAUD-*.json" -File -ErrorAction SilentlyContinue
).Count

return [pscustomobject]@{
    status = if ($AllowlistExists -and [bool]$Policy.safety.require_allowlist) { "protected" } else { "degraded" }
    require_allowlist = [bool]$Policy.safety.require_allowlist
    allowlist_exists = $AllowlistExists
    audit_inbound_messages = [bool]$Policy.safety.audit_inbound_messages
    audit_commands = [bool]$Policy.safety.audit_commands
    audit_routing = [bool]$Policy.safety.audit_routing
    audit_denied_messages = [bool]$Policy.safety.audit_denied_messages
    redact_token_like_values = [bool]$Policy.safety.redact_token_like_values
    audit_event_count = [int]$AuditCount
    checked_at = (Get-Date).ToString("o")
}
