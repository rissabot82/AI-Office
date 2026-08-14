param()

$ErrorActionPreference = "Stop"

return Get-Content `
    -LiteralPath "E:\AI\AI-Office\config\discord-office\routing-policy.json" `
    -Raw |
    ConvertFrom-Json
