param()

$ErrorActionPreference = "Stop"

$Path = "E:\AI\AI-Office\config\intelligence\live-escalation-policy.json"
$Policy = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
$Policy.enabled = $false
$Policy | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $Path -Encoding UTF8

Write-Host "AI Office live external escalation DISABLED. Local inference remains available." -ForegroundColor Yellow
