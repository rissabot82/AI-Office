# ============================================================
# AI Office v1.3 - Part C
# Memory Learning, Health, Certification, and Release
# Repository: E:\AI\AI-Office
# Requires: AI Office v1.3 Parts A and B
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

$RequiredPrevious = @(
    ".\config\memory\memory-policy.json",
    ".\config\memory\memory-capture-recall-policy.json",
    ".\scripts\memory\AIOfficeMemory.Common.ps1",
    ".\scripts\memory\AIOfficeMemoryRecall.Common.ps1",
    ".\scripts\memory\New-AIOfficeMemory.ps1",
    ".\scripts\memory\Search-AIOfficeMemory.ps1",
    ".\scripts\memory\New-AIOfficeMemoryContextPacket.ps1"
)

foreach ($RequiredPath in $RequiredPrevious) {
    if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
        throw "AI Office v1.3 Parts A and B are required. Missing: $RequiredPath"
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
    ".\workspace\memory\feedback",
    ".\workspace\memory\corrections",
    ".\workspace\memory\health",
    ".\workspace\memory\certification",
    ".\workspace\memory\releases"
) | ForEach-Object { Ensure-Directory $_ }

$Now = (Get-Date).ToString("o")

$LearningPolicy = @"
{
  "schema_version": "1.0.0",
  "version": "1.3.0",
  "part": "C",
  "feedback": {
    "allowed_types": [
      "confirm",
      "correct",
      "reject",
      "promote",
      "demote"
    ],
    "adjust_confidence": true,
    "preserve_history": true
  },
  "confidence_adjustments": {
    "confirm": 0.05,
    "correct": -0.10,
    "reject": -0.25,
    "promote": 0.15,
    "demote": -0.15
  },
  "status_rules": {
    "promote_at": 0.90,
    "review_below": 0.50,
    "archive_below": 0.20
  },
  "staleness": {
    "review_after_days": 180,
    "stale_after_days": 365
  },
  "conflicts": {
    "enabled": true,
    "same_scope_only": false,
    "same_entity_or_project_required": true
  },
  "health": {
    "include_stale": true,
    "include_low_confidence": true,
    "include_conflicts": true,
    "include_scope_counts": true,
    "include_type_counts": true
  },
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\memory\memory-learning-health-policy.json" $LearningPolicy

$FeedbackSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/memory-feedback-schema.json",
  "title": "AI Office Memory Feedback",
  "type": "object",
  "required": [
    "feedback_id",
    "memory_id",
    "feedback_type",
    "summary",
    "created_at",
    "created_by"
  ]
}
'@

Write-NewFile ".\config\memory\memory-feedback-schema.json" $FeedbackSchema

$ConflictSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/memory-conflict-schema.json",
  "title": "AI Office Memory Conflict",
  "type": "object",
  "required": [
    "conflict_id",
    "memory_ids",
    "reason",
    "status",
    "created_at"
  ]
}
'@

Write-NewFile ".\config\memory\memory-conflict-schema.json" $ConflictSchema

$ReleaseManifest = @"
{
  "product": "AI Office",
  "component": "Long-Term Memory",
  "version": "1.3.0",
  "release_name": "Long-Term Memory",
  "release_status": "installed",
  "installed_at": "$Now",
  "parts": {
    "A": "Memory Architecture",
    "B": "Capture, Search, Recall, and Context",
    "C": "Learning, Health, Certification, and Release"
  },
  "capabilities": [
    "memory_scopes",
    "personal_business_separation",
    "department_memory",
    "chief_of_staff_memory",
    "memory_capture",
    "json_import",
    "search_and_recall",
    "duplicate_detection",
    "related_memory",
    "context_packets",
    "feedback_and_correction",
    "promotion_and_demotion",
    "staleness_detection",
    "conflict_detection",
    "memory_health_reporting",
    "certification"
  ],
  "next_planned_milestone": "1.4 Autonomous Workflows"
}
"@

Write-NewFile ".\config\memory\release-manifest.json" $ReleaseManifest

