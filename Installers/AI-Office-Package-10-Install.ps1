# ============================================================
# AI Office Package 10
# Knowledge Management System
# Repository: E:\AI\AI-Office
# ============================================================

$ErrorActionPreference = "Stop"

$expectedRepository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $expectedRepository -PathType Container)) {
    throw "AI Office repository not found at $expectedRepository"
}

Set-Location $expectedRepository

function New-SafeDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
    }
}

function New-SafeFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Content
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        $parent = Split-Path -Parent $Path

        if (
            -not [string]::IsNullOrWhiteSpace($parent) -and
            -not (Test-Path -LiteralPath $parent -PathType Container)
        ) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }

        Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
    }
}

$requiredFolders = @(
    ".\config\knowledge",
    ".\workspace\knowledge",
    ".\workspace\knowledge\items",
    ".\workspace\knowledge\archive",
    ".\workspace\knowledge\versions",
    ".\workspace\knowledge\attachments",
    ".\workspace\templates",
    ".\scripts\knowledge",
    ".\docs"
)

foreach ($folder in $requiredFolders) {
    New-SafeDirectory -Path $folder
}

$knowledgePolicy = @'
{
  "version": "1.0.0",
  "default_owner": "chief-of-staff",
  "default_status": "active",
  "default_visibility": "internal",
  "require_title": true,
  "require_summary": true,
  "require_category": true,
  "require_source_for_research": false,
  "allow_empty_tags": true,
  "allow_cross_links": true,
  "create_version_on_update": true,
  "archive_instead_of_delete": true,
  "supported_types": [
    "note",
    "sop",
    "research",
    "reference",
    "decision",
    "lesson",
    "contact",
    "template"
  ],
  "supported_statuses": [
    "draft",
    "active",
    "review",
    "deprecated",
    "archived"
  ],
  "supported_visibility": [
    "internal",
    "private",
    "shared"
  ]
}
'@

New-SafeFile ".\config\knowledge\knowledge-policy.json" $knowledgePolicy

$knowledgeCategories = @'
{
  "version": "1.0.0",
  "categories": [
    {
      "id": "general",
      "name": "General",
      "description": "Knowledge that does not fit another category."
    },
    {
      "id": "marketing",
      "name": "Marketing",
      "description": "Campaign strategy, advertising, offers, audiences, and reporting."
    },
    {
      "id": "creative",
      "name": "Creative",
      "description": "Design systems, prompts, image direction, copy, and production notes."
    },
    {
      "id": "website",
      "name": "Website",
      "description": "Website platforms, development, analytics implementation, and troubleshooting."
    },
    {
      "id": "analytics",
      "name": "Analytics",
      "description": "Measurement, attribution, dashboards, conversion tracking, and reporting."
    },
    {
      "id": "automotive",
      "name": "Automotive",
      "description": "Dealership operations, vehicle marketing, offers, and vendor information."
    },
    {
      "id": "finance",
      "name": "Finance",
      "description": "Personal finance, budgeting, savings, expenses, and financial planning."
    },
    {
      "id": "side-hustles",
      "name": "Side Hustles",
      "description": "User testing, delivery work, freelance work, and additional income."
    },
    {
      "id": "business",
      "name": "Business",
      "description": "Business planning, pricing, operations, clients, and future ventures."
    },
    {
      "id": "youtube",
      "name": "YouTube",
      "description": "Channel strategy, production, publishing, and performance."
    },
    {
      "id": "ai-office",
      "name": "AI Office",
      "description": "Internal architecture, packages, agents, workflows, and operating procedures."
    },
    {
      "id": "openclaw",
      "name": "OpenClaw",
      "description": "OpenClaw installation, configuration, integrations, and operations."
    }
  ]
}
'@

New-SafeFile ".\config\knowledge\knowledge-categories.json" $knowledgeCategories

