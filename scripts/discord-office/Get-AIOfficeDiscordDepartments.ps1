param()

$ErrorActionPreference = "Stop"

$Policy = & "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordRoutingPolicy.ps1"

return @(
    $Policy.departments |
    Where-Object { [bool]$_.enabled } |
    ForEach-Object {
        [pscustomobject]@{
            id = [string]$_.id
            aliases = @($_.aliases)
        }
    }
)
