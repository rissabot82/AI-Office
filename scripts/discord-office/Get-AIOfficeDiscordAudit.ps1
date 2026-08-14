param(
    [int]$Last = 20
)

$ErrorActionPreference = "Stop"

if ($Last -lt 1) { $Last = 20 }
if ($Last -gt 100) { $Last = 100 }

$Directory = "E:\AI\AI-Office\workspace\discord-office\audit"

if (-not (Test-Path -LiteralPath $Directory)) {
    return @()
}

return @(
    Get-ChildItem -LiteralPath $Directory -Filter "DCAUD-*.json" -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime |
    Select-Object -Last $Last |
    ForEach-Object {
        try {
            Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
        }
        catch {}
    }
)
