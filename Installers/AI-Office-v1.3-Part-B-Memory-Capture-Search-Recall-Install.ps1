# ============================================================
# AI Office v1.3 - Part B
# Memory Capture, Search, Recall, and Context Packets
# Repository: E:\AI\AI-Office
# Requires: AI Office v1.3 Part A
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

$RequiredPrevious = @(
    ".\config\memory\memory-policy.json",
    ".\config\memory\memory-record-schema.json",
    ".\scripts\memory\AIOfficeMemory.Common.ps1",
    ".\scripts\memory\Update-AIOfficeMemoryIndex.ps1"
)

foreach ($RequiredPath in $RequiredPrevious) {
    if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
        throw "AI Office v1.3 Part A is required. Missing: $RequiredPath"
    }
}

function Ensure-Directory {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
    }
}

function Write-NewFile {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][AllowEmptyString()][string]$Content
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        $Parent = Split-Path -Parent $Path

        if ($Parent -and -not (Test-Path -LiteralPath $Parent -PathType Container)) {
            New-Item -ItemType Directory -Path $Parent -Force | Out-Null
        }

        Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
    }
}

@(
    ".\workspace\memory\captures",
    ".\workspace\memory\context-packets",
    ".\workspace\memory\duplicates",
    ".\workspace\memory\related",
    ".\workspace\memory\recall-history"
) | ForEach-Object { Ensure-Directory $_ }

$Now = (Get-Date).ToString("o")

$CapturePolicy = @"
{
  "schema_version": "1.0.0",
  "version": "1.3.0",
  "part": "B",
  "capture": {
    "manual_enabled": true,
    "automatic_enabled": true,
    "supported_sources": [
      "manual",
      "chief_of_staff_plan",
      "chief_of_staff_decision",
      "department_execution",
      "department_knowledge",
      "message",
      "workflow",
      "report"
    ]
  },
  "search": {
    "default_limit": 25,
    "maximum_limit": 250,
    "minimum_confidence": 0.0,
    "track_access": true,
    "case_insensitive": true
  },
  "duplicate_detection": {
    "enabled": true,
    "title_match": true,
    "summary_match": true,
    "same_scope_required": true
  },
  "related_memory": {
    "enabled": true,
    "match_tags": true,
    "match_entities": true,
    "match_projects": true,
    "minimum_shared_terms": 1
  },
  "context_packets": {
    "enabled": true,
    "default_limit": 10,
    "include_content": true,
    "include_source": true,
    "include_metadata": true
  },
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\memory\memory-capture-recall-policy.json" $CapturePolicy

$ContextPacketSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/memory-context-packet-schema.json",
  "title": "AI Office Memory Context Packet",
  "type": "object",
  "required": [
    "context_packet_id",
    "created_at",
    "requested_by",
    "query",
    "memory_count",
    "memories"
  ]
}
'@

Write-NewFile ".\config\memory\memory-context-packet-schema.json" $ContextPacketSchema

$CaptureSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/memory-capture-record-schema.json",
  "title": "AI Office Memory Capture Record",
  "type": "object",
  "required": [
    "capture_id",
    "memory_id",
    "capture_type",
    "source_type",
    "created_at"
  ]
}
'@

Write-NewFile ".\config\memory\memory-capture-record-schema.json" $CaptureSchema

$ContextTemplate = @'
{
  "context_packet_id": "CTXMEM-YYYYMMDD-HHMMSS-ABC123",
  "created_at": "",
  "requested_by": "chief-of-staff",
  "query": "",
  "scope": "",
  "department": "",
  "memory_count": 0,
  "memories": []
}
'@

Write-NewFile ".\workspace\templates\memory-context-packet-template.json" $ContextTemplate

$Common = @'
. (Join-Path $PSScriptRoot "AIOfficeMemory.Common.ps1")