$knowledgeTypes = @'
{
  "version": "1.0.0",
  "types": [
    {
      "id": "note",
      "name": "Note",
      "description": "General-purpose knowledge or observations."
    },
    {
      "id": "sop",
      "name": "Standard Operating Procedure",
      "description": "A repeatable process with steps, requirements, and completion criteria."
    },
    {
      "id": "research",
      "name": "Research",
      "description": "Findings, evidence, sources, analysis, and conclusions."
    },
    {
      "id": "reference",
      "name": "Reference",
      "description": "Stable facts, settings, identifiers, definitions, or lookup information."
    },
    {
      "id": "decision",
      "name": "Decision",
      "description": "A recorded decision with rationale, alternatives, and consequences."
    },
    {
      "id": "lesson",
      "name": "Lesson Learned",
      "description": "A mistake, discovery, fix, or reusable insight."
    },
    {
      "id": "contact",
      "name": "Contact",
      "description": "Business contact details and relationship notes."
    },
    {
      "id": "template",
      "name": "Template",
      "description": "Reusable structure, prompt, copy block, or process outline."
    }
  ]
}
'@

New-SafeFile ".\config\knowledge\knowledge-types.json" $knowledgeTypes

$knowledgeSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/knowledge-item-schema.json",
  "title": "AI Office Knowledge Item",
  "type": "object",
  "required": [
    "knowledge_id",
    "title",
    "summary",
    "type",
    "category",
    "status",
    "visibility",
    "owner_agent",
    "created_by",
    "created_at",
    "updated_at",
    "version",
    "content_file",
    "tags",
    "links",
    "sources",
    "history"
  ],
  "properties": {
    "knowledge_id": {
      "type": "string",
      "pattern": "^KNOW-[0-9]{8}-[0-9]{4}$"
    },
    "title": {
      "type": "string",
      "minLength": 1
    },
    "summary": {
      "type": "string",
      "minLength": 1
    },
    "type": {
      "type": "string",
      "enum": [
        "note",
        "sop",
        "research",
        "reference",
        "decision",
        "lesson",
        "contact",
        "template"
      ]
    },
    "category": {
      "type": "string",
      "minLength": 1
    },
    "status": {
      "type": "string",
      "enum": [
        "draft",
        "active",
        "review",
        "deprecated",
        "archived"
      ]
    },
    "visibility": {
      "type": "string",
      "enum": [
        "internal",
        "private",
        "shared"
      ]
    },
    "owner_agent": {
      "type": "string"
    },
    "created_by": {
      "type": "string"
    },
    "created_at": {
      "type": "string"
    },
    "updated_at": {
      "type": "string"
    },
    "version": {
      "type": "integer",
      "minimum": 1
    },
    "content_file": {
      "type": "string"
    },
    "tags": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "links": {
      "type": "array",
      "items": {
        "type": "object",
        "required": [
          "knowledge_id",
          "relationship"
        ],
        "properties": {
          "knowledge_id": {
            "type": "string"
          },
          "relationship": {
            "type": "string"
          }
        }
      }
    },
    "sources": {
      "type": "array",
      "items": {
        "type": "object",
        "required": [
          "title",
          "location"
        ],
        "properties": {
          "title": {
            "type": "string"
          },
          "location": {
            "type": "string"
          },
          "accessed_at": {
            "type": [
              "string",
              "null"
            ]
          },
          "notes": {
            "type": "string"
          }
        }
      }
    },
    "history": {
      "type": "array",
      "items": {
        "type": "object"
      }
    }
  }
}
'@

New-SafeFile ".\config\knowledge\knowledge-item-schema.json" $knowledgeSchema

$knowledgeIndex = @'
{
  "version": "1.0.0",
  "generated_at": null,
  "total_items": 0,
  "items": []
}
'@

New-SafeFile ".\workspace\knowledge\knowledge-index.json" $knowledgeIndex

$knowledgeTemplate = @'
{
  "knowledge_id": "KNOW-YYYYMMDD-0001",
  "title": "Knowledge item title",
  "summary": "Short description of the knowledge item.",
  "type": "note",
  "category": "general",
  "status": "active",
  "visibility": "internal",
  "owner_agent": "chief-of-staff",
  "created_by": "Clarissa",
  "created_at": "YYYY-MM-DDTHH:MM:SS",
  "updated_at": "YYYY-MM-DDTHH:MM:SS",
  "version": 1,
  "content_file": "content.md",
  "tags": [],
  "links": [],
  "sources": [],
  "history": []
}
'@

New-SafeFile ".\workspace\templates\knowledge-item-template.json" $knowledgeTemplate

$noteTemplate = @'
# Knowledge Note

## Summary

Add a concise summary.

## Details

Add the full note.

## Key Points

- Add important points.

## Related Knowledge

- Add related knowledge IDs.

## Sources

- Add sources when applicable.

