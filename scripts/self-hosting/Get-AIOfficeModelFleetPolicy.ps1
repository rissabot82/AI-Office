param()

$ErrorActionPreference = "Stop"

return Get-Content `
    -LiteralPath "E:\AI\AI-Office\config\self-hosting\model-fleet-policy.json" `
    -Raw |
    ConvertFrom-Json