$FeedbackTemplate = @'
{
  "feedback_id": "MFB-YYYYMMDD-HHMMSS-ABC123",
  "memory_id": "MEM-YYYYMMDD-HHMMSS-ABC123",
  "feedback_type": "confirm",
  "summary": "",
  "confidence_before": 0.75,
  "confidence_after": 0.80,
  "created_at": "",
  "created_by": "chief-of-staff"
}
'@

Write-NewFile ".\workspace\templates\memory-feedback-template.json" $FeedbackTemplate

$Common = @'
. (Join-Path $PSScriptRoot "AIOfficeMemoryRecall.Common.ps1")

function Get-AIOfficeMemoryLearningPolicy {
    $Root = Get-AIOfficeMemoryRoot

    return Read-AIOfficeMemoryJson `
        -Path (Join-Path $Root "config\memory\memory-learning-health-policy.json")
}

function New-AIOfficeMemoryFeedbackId {
    return (
        "MFB-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeMemoryConflictId {
    return (
        "MCF-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}
'@

Write-NewFile ".\scripts\memory\AIOfficeMemoryLearning.Common.ps1" $Common

$Feedback = @'
param(
    [Parameter(Mandatory=$true)][string]$MemoryId,
    [ValidateSet("confirm","correct","reject","promote","demote")]
    [string]$FeedbackType,
    [Parameter(Mandatory=$true)][string]$Summary,
    [string]$CreatedBy = "chief-of-staff"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryLearning.Common.ps1")

$File = Find-AIOfficeMemoryFile -MemoryId $MemoryId

if ($null -eq $File) {
    throw "Memory record not found: $MemoryId"
}

$Record = Read-AIOfficeMemoryJson -Path $File.FullName
$Policy = Get-AIOfficeMemoryLearningPolicy

$Before = [double]$Record.confidence
$Adjustment = [double]$Policy.confidence_adjustments.$FeedbackType
$After = [math]::Min(1.0, [math]::Max(0.0, $Before + $Adjustment))

$Record.confidence = $After
$Record.updated_at = (Get-Date).ToString("o")

if ($After -ge [double]$Policy.status_rules.promote_at) {
    $Record.status = "promoted"
}
elseif ($After -lt [double]$Policy.status_rules.archive_below) {
    $Record.status = "archived"
}
elseif ($After -lt [double]$Policy.status_rules.review_below) {
    $Record.status = "review_required"
}
else {
    $Record.status = "active"
}

$History = New-Object System.Collections.Generic.List[object]

foreach ($Entry in @($Record.history)) {
    $History.Add($Entry)
}

$History.Add([ordered]@{
    timestamp = (Get-Date).ToString("o")
    action = $FeedbackType
    actor = $CreatedBy
    details = $Summary
})

$Record.history = @($History | ForEach-Object { $_ })

Write-AIOfficeMemoryJson -Value $Record -Path $File.FullName

$FeedbackRecord = [ordered]@{
    feedback_id = New-AIOfficeMemoryFeedbackId
    memory_id = $MemoryId
    feedback_type = $FeedbackType
    summary = $Summary
    confidence_before = $Before
    confidence_after = $After
    status_after = [string]$Record.status
    created_at = (Get-Date).ToString("o")
    created_by = $CreatedBy
}

Write-AIOfficeMemoryJson `
    -Value $FeedbackRecord `
    -Path (
        ".\workspace\memory\feedback\" +
        [string]$FeedbackRecord.feedback_id +
        ".json"
    )

& ".\scripts\memory\Update-AIOfficeMemoryIndex.ps1" |
    Out-Null

Write-Host (
    "Memory feedback recorded: " +
    [string]$FeedbackRecord.feedback_id
) -ForegroundColor Green

return [pscustomobject]$FeedbackRecord
'@

Write-NewFile ".\scripts\memory\Add-AIOfficeMemoryFeedback.ps1" $Feedback

$Stale = @'
param(
    [int]$ReviewAfterDays = 180,
    [int]$StaleAfterDays = 365
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryLearning.Common.ps1")

$Now = Get-Date
$Results = New-Object System.Collections.Generic.List[object]

foreach ($File in @(Get-AIOfficeAllMemoryFiles)) {
    $Record = Read-AIOfficeMemoryJson -Path $File.FullName

    if ($null -eq $Record) {
        continue
    }

    $Updated = [datetime]$Record.updated_at
    $AgeDays = ($Now - $Updated).TotalDays

    $Results.Add([pscustomobject]@{
        memory_id = [string]$Record.memory_id
        title = [string]$Record.title
        scope = [string]$Record.scope
        department = [string]$Record.department
        age_days = [math]::Round($AgeDays, 2)
        review_due = ($AgeDays -ge $ReviewAfterDays)
        stale = ($AgeDays -ge $StaleAfterDays)
        confidence = [double]$Record.confidence
        status = [string]$Record.status
    })
}

return @(
    $Results |
        Sort-Object stale, review_due, age_days -Descending
)
'@

Write-NewFile ".\scripts\memory\Find-AIOfficeStaleMemory.ps1" $Stale

$Conflicts = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryLearning.Common.ps1")

$Records = @(
    foreach ($File in @(Get-AIOfficeAllMemoryFiles)) {
        $Record = Read-AIOfficeMemoryJson -Path $File.FullName

        if ($null -ne $Record) {
            $Record
        }
    }
)

$Conflicts = New-Object System.Collections.Generic.List[object]

for ($i = 0; $i -lt $Records.Count; $i++) {
    for ($j = $i + 1; $j -lt $Records.Count; $j++) {
        $A = $Records[$i]
        $B = $Records[$j]

        $SharedEntities = @(
            $A.entities | Where-Object { @($B.entities) -contains $_ }
        )

        $SharedProjects = @(
            $A.projects | Where-Object { @($B.projects) -contains $_ }
        )

        if ($SharedEntities.Count -lt 1 -and $SharedProjects.Count -lt 1) {
            continue
        }

        if ([string]$A.memory_type -ne [string]$B.memory_type) {
            continue
        }

        if ([string]$A.summary -eq [string]$B.summary) {
            continue
        }

        $Conflict = [ordered]@{
            conflict_id = New-AIOfficeMemoryConflictId
            memory_ids = @(
                [string]$A.memory_id,
                [string]$B.memory_id
            )
            reason = "Memories share entities or projects but contain different summaries."
            shared_entities = $SharedEntities
            shared_projects = $SharedProjects
            status = "open"
            created_at = (Get-Date).ToString("o")
        }

        Write-AIOfficeMemoryJson `
            -Value $Conflict `
            -Path (
                ".\workspace\memory\conflicts\" +
                [string]$Conflict.conflict_id +
                ".json"
            )

        $Conflicts.Add([pscustomobject]$Conflict)
    }
}

return @($Conflicts | ForEach-Object { $_ })
'@

Write-NewFile ".\scripts\memory\Find-AIOfficeMemoryConflicts.ps1" $Conflicts

$Health = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryLearning.Common.ps1")

$Root = Get-AIOfficeMemoryRoot
Set-Location $Root

$Index = & ".\scripts\memory\Update-AIOfficeMemoryIndex.ps1"
$Policy = Get-AIOfficeMemoryLearningPolicy

$Stale = @(
    & ".\scripts\memory\Find-AIOfficeStaleMemory.ps1" `
        -ReviewAfterDays ([int]$Policy.staleness.review_after_days) `
        -StaleAfterDays ([int]$Policy.staleness.stale_after_days)
)

$Conflicts = @(
    & ".\scripts\memory\Find-AIOfficeMemoryConflicts.ps1"
)

$LowConfidence = @(
    foreach ($File in @(Get-AIOfficeAllMemoryFiles)) {
        $Record = Read-AIOfficeMemoryJson -Path $File.FullName

        if ($null -ne $Record -and
            [double]$Record.confidence -lt
            [double]$Policy.status_rules.review_below) {
            [pscustomobject]@{
                memory_id = [string]$Record.memory_id
                title = [string]$Record.title
                confidence = [double]$Record.confidence
                status = [string]$Record.status
            }
        }
    }
)

$HealthStatus = if (
    @($Stale | Where-Object { $_.stale }).Count -gt 0 -or
    $Conflicts.Count -gt 0 -or
    $LowConfidence.Count -gt 0
) {
    "attention_required"
}
else {
    "healthy"
}

$Report = [ordered]@{
    report_id = (
        "MEMHEALTH-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss")
    )
    generated_at = (Get-Date).ToString("o")
    status = $HealthStatus
    total_memory_count = [int]$Index.total_memory_count
    active_memory_count = [int]$Index.active_memory_count
    archived_memory_count = [int]$Index.archived_memory_count
    review_due_count = @(
        $Stale | Where-Object { $_.review_due }
    ).Count
    stale_count = @(
        $Stale | Where-Object { $_.stale }
    ).Count
    low_confidence_count = $LowConfidence.Count
    conflict_count = $Conflicts.Count
    scope_counts = $Index.scope_counts
    type_counts = $Index.type_counts
    department_counts = $Index.department_counts
    stale_memories = $Stale
    low_confidence_memories = $LowConfidence
    conflicts = $Conflicts
}

Write-AIOfficeMemoryJson `
    -Value $Report `
    -Path (
        ".\workspace\memory\health\" +
        [string]$Report.report_id +
        ".json"
    )

Write-Host (
    "Memory health report created: " +
    [string]$Report.report_id
) -ForegroundColor Green

return [pscustomobject]$Report
'@

Write-NewFile ".\scripts\memory\Get-AIOfficeMemoryHealthReport.ps1" $Health

$Certify = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryLearning.Common.ps1")

$Root = Get-AIOfficeMemoryRoot
Set-Location $Root

$Checks = New-Object System.Collections.Generic.List[object]

function Add-MemoryCheck {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Details
    )

    $Checks.Add([ordered]@{
        name = $Name
        passed = $Passed
        details = $Details
    })
}

$JsonFiles = @(
    ".\config\memory\memory-policy.json",
    ".\config\memory\memory-capture-recall-policy.json",
    ".\config\memory\memory-learning-health-policy.json",
    ".\config\memory\release-manifest.json"
)

foreach ($Path in $JsonFiles) {
    try {
        Get-Content -LiteralPath $Path -Raw |
            ConvertFrom-Json |
            Out-Null

        Add-MemoryCheck `
            -Name ("Valid JSON: " + $Path) `
            -Passed $true `
            -Details "Parsed successfully."
    }
    catch {
        Add-MemoryCheck `
            -Name ("Valid JSON: " + $Path) `
            -Passed $false `
            -Details $_.Exception.Message
    }
}

$Scripts = @(
    ".\scripts\memory\AIOfficeMemory.Common.ps1",
    ".\scripts\memory\AIOfficeMemoryRecall.Common.ps1",
    ".\scripts\memory\AIOfficeMemoryLearning.Common.ps1",
    ".\scripts\memory\New-AIOfficeMemory.ps1",
    ".\scripts\memory\Search-AIOfficeMemory.ps1",
    ".\scripts\memory\Find-AIOfficeMemoryDuplicates.ps1",
    ".\scripts\memory\Find-AIOfficeRelatedMemory.ps1",
    ".\scripts\memory\New-AIOfficeMemoryContextPacket.ps1",
    ".\scripts\memory\Add-AIOfficeMemoryFeedback.ps1",
    ".\scripts\memory\Find-AIOfficeStaleMemory.ps1",
    ".\scripts\memory\Find-AIOfficeMemoryConflicts.ps1",
    ".\scripts\memory\Get-AIOfficeMemoryHealthReport.ps1",
    ".\scripts\memory\Certify-AIOfficeLongTermMemory.ps1",
    ".\scripts\memory\Test-AIOfficeLongTermMemory.ps1",
    ".\scripts\memory\Publish-AIOfficeLongTermMemoryRelease.ps1"
)

foreach ($Path in $Scripts) {
    $Exists = Test-Path -LiteralPath $Path -PathType Leaf

    Add-MemoryCheck `
        -Name ("Script exists: " + $Path) `
        -Passed $Exists `
        -Details $(if ($Exists) { "Found." } else { "Missing." })
}

