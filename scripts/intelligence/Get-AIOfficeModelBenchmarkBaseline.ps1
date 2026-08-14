param()

$ErrorActionPreference = "Stop"

return Get-Content `
    -LiteralPath "E:\AI\AI-Office\config\intelligence\model-benchmark-baseline.json" `
    -Raw |
    ConvertFrom-Json
