param(
    [Parameter(Mandatory=$true)][string]$CommandText
)

$ErrorActionPreference = "Stop"

$Text = $CommandText.Trim().ToLowerInvariant()

switch -Regex ($Text) {
    '^/security$' {
        $Status = & "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordSafetyStatus.ps1"

        return [pscustomobject]@{
            handled = $true
            command = "security"
            response = "AI Office Discord security: $($Status.status). Allowlist=$($Status.allowlist_exists); auditing=$($Status.audit_inbound_messages); token redaction=$($Status.redact_token_like_values); audit events=$($Status.audit_event_count)."
        }
    }

    '^/audit(?:\s+(\d+))?$' {
        $Count = 5
        if ($Matches[1]) {
            $Count = [Math]::Min([Math]::Max([int]$Matches[1],1),10)
        }

        $Events = & "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordAudit.ps1" -Last $Count

        if (@($Events).Count -eq 0) {
            $Response = "No Discord audit events recorded."
        }
        else {
            $Lines = @("Recent Discord audit events:")
            foreach ($Event in @($Events)) {
                $Lines += "$($Event.created_at) | $($Event.event_type) | $($Event.outcome) | department=$($Event.department)"
            }
            $Response = $Lines -join [Environment]::NewLine
        }

        return [pscustomobject]@{
            handled = $true
            command = "audit"
            response = $Response
        }
    }

    default {
        return [pscustomobject]@{
            handled = $false
            command = ""
            response = ""
        }
    }
}