$MemoryIds = New-Object System.Collections.Generic.List[string]
$PacketId = ""

try {
    $MemoryOne = & ".\scripts\memory\New-AIOfficeMemory.ps1" `
        -Scope "business" `
        -MemoryType "fact" `
        -Title "Certification memory one" `
        -Summary "Primary certification fact." `
        -ContentJson '{"value":"one"}' `
        -SourceJson '{"type":"certification"}' `
        -Confidence 0.75 `
        -Tags @("certification") `
        -Entities @("AI Office") `
        -Projects @("Long-Term Memory")

    $MemoryTwo = & ".\scripts\memory\New-AIOfficeMemory.ps1" `
        -Scope "shared" `
        -MemoryType "fact" `
        -Title "Certification memory two" `
        -Summary "Secondary certification fact." `
        -ContentJson '{"value":"two"}' `
        -SourceJson '{"type":"certification"}' `
        -Confidence 0.80 `
        -Tags @("certification") `
        -Entities @("AI Office") `
        -Projects @("Long-Term Memory")

    $MemoryIds.Add([string]$MemoryOne.memory_id)
    $MemoryIds.Add([string]$MemoryTwo.memory_id)

    Add-MemoryCheck `
        -Name "Memory creation" `
        -Passed ($MemoryIds.Count -eq 2) `
        -Details "Created two certification memories."

    $Search = @(
        & ".\scripts\memory\Search-AIOfficeMemory.ps1" `
            -Query "certification" `
            -Limit 10
    )

    Add-MemoryCheck `
        -Name "Memory search" `
        -Passed ($Search.Count -ge 2) `
        -Details ($Search.Count.ToString() + " result(s)")

    $Packet = & ".\scripts\memory\New-AIOfficeMemoryContextPacket.ps1" `
        -Query "certification" `
        -RequestedBy "chief-of-staff" `
        -Limit 10

    $PacketId = [string]$Packet.context_packet_id

    Add-MemoryCheck `
        -Name "Context packet" `
        -Passed ([int]$Packet.memory_count -ge 2) `
        -Details $PacketId

    $Feedback = & ".\scripts\memory\Add-AIOfficeMemoryFeedback.ps1" `
        -MemoryId ([string]$MemoryIds[0]) `
        -FeedbackType "promote" `
        -Summary "Certification promotion test."

    Add-MemoryCheck `
        -Name "Feedback and promotion" `
        -Passed ([double]$Feedback.confidence_after -gt
            [double]$Feedback.confidence_before) `
        -Details ([string]$Feedback.feedback_id)

    $Health = & ".\scripts\memory\Get-AIOfficeMemoryHealthReport.ps1"

    Add-MemoryCheck `
        -Name "Memory health report" `
        -Passed ($null -ne $Health) `
        -Details ([string]$Health.report_id)
}
catch {
    Add-MemoryCheck `
        -Name "Offline end-to-end Long-Term Memory workflow" `
        -Passed $false `
        -Details $_.Exception.Message
}

