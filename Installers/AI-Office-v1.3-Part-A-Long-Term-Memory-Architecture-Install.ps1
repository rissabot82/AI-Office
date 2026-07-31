# ============================================================
# AI Office v1.3 - Part A
# Long-Term Memory Architecture
# Repository: E:\AI\AI-Office
# Requires: AI Office v1.2 Department Intelligence
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

$RequiredPrevious = @(
    ".\config\identity\office.json",
    ".\config\departments\release-manifest.json",
    ".\config\chief-of-staff\release-manifest.json",
    ".\scripts\departments\AIOfficeDepartments.Common.ps1",
    ".\scripts\chief-of-staff\AIOfficeChiefOfStaff.Common.ps1"
)

foreach ($RequiredPath in $RequiredPrevious) {
    if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
        throw "AI Office v1.2 is required. Missing: $RequiredPath"
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

$Departments = @(
    "marketing",
    "creative",
    "website",
    "analytics",
    "finance",
    "business",
    "side-hustles",
    "youtube",
    "personal-assistant"
)

@(
    ".\config\memory",
    ".\workspace\memory",
    ".\workspace\memory\global",
    ".\workspace\memory\chief-of-staff",
    ".\workspace\memory\personal",
    ".\workspace\memory\business",
    ".\workspace\memory\shared",
    ".\workspace\memory\archive",
    ".\workspace\memory\conflicts",
    ".\workspace\memory\indexes",
    ".\workspace\memory\reports",
    ".\workspace\templates",
    ".\scripts\memory",
    ".\docs",
    ".\Installers"
) | ForEach-Object { Ensure-Directory $_ }

foreach ($Department in $Departments) {
    @(
        ".\workspace\memory\departments\$Department",
        ".\workspace\memory\departments\$Department\records",
        ".\workspace\memory\departments\$Department\archive",
        ".\workspace\memory\departments\$Department\indexes"
    ) | ForEach-Object { Ensure-Directory $_ }
}

$Now = (Get-Date).ToString("o")

$MemoryPolicy = @"
{
  "schema_version": "1.0.0",
  "version": "1.3.0",
  "part": "A",
  "memory_scopes": [
    "global",
    "chief-of-staff",
    "department",
    "personal",
    "business",
    "shared"
  ],
  "memory_types": [
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
  ],
  "governance": {
    "require_source": true,
    "require_scope": true,
    "require_memory_type": true,
    "require_confidence": true,
    "require_created_at": true,
    "require_updated_at": true,
    "preserve_history": true,
    "allow_cross_scope_recall": true,
    "allow_department_recall": true,
    "allow_chief_of_staff_recall": true
  },
  "privacy": {
    "separate_personal_and_business": true,
    "allow_shared_scope": true,
    "default_scope": "shared",
    "restricted_types": [
      "credential",
      "secret",
      "authentication_token"
    ],
    "store_secrets": false
  },
  "confidence": {
    "minimum": 0.0,
    "maximum": 1.0,
    "default": 0.75,
    "promote_threshold": 0.90,
    "review_threshold": 0.50
  },
  "retention": {
    "archive_instead_of_delete": true,
    "stale_after_days": 365,
    "review_after_days": 180,
    "retain_history": true
  },
  "indexing": {
    "enabled": true,
    "index_by_scope": true,
    "index_by_type": true,
    "index_by_department": true,
    "index_by_project": true,
    "index_by_entity": true
  },
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\memory\memory-policy.json" $MemoryPolicy

$MemorySchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/long-term-memory-record-schema.json",
  "title": "AI Office Long-Term Memory Record",
  "type": "object",
  "required": [
    "memory_id",
    "scope",
    "memory_type",
    "title",
    "summary",
    "content",
    "source",
    "confidence",
    "status",
    "created_at",
    "updated_at",
    "history"
  ],
  "properties": {
    "memory_id": {
      "type": "string",
      "pattern": "^MEM-[0-9]{8}-[0-9]{6}-[A-F0-9]{6}$"
    },
    "scope": {
      "type": "string"
    },
    "department": {
      "type": "string"
    },
    "memory_type": {
      "type": "string"
    },
    "title": {
      "type": "string"
    },
    "summary": {
      "type": "string"
    },
    "content": {
      "type": "object"
    },
    "source": {
      "type": "object"
    },
    "confidence": {
      "type": "number"
    },
    "status": {
      "type": "string"
    },
    "created_at": {
      "type": "string"
    },
    "updated_at": {
      "type": "string"
    },
    "last_accessed_at": {
      "type": ["string", "null"]
    },
    "access_count": {
      "type": "integer"
    },
    "tags": {
      "type": "array"
    },
    "entities": {
      "type": "array"
    },
    "projects": {
      "type": "array"
    },
    "history": {
      "type": "array"
    }
  }
}
'@

Write-NewFile ".\config\memory\memory-record-schema.json" $MemorySchema

$IndexSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/memory-index-schema.json",
  "title": "AI Office Long-Term Memory Index",
  "type": "object",
  "required": [
    "schema_version",
    "version",
    "updated_at",
    "status",
    "total_memory_count",
    "active_memory_count",
    "archived_memory_count",
    "scope_counts",
    "type_counts",
    "department_counts"
  ]
}
'@

