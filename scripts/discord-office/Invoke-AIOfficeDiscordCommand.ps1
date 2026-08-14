param(
    [Parameter(Mandatory=$true)][string]$CommandText,
    [Parameter(Mandatory=$true)][string]$DiscordUserId,
    [Parameter(Mandatory=$true)][string]$DiscordGuildId,
    [Parameter(Mandatory=$true)][string]$DiscordChannelId
)

$ErrorActionPreference = "Stop"

$Text = $CommandText.Trim()
$Parts = @($Text.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries))
$Command = if ($Parts.Count -gt 0) { $Parts[0].TrimStart("/").ToLowerInvariant() } else { "" }

switch ($Command) {
    "new" {
        $Reset = & "E:\AI\AI-Office\scripts\discord-office\Reset-AIOfficeDiscordSession.ps1" `
            -DiscordUserId $DiscordUserId `
            -DiscordGuildId $DiscordGuildId `
            -DiscordChannelId $DiscordChannelId

        return [pscustomobject]@{
            command = "new"
            handled = $true
            response = "New AI Office conversation started. Session: $($Reset.conversation.session_id)"
        }
    }

    "session" {
        $Mapping = & "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordSessionMapping.ps1" `
            -DiscordUserId $DiscordUserId `
            -DiscordChannelId $DiscordChannelId

        $Response = if ($null -eq $Mapping) {
            "No active AI Office conversation session."
        } else {
            "Active AI Office session: $($Mapping.conversation_session_id)"
        }

        return [pscustomobject]@{ command="session"; handled=$true; response=$Response }
    }

    "status" {
        $Discord = & "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordStatus.ps1"
        return [pscustomobject]@{
            command = "status"
            handled = $true
            response = "AI Office Discord status: $($Discord.status). Connected: $($Discord.connected). Active Discord mappings: $($Discord.active_session_mappings)."
        }
    }

    "history" {
        $Count = 8
        if ($Parts.Count -gt 1) { [int]::TryParse($Parts[1], [ref]$Count) | Out-Null }

        $History = & "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordConversationHistory.ps1" `
            -DiscordUserId $DiscordUserId `
            -DiscordChannelId $DiscordChannelId `
            -Count $Count

        if (@($History.messages).Count -eq 0) {
            $Response = "No conversation history available."
        } else {
            $Lines = New-Object System.Collections.Generic.List[string]
            $Lines.Add("Recent AI Office conversation:")
            foreach ($Message in @($History.messages)) {
                $Role = ([string]$Message.role).ToUpperInvariant()
                $Body = [string]$Message.content
                if ($Body.Length -gt 300) { $Body = $Body.Substring(0,300) + "..." }
                $Lines.Add("${Role}: $Body")
            }
            $Response = $Lines -join [Environment]::NewLine
        }

        return [pscustomobject]@{ command="history"; handled=$true; response=$Response }
    }

    "departments" {
        $Departments = & "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordDepartments.ps1"
        $Names = @($Departments | ForEach-Object { [string]$_.id })
        return [pscustomobject]@{
            command = "departments"
            handled = $true
            response = "Available AI Office departments: " + ($Names -join ", ")
        }
    }

    "department" {
        # A /department <name> <request> message must continue to routing,
        # not be swallowed as a normal command.
        return [pscustomobject]@{
            command = "department"
            handled = $false
            response = ""
        }
    }

    "help" {
        return [pscustomobject]@{
            command = "help"
            handled = $true
            response = @"
/new - start a new AI Office conversation
/session - show the active conversation session
/status - show AI Office Discord status
/history [count] - show recent conversation history
/departments - list available AI Office departments
/department <name> <request> - route one request to a department
/help - show this command list
"@
        }
    }

    default {
        return [pscustomobject]@{ command=$Command; handled=$false; response="" }
    }
}
