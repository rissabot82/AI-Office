param(
    [Parameter(Mandatory=$true)][string]$MemoryId
)

$ErrorActionPreference = "Stop"

$Index = Get-Content `
    "E:\AI\AI-Office\workspace\memory\indexes\memory-index.json" `
    -Raw | ConvertFrom-Json

$Entry = @(
    $Index.records |
    Where-Object { [string]$_.memory_id -eq $MemoryId }
) | Select-Object -First 1

if ($null -eq $Entry) {
    throw "Memory record not found: $MemoryId"
}

$Path = Join-Path "E:\AI\AI-Office" ([string]$Entry.path)

if (-not (Test-Path -LiteralPath $Path)) {
    throw "Memory file is missing for index entry: $MemoryId"
}

return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
