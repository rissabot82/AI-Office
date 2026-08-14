param()

$ErrorActionPreference = "Stop"
$Path = "E:\AI\AI-Office\workspace\discord-office\state\worker-state.json"

if (-not (Test-Path -LiteralPath $Path)) {
    throw "Discord worker state not found."
}

return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