foreach ($MemoryId in $MemoryIds) {
    $File = Find-AIOfficeMemoryFile -MemoryId $MemoryId

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

foreach ($Folder in @(
    ".\workspace\memory\captures",
    ".\workspace\memory\feedback"
)) {
    Get-ChildItem `
        -LiteralPath $Folder `
        -Filter "*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        ForEach-Object {
            $Record = Read-AIOfficeMemoryJson -Path $_.FullName

            if ($null -ne $Record -and
                $MemoryIds -contains [string]$Record.memory_id) {
                Remove-Item -LiteralPath $_.FullName -Force
            }
        }
}

Get-ChildItem `
    -LiteralPath ".\workspace\memory\conflicts" `
    -Filter "MCF-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    ForEach-Object {
        $Record = Read-AIOfficeMemoryJson -Path $_.FullName

        if ($null -ne $Record -and
            (@($Record.memory_ids) | Where-Object {
                $MemoryIds -contains [string]$_
            }).Count -gt 0) {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }

& ".\scripts\memory\Update-AIOfficeMemoryIndex.ps1" |
    Out-Null

$PassedCount = @(
    $Checks | Where-Object { $_.passed -eq $true }
).Count

$FailedCount = @(
    $Checks | Where-Object { $_.passed -eq $false }
).Count

