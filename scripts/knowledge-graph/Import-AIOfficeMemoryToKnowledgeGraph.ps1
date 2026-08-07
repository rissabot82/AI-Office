param(
    [int]$Limit = 250
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\knowledge-graph\AIOfficeKnowledgeReasoning.Common.ps1"

$MemoryFiles = @(
    Get-ChildItem `
        -LiteralPath "E:\AI\AI-Office\workspace\memory" `
        -Recurse `
        -Filter "MEM-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First $Limit
)

$Imported = New-Object System.Collections.Generic.List[object]

foreach ($File in $MemoryFiles) {
    try {
        $Memory = Get-Content -LiteralPath $File.FullName -Raw | ConvertFrom-Json
    }
    catch {
        continue
    }

    $Title = [string]$Memory.title

    if ([string]::IsNullOrWhiteSpace($Title)) {
        continue
    }

    $Scope = if ([string]::IsNullOrWhiteSpace([string]$Memory.scope)) {
        "business"
    }
    else {
        [string]$Memory.scope
    }

    $EntityType = "document"

    if ($null -ne $Memory.PSObject.Properties["memory_type"]) {
        $MemoryType = [string]$Memory.memory_type

        if ($MemoryType -match "person") {
            $EntityType = "person"
        }
        elseif ($MemoryType -match "vendor") {
            $EntityType = "vendor"
        }
        elseif ($MemoryType -match "dealership|store") {
            $EntityType = "dealership"
        }
        elseif ($MemoryType -match "project") {
            $EntityType = "project"
        }
        elseif ($MemoryType -match "campaign") {
            $EntityType = "campaign"
        }
        elseif ($MemoryType -match "decision") {
            $EntityType = "decision"
        }
        elseif ($MemoryType -match "goal") {
            $EntityType = "goal"
        }
    }

    $Entity = & "E:\AI\AI-Office\scripts\knowledge-graph\Resolve-AIOfficeKnowledgeEntity.ps1" `
        -Name $Title `
        -EntityType $EntityType `
        -Scope $Scope `
        -Confidence 0.72 `
        -SourceType "long_term_memory" `
        -SourceRef ([string]$Memory.memory_id) `
        -SourceDetail $File.FullName

    $Imported.Add($Entity)
}

& "E:\AI\AI-Office\scripts\knowledge-graph\Update-AIOfficeKnowledgeGraphIndex.ps1" |
    Out-Null

Write-Host "Memory import completed: $($Imported.Count) entity record(s) resolved." `
    -ForegroundColor Green

return @($Imported | ForEach-Object { $_ })
