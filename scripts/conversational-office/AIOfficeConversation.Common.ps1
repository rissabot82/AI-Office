$script:AIOfficeConversationRoot = "E:\AI\AI-Office"

function New-AIOfficeConversationId {
    param([Parameter(Mandatory=$true)][string]$Prefix)
    $Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $Suffix = ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    return "$Prefix-$Stamp-$Suffix"
}

function Write-AIOfficeConversationJson {
    param([Parameter(Mandatory=$true)]$Value,[Parameter(Mandatory=$true)][string]$Path)
    $Parent = Split-Path -Parent $Path
    if ($Parent -and -not (Test-Path -LiteralPath $Parent)) {
        New-Item -ItemType Directory -Path $Parent -Force | Out-Null
    }
    $Value | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-AIOfficeConversationCollection {
    param([Parameter(Mandatory=$true)][string]$Directory,[Parameter(Mandatory=$true)][string]$Filter)
    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) { return @() }
    return @(Get-ChildItem -LiteralPath $Directory -Filter $Filter -File -ErrorAction SilentlyContinue | ForEach-Object {
        try { Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json } catch {}
    })
}

function Get-AIOfficeConversationPolicy {
    return Get-Content -LiteralPath "E:\AI\AI-Office\config\conversational-office\conversation-policy.json" -Raw | ConvertFrom-Json
}
