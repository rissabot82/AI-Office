param()

$ErrorActionPreference = "Stop"

return Get-Content `
    -LiteralPath "E:\AI\AI-Office\config\intelligence\model-selection-policy.json" `
    -Raw |
    ConvertFrom-Json
