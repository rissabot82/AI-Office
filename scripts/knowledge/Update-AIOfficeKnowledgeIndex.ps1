$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

$itemsRoot = ".\workspace\knowledge\items"
$indexPath = ".\workspace\knowledge\knowledge-index.json"
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

$indexItems = @()

$knowledgeFiles = Get-ChildItem `
    -Path $itemsRoot `
    -Filter "knowledge.json" `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue

foreach ($knowledgeFile in $knowledgeFiles) {
    try {
        $item = Get-Content `
            -LiteralPath $knowledgeFile.FullName `
            -Raw |
            ConvertFrom-Json

        $contentPath = Join-Path `
            $knowledgeFile.Directory.FullName `
            ([string]$item.content_file)

        if (Test-Path -LiteralPath $contentPath -PathType Leaf) {
            $content = Get-Content -LiteralPath $contentPath -Raw
        }
        else {
            $content = ""
        }

        $searchText = (
            @(
                $item.title,
                $item.summary,
                $item.type,
                $item.category,
                (@($item.tags) -join " "),
                $content
            ) -join "`n"
        ).ToLowerInvariant()

        $relativeFolder = $knowledgeFile.Directory.FullName.Substring(
            $repositoryRoot.Path.Length
        ).TrimStart("\", "/")

        $indexItems += [PSCustomObject]@{
            knowledge_id = [string]$item.knowledge_id
            title = [string]$item.title
            summary = [string]$item.summary
            type = [string]$item.type
            category = [string]$item.category
            status = [string]$item.status
            visibility = [string]$item.visibility
            owner_agent = [string]$item.owner_agent
            version = [int]$item.version
            updated_at = [string]$item.updated_at
            tags = @($item.tags)
            folder = $relativeFolder
            search_text = $searchText
        }
    }
    catch {
        Write-Warning "Skipped invalid knowledge item: $($knowledgeFile.FullName)"
    }
}

$index = [ordered]@{
    version = "1.0.0"
    generated_at = $timestamp
    total_items = $indexItems.Count
    items = @(
        $indexItems |
        Sort-Object updated_at -Descending
    )
}

$index |
    ConvertTo-Json -Depth 20 |
    Set-Content -LiteralPath $indexPath -Encoding UTF8

Write-Host "Knowledge index updated: $($indexItems.Count) item(s)." -ForegroundColor Green