Write-NewFile ".\config\memory\memory-index-schema.json" $IndexSchema

$ScopeSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/memory-scope-schema.json",
  "title": "AI Office Memory Scope",
  "type": "object",
  "required": [
    "scope_id",
    "name",
    "description",
    "path",
    "allowed_memory_types",
    "created_at",
    "updated_at"
  ]
}
'@

Write-NewFile ".\config\memory\memory-scope-schema.json" $ScopeSchema

$Template = @'
{
  "memory_id": "MEM-YYYYMMDD-HHMMSS-ABC123",
  "scope": "shared",
  "department": "",
  "memory_type": "fact",
  "title": "",
  "summary": "",
  "content": {},
  "source": {},
  "confidence": 0.75,
  "status": "active",
  "created_at": "",
  "updated_at": "",
  "last_accessed_at": null,
  "access_count": 0,
  "tags": [],
  "entities": [],
  "projects": [],
  "history": []
}
'@

Write-NewFile ".\workspace\templates\long-term-memory-record-template.json" $Template

$Scopes = @(
    @{
        Id = "SCOPE-GLOBAL"
        Name = "global"
        Description = "Office-wide memory available to all authorized components."
        Path = "workspace\memory\global"
    },
    @{
        Id = "SCOPE-CHIEF"
        Name = "chief-of-staff"
        Description = "Executive memory used by the Chief of Staff."
        Path = "workspace\memory\chief-of-staff"
    },
    @{
        Id = "SCOPE-PERSONAL"
        Name = "personal"
        Description = "Personal goals, preferences, schedules, and life administration."
        Path = "workspace\memory\personal"
    },
    @{
        Id = "SCOPE-BUSINESS"
        Name = "business"
        Description = "Business, dealership, client, and professional memory."
        Path = "workspace\memory\business"
    },
    @{
        Id = "SCOPE-SHARED"
        Name = "shared"
        Description = "Cross-domain memory explicitly shared between personal and business contexts."
        Path = "workspace\memory\shared"
    }
)

foreach ($Scope in $Scopes) {
    $ScopeJson = [ordered]@{
        scope_id = $Scope.Id
        name = $Scope.Name
        description = $Scope.Description
        path = $Scope.Path
        allowed_memory_types = @(
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
        )
        created_at = $Now
        updated_at = $Now
    } | ConvertTo-Json -Depth 20

    Write-NewFile ".\config\memory\scope-$($Scope.Name).json" $ScopeJson
}

foreach ($Department in $Departments) {
    $ScopeJson = [ordered]@{
        scope_id = (
            "SCOPE-DEPARTMENT-" +
            $Department.ToUpperInvariant().Replace("-", "_")
        )
        name = "department"
        department = $Department
        description = "Long-term memory for the $Department department."
        path = "workspace\memory\departments\$Department\records"
        allowed_memory_types = @(
            "fact",
            "decision",
            "goal",
            "project",
            "procedure",
            "lesson",
            "event",
            "metric",
            "constraint",
            "reference"
        )
        created_at = $Now
        updated_at = $Now
    } | ConvertTo-Json -Depth 20

    Write-NewFile ".\config\memory\scope-department-$Department.json" $ScopeJson
}

