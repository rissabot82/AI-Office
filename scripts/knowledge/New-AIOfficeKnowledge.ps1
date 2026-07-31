param(
    [Parameter(Mandatory = $true)]
    [string]$Title,

    [Parameter(Mandatory = $true)]
    [string]$Summary,

    [ValidateSet(
        "note",
        "sop",
        "research",
        "reference",
        "decision",
        "lesson",
        "contact",
        "template"
    )]
    [string]$Type = "note",

    [string]$Category = "general",

    [ValidateSet(
        "draft",
        "active",
        "review",
        "deprecated",
        "archived"
    )]
    [string]$Status = "active",

    [ValidateSet(
        "internal",
        "private",
        "shared"
    )]
    [string]$Visibility = "internal",

    [string]$OwnerAgent = "chief-of-staff",
    [string]$CreatedBy = "Clarissa",
    [string[]]$Tags = @(),
    [string]$Content = "",
    [string]$SourceTitle = "",
    [string]$SourceLocation = "",
    [string]$SourceNotes = ""
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

$categoryConfig = Get-Content `
    -LiteralPath ".\config\knowledge\knowledge-categories.json" `
    -Raw |
    ConvertFrom-Json

$validCategories = @($categoryConfig.categories.id)

if ($validCategories -notcontains $Category) {
    throw "Unknown knowledge category: $Category"
}

$itemsRoot = ".\workspace\knowledge\items"

if (-not (Test-Path -LiteralPath $itemsRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $itemsRoot -Force | Out-Null
}

$today = Get-Date -Format "yyyyMMdd"
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

$existingFolders = Get-ChildItem `
    -LiteralPath $itemsRoot `
    -Directory `
    -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -match "^KNOW-$today-(\d{4})$"
    }

$highestNumber = 0

foreach ($folder in $existingFolders) {
    if ($folder.Name -match "^KNOW-$today-(\d{4})$") {
        $number = [int]$Matches[1]

        if ($number -gt $highestNumber) {
            $highestNumber = $number
        }
    }
}

$knowledgeId = "KNOW-$today-{0:D4}" -f ($highestNumber + 1)
$itemFolder = Join-Path $itemsRoot $knowledgeId

New-Item -ItemType Directory -Path $itemFolder -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $itemFolder "attachments") -Force | Out-Null

$templateMap = @{
    note = ".\workspace\templates\knowledge-note-template.md"
    sop = ".\workspace\templates\knowledge-sop-template.md"
    research = ".\workspace\templates\knowledge-research-template.md"
    reference = ".\workspace\templates\knowledge-note-template.md"
    decision = ".\workspace\templates\knowledge-decision-template.md"
    lesson = ".\workspace\templates\knowledge-note-template.md"
    contact = ".\workspace\templates\knowledge-note-template.md"
    template = ".\workspace\templates\knowledge-note-template.md"
}

if ([string]::IsNullOrWhiteSpace($Content)) {
    $contentText = Get-Content -LiteralPath $templateMap[$Type] -Raw
}
else {
    $contentText = $Content
}

$contentPath = Join-Path $itemFolder "content.md"
Set-Content -LiteralPath $contentPath -Value $contentText -Encoding UTF8

$sources = @()

if (
    -not [string]::IsNullOrWhiteSpace($SourceTitle) -or
    -not [string]::IsNullOrWhiteSpace($SourceLocation)
) {
    if ([string]::IsNullOrWhiteSpace($SourceTitle)) {
        throw "SourceTitle is required when SourceLocation is supplied."
    }

    if ([string]::IsNullOrWhiteSpace($SourceLocation)) {
        throw "SourceLocation is required when SourceTitle is supplied."
    }

    $sources += [PSCustomObject]@{
        title = $SourceTitle
        location = $SourceLocation
        accessed_at = $timestamp
        notes = $SourceNotes
    }
}

$normalizedTags = @(
    $Tags |
    ForEach-Object {
        [string]$_
    } |
    ForEach-Object {
        $_.Trim().ToLowerInvariant()
    } |
    Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    } |
    Sort-Object -Unique
)

$item = [ordered]@{
    knowledge_id = $knowledgeId
    title = $Title
    summary = $Summary
    type = $Type
    category = $Category
    status = $Status
    visibility = $Visibility
    owner_agent = $OwnerAgent
    created_by = $CreatedBy
    created_at = $timestamp
    updated_at = $timestamp
    version = 1
    content_file = "content.md"
    tags = $normalizedTags
    links = @()
    sources = $sources
    history = @(
        [ordered]@{
            timestamp = $timestamp
            action = "knowledge-created"
            actor = $CreatedBy
            details = "Knowledge item created."
        }
    )
}

$itemPath = Join-Path $itemFolder "knowledge.json"

$item |
    ConvertTo-Json -Depth 20 |
    Set-Content -LiteralPath $itemPath -Encoding UTF8

$indexScript = ".\scripts\knowledge\Update-AIOfficeKnowledgeIndex.ps1"

if (Test-Path -LiteralPath $indexScript -PathType Leaf) {
    & $indexScript | Out-Null
}

Write-Host ""
Write-Host "Knowledge item created successfully." -ForegroundColor Green
Write-Host ""
Write-Host "Knowledge ID: $knowledgeId"
Write-Host "Title:        $Title"
Write-Host "Type:         $Type"
Write-Host "Category:     $Category"
Write-Host "Status:       $Status"
Write-Host "Folder:       $itemFolder"
