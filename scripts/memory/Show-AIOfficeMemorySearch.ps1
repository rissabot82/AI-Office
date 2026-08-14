param(
    [Parameter(Mandatory=$true)][string]$Query,
    [string]$Scope = "",
    [string[]]$MemoryTypes = @(),
    [int]$MaxItems = 8
)

$Results = @(
    & "E:\AI\AI-Office\scripts\memory\Search-AIOfficeMemory.ps1" `
        -Query $Query `
        -Scope $Scope `
        -MemoryTypes $MemoryTypes `
        -MaxItems $MaxItems
)

Write-Host ""
Write-Host "AI Office Memory Search" -ForegroundColor Cyan
Write-Host "-----------------------"
Write-Host ("Query: " + $Query)
if (-not [string]::IsNullOrWhiteSpace($Scope)) {
    Write-Host ("Scope: " + $Scope)
}
Write-Host ""

foreach ($Item in $Results) {
    Write-Host ("[" + $Item.score + "] " + $Item.memory_type + " | " + $Item.title) -ForegroundColor Green
    Write-Host ("  " + $Item.content)
    Write-Host ("  Reasons: " + (@($Item.reasons) -join ", "))
    Write-Host ""
}

if ($Results.Count -eq 0) {
    Write-Host "No relevant memories found." -ForegroundColor Yellow
}

return @($Results)
