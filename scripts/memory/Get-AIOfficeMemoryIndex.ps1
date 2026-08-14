param(
    [ValidateSet("project","dealership","organization","workflow","user_approved")]
    [string]$MemoryType,
    [string]$Scope,
    [switch]$IncludeDisabled
)

$ErrorActionPreference = "Stop"

$Index = Get-Content `
    "E:\AI\AI-Office\workspace\memory\indexes\memory-index.json" `
    -Raw | ConvertFrom-Json

$Records = @($Index.records)

if (-not $IncludeDisabled) {
    $Records = @($Records | Where-Object { [bool]$_.enabled })
}

if (-not [string]::IsNullOrWhiteSpace($MemoryType)) {
    $Records = @($Records | Where-Object { [string]$_.memory_type -eq $MemoryType })
}

if (-not [string]::IsNullOrWhiteSpace($Scope)) {
    $Records = @($Records | Where-Object { [string]$_.scope -eq $Scope })
}

return @($Records)