## Notes

Add supporting information.
'@

New-SafeFile ".\workspace\templates\knowledge-note-template.md" $noteTemplate

$sopTemplate = @'
# Standard Operating Procedure

## Purpose

Describe what this procedure accomplishes.

## Owner

Identify the responsible agent or department.

## Trigger

Describe when this procedure should be used.

## Prerequisites

- List prerequisites.

## Inputs

- List required inputs.

## Procedure

1. Add the first step.
2. Add the next step.
3. Continue until complete.

## Validation

Describe how to confirm the procedure succeeded.

## Completion Criteria

Describe the conditions required for completion.

## Exceptions

Document known exceptions and alternate paths.

## Related Knowledge

- Add related knowledge IDs.

## Revision Notes

Document important changes.
'@

New-SafeFile ".\workspace\templates\knowledge-sop-template.md" $sopTemplate

$researchTemplate = @'
# Research Record

## Question

State the question being investigated.

## Summary

Summarize the findings.

## Evidence

Document the evidence.

## Analysis

Explain what the evidence means.

## Conclusions

List the supported conclusions.

## Limitations

Document uncertainty, missing information, or weak evidence.

## Recommendations

List recommended actions.

## Sources

- Source title and location.

## Related Knowledge

- Add related knowledge IDs.
'@

New-SafeFile ".\workspace\templates\knowledge-research-template.md" $researchTemplate

$decisionTemplate = @'
# Decision Record

## Decision

State the decision.

## Context

Describe the situation and why a decision was required.

## Options Considered

### Option 1

Describe the option.

### Option 2

Describe the option.

## Rationale

Explain why the selected option was chosen.

## Consequences

Describe expected benefits, costs, risks, and follow-up actions.

## Decision Owner

Identify the person or agent responsible.

## Review Date

Add a future review date when applicable.

## Related Knowledge

- Add related knowledge IDs.
'@

New-SafeFile ".\workspace\templates\knowledge-decision-template.md" $decisionTemplate

$newKnowledgeScript = @'
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
'@

New-SafeFile ".\scripts\knowledge\New-AIOfficeKnowledge.ps1" $newKnowledgeScript

$updateIndexScript = @'
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
'@

New-SafeFile ".\scripts\knowledge\Update-AIOfficeKnowledgeIndex.ps1" $updateIndexScript