$GlobalIndex = @'
{
  "schema_version": "1.0.0",
  "version": "1.3.0",
  "updated_at": "",
  "status": "ready",
  "total_memory_count": 0,
  "active_memory_count": 0,
  "archived_memory_count": 0,
  "scope_counts": {},
  "type_counts": {},
  "department_counts": {},
  "latest_memory_id": ""
}
'@

Write-NewFile ".\workspace\memory\indexes\memory-index.json" $GlobalIndex

foreach ($Department in $Departments) {
    $DepartmentIndex = [ordered]@{
        schema_version = "1.0.0"
        version = "1.3.0"
        department = $Department
        updated_at = ""
        status = "ready"
        active_memory_count = 0
        archived_memory_count = 0
        type_counts = [ordered]@{}
        latest_memory_id = ""
    } | ConvertTo-Json -Depth 20

    Write-NewFile ".\workspace\memory\departments\$Department\indexes\memory-index.json" $DepartmentIndex
}

$Common = @'
$script:AIOfficeMemoryRoot = $null

function Get-AIOfficeMemoryRoot {
    if ($script:AIOfficeMemoryRoot) {
        return $script:AIOfficeMemoryRoot
    }

    $script:AIOfficeMemoryRoot = (
        Resolve-Path (Join-Path $PSScriptRoot "..\..")
    ).Path

    return $script:AIOfficeMemoryRoot
}

