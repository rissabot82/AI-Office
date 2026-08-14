param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("project","dealership","organization","workflow","user_approved")]
    [string]$MemoryType,

    [Parameter(Mandatory=$true)][string]$Title,
    [Parameter(Mandatory=$true)][string]$Content,
    [string]$Source = "manual",
    [string]$Scope = "global",
    [string[]]$Tags = @(),
    [hashtable]$Metadata = @{},
    [switch]$AllowDuplicate
)

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$Policy = Get-Content `
    ".\config\memory\memory-write-policy.json" `
    -Raw | ConvertFrom-Json

if (-not [bool]$Policy.enabled) {
    throw "Memory writes are disabled."
}

if ([string]::IsNullOrWhiteSpace($Title)) {
    throw "Memory title cannot be empty."
}

if ([string]::IsNullOrWhiteSpace($Content)) {
    throw "Memory content cannot be empty."
}

if ([bool]$Policy.reject_secret_like_content) {
    $Lower = $Content.ToLowerInvariant()

    foreach ($Pattern in @($Policy.secret_patterns)) {
        if ($Lower.Contains(([string]$Pattern).ToLowerInvariant())) {
            throw "Memory content was rejected because it appears to contain secret-like material: $Pattern"
        }
    }
}

$RecordsDir = ".\workspace\memory\records"
$IndexPath = ".\workspace\memory\indexes\memory-index.json"

New-Item -ItemType Directory -Path $RecordsDir -Force | Out-Null

$Index = Get-Content $IndexPath -Raw | ConvertFrom-Json

if (-not $AllowDuplicate -and [bool]$Policy.indexing.deduplicate_exact_content) {
    foreach ($Entry in @($Index.records)) {
        $RecordPath = Join-Path "E:\AI\AI-Office" ([string]$Entry.path)

        if (Test-Path -LiteralPath $RecordPath) {
            $Existing = Get-Content $RecordPath -Raw | ConvertFrom-Json

            if (
                [string]$Existing.memory_type -eq $MemoryType -and
                [string]$Existing.scope -eq $Scope -and
                [string]$Existing.content -eq $Content
            ) {
                return [pscustomobject]@{
                    created = $false
                    duplicate = $true
                    memory_id = [string]$Existing.memory_id
                    path = [string]$Entry.path
                }
            }
        }
    }
}

$MemoryId = & ".\scripts\memory\New-AIOfficeMemoryId.ps1" -Prefix "MEM"
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    memory_id = $MemoryId
    memory_type = $MemoryType
    title = $Title.Trim()
    content = $Content.Trim()
    source = $Source
    scope = $Scope
    tags = @($Tags | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Unique)
    metadata = $Metadata
    enabled = $true
    created_at = $Now
    updated_at = $Now
}

$RelativePath = "workspace\memory\records\$MemoryId.json"
$FullPath = Join-Path "E:\AI\AI-Office" $RelativePath

$Record |
    ConvertTo-Json -Depth 30 |
    Set-Content -LiteralPath $FullPath -Encoding UTF8

$Index.records = @($Index.records) + @(
    [pscustomobject]@{
        memory_id = $MemoryId
        memory_type = $MemoryType
        title = $Record.title
        scope = $Scope
        source = $Source
        tags = @($Record.tags)
        enabled = $true
        path = $RelativePath
        created_at = $Now
        updated_at = $Now
    }
)

$Index.record_count = @($Index.records).Count
$Index.updated_at = $Now

$Index |
    ConvertTo-Json -Depth 30 |
    Set-Content -LiteralPath $IndexPath -Encoding UTF8

Write-Host "Memory record created: $MemoryId | $MemoryType | $($Record.title)" -ForegroundColor Green

return [pscustomobject]@{
    created = $true
    duplicate = $false
    memory_id = $MemoryId
    path = $RelativePath
    memory_type = $MemoryType
    title = $Record.title
    scope = $Scope
}
