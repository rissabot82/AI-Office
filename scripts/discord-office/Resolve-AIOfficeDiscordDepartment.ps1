param(
    [Parameter(Mandatory=$true)][string]$Content,
    [string]$RequestedDepartment = ""
)

$ErrorActionPreference = "Stop"

$Policy = & "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordRoutingPolicy.ps1"

function Resolve-DepartmentId {
    param([string]$Value)

    $Normalized = $Value.Trim().ToLowerInvariant()

    foreach ($Department in @($Policy.departments)) {
        if (-not [bool]$Department.enabled) { continue }

        if ([string]$Department.id -eq $Normalized) {
            return [string]$Department.id
        }

        foreach ($Alias in @($Department.aliases)) {
            if ([string]$Alias -eq $Normalized) {
                return [string]$Department.id
            }
        }
    }

    return ""
}

if (-not [string]::IsNullOrWhiteSpace($RequestedDepartment)) {
    $Explicit = Resolve-DepartmentId -Value $RequestedDepartment
    if (-not [string]::IsNullOrWhiteSpace($Explicit)) {
        return [pscustomobject]@{
            department = $Explicit
            routing_reason = "explicit"
            content = $Content
        }
    }
}

$Trimmed = $Content.Trim()

if ($Trimmed -match '^/department\s+([^\s]+)\s*(.*)$') {
    $Resolved = Resolve-DepartmentId -Value $Matches[1]

    if ([string]::IsNullOrWhiteSpace($Resolved)) {
        throw "Unknown or disabled AI Office department: $($Matches[1])"
    }

    return [pscustomobject]@{
        department = $Resolved
        routing_reason = "explicit_command"
        content = [string]$Matches[2]
    }
}

return [pscustomobject]@{
    department = [string]$Policy.routing.default_route
    routing_reason = "default_chief_of_staff"
    content = $Content
}