function Read-AIOfficeMemoryJson {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function Write-AIOfficeMemoryJson {
    param(
        [Parameter(Mandatory=$true)]$Value,
        [Parameter(Mandatory=$true)][string]$Path
    )

    $Parent = Split-Path -Parent $Path

    if ($Parent -and -not (Test-Path -LiteralPath $Parent -PathType Container)) {
        New-Item -ItemType Directory -Path $Parent -Force | Out-Null
    }

    $Value |
        ConvertTo-Json -Depth 60 |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-AIOfficeMemoryPolicy {
    $Root = Get-AIOfficeMemoryRoot

    return Read-AIOfficeMemoryJson `
        -Path (Join-Path $Root "config\memory\memory-policy.json")
}

function New-AIOfficeMemoryId {
    return (
        "MEM-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeMemoryScopePath {
    param(
        [Parameter(Mandatory=$true)][string]$Scope,
        [string]$Department = ""
    )

    $Root = Get-AIOfficeMemoryRoot

    switch ($Scope) {
        "global" {
            return Join-Path $Root "workspace\memory\global"
        }
        "chief-of-staff" {
            return Join-Path $Root "workspace\memory\chief-of-staff"
        }
        "personal" {
            return Join-Path $Root "workspace\memory\personal"
        }
        "business" {
            return Join-Path $Root "workspace\memory\business"
        }
        "shared" {
            return Join-Path $Root "workspace\memory\shared"
        }
        "department" {
            if ([string]::IsNullOrWhiteSpace($Department)) {
                throw "Department is required when Scope is department."
            }

            return Join-Path `
                $Root `
                ("workspace\memory\departments\" + $Department + "\records")
        }
        default {
            throw "Unsupported memory scope: $Scope"
        }
    }
}

function Test-AIOfficeMemoryScope {
    param(
        [Parameter(Mandatory=$true)][string]$Scope,
        [string]$Department = ""
    )

    $Policy = Get-AIOfficeMemoryPolicy

    if ($null -eq $Policy) {
        throw "Memory policy could not be loaded."
    }

    if (@($Policy.memory_scopes) -notcontains $Scope) {
        return $false
    }

    if ($Scope -eq "department" -and [string]::IsNullOrWhiteSpace($Department)) {
        return $false
    }

    return $true
}

function Test-AIOfficeMemoryType {
    param([Parameter(Mandatory=$true)][string]$MemoryType)

    $Policy = Get-AIOfficeMemoryPolicy

    if ($null -eq $Policy) {
        throw "Memory policy could not be loaded."
    }

    return @($Policy.memory_types) -contains $MemoryType
}
'@

Write-NewFile ".\scripts\memory\AIOfficeMemory.Common.ps1" $Common

$UpdateIndex = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemory.Common.ps1")

$Root = Get-AIOfficeMemoryRoot
Set-Location $Root

$Policy = Get-AIOfficeMemoryPolicy

if ($null -eq $Policy) {
    throw "Memory policy could not be loaded."
}

$Records = New-Object System.Collections.Generic.List[object]
$ScopeCounts = [ordered]@{}
$TypeCounts = [ordered]@{}
$DepartmentCounts = [ordered]@{}

$ScopePaths = @(
    @{ Scope = "global"; Path = ".\workspace\memory\global" },
    @{ Scope = "chief-of-staff"; Path = ".\workspace\memory\chief-of-staff" },
    @{ Scope = "personal"; Path = ".\workspace\memory\personal" },
    @{ Scope = "business"; Path = ".\workspace\memory\business" },
    @{ Scope = "shared"; Path = ".\workspace\memory\shared" }
)

foreach ($ScopePath in $ScopePaths) {
    foreach ($File in @(
        Get-ChildItem `
            -LiteralPath $ScopePath.Path `
            -Filter "MEM-*.json" `
            -File `
            -ErrorAction SilentlyContinue
    )) {
        $Record = Read-AIOfficeMemoryJson -Path $File.FullName

        if ($null -ne $Record) {
            $Records.Add($Record)
        }
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
    $DepartmentRecords = New-Object System.Collections.Generic.List[object]

    foreach ($File in @(
        Get-ChildItem `
            -LiteralPath ".\workspace\memory\departments\$Department\records" `
            -Filter "MEM-*.json" `
            -File `
            -ErrorAction SilentlyContinue
    )) {
        $Record = Read-AIOfficeMemoryJson -Path $File.FullName

        if ($null -ne $Record) {
            $Records.Add($Record)
            $DepartmentRecords.Add($Record)
        }
    }

    $DepartmentCounts[$Department] = $DepartmentRecords.Count

    $DepartmentTypeCounts = [ordered]@{}

    foreach ($Record in $DepartmentRecords) {
        $Type = [string]$Record.memory_type

        if (-not $DepartmentTypeCounts.Contains($Type)) {
            $DepartmentTypeCounts[$Type] = 0
        }

        $DepartmentTypeCounts[$Type] = [int]$DepartmentTypeCounts[$Type] + 1
    }

    $DepartmentIndex = [ordered]@{
        schema_version = "1.0.0"
        version = "1.3.0"
        department = $Department
        updated_at = (Get-Date).ToString("o")
        status = "ready"
        active_memory_count = @(
            $DepartmentRecords | Where-Object { $_.status -eq "active" }
        ).Count
        archived_memory_count = @(
            $DepartmentRecords | Where-Object { $_.status -eq "archived" }
        ).Count
        type_counts = $DepartmentTypeCounts
        latest_memory_id = if ($DepartmentRecords.Count -gt 0) {
            [string](
                $DepartmentRecords |
                    Sort-Object updated_at -Descending |
                    Select-Object -First 1
            ).memory_id
        }
        else {
            ""
        }
    }

    Write-AIOfficeMemoryJson `
        -Value $DepartmentIndex `
        -Path ".\workspace\memory\departments\$Department\indexes\memory-index.json"
}

foreach ($Record in $Records) {
    $Scope = [string]$Record.scope
    $Type = [string]$Record.memory_type

    if (-not $ScopeCounts.Contains($Scope)) {
        $ScopeCounts[$Scope] = 0
    }

    if (-not $TypeCounts.Contains($Type)) {
        $TypeCounts[$Type] = 0
    }

    $ScopeCounts[$Scope] = [int]$ScopeCounts[$Scope] + 1
    $TypeCounts[$Type] = [int]$TypeCounts[$Type] + 1
}

$Latest = @(
    $Records |
        Sort-Object updated_at -Descending |
        Select-Object -First 1
)

$Index = [ordered]@{
    schema_version = "1.0.0"
    version = "1.3.0"
    updated_at = (Get-Date).ToString("o")
    status = "ready"
    total_memory_count = $Records.Count
    active_memory_count = @(
        $Records | Where-Object { $_.status -eq "active" }
    ).Count
    archived_memory_count = @(
        $Records | Where-Object { $_.status -eq "archived" }
    ).Count
    scope_counts = $ScopeCounts
    type_counts = $TypeCounts
    department_counts = $DepartmentCounts
    latest_memory_id = if ($Latest.Count -gt 0) {
        [string]$Latest[0].memory_id
    }
    else {
        ""
    }
}

Write-AIOfficeMemoryJson `
    -Value $Index `
    -Path ".\workspace\memory\indexes\memory-index.json"

Write-Host (
    "Long-Term Memory index updated: " +
    $Records.Count.ToString() +
    " memory record(s)"
) -ForegroundColor Green

return [pscustomobject]$Index
'@

Write-NewFile ".\scripts\memory\Update-AIOfficeMemoryIndex.ps1" $UpdateIndex

$ShowStatus = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$Index = & ".\scripts\memory\Update-AIOfficeMemoryIndex.ps1"

Write-Host ""
Write-Host "AI OFFICE LONG-TERM MEMORY STATUS" -ForegroundColor Cyan
Write-Host ("=" * 72)
Write-Host ("Status            : " + [string]$Index.status)
Write-Host ("Total memories    : " + [string]$Index.total_memory_count)
Write-Host ("Active memories   : " + [string]$Index.active_memory_count)
Write-Host ("Archived memories : " + [string]$Index.archived_memory_count)
Write-Host ("Latest memory     : " + [string]$Index.latest_memory_id)
Write-Host ""

return $Index
'@

Write-NewFile ".\scripts\memory\Show-AIOfficeMemoryStatus.ps1" $ShowStatus

$Test = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.3 Part A Long-Term Memory Architecture..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\memory\memory-policy.json",
    ".\config\memory\memory-record-schema.json",
    ".\config\memory\memory-index-schema.json",
    ".\config\memory\memory-scope-schema.json",
    ".\workspace\templates\long-term-memory-record-template.json",
    ".\workspace\memory\indexes\memory-index.json"
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
    ".\scripts\memory\AIOfficeMemory.Common.ps1",
    ".\scripts\memory\Update-AIOfficeMemoryIndex.ps1",
    ".\scripts\memory\Show-AIOfficeMemoryStatus.ps1",
    ".\scripts\memory\Test-AIOfficeMemoryArchitecture.ps1"
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

try {
    . ".\scripts\memory\AIOfficeMemory.Common.ps1"

    $ScopeChecks = @(
        Test-AIOfficeMemoryScope -Scope "global",
        Test-AIOfficeMemoryScope -Scope "chief-of-staff",
        Test-AIOfficeMemoryScope -Scope "personal",
        Test-AIOfficeMemoryScope -Scope "business",
        Test-AIOfficeMemoryScope -Scope "shared",
        Test-AIOfficeMemoryScope -Scope "department" -Department "marketing"
    )

    if ($ScopeChecks -contains $false) {
        throw "One or more memory scopes failed validation."
    }

    Write-Host "[SCOPE OK   ] Memory scope validation passed." `
        -ForegroundColor Green
}
catch {
    Write-Host "[SCOPE ERR  ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Scope validation failed: " + $_.Exception.Message)
}

try {
    . ".\scripts\memory\AIOfficeMemory.Common.ps1"

    foreach ($MemoryType in @(
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
    )) {
        if (-not (Test-AIOfficeMemoryType -MemoryType $MemoryType)) {
            throw "Memory type failed validation: $MemoryType"
        }
    }

    Write-Host "[TYPE OK    ] Memory type validation passed." `
        -ForegroundColor Green
}
catch {
    Write-Host "[TYPE ERR   ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Memory type validation failed: " + $_.Exception.Message)
}

try {
    $Index = & ".\scripts\memory\Update-AIOfficeMemoryIndex.ps1"

    if ($null -eq $Index -or
        [int]$Index.total_memory_count -ne 0 -or
        [string]$Index.status -ne "ready") {
        throw "Memory index did not initialize correctly."
    }

    Write-Host "[INDEX OK   ] Empty memory index initialized." `
        -ForegroundColor Green
}
catch {
    Write-Host "[INDEX ERR  ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Memory index validation failed: " + $_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Long-Term Memory architecture error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.3 Part A Long-Term Memory Architecture checks passed." `
    -ForegroundColor Green
'@

Write-NewFile ".\scripts\memory\Test-AIOfficeMemoryArchitecture.ps1" $Test

$Guide = @'
# AI Office v1.3 Part A — Long-Term Memory Architecture

Part A creates the governed memory foundation for AI Office.

## Added

- Global memory policy
- Memory types and scopes
- Personal/business separation
- Chief of Staff memory scope
- Department memory scopes
- Shared memory scope
- Confidence rules
- Retention and archival rules
- Memory schemas
- Global and department indexes
- Memory status reporting
- Full architecture validation

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\memory\Test-AIOfficeMemoryArchitecture.ps1"
```

Expected result:

```text
All AI Office v1.3 Part A Long-Term Memory Architecture checks passed.
```

## Show memory status

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\memory\Show-AIOfficeMemoryStatus.ps1"
```

## Next

Part B will add memory creation, automatic capture, search, recall, duplicate detection, related-memory discovery, and context packets.
'@

Write-NewFile ".\docs\AI-Office-v1.3-Part-A-Long-Term-Memory-Architecture.md" $Guide

$ReleaseNotes = @'
# AI Office v1.3 Part A Release Notes

## Release

Long-Term Memory Architecture

## Added

- Memory governance
- Memory types
- Memory scopes
- Personal/business separation
- Department memory stores
- Confidence scoring
- Retention and archival rules
- Memory indexes
- Validation suite

## Next

v1.3 Part B — Memory Capture, Search, and Recall
'@

Write-NewFile ".\docs\AI-Office-v1.3-Part-A-Release-Notes.md" $ReleaseNotes

$IdentityPath = ".\config\identity\office.json"

if (Test-Path -LiteralPath $IdentityPath -PathType Leaf) {
    $Identity = Get-Content -LiteralPath $IdentityPath -Raw |
        ConvertFrom-Json

    $Identity.version = "1.3.0"
    $Identity.codename = "Long-Term Memory"
    $Identity.updated_at = (Get-Date).ToString("o")

    $Identity |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $IdentityPath -Encoding UTF8

    Write-Host "[UPDATED] AI Office identity version set to 1.3.0" `
        -ForegroundColor Green
}

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw |
        ConvertFrom-Json

    $Version.version = "1.3.0"
    $Version.release_name = "Long-Term Memory"
    $Version.status = "part_a_installed"
    $Version.installed_at = (Get-Date).ToString("o")
    $Version.previous_version = "1.2.0"
    $Version.next_planned_milestone = "1.3 Part B Memory Capture, Search, and Recall"

    $Version |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $VersionPath -Encoding UTF8

    Write-Host "[UPDATED] Identity release metadata set to v1.3 Part A" `
        -ForegroundColor Green
}

Write-Host ""
Write-Host "Validating Part A JSON files..." -ForegroundColor Cyan

@(
    ".\config\memory\memory-policy.json",
    ".\config\memory\memory-record-schema.json",
    ".\config\memory\memory-index-schema.json",
    ".\config\memory\memory-scope-schema.json",
    ".\workspace\templates\long-term-memory-record-template.json",
    ".\workspace\memory\indexes\memory-index.json"
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
        "Installers\AI-Office-v1.3-Part-A-Long-Term-Memory-Architecture-Install.ps1"

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
Write-Host "AI Office v1.3 Part A installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\memory\Test-AIOfficeMemoryArchitecture.ps1"'
Write-Host ""
