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
