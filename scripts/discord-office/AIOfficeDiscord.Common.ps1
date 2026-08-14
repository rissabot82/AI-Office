$script:AIOfficeDiscordRoot = "E:\AI\AI-Office"

function New-AIOfficeDiscordId {
    param([Parameter(Mandatory=$true)][string]$Prefix)

    $Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $Suffix = ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    return "$Prefix-$Stamp-$Suffix"
}

function Write-AIOfficeDiscordJson {
    param(
        [Parameter(Mandatory=$true)]$Value,
        [Parameter(Mandatory=$true)][string]$Path
    )

    $Parent = Split-Path -Parent $Path

    if ($Parent -and -not (Test-Path -LiteralPath $Parent)) {
        New-Item -ItemType Directory -Path $Parent -Force | Out-Null
    }

    $Value |
        ConvertTo-Json -Depth 100 |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-AIOfficeDiscordPolicy {
    return Get-Content `
        -LiteralPath "E:\AI\AI-Office\config\discord-office\discord-policy.json" `
        -Raw |
        ConvertFrom-Json
}

function Get-AIOfficeDiscordAllowlist {
    $CanonicalPath = "E:\AI\AI-Office\config\discord-office\allowlist.json"

    if (Test-Path -LiteralPath $CanonicalPath -PathType Leaf) {
        $Canonical = Get-Content -LiteralPath $CanonicalPath -Raw | ConvertFrom-Json

        return [pscustomobject]@{
            guilds   = @($Canonical.allowed_guild_ids)
            channels = @($Canonical.allowed_channel_ids)
            users    = @($Canonical.allowed_user_ids)
        }
    }

    return Get-Content `
        -LiteralPath "E:\AI\AI-Office\config\discord-office\discord-allowlist.json" `
        -Raw |
        ConvertFrom-Json
}

function Get-AIOfficeDiscordCollection {
    param(
        [Parameter(Mandatory=$true)][string]$Directory,
        [Parameter(Mandatory=$true)][string]$Filter
    )

    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        return @()
    }

    return @(
        Get-ChildItem -LiteralPath $Directory -Filter $Filter -File -ErrorAction SilentlyContinue |
        ForEach-Object {
            try {
                Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
            }
            catch {}
        }
    )
}

function Test-AIOfficeDiscordIdentifierAllowed {
    param(
        [Parameter(Mandatory=$true)][string]$Identifier,
        [Parameter(Mandatory=$true)][ValidateSet("guilds","channels","users")][string]$Collection
    )

    $Allowlist = Get-AIOfficeDiscordAllowlist
    $Allowed = @($Allowlist.$Collection | ForEach-Object { [string]$_ })

    if ($Allowed.Count -eq 0) {
        return $false
    }

    return ($Allowed -contains $Identifier)
}

