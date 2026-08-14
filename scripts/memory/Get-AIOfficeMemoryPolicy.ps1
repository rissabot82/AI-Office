param()
$ErrorActionPreference="Stop"
Get-Content "E:\AI\AI-Office\config\memory\memory-policy.json" -Raw | ConvertFrom-Json