$showKnowledgeScript = @'
param(
    [Parameter(Mandatory = $true)]
    [string]$KnowledgeId,

    [switch]$MetadataOnly,
    [switch]$ShowHistory
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

$itemFolder = Join-Path ".\workspace\knowledge\items" $KnowledgeId
$itemPath = Join-Path $itemFolder "knowledge.json"

if (-not (Test-Path -LiteralPath $itemPath -PathType Leaf)) {
    throw "Knowledge item not found: $KnowledgeId"
}

$item = Get-Content -LiteralPath $itemPath -Raw | ConvertFrom-Json
$contentPath = Join-Path $itemFolder ([string]$item.content_file)

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " AI Office Knowledge Item" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Knowledge ID:  $($item.knowledge_id)"
Write-Host "Title:         $($item.title)"
Write-Host "Summary:       $($item.summary)"
Write-Host "Type:          $($item.type)"
Write-Host "Category:      $($item.category)"
Write-Host "Status:        $($item.status)"
Write-Host "Visibility:    $($item.visibility)"
Write-Host "Owner:         $($item.owner_agent)"
Write-Host "Version:       $($item.version)"
Write-Host "Created:       $($item.created_at)"
Write-Host "Updated:       $($item.updated_at)"
Write-Host "Tags:          $(@($item.tags) -join ', ')"
Write-Host "Links:         $(@($item.links).Count)"
Write-Host "Sources:       $(@($item.sources).Count)"

if (-not $MetadataOnly) {
    Write-Host ""
    Write-Host "Content" -ForegroundColor Cyan
    Write-Host "-------" -ForegroundColor Cyan

    if (Test-Path -LiteralPath $contentPath -PathType Leaf) {
        Get-Content -LiteralPath $contentPath
    }
    else {
        Write-Host "Content file is missing." -ForegroundColor Red
    }
}

if ($ShowHistory) {
    Write-Host ""
    Write-Host "History" -ForegroundColor Cyan
    Write-Host "-------" -ForegroundColor Cyan

    foreach ($entry in @($item.history)) {
        Write-Host (
            "{0} | {1} | {2} | {3}" -f
            $entry.timestamp,
            $entry.action,
            $entry.actor,
            $entry.details
        )
    }
}
'@

New-SafeFile ".\scripts\knowledge\Show-AIOfficeKnowledge.ps1" $showKnowledgeScript

$searchKnowledgeScript = @'
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
'@

New-SafeFile ".\scripts\knowledge\Search-AIOfficeKnowledge.ps1" $searchKnowledgeScript

$updateKnowledgeScript = @'
param(
    [Parameter(Mandatory = $true)]
    [string]$KnowledgeId,

    [string]$Title = "",
    [string]$Summary = "",
    [string]$Category = "",

    [ValidateSet(
        "",
        "note",
        "sop",
        "research",
        "reference",
        "decision",
        "lesson",
        "contact",
        "template"
    )]
    [string]$Type = "",

    [ValidateSet(
        "",
        "draft",
        "active",
        "review",
        "deprecated",
        "archived"
    )]
    [string]$Status = "",

    [ValidateSet(
        "",
        "internal",
        "private",
        "shared"
    )]
    [string]$Visibility = "",

    [string]$OwnerAgent = "",
    [string[]]$Tags,
    [string]$Content = "",
    [switch]$ReplaceContent,
    [string]$UpdatedBy = "Clarissa",
    [string]$ChangeNote = "Knowledge item updated."
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

$itemFolder = Join-Path ".\workspace\knowledge\items" $KnowledgeId
$itemPath = Join-Path $itemFolder "knowledge.json"

if (-not (Test-Path -LiteralPath $itemPath -PathType Leaf)) {
    throw "Knowledge item not found: $KnowledgeId"
}

$item = Get-Content -LiteralPath $itemPath -Raw | ConvertFrom-Json
$contentPath = Join-Path $itemFolder ([string]$item.content_file)
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

$versionRoot = Join-Path ".\workspace\knowledge\versions" $KnowledgeId
New-Item -ItemType Directory -Path $versionRoot -Force | Out-Null

$versionNumber = [int]$item.version
$versionFolder = Join-Path $versionRoot ("v{0:D4}" -f $versionNumber)

if (-not (Test-Path -LiteralPath $versionFolder -PathType Container)) {
    New-Item -ItemType Directory -Path $versionFolder -Force | Out-Null
    Copy-Item -LiteralPath $itemPath -Destination (Join-Path $versionFolder "knowledge.json") -Force

    if (Test-Path -LiteralPath $contentPath -PathType Leaf) {
        Copy-Item -LiteralPath $contentPath -Destination (Join-Path $versionFolder "content.md") -Force
    }
}

if (-not [string]::IsNullOrWhiteSpace($Title)) {
    $item.title = $Title
}

if (-not [string]::IsNullOrWhiteSpace($Summary)) {
    $item.summary = $Summary
}

if (-not [string]::IsNullOrWhiteSpace($Category)) {
    $categoryConfig = Get-Content `
        -LiteralPath ".\config\knowledge\knowledge-categories.json" `
        -Raw |
        ConvertFrom-Json

    if (@($categoryConfig.categories.id) -notcontains $Category) {
        throw "Unknown knowledge category: $Category"
    }

    $item.category = $Category
}

if (-not [string]::IsNullOrWhiteSpace($Type)) {
    $item.type = $Type
}

if (-not [string]::IsNullOrWhiteSpace($Status)) {
    $item.status = $Status
}

if (-not [string]::IsNullOrWhiteSpace($Visibility)) {
    $item.visibility = $Visibility
}

if (-not [string]::IsNullOrWhiteSpace($OwnerAgent)) {
    $item.owner_agent = $OwnerAgent
}

if ($PSBoundParameters.ContainsKey("Tags")) {
    $item.tags = @(
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
}

if ($ReplaceContent) {
    Set-Content -LiteralPath $contentPath -Value $Content -Encoding UTF8
}
elseif (-not [string]::IsNullOrWhiteSpace($Content)) {
    Add-Content -LiteralPath $contentPath -Value ("`r`n" + $Content) -Encoding UTF8
}

$item.version = $versionNumber + 1
$item.updated_at = $timestamp
$item.history = @($item.history) + [PSCustomObject]@{
    timestamp = $timestamp
    action = "knowledge-updated"
    actor = $UpdatedBy
    details = $ChangeNote
}

$item |
    ConvertTo-Json -Depth 20 |
    Set-Content -LiteralPath $itemPath -Encoding UTF8

& ".\scripts\knowledge\Update-AIOfficeKnowledgeIndex.ps1" | Out-Null

Write-Host ""
Write-Host "Knowledge item updated successfully." -ForegroundColor Green
Write-Host "Knowledge ID: $KnowledgeId"
Write-Host "Version:      $($item.version)"
Write-Host "Updated by:   $UpdatedBy"
'@

New-SafeFile ".\scripts\knowledge\Update-AIOfficeKnowledge.ps1" $updateKnowledgeScript

$linkKnowledgeScript = @'
param(
    [Parameter(Mandatory = $true)]
    [string]$KnowledgeId,

    [Parameter(Mandatory = $true)]
    [string]$RelatedKnowledgeId,

    [string]$Relationship = "related-to",
    [string]$LinkedBy = "Clarissa",
    [switch]$OneWay
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

function Add-KnowledgeLink {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceId,

        [Parameter(Mandatory = $true)]
        [string]$TargetId,

        [Parameter(Mandatory = $true)]
        [string]$LinkRelationship,

        [Parameter(Mandatory = $true)]
        [string]$Actor
    )

    $sourcePath = Join-Path `
        (Join-Path ".\workspace\knowledge\items" $SourceId) `
        "knowledge.json"

    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Knowledge item not found: $SourceId"
    }

    $targetPath = Join-Path `
        (Join-Path ".\workspace\knowledge\items" $TargetId) `
        "knowledge.json"

    if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
        throw "Related knowledge item not found: $TargetId"
    }

    $item = Get-Content -LiteralPath $sourcePath -Raw | ConvertFrom-Json
    $existing = @(
        $item.links | Where-Object {
            $_.knowledge_id -eq $TargetId -and
            $_.relationship -eq $LinkRelationship
        }
    )

    if ($existing.Count -eq 0) {
        $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

        $item.links = @($item.links) + [PSCustomObject]@{
            knowledge_id = $TargetId
            relationship = $LinkRelationship
        }

        $item.updated_at = $timestamp
        $item.version = [int]$item.version + 1
        $item.history = @($item.history) + [PSCustomObject]@{
            timestamp = $timestamp
            action = "knowledge-linked"
            actor = $Actor
            details = "Linked to $TargetId using relationship $LinkRelationship."
        }

        $item |
            ConvertTo-Json -Depth 20 |
            Set-Content -LiteralPath $sourcePath -Encoding UTF8
    }
}

Add-KnowledgeLink `
    -SourceId $KnowledgeId `
    -TargetId $RelatedKnowledgeId `
    -LinkRelationship $Relationship `
    -Actor $LinkedBy

if (-not $OneWay) {
    Add-KnowledgeLink `
        -SourceId $RelatedKnowledgeId `
        -TargetId $KnowledgeId `
        -LinkRelationship $Relationship `
        -Actor $LinkedBy
}

& ".\scripts\knowledge\Update-AIOfficeKnowledgeIndex.ps1" | Out-Null

Write-Host ""
Write-Host "Knowledge items linked successfully." -ForegroundColor Green
Write-Host "Source:       $KnowledgeId"
Write-Host "Related item: $RelatedKnowledgeId"
Write-Host "Relationship: $Relationship"
Write-Host "Two-way:      $(-not $OneWay.IsPresent)"
'@

New-SafeFile ".\scripts\knowledge\Link-AIOfficeKnowledge.ps1" $linkKnowledgeScript

$addSourceScript = @'
param(
    [Parameter(Mandatory = $true)]
    [string]$KnowledgeId,

    [Parameter(Mandatory = $true)]
    [string]$Title,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [string]$Notes = "",
    [string]$AddedBy = "Clarissa"
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

$itemPath = Join-Path `
    (Join-Path ".\workspace\knowledge\items" $KnowledgeId) `
    "knowledge.json"

if (-not (Test-Path -LiteralPath $itemPath -PathType Leaf)) {
    throw "Knowledge item not found: $KnowledgeId"
}

$item = Get-Content -LiteralPath $itemPath -Raw | ConvertFrom-Json
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

$item.sources = @($item.sources) + [PSCustomObject]@{
    title = $Title
    location = $Location
    accessed_at = $timestamp
    notes = $Notes
}

$item.updated_at = $timestamp
$item.version = [int]$item.version + 1
$item.history = @($item.history) + [PSCustomObject]@{
    timestamp = $timestamp
    action = "source-added"
    actor = $AddedBy
    details = "Source added: $Title"
}

$item |
    ConvertTo-Json -Depth 20 |
    Set-Content -LiteralPath $itemPath -Encoding UTF8

& ".\scripts\knowledge\Update-AIOfficeKnowledgeIndex.ps1" | Out-Null

Write-Host ""
Write-Host "Source added successfully." -ForegroundColor Green
Write-Host "Knowledge ID: $KnowledgeId"
Write-Host "Source title: $Title"
Write-Host "Location:     $Location"
'@

New-SafeFile ".\scripts\knowledge\Add-AIOfficeKnowledgeSource.ps1" $addSourceScript

$archiveKnowledgeScript = @'
param(
    [Parameter(Mandatory = $true)]
    [string]$KnowledgeId,

    [string]$ArchivedBy = "Clarissa",
    [string]$Reason = "Knowledge item archived."
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

$itemFolder = Join-Path ".\workspace\knowledge\items" $KnowledgeId
$itemPath = Join-Path $itemFolder "knowledge.json"

if (-not (Test-Path -LiteralPath $itemPath -PathType Leaf)) {
    throw "Knowledge item not found: $KnowledgeId"
}

$item = Get-Content -LiteralPath $itemPath -Raw | ConvertFrom-Json
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

$item.status = "archived"
$item.updated_at = $timestamp
$item.version = [int]$item.version + 1
$item.history = @($item.history) + [PSCustomObject]@{
    timestamp = $timestamp
    action = "knowledge-archived"
    actor = $ArchivedBy
    details = $Reason
}

$item |
    ConvertTo-Json -Depth 20 |
    Set-Content -LiteralPath $itemPath -Encoding UTF8

$archiveRoot = Join-Path ".\workspace\knowledge\archive" $KnowledgeId

if (-not (Test-Path -LiteralPath $archiveRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $archiveRoot -Force | Out-Null
}

Copy-Item -Path (Join-Path $itemFolder "*") -Destination $archiveRoot -Recurse -Force

& ".\scripts\knowledge\Update-AIOfficeKnowledgeIndex.ps1" | Out-Null

Write-Host ""
Write-Host "Knowledge item archived successfully." -ForegroundColor Green
Write-Host "Knowledge ID: $KnowledgeId"
Write-Host "Archive copy: $archiveRoot"
'@

New-SafeFile ".\scripts\knowledge\Archive-AIOfficeKnowledge.ps1" $archiveKnowledgeScript

$testKnowledgeScript = @'
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
'@

New-SafeFile ".\scripts\knowledge\Test-AIOfficeKnowledge.ps1" $testKnowledgeScript

$knowledgeGuide = @'
# AI Office Knowledge Management Guide

Status: Active
Owner: Chief of Staff
Version: 1.0.0

## Purpose

Package 10 provides persistent organizational memory for AI Office.

Knowledge items can store:

- General notes
- Standard operating procedures
- Research
- Stable reference information
- Decisions
- Lessons learned
- Contacts
- Reusable templates

## Storage Structure

Knowledge items are stored in:

workspace/knowledge/items/KNOW-ID/

Each item contains:

- knowledge.json
- content.md
- attachments/

Archived copies are stored in:

workspace/knowledge/archive/

Prior versions are stored in:

workspace/knowledge/versions/

## Creating Knowledge

Example:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/New-AIOfficeKnowledge.ps1 -Title "Meta Pixel Troubleshooting" -Summary "Troubleshooting notes for duplicate and incorrectly firing Meta Pixel events." -Type lesson -Category analytics -Tags meta,pixel,gtm,troubleshooting

## Creating an SOP

Example:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/New-AIOfficeKnowledge.ps1 -Title "Monthly Dealership Campaign Launch" -Summary "Standard process for launching a dealership campaign." -Type sop -Category marketing -Tags campaign,dealership,sop

## Searching Knowledge

Search all content:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Search-AIOfficeKnowledge.ps1 -Query "Meta Pixel"

Filter by category:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Search-AIOfficeKnowledge.ps1 -Category analytics

Filter by tag:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Search-AIOfficeKnowledge.ps1 -Tag gtm

Combine filters:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Search-AIOfficeKnowledge.ps1 -Query "conversion tracking" -Category analytics -Type lesson

## Viewing Knowledge

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Show-AIOfficeKnowledge.ps1 -KnowledgeId KNOW-20260731-0001

Metadata only:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Show-AIOfficeKnowledge.ps1 -KnowledgeId KNOW-20260731-0001 -MetadataOnly

Include history:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Show-AIOfficeKnowledge.ps1 -KnowledgeId KNOW-20260731-0001 -ShowHistory

## Updating Knowledge

Replace selected metadata:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Update-AIOfficeKnowledge.ps1 -KnowledgeId KNOW-20260731-0001 -Summary "Updated summary." -Tags meta,pixel,gtm

Replace content:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Update-AIOfficeKnowledge.ps1 -KnowledgeId KNOW-20260731-0001 -ReplaceContent -Content "# Updated Content"

Append content:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Update-AIOfficeKnowledge.ps1 -KnowledgeId KNOW-20260731-0001 -Content "Additional notes."

Each update creates a preserved copy of the previous version.

## Linking Knowledge

Two-way link:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Link-AIOfficeKnowledge.ps1 -KnowledgeId KNOW-20260731-0001 -RelatedKnowledgeId KNOW-20260731-0002 -Relationship supports

One-way link:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Link-AIOfficeKnowledge.ps1 -KnowledgeId KNOW-20260731-0001 -RelatedKnowledgeId KNOW-20260731-0002 -Relationship references -OneWay

## Adding Sources

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Add-AIOfficeKnowledgeSource.ps1 -KnowledgeId KNOW-20260731-0001 -Title "Source title" -Location "https://example.com" -Notes "Supporting reference."

## Archiving Knowledge

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Archive-AIOfficeKnowledge.ps1 -KnowledgeId KNOW-20260731-0001 -Reason "Replaced by updated procedure."

The live record remains searchable when IncludeArchived is used, and a copy is stored in the archive folder.

## Updating the Index

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Update-AIOfficeKnowledgeIndex.ps1

Creation, updates, linking, sources, and archiving also update the index automatically.

## Validation

Run:

powershell -ExecutionPolicy Bypass -File scripts/knowledge/Test-AIOfficeKnowledge.ps1

Expected result:

All knowledge management checks passed.
'@

New-SafeFile ".\docs\Knowledge-Management-Guide.md" $knowledgeGuide

Write-Host ""
Write-Host "Validating Package 10 JSON..." -ForegroundColor Cyan
Write-Host ""

$jsonFiles = @(
    ".\config\knowledge\knowledge-policy.json",
    ".\config\knowledge\knowledge-categories.json",
    ".\config\knowledge\knowledge-types.json",
    ".\config\knowledge\knowledge-item-schema.json",
    ".\workspace\knowledge\knowledge-index.json",
    ".\workspace\templates\knowledge-item-template.json"
)

$jsonErrors = 0

foreach ($jsonFile in $jsonFiles) {
    try {
        Get-Content -LiteralPath $jsonFile -Raw | ConvertFrom-Json | Out-Null
        Write-Host "[VALID  ] $jsonFile" -ForegroundColor Green
    }
    catch {
        Write-Host "[INVALID] $jsonFile" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $jsonErrors++
    }
}

Write-Host ""

if ($jsonErrors -gt 0) {
    Write-Host "Package 10 completed with validation errors." -ForegroundColor Red
    Write-Host "Do not commit until those errors are corrected." -ForegroundColor Yellow
    exit 1
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host " AI Office Package 10 Complete" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Created:" -ForegroundColor White
Write-Host "  Knowledge policies, types, categories, and schema"
Write-Host "  Knowledge item and content templates"
Write-Host "  Knowledge creation command"
Write-Host "  Searchable knowledge index"
Write-Host "  Knowledge display and search commands"
Write-Host "  Versioned knowledge update command"
Write-Host "  Cross-linking command"
Write-Host "  Source management command"
Write-Host "  Archive command"
Write-Host "  Validation command"
Write-Host "  Knowledge management guide"
Write-Host ""
Write-Host "All Package 10 JSON files passed validation." -ForegroundColor Green
