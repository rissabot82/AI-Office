$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

Write-Host ""
Write-Host "Testing AI Office knowledge management system..." -ForegroundColor Cyan
Write-Host ""

$errorsFound = 0

$jsonFiles = @(
    ".\config\knowledge\knowledge-policy.json",
    ".\config\knowledge\knowledge-categories.json",
    ".\config\knowledge\knowledge-types.json",
    ".\config\knowledge\knowledge-item-schema.json",
    ".\workspace\knowledge\knowledge-index.json",
    ".\workspace\templates\knowledge-item-template.json"
)

foreach ($file in $jsonFiles) {
    try {
        Get-Content -LiteralPath $file -Raw | ConvertFrom-Json | Out-Null
        Write-Host "[VALID JSON] $file" -ForegroundColor Green
    }
    catch {
        Write-Host "[INVALID   ] $file" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $errorsFound++
    }
}

$requiredScripts = @(
    ".\scripts\knowledge\New-AIOfficeKnowledge.ps1",
    ".\scripts\knowledge\Update-AIOfficeKnowledgeIndex.ps1",
    ".\scripts\knowledge\Show-AIOfficeKnowledge.ps1",
    ".\scripts\knowledge\Search-AIOfficeKnowledge.ps1",
    ".\scripts\knowledge\Update-AIOfficeKnowledge.ps1",
    ".\scripts\knowledge\Link-AIOfficeKnowledge.ps1",
    ".\scripts\knowledge\Add-AIOfficeKnowledgeSource.ps1",
    ".\scripts\knowledge\Archive-AIOfficeKnowledge.ps1"
)

foreach ($script in $requiredScripts) {
    if (Test-Path -LiteralPath $script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING     ] $script" -ForegroundColor Red
        $errorsFound++
    }
}

$requiredTemplates = @(
    ".\workspace\templates\knowledge-note-template.md",
    ".\workspace\templates\knowledge-sop-template.md",
    ".\workspace\templates\knowledge-research-template.md",
    ".\workspace\templates\knowledge-decision-template.md"
)

foreach ($template in $requiredTemplates) {
    if (Test-Path -LiteralPath $template -PathType Leaf) {
        Write-Host "[FOUND TMPL ] $template" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING     ] $template" -ForegroundColor Red
        $errorsFound++
    }
}

$categoryFile = Get-Content `
    -LiteralPath ".\config\knowledge\knowledge-categories.json" `
    -Raw |
    ConvertFrom-Json

$requiredCategories = @(
    "general",
    "marketing",
    "creative",
    "website",
    "analytics",
    "automotive",
    "finance",
    "side-hustles",
    "business",
    "youtube",
    "ai-office",
    "openclaw"
)

foreach ($category in $requiredCategories) {
    if (@($categoryFile.categories.id) -contains $category) {
        Write-Host "[VALID CAT  ] $category" -ForegroundColor Green
    }
    else {
        Write-Host "[BAD CAT    ] $category" -ForegroundColor Red
        $errorsFound++
    }
}

$knowledgeFiles = Get-ChildItem `
    -Path ".\workspace\knowledge\items" `
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

        if ([string]::IsNullOrWhiteSpace([string]$item.knowledge_id)) {
            throw "knowledge_id is missing."
        }

        if ([string]::IsNullOrWhiteSpace([string]$item.title)) {
            throw "title is missing."
        }

        if ([string]::IsNullOrWhiteSpace([string]$item.summary)) {
            throw "summary is missing."
        }

        if ($null -eq $item.tags) {
            throw "tags array is missing."
        }

        if ($null -eq $item.links) {
            throw "links array is missing."
        }

        if ($null -eq $item.sources) {
            throw "sources array is missing."
        }

        if ($null -eq $item.history) {
            throw "history array is missing."
        }

        $contentPath = Join-Path `
            $knowledgeFile.Directory.FullName `
            ([string]$item.content_file)

        if (-not (Test-Path -LiteralPath $contentPath -PathType Leaf)) {
            throw "content file is missing."
        }

        Write-Host "[VALID ITEM ] $($item.knowledge_id)" -ForegroundColor Green
    }
    catch {
        Write-Host "[INVALID    ] $($knowledgeFile.FullName)" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $errorsFound++
    }
}

try {
    & ".\scripts\knowledge\Update-AIOfficeKnowledgeIndex.ps1" | Out-Null

    $index = Get-Content `
        -LiteralPath ".\workspace\knowledge\knowledge-index.json" `
        -Raw |
        ConvertFrom-Json

    Write-Host "[INDEX OK   ] $($index.total_items) knowledge item(s)" -ForegroundColor Green
}
catch {
    Write-Host "[INDEX ERROR] Knowledge index failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $errorsFound++
}

Write-Host ""

if ($errorsFound -eq 0) {
    Write-Host "All knowledge management checks passed." -ForegroundColor Green
}
else {
    Write-Host (
        "{0} knowledge management error or errors were found." -f
        $errorsFound
    ) -ForegroundColor Red

    exit 1
}
