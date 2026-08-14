param(
    [switch]$Persist
)

$ErrorActionPreference = "Stop"

$Models = @(
    & "E:\AI\AI-Office\scripts\intelligence\Get-AIOfficeInstalledModels.ps1"
)

$Inventory = [ordered]@{
    inventory_id = "INTINV-" + (Get-Date -Format "yyyyMMdd-HHmmss")
    provider = "ollama"
    model_count = $Models.Count
    models = @(
        $Models |
        ForEach-Object {
            [ordered]@{
                model = [string]$_.model
                provider = [string]$_.provider
                available = [bool]$_.available
                source = [string]$_.source
            }
        }
    )
    created_at = (Get-Date).ToString("o")
}

if ($Persist) {
    $Directory = "E:\AI\AI-Office\workspace\intelligence\inventories"
    New-Item -ItemType Directory -Path $Directory -Force | Out-Null

    $Inventory |
        ConvertTo-Json -Depth 50 |
        Set-Content `
            -LiteralPath (Join-Path $Directory ($Inventory.inventory_id + ".json")) `
            -Encoding UTF8
}

return [pscustomobject]$Inventory