$Status = if ($FailedCount -eq 0) {
    "certified"
}
else {
    "failed"
}

$CertificationId = (
    "CERT-MEM-" +
    (Get-Date).ToString("yyyyMMdd-HHmmss")
)

$Certification = [ordered]@{
    certification_id = $CertificationId
    version = "1.3.0"
    certified_at = (Get-Date).ToString("o")
    status = $Status
    passed_checks = $PassedCount
    failed_checks = $FailedCount
    checks = @($Checks | ForEach-Object { $_ })
}

Write-AIOfficeMemoryJson `
    -Value $Certification `
    -Path (
        ".\workspace\memory\certification\" +
        $CertificationId +
        ".json"
    )

Write-Host (
    "Long-Term Memory certification: " +
    $Status +
    " | " +
    $PassedCount.ToString() +
    " passed, " +
    $FailedCount.ToString() +
    " failed"
) -ForegroundColor $(if ($FailedCount -eq 0) { "Green" } else { "Red" })

return [pscustomobject]$Certification
'@

Write-NewFile ".\scripts\memory\Certify-AIOfficeLongTermMemory.ps1" $Certify

$CompleteTest = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.3 Long-Term Memory..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

function Invoke-MemoryTest {
    param(
        [string]$Name,
        [string]$Path
    )

    try {
        & $Path

        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            throw "$Name returned exit code $LASTEXITCODE."
        }

        Write-Host ("[PASS] " + $Name) -ForegroundColor Green
    }
    catch {
        Write-Host ("[FAIL] " + $Name) -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $Errors.Add($Name + ": " + $_.Exception.Message)
    }
}

