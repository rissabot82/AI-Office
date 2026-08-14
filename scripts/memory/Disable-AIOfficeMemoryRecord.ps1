param(
    [Parameter(Mandatory=$true)][string]$MemoryId
)

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$IndexPath = ".\workspace\memory\indexes\memory-index.json"
$Index = Get-Content $IndexPath -Raw | ConvertFrom-Json

$Entry = @(
    $Index.records |
    Where-Object { [string]$_.memory_id -eq $MemoryId }
) | Select-Object -First 1

if ($null -eq $Entry) {
    throw "Memory record not found: $MemoryId"
}

$RecordPath = Join-Path "E:\AI\AI-Office" ([string]$Entry.path)
$Record = Get-Content $RecordPath -Raw | ConvertFrom-Json

$Now = (Get-Date).ToString("o")
$Record.enabled = $false
$Record.updated_at = $Now

$Record |
    ConvertTo-Json -Depth 30 |
    Set-Content -LiteralPath $RecordPath -Encoding UTF8

foreach ($Item in @($Index.records)) {
    if ([string]$Item.memory_id -eq $MemoryId) {
        $Item.enabled = $false
        $Item.updated_at = $Now
    }
}

$Index.updated_at = $Now

$Index |
    ConvertTo-Json -Depth 30 |
    Set-Content -LiteralPath $IndexPath -Encoding UTF8

Write-Host "Memory record disabled: $MemoryId" -ForegroundColor Yellow
