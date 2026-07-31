param(
    [string]$Query = "",
    [string]$Category = "",
    [string]$Type = "",
    [string]$Status = "",
    [string]$Tag = "",
    [string]$OwnerAgent = "",
    [int]$Limit = 25,
    [switch]$IncludeArchived
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

$indexScript = ".\scripts\knowledge\Update-AIOfficeKnowledgeIndex.ps1"
$indexPath = ".\workspace\knowledge\knowledge-index.json"

if (-not (Test-Path -LiteralPath $indexPath -PathType Leaf)) {
    & $indexScript | Out-Null
}

$index = Get-Content -LiteralPath $indexPath -Raw | ConvertFrom-Json
$results = @($index.items)

if (-not $IncludeArchived) {
    $results = @(
        $results | Where-Object {
            $_.status -ne "archived"
        }
    )
}

if (-not [string]::IsNullOrWhiteSpace($Query)) {
    $queryText = $Query.ToLowerInvariant()

    $results = @(
        $results | Where-Object {
            ([string]$_.search_text).Contains($queryText)
        }
    )
}

if (-not [string]::IsNullOrWhiteSpace($Category)) {
    $results = @(
        $results | Where-Object {
            $_.category -eq $Category
        }
    )
}

if (-not [string]::IsNullOrWhiteSpace($Type)) {
    $results = @(
        $results | Where-Object {
            $_.type -eq $Type
        }
    )
}

if (-not [string]::IsNullOrWhiteSpace($Status)) {
    $results = @(
        $results | Where-Object {
            $_.status -eq $Status
        }
    )
}

if (-not [string]::IsNullOrWhiteSpace($OwnerAgent)) {
    $results = @(
        $results | Where-Object {
            $_.owner_agent -eq $OwnerAgent
        }
    )
}

if (-not [string]::IsNullOrWhiteSpace($Tag)) {
    $tagText = $Tag.Trim().ToLowerInvariant()

    $results = @(
        $results | Where-Object {
            @($_.tags) -contains $tagText
        }
    )
}

$results = @(
    $results |
    Sort-Object updated_at -Descending |
    Select-Object -First $Limit
)

Write-Host ""
Write-Host "Knowledge search results: $($results.Count)" -ForegroundColor Cyan
Write-Host ""

if ($results.Count -eq 0) {
    Write-Host "No matching knowledge items were found." -ForegroundColor Yellow
    exit 0
}

$rows = foreach ($item in $results) {
    [PSCustomObject]@{
        KnowledgeId = $item.knowledge_id
        Type = $item.type
        Category = $item.category
        Status = $item.status
        Updated = $item.updated_at
        Title = $item.title
        Tags = (@($item.tags) -join ", ")
    }
}

$rows | Format-Table -AutoSize