Invoke-MemoryTest `
    -Name "Part A Memory Architecture" `
    -Path ".\scripts\memory\Test-AIOfficeMemoryArchitecture.ps1"

Invoke-MemoryTest `
    -Name "Part B Capture, Search, and Recall" `
    -Path ".\scripts\memory\Test-AIOfficeMemoryCaptureRecall.ps1"

try {
    $Certification = & `
        ".\scripts\memory\Certify-AIOfficeLongTermMemory.ps1"

    if ($null -eq $Certification -or
        [string]$Certification.status -ne "certified" -or
        [int]$Certification.failed_checks -ne 0) {
        throw "Long-Term Memory certification failed."
    }

    Write-Host (
        "[PASS] Long-Term Memory certification: " +
        [string]$Certification.certification_id
    ) -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Long-Term Memory certification" `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Long-Term Memory certification: " + $_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Long-Term Memory error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.3 Long-Term Memory checks passed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "AI Office v1.3 Long-Term Memory is operational." `
    -ForegroundColor Cyan
'@

Write-NewFile ".\scripts\memory\Test-AIOfficeLongTermMemory.ps1" $CompleteTest

$PublishRelease = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryLearning.Common.ps1")

$Root = Get-AIOfficeMemoryRoot
Set-Location $Root

$CertificationFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\memory\certification" `
        -Filter "CERT-MEM-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending
)

if ($CertificationFiles.Count -lt 1) {
    throw "No Long-Term Memory certification record exists."
}

