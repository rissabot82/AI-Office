param(
    [Parameter(Mandatory=$true)][string]$SessionId,
    [Parameter(Mandatory=$true)][string]$Content,
    [string]$RequestedDepartment = ""
)

$ErrorActionPreference = "Stop"

$Route = & "E:\AI\AI-Office\scripts\discord-office\Resolve-AIOfficeDiscordDepartment.ps1" `
    -Content $Content `
    -RequestedDepartment $RequestedDepartment

# Normal Discord messages should behave exactly like normal AI Office conversation.
if (
    [string]$Route.department -eq "chief-of-staff" -and
    [string]$Route.routing_reason -eq "default_chief_of_staff"
) {
    $Result = & "E:\AI\AI-Office\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1" `
        -SessionId $SessionId `
        -Content ([string]$Route.content) `
        -Sensitivity "normal"

    return [pscustomobject]@{
        department = "chief-of-staff"
        routing_reason = "default_chief_of_staff"
        provider = [string]$Result.provider
        model = [string]$Result.model
        response = [string]$Result.response
    }
}

# Explicit department routing gets lightweight department context.
$DepartmentPrompt = @"
You are operating as the AI Office $($Route.department) department.

Respond directly to the user's request.
Do not reject ordinary requests merely because they are simple.
Do not discuss the routing system unless the user asks about it.

User request:
$($Route.content)
"@

$Result = & "E:\AI\AI-Office\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1" `
    -SessionId $SessionId `
    -Content $DepartmentPrompt `
    -Sensitivity "normal"

return [pscustomobject]@{
    department = [string]$Route.department
    routing_reason = [string]$Route.routing_reason
    provider = [string]$Result.provider
    model = [string]$Result.model
    response = [string]$Result.response
}