function Get-AIOfficeMemoryCaptureRecallPolicy {
    $Root = Get-AIOfficeMemoryRoot

    return Read-AIOfficeMemoryJson `
        -Path (Join-Path $Root "config\memory\memory-capture-recall-policy.json")
}

function New-AIOfficeMemoryCaptureId {
    return (
        "MCAP-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeMemoryContextPacketId {
    return (
        "CTXMEM-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeAllMemoryFiles {
    $Root = Get-AIOfficeMemoryRoot

    $Paths = @(
        "workspace\memory\global",
        "workspace\memory\chief-of-staff",
        "workspace\memory\personal",
        "workspace\memory\business",
        "workspace\memory\shared"
    )

    $Files = New-Object System.Collections.Generic.List[object]

    foreach ($RelativePath in $Paths) {
        foreach ($File in @(
            Get-ChildItem `
                -LiteralPath (Join-Path $Root $RelativePath) `
                -Filter "MEM-*.json" `
                -File `
                -ErrorAction SilentlyContinue
        )) {
            $Files.Add($File)
        }
    }

    foreach ($Department in @(
        "marketing",
        "creative",
        "website",
        "analytics",
        "finance",
        "business",
        "side-hustles",
        "youtube",
        "personal-assistant"
    )) {
        foreach ($File in @(
            Get-ChildItem `
                -LiteralPath (
                    Join-Path $Root (
                        "workspace\memory\departments\" +
                        $Department +
                        "\records"
                    )
                ) `
                -Filter "MEM-*.json" `
                -File `
                -ErrorAction SilentlyContinue
        )) {
            $Files.Add($File)
        }
    }

    return @($Files | ForEach-Object { $_ })
}

function Find-AIOfficeMemoryFile {
    param([Parameter(Mandatory=$true)][string]$MemoryId)

    foreach ($File in @(Get-AIOfficeAllMemoryFiles)) {
        if ($File.BaseName -eq $MemoryId) {
            return $File
        }
    }

    return $null
}

function Get-AIOfficeMemorySearchText {
    param([Parameter(Mandatory=$true)]$Record)

    return (
        [string]$Record.title + " " +
        [string]$Record.summary + " " +
        (@($Record.tags) -join " ") + " " +
        (@($Record.entities) -join " ") + " " +
        (@($Record.projects) -join " ") + " " +
        ($Record.content | ConvertTo-Json -Depth 30 -Compress)
    ).ToLowerInvariant()
}
'@

Write-NewFile ".\scripts\memory\AIOfficeMemoryRecall.Common.ps1" $Common

$NewMemory = @'
param(
    [ValidateSet(
        "global",
        "chief-of-staff",
        "department",
        "personal",
        "business",
        "shared"
    )]
    [string]$Scope = "shared",
    [string]$Department = "",
    [ValidateSet(
        "fact",
        "preference",
        "decision",
        "goal",
        "project",
        "relationship",
        "procedure",
        "lesson",
        "event",
        "metric",
        "constraint",
        "reference"
    )]
    [string]$MemoryType,
    [Parameter(Mandatory=$true)][string]$Title,
    [Parameter(Mandatory=$true)][string]$Summary,
    [Parameter(Mandatory=$true)][string]$ContentJson,
    [Parameter(Mandatory=$true)][string]$SourceJson,
    [double]$Confidence = 0.75,
    [string[]]$Tags = @(),
    [string[]]$Entities = @(),
    [string[]]$Projects = @()
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryRecall.Common.ps1")

$Root = Get-AIOfficeMemoryRoot
Set-Location $Root

if (-not (Test-AIOfficeMemoryScope -Scope $Scope -Department $Department)) {
    throw "Invalid memory scope or missing department."
}

if (-not (Test-AIOfficeMemoryType -MemoryType $MemoryType)) {
    throw "Invalid memory type: $MemoryType"
}

if ($Confidence -lt 0.0 -or $Confidence -gt 1.0) {
    throw "Confidence must be between 0.0 and 1.0."
}

try {
    $Content = $ContentJson | ConvertFrom-Json
}
catch {
    throw "ContentJson is invalid: $($_.Exception.Message)"
}

try {
    $Source = $SourceJson | ConvertFrom-Json
}
catch {
    throw "SourceJson is invalid: $($_.Exception.Message)"
}

$MemoryId = New-AIOfficeMemoryId
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    memory_id = $MemoryId
    scope = $Scope
    department = $Department
    memory_type = $MemoryType
    title = $Title
    summary = $Summary
    content = $Content
    source = $Source
    confidence = $Confidence
    status = "active"
    created_at = $Now
    updated_at = $Now
    last_accessed_at = $null
    access_count = 0
    tags = @($Tags)
    entities = @($Entities)
    projects = @($Projects)
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = "memory-engine"
            details = "Long-term memory record created."
        }
    )
}

$ScopePath = Get-AIOfficeMemoryScopePath `
    -Scope $Scope `
    -Department $Department

$Path = Join-Path $ScopePath ($MemoryId + ".json")

Write-AIOfficeMemoryJson -Value $Record -Path $Path

$Capture = [ordered]@{
    capture_id = New-AIOfficeMemoryCaptureId
    memory_id = $MemoryId
    capture_type = "manual"
    source_type = if ($null -ne $Source.PSObject.Properties["type"]) {
        [string]$Source.type
    }
    else {
        "manual"
    }
    created_at = $Now
}

Write-AIOfficeMemoryJson `
    -Value $Capture `
    -Path (
        ".\workspace\memory\captures\" +
        [string]$Capture.capture_id +
        ".json"
    )

& ".\scripts\memory\Update-AIOfficeMemoryIndex.ps1" |
    Out-Null

Write-Host "Long-term memory created: $MemoryId" -ForegroundColor Green

return [pscustomobject]$Record
'@

Write-NewFile ".\scripts\memory\New-AIOfficeMemory.ps1" $NewMemory

$SearchMemory = @'
param(
    [string]$Query = "",
    [string]$Scope = "",
    [string]$Department = "",
    [string]$MemoryType = "",
    [string]$Project = "",
    [string]$Entity = "",
    [string]$Status = "active",
    [double]$MinimumConfidence = 0.0,
    [int]$Limit = 25,
    [switch]$TrackAccess
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryRecall.Common.ps1")

$Root = Get-AIOfficeMemoryRoot
Set-Location $Root

$Policy = Get-AIOfficeMemoryCaptureRecallPolicy

if ($Limit -lt 1) {
    $Limit = 1
}

if ($Limit -gt [int]$Policy.search.maximum_limit) {
    $Limit = [int]$Policy.search.maximum_limit
}

$Results = New-Object System.Collections.Generic.List[object]

foreach ($File in @(Get-AIOfficeAllMemoryFiles)) {
    $Record = Read-AIOfficeMemoryJson -Path $File.FullName

    if ($null -eq $Record) {
        continue
    }

    if ($Scope -and [string]$Record.scope -ne $Scope) {
        continue
    }

    if ($Department -and [string]$Record.department -ne $Department) {
        continue
    }

    if ($MemoryType -and [string]$Record.memory_type -ne $MemoryType) {
        continue
    }

    if ($Status -and [string]$Record.status -ne $Status) {
        continue
    }

    if ([double]$Record.confidence -lt $MinimumConfidence) {
        continue
    }

    if ($Project -and @($Record.projects) -notcontains $Project) {
        continue
    }

    if ($Entity -and @($Record.entities) -notcontains $Entity) {
        continue
    }

    if ($Query) {
        $SearchText = Get-AIOfficeMemorySearchText -Record $Record

        if (-not $SearchText.Contains($Query.ToLowerInvariant())) {
            continue
        }
    }

    if ($TrackAccess -or [bool]$Policy.search.track_access) {
        $Record.access_count = [int]$Record.access_count + 1
        $Record.last_accessed_at = (Get-Date).ToString("o")
        $Record.updated_at = (Get-Date).ToString("o")

        Write-AIOfficeMemoryJson `
            -Value $Record `
            -Path $File.FullName
    }

    $Results.Add([pscustomobject]@{
        memory_id = [string]$Record.memory_id
        scope = [string]$Record.scope
        department = [string]$Record.department
        memory_type = [string]$Record.memory_type
        title = [string]$Record.title
        summary = [string]$Record.summary
        confidence = [double]$Record.confidence
        status = [string]$Record.status
        tags = @($Record.tags)
        entities = @($Record.entities)
        projects = @($Record.projects)
        access_count = [int]$Record.access_count
        updated_at = [string]$Record.updated_at
        source_path = $File.FullName
    })
}

return @(
    $Results |
        Sort-Object confidence, access_count, updated_at -Descending |
        Select-Object -First $Limit
)
'@

Write-NewFile ".\scripts\memory\Search-AIOfficeMemory.ps1" $SearchMemory

$GetMemory = @'
param(
    [Parameter(Mandatory=$true)][string]$MemoryId,
    [switch]$TrackAccess
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryRecall.Common.ps1")

$File = Find-AIOfficeMemoryFile -MemoryId $MemoryId

if ($null -eq $File) {
    throw "Long-term memory record not found: $MemoryId"
}

$Record = Read-AIOfficeMemoryJson -Path $File.FullName

if ($TrackAccess) {
    $Record.access_count = [int]$Record.access_count + 1
    $Record.last_accessed_at = (Get-Date).ToString("o")
    $Record.updated_at = (Get-Date).ToString("o")

    Write-AIOfficeMemoryJson -Value $Record -Path $File.FullName
}

return $Record
'@

Write-NewFile ".\scripts\memory\Get-AIOfficeMemory.ps1" $GetMemory

$DuplicateScript = @'
param(
    [Parameter(Mandatory=$true)][string]$Title,
    [Parameter(Mandatory=$true)][string]$Summary,
    [Parameter(Mandatory=$true)][string]$Scope,
    [string]$Department = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryRecall.Common.ps1")

$Matches = New-Object System.Collections.Generic.List[object]

foreach ($File in @(Get-AIOfficeAllMemoryFiles)) {
    $Record = Read-AIOfficeMemoryJson -Path $File.FullName

    if ($null -eq $Record) {
        continue
    }

    if ([string]$Record.scope -ne $Scope) {
        continue
    }

    if ($Scope -eq "department" -and
        [string]$Record.department -ne $Department) {
        continue
    }

    $TitleMatch = [string]$Record.title -eq $Title
    $SummaryMatch = [string]$Record.summary -eq $Summary

    if ($TitleMatch -or $SummaryMatch) {
        $Matches.Add([pscustomobject]@{
            memory_id = [string]$Record.memory_id
            title_match = $TitleMatch
            summary_match = $SummaryMatch
            scope = [string]$Record.scope
            department = [string]$Record.department
            confidence = [double]$Record.confidence
        })
    }
}

$Record = [ordered]@{
    duplicate_check_id = (
        "DUPMEM-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
    checked_at = (Get-Date).ToString("o")
    title = $Title
    summary = $Summary
    scope = $Scope
    department = $Department
    duplicate_count = $Matches.Count
    duplicates = @($Matches | ForEach-Object { $_ })
}

Write-AIOfficeMemoryJson `
    -Value $Record `
    -Path (
        ".\workspace\memory\duplicates\" +
        [string]$Record.duplicate_check_id +
        ".json"
    )

return [pscustomobject]$Record
'@

Write-NewFile ".\scripts\memory\Find-AIOfficeMemoryDuplicates.ps1" $DuplicateScript

$RelatedScript = @'
param(
    [Parameter(Mandatory=$true)][string]$MemoryId,
    [int]$Limit = 10
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryRecall.Common.ps1")

$Source = & ".\scripts\memory\Get-AIOfficeMemory.ps1" `
    -MemoryId $MemoryId

$Results = New-Object System.Collections.Generic.List[object]

foreach ($File in @(Get-AIOfficeAllMemoryFiles)) {
    if ($File.BaseName -eq $MemoryId) {
        continue
    }

    $Record = Read-AIOfficeMemoryJson -Path $File.FullName

    if ($null -eq $Record) {
        continue
    }

    $SharedTags = @($Source.tags | Where-Object { @($Record.tags) -contains $_ })
    $SharedEntities = @($Source.entities | Where-Object { @($Record.entities) -contains $_ })
    $SharedProjects = @($Source.projects | Where-Object { @($Record.projects) -contains $_ })

    $Score = $SharedTags.Count + $SharedEntities.Count + $SharedProjects.Count

    if ($Score -lt 1) {
        continue
    }

    $Results.Add([pscustomobject]@{
        memory_id = [string]$Record.memory_id
        title = [string]$Record.title
        scope = [string]$Record.scope
        department = [string]$Record.department
        relation_score = $Score
        shared_tags = $SharedTags
        shared_entities = $SharedEntities
        shared_projects = $SharedProjects
    })
}

$Sorted = @(
    $Results |
        Sort-Object relation_score -Descending |
        Select-Object -First $Limit
)

$Record = [ordered]@{
    related_check_id = (
        "RELMEM-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
    source_memory_id = $MemoryId
    created_at = (Get-Date).ToString("o")
    related_count = $Sorted.Count
    related_memories = $Sorted
}

Write-AIOfficeMemoryJson `
    -Value $Record `
    -Path (
        ".\workspace\memory\related\" +
        [string]$Record.related_check_id +
        ".json"
    )

return [pscustomobject]$Record
'@

Write-NewFile ".\scripts\memory\Find-AIOfficeRelatedMemory.ps1" $RelatedScript

$ContextPacket = @'
param(
    [string]$Query = "",
    [string]$Scope = "",
    [string]$Department = "",
    [string]$Project = "",
    [string]$Entity = "",
    [string]$RequestedBy = "chief-of-staff",
    [int]$Limit = 10
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryRecall.Common.ps1")

$Root = Get-AIOfficeMemoryRoot
Set-Location $Root

$SearchArgs = @{
    Query = $Query
    Scope = $Scope
    Department = $Department
    Project = $Project
    Entity = $Entity
    Limit = $Limit
    TrackAccess = $true
}

$SearchArgs = @{}
if ($Query) { $SearchArgs.Query = $Query }
if ($Scope) { $SearchArgs.Scope = $Scope }
if ($Department) { $SearchArgs.Department = $Department }
if ($Project) { $SearchArgs.Project = $Project }
if ($Entity) { $SearchArgs.Entity = $Entity }
$SearchArgs.Limit = $Limit
$SearchArgs.TrackAccess = $true

$SearchResults = @(
    & ".\scripts\memory\Search-AIOfficeMemory.ps1" @SearchArgs
)

$Memories = New-Object System.Collections.Generic.List[object]

foreach ($SearchResult in $SearchResults) {
    $Record = & ".\scripts\memory\Get-AIOfficeMemory.ps1" `
        -MemoryId ([string]$SearchResult.memory_id)

    $Memories.Add($Record)
}

$PacketId = New-AIOfficeMemoryContextPacketId

$Packet = [ordered]@{
    context_packet_id = $PacketId
    created_at = (Get-Date).ToString("o")
    requested_by = $RequestedBy
    query = $Query
    scope = $Scope
    department = $Department
    project = $Project
    entity = $Entity
    memory_count = $Memories.Count
    memories = @($Memories | ForEach-Object { $_ })
}

$Path = Join-Path `
    ".\workspace\memory\context-packets" `
    ($PacketId + ".json")

Write-AIOfficeMemoryJson -Value $Packet -Path $Path

Write-Host (
    "Memory context packet created: " +
    $PacketId +
    " | " +
    $Memories.Count.ToString() +
    " memory record(s)"
) -ForegroundColor Green

return [pscustomobject]$Packet
'@

Write-NewFile ".\scripts\memory\New-AIOfficeMemoryContextPacket.ps1" $ContextPacket

$CaptureFromJson = @'
param(
    [Parameter(Mandatory=$true)][string]$SourceType,
    [Parameter(Mandatory=$true)][string]$SourcePath,
    [ValidateSet(
        "global",
        "chief-of-staff",
        "department",
        "personal",
        "business",
        "shared"
    )]
    [string]$Scope = "shared",
    [string]$Department = "",
    [ValidateSet(
        "fact",
        "preference",
        "decision",
        "goal",
        "project",
        "relationship",
        "procedure",
        "lesson",
        "event",
        "metric",
        "constraint",
        "reference"
    )]
    [string]$MemoryType = "reference",
    [string]$Title = "",
    [string]$Summary = "",
    [double]$Confidence = 0.75
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
    throw "Source file not found: $SourcePath"
}

try {
    $SourceRecord = Get-Content -LiteralPath $SourcePath -Raw |
        ConvertFrom-Json
}
catch {
    throw "Source file is not valid JSON: $($_.Exception.Message)"
}

if ([string]::IsNullOrWhiteSpace($Title)) {
    foreach ($PropertyName in @("title","subject","name","objective","summary")) {
        if ($null -ne $SourceRecord.PSObject.Properties[$PropertyName] -and
            -not [string]::IsNullOrWhiteSpace([string]$SourceRecord.$PropertyName)) {
            $Title = [string]$SourceRecord.$PropertyName
            break
        }
    }
}

if ([string]::IsNullOrWhiteSpace($Title)) {
    $Title = [System.IO.Path]::GetFileNameWithoutExtension($SourcePath)
}

if ([string]::IsNullOrWhiteSpace($Summary)) {
    foreach ($PropertyName in @("summary","objective","description","decision","result_summary")) {
        if ($null -ne $SourceRecord.PSObject.Properties[$PropertyName] -and
            -not [string]::IsNullOrWhiteSpace([string]$SourceRecord.$PropertyName)) {
            $Summary = [string]$SourceRecord.$PropertyName
            break
        }
    }
}

if ([string]::IsNullOrWhiteSpace($Summary)) {
    $Summary = "Memory captured from $SourceType source."
}

$Source = [ordered]@{
    type = $SourceType
    path = (Resolve-Path -LiteralPath $SourcePath).Path
    captured_at = (Get-Date).ToString("o")
}

return & ".\scripts\memory\New-AIOfficeMemory.ps1" `
    -Scope $Scope `
    -Department $Department `
    -MemoryType $MemoryType `
    -Title $Title `
    -Summary $Summary `
    -ContentJson ($SourceRecord | ConvertTo-Json -Depth 50 -Compress) `
    -SourceJson ($Source | ConvertTo-Json -Depth 10 -Compress) `
    -Confidence $Confidence
'@

Write-NewFile ".\scripts\memory\Import-AIOfficeMemoryFromJson.ps1" $CaptureFromJson

$Test = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.3 Part B Memory Capture, Search, and Recall..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\memory\memory-capture-recall-policy.json",
    ".\config\memory\memory-context-packet-schema.json",
    ".\config\memory\memory-capture-record-schema.json",
    ".\workspace\templates\memory-context-packet-template.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw |
            ConvertFrom-Json |
            Out-Null

        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $File" -ForegroundColor Red
        $Errors.Add("Invalid JSON: " + $File)
    }
}

$Scripts = @(
    ".\scripts\memory\AIOfficeMemoryRecall.Common.ps1",
    ".\scripts\memory\New-AIOfficeMemory.ps1",
    ".\scripts\memory\Search-AIOfficeMemory.ps1",
    ".\scripts\memory\Get-AIOfficeMemory.ps1",
    ".\scripts\memory\Find-AIOfficeMemoryDuplicates.ps1",
    ".\scripts\memory\Find-AIOfficeRelatedMemory.ps1",
    ".\scripts\memory\New-AIOfficeMemoryContextPacket.ps1",
    ".\scripts\memory\Import-AIOfficeMemoryFromJson.ps1",
    ".\scripts\memory\Test-AIOfficeMemoryCaptureRecall.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING    ] $Script" -ForegroundColor Red
        $Errors.Add("Missing script: " + $Script)
    }
}

$MemoryIds = New-Object System.Collections.Generic.List[string]
$PacketId = ""

try {
    $MemoryOne = & ".\scripts\memory\New-AIOfficeMemory.ps1" `
        -Scope "department" `
        -Department "marketing" `
        -MemoryType "lesson" `
        -Title "Campaign structure validation" `
        -Summary "Reusable dealership campaign workflow." `
        -ContentJson '{"steps":["offer","creative","website","tracking"],"result":"successful"}' `
        -SourceJson '{"type":"validation","source_id":"MEMORY-PART-B"}' `
        -Confidence 0.90 `
        -Tags @("campaign","dealership") `
        -Entities @("Elite Auto Sales") `
        -Projects @("Memory Validation")

    $MemoryTwo = & ".\scripts\memory\New-AIOfficeMemory.ps1" `
        -Scope "business" `
        -MemoryType "decision" `
        -Title "Campaign structure decision" `
        -Summary "Use a repeatable campaign launch sequence." `
        -ContentJson '{"decision":"Use offer, creative, page, tracking, reporting sequence."}' `
        -SourceJson '{"type":"validation","source_id":"MEMORY-PART-B-2"}' `
        -Confidence 0.85 `
        -Tags @("campaign","workflow") `
        -Entities @("Elite Auto Sales") `
        -Projects @("Memory Validation")

    $MemoryIds.Add([string]$MemoryOne.memory_id)
    $MemoryIds.Add([string]$MemoryTwo.memory_id)

    Write-Host "[CREATE OK  ] 2 memory records" -ForegroundColor Green
}
catch {
    Write-Host "[CREATE ERR ] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Memory creation failed: " + $_.Exception.Message)
}

try {
    $Search = @(
        & ".\scripts\memory\Search-AIOfficeMemory.ps1" `
            -Query "campaign" `
            -MinimumConfidence 0.50 `
            -Limit 10
    )

    if ($Search.Count -lt 2) {
        throw "Memory search returned fewer than two results."
    }

    Write-Host (
        "[SEARCH OK  ] " +
        $Search.Count.ToString() +
        " result(s)"
    ) -ForegroundColor Green
}
catch {
    Write-Host "[SEARCH ERR ] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Memory search failed: " + $_.Exception.Message)
}

try {
    $Duplicate = & ".\scripts\memory\Find-AIOfficeMemoryDuplicates.ps1" `
        -Title "Campaign structure validation" `
        -Summary "Reusable dealership campaign workflow." `
        -Scope "department" `
        -Department "marketing"

    if ([int]$Duplicate.duplicate_count -lt 1) {
        throw "Duplicate detection found no matches."
    }

    Write-Host "[DUPLICATE OK] Duplicate detection passed." `
        -ForegroundColor Green
}
catch {
    Write-Host "[DUPLICATE ER] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Duplicate detection failed: " + $_.Exception.Message)
}

try {
    $Related = & ".\scripts\memory\Find-AIOfficeRelatedMemory.ps1" `
        -MemoryId ([string]$MemoryIds[0]) `
        -Limit 10

    if ([int]$Related.related_count -lt 1) {
        throw "Related-memory discovery found no matches."
    }

    Write-Host "[RELATED OK ] Related-memory discovery passed." `
        -ForegroundColor Green
}
catch {
    Write-Host "[RELATED ERR] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Related-memory discovery failed: " + $_.Exception.Message)
}

try {
    $Packet = & ".\scripts\memory\New-AIOfficeMemoryContextPacket.ps1" `
        -Query "campaign" `
        -RequestedBy "chief-of-staff" `
        -Limit 10

    $PacketId = [string]$Packet.context_packet_id

    if ([int]$Packet.memory_count -lt 2) {
        throw "Context packet contained fewer than two memories."
    }

    Write-Host (
        "[CONTEXT OK ] " +
        $PacketId +
        " | " +
        [string]$Packet.memory_count +
        " memory record(s)"
    ) -ForegroundColor Green
}
catch {
    Write-Host "[CONTEXT ERR] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Context packet failed: " + $_.Exception.Message)
}

foreach ($MemoryId in $MemoryIds) {
    $File = $null

    try {
        . ".\scripts\memory\AIOfficeMemoryRecall.Common.ps1"
        $File = Find-AIOfficeMemoryFile -MemoryId $MemoryId
    }
    catch {
    }

    if ($null -ne $File -and
        (Test-Path -LiteralPath $File.FullName -PathType Leaf)) {
        Remove-Item -LiteralPath $File.FullName -Force
    }
}

if ($PacketId) {
    $Path = ".\workspace\memory\context-packets\$PacketId.json"

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

Get-ChildItem `
    -LiteralPath ".\workspace\memory\captures" `
    -Filter "MCAP-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    ForEach-Object {
        $Record = Get-Content -LiteralPath $_.FullName -Raw |
            ConvertFrom-Json

        if ($MemoryIds -contains [string]$Record.memory_id) {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }

& ".\scripts\memory\Update-AIOfficeMemoryIndex.ps1" |
    Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Memory Capture, Search, and Recall error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.3 Part B Memory Capture, Search, and Recall checks passed." `
    -ForegroundColor Green
'@

Write-NewFile ".\scripts\memory\Test-AIOfficeMemoryCaptureRecall.ps1" $Test

$Guide = @'
# AI Office v1.3 Part B — Memory Capture, Search, and Recall

Part B makes Long-Term Memory usable across AI Office.

## Added

- Manual memory creation
- JSON source import
- Search by text, scope, department, type, project, entity, status, and confidence
- Access tracking
- Duplicate detection
- Related-memory discovery
- Context packet generation
- Capture records
- Recall history support
- Full validation

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\memory\Test-AIOfficeMemoryCaptureRecall.ps1"
```

Expected result:

```text
All AI Office v1.3 Part B Memory Capture, Search, and Recall checks passed.
```

## Create memory

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\memory\New-AIOfficeMemory.ps1" `
    -Scope "department" `
    -Department "marketing" `
    -MemoryType "lesson" `
    -Title "Successful dealership campaign structure" `
    -Summary "Reusable campaign launch sequence." `
    -ContentJson '{"steps":["offer","creative","website","tracking","reporting"]}' `
    -SourceJson '{"type":"manual","project":"Elite Auto Sales"}' `
    -Confidence 0.90 `
    -Tags @("campaign","dealership") `
    -Entities @("Elite Auto Sales") `
    -Projects @("Elite Marketing")
```

## Search memory

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\memory\Search-AIOfficeMemory.ps1" `
    -Query "campaign" `
    -Department "marketing"
```

## Build a Chief of Staff context packet

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\memory\New-AIOfficeMemoryContextPacket.ps1" `
    -Query "campaign" `
    -RequestedBy "chief-of-staff" `
    -Limit 10
```

## Next

Part C will add feedback, correction, promotion, demotion, staleness review, conflict handling, memory health, certification, and release publication.
'@

Write-NewFile ".\docs\AI-Office-v1.3-Part-B-Memory-Capture-Search-Recall.md" $Guide

$ReleaseNotes = @'
# AI Office v1.3 Part B Release Notes

## Release

Memory Capture, Search, and Recall

## Added

- Memory creation
- Automatic JSON import
- Multi-filter search
- Recall tracking
- Duplicate detection
- Related-memory discovery
- Context packets
- Validation suite

## Next

v1.3 Part C — Memory Learning, Health, Certification, and Release
'@

Write-NewFile ".\docs\AI-Office-v1.3-Part-B-Release-Notes.md" $ReleaseNotes

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw |
        ConvertFrom-Json

    $Version.version = "1.3.0"
    $Version.release_name = "Long-Term Memory"
    $Version.status = "part_b_installed"
    $Version.installed_at = (Get-Date).ToString("o")
    $Version.next_planned_milestone = "1.3 Part C Memory Learning and Release"

    $Version |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $VersionPath -Encoding UTF8

    Write-Host "[UPDATED] Identity release metadata set to v1.3 Part B" `
        -ForegroundColor Green
}

Write-Host ""
Write-Host "Validating Part B JSON files..." -ForegroundColor Cyan

@(
    ".\config\memory\memory-capture-recall-policy.json",
    ".\config\memory\memory-context-packet-schema.json",
    ".\config\memory\memory-capture-record-schema.json",
    ".\workspace\templates\memory-context-packet-template.json"
) | ForEach-Object {
    Get-Content -LiteralPath $_ -Raw |
        ConvertFrom-Json |
        Out-Null

    Write-Host "[VALID JSON] $_" -ForegroundColor Green
}

try {
    $Source = $MyInvocation.MyCommand.Path
    $Destination = Join-Path `
        $Repository `
        "Installers\AI-Office-v1.3-Part-B-Memory-Capture-Search-Recall-Install.ps1"

    if ($Source -and
        (Test-Path -LiteralPath $Source -PathType Leaf) -and
        [System.IO.Path]::GetFullPath($Source) -ne
        [System.IO.Path]::GetFullPath($Destination)) {
        Copy-Item `
            -LiteralPath $Source `
            -Destination $Destination `
            -Force

        Write-Host "[COPIED ] Installer saved to $Destination" `
            -ForegroundColor Green
    }
}
catch {
    Write-Host (
        "[WARNING] Installer copy was not completed: " +
        $_.Exception.Message
    ) -ForegroundColor Yellow
}

Write-Host ""
Write-Host "AI Office v1.3 Part B installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\memory\Test-AIOfficeMemoryCaptureRecall.ps1"'
Write-Host ""