$Certification = Read-AIOfficeMemoryJson `
    -Path $CertificationFiles[0].FullName

if ($null -eq $Certification -or
    [string]$Certification.status -ne "certified") {
    throw "Latest Long-Term Memory certification did not pass."
}

$ManifestPath = ".\config\memory\release-manifest.json"
$Manifest = Read-AIOfficeMemoryJson -Path $ManifestPath

if ($null -eq $Manifest) {
    throw "Long-Term Memory release manifest could not be loaded."
}

$ReleasedAt = (Get-Date).ToString("o")
$Manifest.release_status = "released"
$Manifest.released_at = $ReleasedAt
$Manifest.certification_id = [string]$Certification.certification_id

Write-AIOfficeMemoryJson `
    -Value $Manifest `
    -Path $ManifestPath

$ReleaseRecord = [ordered]@{
    product = "AI Office"
    component = "Long-Term Memory"
    version = "1.3.0"
    released_at = $ReleasedAt
    status = "released"
    certification_id = [string]$Certification.certification_id
    next_milestone = "1.4 Autonomous Workflows"
}

Write-AIOfficeMemoryJson `
    -Value $ReleaseRecord `
    -Path (
        ".\workspace\memory\releases\AI-Office-v1.3-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        ".json"
    )

$IdentityPath = ".\config\identity\office.json"

if (Test-Path -LiteralPath $IdentityPath -PathType Leaf) {
    $Identity = Read-AIOfficeMemoryJson -Path $IdentityPath
    $Identity.version = "1.3.0"
    $Identity.codename = "Long-Term Memory"
    $Identity.updated_at = $ReleasedAt

    Write-AIOfficeMemoryJson `
        -Value $Identity `
        -Path $IdentityPath
}

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Read-AIOfficeMemoryJson -Path $VersionPath
    $Version.version = "1.3.0"
    $Version.release_name = "Long-Term Memory"
    $Version.status = "released"
    $Version.installed_at = $ReleasedAt
    $Version.previous_version = "1.2.0"
    $Version.next_planned_milestone = "1.4 Autonomous Workflows"

    Write-AIOfficeMemoryJson `
        -Value $Version `
        -Path $VersionPath
}

Write-Host (
    "AI Office v1.3 Long-Term Memory release recorded: " +
    [string]$Certification.certification_id
) -ForegroundColor Green

return [pscustomobject]$ReleaseRecord
'@

Write-NewFile ".\scripts\memory\Publish-AIOfficeLongTermMemoryRelease.ps1" $PublishRelease

$Guide = @'
# AI Office v1.3 — Long-Term Memory

AI Office v1.3 adds persistent, governed memory across the Chief of Staff, departments, personal work, business work, and shared context.

## Delivered

### Part A — Architecture
- Memory policy
- Memory scopes
- Personal/business separation
- Department memory
- Confidence and retention rules
- Global and department indexes

### Part B — Capture and Recall
- Manual memory creation
- JSON import
- Multi-filter search
- Duplicate detection
- Related-memory discovery
- Context packets
- Recall tracking

### Part C — Learning and Health
- Feedback and correction
- Promotion and demotion
- Confidence adjustment
- Review and archival thresholds
- Staleness detection
- Conflict detection
- Memory health reports
- Full certification
- Release publication

## Complete validation

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\memory\Test-AIOfficeLongTermMemory.ps1"
```

Expected ending:

```text
All AI Office v1.3 Long-Term Memory checks passed.
AI Office v1.3 Long-Term Memory is operational.
```

## Publish release

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\memory\Publish-AIOfficeLongTermMemoryRelease.ps1"
```

## Generate health report

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\memory\Get-AIOfficeMemoryHealthReport.ps1"
```

## Next milestone

AI Office v1.4 will introduce Autonomous Workflows.
'@

Write-NewFile ".\docs\AI-Office-v1.3-Long-Term-Memory-Guide.md" $Guide

$ReleaseNotes = @'
# AI Office v1.3 Release Notes

## Release name

Long-Term Memory

## Added

- Global, executive, department, personal, business, and shared memory
- Memory creation and import
- Search and recall
- Duplicate and related-memory detection
- Context packets
- Feedback and correction
- Promotion and demotion
- Staleness and conflict detection
- Memory health reporting
- Certification and release publication

## Next

AI Office v1.4 — Autonomous Workflows
'@

Write-NewFile ".\docs\AI-Office-v1.3-Release-Notes.md" $ReleaseNotes

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw |
        ConvertFrom-Json

    $Version.version = "1.3.0"
    $Version.release_name = "Long-Term Memory"
    $Version.status = "part_c_installed"
    $Version.installed_at = (Get-Date).ToString("o")
    $Version.next_planned_milestone = "1.4 Autonomous Workflows"

    $Version |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $VersionPath -Encoding UTF8

    Write-Host "[UPDATED] Identity release metadata set to v1.3 Part C" `
        -ForegroundColor Green
}

Write-Host ""
Write-Host "Validating Part C JSON files..." -ForegroundColor Cyan

@(
    ".\config\memory\memory-learning-health-policy.json",
    ".\config\memory\memory-feedback-schema.json",
    ".\config\memory\memory-conflict-schema.json",
    ".\config\memory\release-manifest.json",
    ".\workspace\templates\memory-feedback-template.json"
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
        "Installers\AI-Office-v1.3-Part-C-Memory-Learning-Health-Release-Install.ps1"

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
Write-Host "AI Office v1.3 Part C installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run complete validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\memory\Test-AIOfficeLongTermMemory.ps1"'
Write-Host ""
