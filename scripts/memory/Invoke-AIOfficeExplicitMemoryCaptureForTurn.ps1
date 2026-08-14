param(
    [Parameter(Mandatory=$true)][string]$Content,
    [string]$Scope = "global"
)

$ErrorActionPreference = "Stop"

try {
    $Result = & "E:\AI\AI-Office\scripts\memory\Save-AIOfficeExplicitConversationMemory.ps1" `
        -Content $Content `
        -Title "User-approved conversation memory" `
        -Scope $Scope

    return [pscustomobject]@{
        attempted = $true
        captured = [bool]$Result.captured
        memory_id = [string]$Result.memory_id
        duplicate = [bool]$Result.duplicate
        reason = if ([bool]$Result.captured) { "captured" } else { [string]$Result.reason }
    }
}
catch {
    # Explicit-memory capture must never take down the conversational runtime.
    return [pscustomobject]@{
        attempted = $true
        captured = $false
        memory_id = ""
        duplicate = $false
        reason = "capture_error"
        error = $_.Exception.Message
    }
}
