# AI Office v1.1.1 - Identity System
# Repository: E:\AI\AI-Office

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

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
        if ($Parent -and -not (Test-Path -LiteralPath $Parent)) {
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
    ".\config\identity",
    ".\workspace\identity",
    ".\workspace\identity\history",
    ".\workspace\identity\exports",
    ".\scripts\identity",
    ".\docs",
    ".\Installers"
) | ForEach-Object { Ensure-Directory $_ }

$Now = (Get-Date).ToString("o")

$OfficeJson = @"
{
  "schema_version": "1.0.0",
  "office_id": "AIOFFICE-RISSABOT82-001",
  "name": "AI Office",
  "formal_name": "AI Office Executive Operating System",
  "version": "1.1.1",
  "codename": "Identity",
  "release_line": "1.1",
  "status": "active",
  "repository": "E:\\AI\\AI-Office",
  "executive_role": "Chief of Staff",
  "execution_engine": "OpenClaw",
  "governance_model": "Human-supervised AI organization",
  "mission": "AI Office organizes, delegates, executes, and continuously improves professional and personal work through specialized AI departments under the supervision of a Chief of Staff.",
  "operating_principles": [
    "AI Office owns planning, governance, memory, routing, and accountability.",
    "OpenClaw performs approved execution work.",
    "High-impact actions require human approval.",
    "All meaningful actions should be auditable.",
    "Agents operate within defined capabilities and departments.",
    "The repository is the source of truth for system design.",
    "Runtime state remains separate from source code."
  ],
  "owner": {
    "display_name": "Clarissa Schmidtberger",
    "github_username": "rissabot82"
  },
  "environment": {
    "platform": "Windows",
    "repository_path": "E:\\AI\\AI-Office",
    "timezone": "America/Chicago",
    "openclaw_gateway": "ws://localhost:18789"
  },
  "created_at": "$Now",
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\identity\office.json" $OfficeJson

$CapabilitiesJson = @"
{
  "schema_version": "1.0.0",
  "office_id": "AIOFFICE-RISSABOT82-001",
  "capability_groups": {
    "governance": [
      "approval_gates",
      "priority_management",
      "risk_escalation",
      "audit_logging",
      "release_management"
    ],
    "executive_operations": [
      "startup_routine",
      "daily_briefing",
      "end_of_day_report",
      "weekly_report",
      "monthly_report",
      "office_health_monitoring",
      "executive_dashboard"
    ],
    "work_management": [
      "task_creation",
      "workflow_routing",
      "workflow_automation",
      "calendar_management",
      "delegation",
      "dependency_tracking"
    ],
    "knowledge": [
      "knowledge_storage",
      "knowledge_indexing",
      "shared_context",
      "templates",
      "department_reference_material"
    ],
    "collaboration": [
      "agent_registration",
      "agent_messaging",
      "shared_work_queues",
      "delegation",
      "conflict_resolution",
      "department_coordination"
    ],
    "execution": [
      "openclaw_bridge_planned",
      "browser_execution_planned",
      "powershell_execution_planned",
      "system_action_approval_planned"
    ]
  },
  "restricted_capabilities": [
    "arbitrary_shell_execution",
    "credential_exposure",
    "unapproved_git_push",
    "unapproved_file_deletion",
    "unapproved_external_publish",
    "unapproved_financial_transaction",
    "unapproved_account_changes"
  ],
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\identity\capabilities.json" $CapabilitiesJson

$VersionJson = @"
{
  "product": "AI Office",
  "version": "1.1.1",
  "release_name": "Identity System",
  "release_type": "minor_feature",
  "status": "installed",
  "installed_at": "$Now",
  "previous_version": "1.0.0",
  "next_planned_milestone": "1.1.2 Message Bus",
  "compatibility": {
    "windows_powershell": "5.1+",
    "powershell": "7.x supported",
    "repository_layout": "AI Office v1.0",
    "openclaw_gateway": "2026.6.10"
  }
}
"@

Write-NewFile ".\config\identity\version.json" $VersionJson

$SchemaJson = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/identity-envelope-schema.json",
  "title": "AI Office Identity Envelope",
  "type": "object",
  "required": [
    "office_id",
    "office_name",
    "office_version",
    "message_type",
    "created_at",
    "payload"
  ],
  "properties": {
    "office_id": {
      "type": "string",
      "pattern": "^AIOFFICE-[A-Z0-9-]+$"
    },
    "office_name": {
      "type": "string",
      "minLength": 1
    },
    "office_version": {
      "type": "string"
    },
    "message_type": {
      "type": "string"
    },
    "created_at": {
      "type": "string"
    },
    "correlation_id": {
      "type": "string"
    },
    "source_component": {
      "type": "string"
    },
    "target_component": {
      "type": "string"
    },
    "payload": {
      "type": "object"
    }
  }
}
'@

Write-NewFile ".\config\identity\api-schema.json" $SchemaJson

$IndexJson = @'
{
  "schema_version": "1.0.0",
  "updated_at": "",
  "office_id": "",
  "office_name": "",
  "office_version": "",
  "codename": "",
  "status": "",
  "execution_engine": "",
  "capability_group_count": 0,
  "restricted_capability_count": 0,
  "identity_valid": false,
  "latest_export": ""
}
'@

Write-NewFile ".\workspace\identity\identity-index.json" $IndexJson

$CommonScript = @'
$script:AIOfficeIdentityRoot = $null

function Get-AIOfficeIdentityRoot {
    if ($script:AIOfficeIdentityRoot) {
        return $script:AIOfficeIdentityRoot
    }

    $script:AIOfficeIdentityRoot = (
        Resolve-Path (Join-Path $PSScriptRoot "..\..")
    ).Path

    return $script:AIOfficeIdentityRoot
}

function Read-AIOfficeIdentityJson {
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

function Write-AIOfficeIdentityJson {
    param(
        [Parameter(Mandatory=$true)]$Value,
        [Parameter(Mandatory=$true)][string]$Path
    )

    $Value |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-AIOfficeIdentity {
    $Root = Get-AIOfficeIdentityRoot

    return Read-AIOfficeIdentityJson `
        -Path (Join-Path $Root "config\identity\office.json")
}

function Get-AIOfficeIdentityCapabilities {
    $Root = Get-AIOfficeIdentityRoot

    return Read-AIOfficeIdentityJson `
        -Path (Join-Path $Root "config\identity\capabilities.json")
}

function New-AIOfficeIdentityEnvelope {
    param(
        [Parameter(Mandatory=$true)][string]$MessageType,
        [Parameter(Mandatory=$true)]$Payload,
        [string]$SourceComponent = "AI Office",
        [string]$TargetComponent = "",
        [string]$CorrelationId = ""
    )

    $Identity = Get-AIOfficeIdentity

    if ($null -eq $Identity) {
        throw "AI Office identity could not be loaded."
    }

    if ([string]::IsNullOrWhiteSpace($CorrelationId)) {
        $CorrelationId = "COR-" + (
            [guid]::NewGuid().ToString("N").Substring(0,12)
        ).ToUpperInvariant()
    }

    return [ordered]@{
        office_id = [string]$Identity.office_id
        office_name = [string]$Identity.name
        office_version = [string]$Identity.version
        message_type = $MessageType
        created_at = (Get-Date).ToString("o")
        correlation_id = $CorrelationId
        source_component = $SourceComponent
        target_component = $TargetComponent
        payload = $Payload
    }
}
'@

Write-NewFile ".\scripts\identity\AIOfficeIdentity.Common.ps1" $CommonScript

$UpdateScript = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeIdentity.Common.ps1")

$Root = Get-AIOfficeIdentityRoot
Set-Location $Root

$Identity = Get-AIOfficeIdentity
$Capabilities = Get-AIOfficeIdentityCapabilities

if ($null -eq $Identity) {
    throw "Identity configuration could not be loaded."
}

if ($null -eq $Capabilities) {
    throw "Capability configuration could not be loaded."
}

$GroupCount = @(
    $Capabilities.capability_groups.PSObject.Properties
).Count

$RestrictedCount = @(
    $Capabilities.restricted_capabilities
).Count

$Existing = Read-AIOfficeIdentityJson `
    -Path ".\workspace\identity\identity-index.json"

$LatestExport = ""

if ($null -ne $Existing -and
    $null -ne $Existing.PSObject.Properties["latest_export"]) {
    $LatestExport = [string]$Existing.latest_export
}

$Index = [ordered]@{
    schema_version = "1.0.0"
    updated_at = (Get-Date).ToString("o")
    office_id = [string]$Identity.office_id
    office_name = [string]$Identity.name
    office_version = [string]$Identity.version
    codename = [string]$Identity.codename
    status = [string]$Identity.status
    execution_engine = [string]$Identity.execution_engine
    capability_group_count = [int]$GroupCount
    restricted_capability_count = [int]$RestrictedCount
    identity_valid = $true
    latest_export = $LatestExport
}

Write-AIOfficeIdentityJson `
    -Value $Index `
    -Path ".\workspace\identity\identity-index.json"

Write-Host (
    "Identity index updated: " +
    [string]$Index.office_name +
    " v" +
    [string]$Index.office_version
) -ForegroundColor Green

return [pscustomobject]$Index
'@

Write-NewFile ".\scripts\identity\Update-AIOfficeIdentityIndex.ps1" $UpdateScript

$ShowScript = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeIdentity.Common.ps1")

$Root = Get-AIOfficeIdentityRoot
Set-Location $Root

$Index = & ".\scripts\identity\Update-AIOfficeIdentityIndex.ps1"
$Identity = Get-AIOfficeIdentity
$Capabilities = Get-AIOfficeIdentityCapabilities

Write-Host ""
Write-Host "AI OFFICE IDENTITY" -ForegroundColor Cyan
Write-Host ("=" * 72)
Write-Host ("Office ID       : " + [string]$Identity.office_id)
Write-Host ("Name            : " + [string]$Identity.formal_name)
Write-Host ("Version         : " + [string]$Identity.version)
Write-Host ("Codename        : " + [string]$Identity.codename)
Write-Host ("Status          : " + [string]$Identity.status)
Write-Host ("Executive Role  : " + [string]$Identity.executive_role)
Write-Host ("Execution Engine: " + [string]$Identity.execution_engine)
Write-Host ("Repository      : " + [string]$Identity.repository)
Write-Host ""
Write-Host "MISSION" -ForegroundColor Yellow
Write-Host ([string]$Identity.mission)
Write-Host ""
Write-Host "CAPABILITY GROUPS" -ForegroundColor Yellow

foreach ($Property in $Capabilities.capability_groups.PSObject.Properties) {
    Write-Host (
        "- " +
        [string]$Property.Name +
        ": " +
        @($Property.Value).Count.ToString()
    )
}

Write-Host ""
return $Index
'@

Write-NewFile ".\scripts\identity\Show-AIOfficeIdentity.ps1" $ShowScript

$ExportScript = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeIdentity.Common.ps1")

$Root = Get-AIOfficeIdentityRoot
Set-Location $Root

$Identity = Get-AIOfficeIdentity
$Capabilities = Get-AIOfficeIdentityCapabilities
$Version = Read-AIOfficeIdentityJson `
    -Path ".\config\identity\version.json"

if ($null -eq $Identity -or
    $null -eq $Capabilities -or
    $null -eq $Version) {
    throw "Identity export could not load required configuration."
}

$Record = [ordered]@{
    exported_at = (Get-Date).ToString("o")
    identity = $Identity
    capabilities = $Capabilities
    release = $Version
}

$FileName = (
    "identity-export-" +
    (Get-Date).ToString("yyyyMMdd-HHmmss") +
    ".json"
)

$Path = Join-Path ".\workspace\identity\exports" $FileName

Write-AIOfficeIdentityJson -Value $Record -Path $Path

$Index = Read-AIOfficeIdentityJson `
    -Path ".\workspace\identity\identity-index.json"

if ($null -eq $Index) {
    & ".\scripts\identity\Update-AIOfficeIdentityIndex.ps1" |
        Out-Null

    $Index = Read-AIOfficeIdentityJson `
        -Path ".\workspace\identity\identity-index.json"
}

$Index.latest_export = $Path
$Index.updated_at = (Get-Date).ToString("o")

Write-AIOfficeIdentityJson `
    -Value $Index `
    -Path ".\workspace\identity\identity-index.json"

Write-Host "Identity export created: $Path" -ForegroundColor Green
return $Path
'@

Write-NewFile ".\scripts\identity\Export-AIOfficeIdentity.ps1" $ExportScript

$TestScript = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.1 Identity System..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\identity\office.json",
    ".\config\identity\capabilities.json",
    ".\config\identity\version.json",
    ".\config\identity\api-schema.json",
    ".\workspace\identity\identity-index.json"
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
    ".\scripts\identity\AIOfficeIdentity.Common.ps1",
    ".\scripts\identity\Update-AIOfficeIdentityIndex.ps1",
    ".\scripts\identity\Show-AIOfficeIdentity.ps1",
    ".\scripts\identity\Export-AIOfficeIdentity.ps1",
    ".\scripts\identity\Test-AIOfficeIdentity.ps1"
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
    $Index = & ".\scripts\identity\Update-AIOfficeIdentityIndex.ps1"

    if ($null -eq $Index -or
        [string]$Index.office_version -ne "1.1.1" -or
        -not [bool]$Index.identity_valid) {
        throw "Identity index did not contain expected values."
    }

    Write-Host (
        "[INDEX OK   ] " +
        [string]$Index.office_id +
        " v" +
        [string]$Index.office_version
    ) -ForegroundColor Green
}
catch {
    Write-Host "[INDEX ERR  ] Identity indexing failed." `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Identity indexing failed: " + $_.Exception.Message)
}

try {
    . ".\scripts\identity\AIOfficeIdentity.Common.ps1"

    $Envelope = New-AIOfficeIdentityEnvelope `
        -MessageType "identity_test" `
        -Payload ([ordered]@{ test = $true }) `
        -SourceComponent "Identity System" `
        -TargetComponent "Validation Suite"

    if ([string]$Envelope.office_version -ne "1.1.1" -or
        [string]$Envelope.message_type -ne "identity_test") {
        throw "Identity envelope did not contain expected values."
    }

    Write-Host (
        "[ENVELOPE OK] " +
        [string]$Envelope.correlation_id
    ) -ForegroundColor Green
}
catch {
    Write-Host "[ENVELOPE ER] Identity envelope test failed." `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Identity envelope failed: " + $_.Exception.Message)
}

try {
    $ExportPath = & ".\scripts\identity\Export-AIOfficeIdentity.ps1"

    if (-not (Test-Path -LiteralPath $ExportPath -PathType Leaf)) {
        throw "Identity export file was not created."
    }

    Get-Content -LiteralPath $ExportPath -Raw |
        ConvertFrom-Json |
        Out-Null

    Write-Host (
        "[EXPORT OK  ] " +
        [string]$ExportPath
    ) -ForegroundColor Green
}
catch {
    Write-Host "[EXPORT ERR ] Identity export failed." `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Identity export failed: " + $_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " identity system error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.1 Identity System checks passed." `
    -ForegroundColor Green
'@

Write-NewFile ".\scripts\identity\Test-AIOfficeIdentity.ps1" $TestScript

$Guide = @'
# AI Office v1.1.1 — Identity System

This milestone gives AI Office a formal identity, mission, version, capability catalog, and standard identity envelope.

## Show the identity

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\identity\Show-AIOfficeIdentity.ps1"
```

## Export the identity

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\identity\Export-AIOfficeIdentity.ps1"
```

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\identity\Test-AIOfficeIdentity.ps1"
```

Expected result:

```text
All AI Office v1.1.1 Identity System checks passed.
```

## Next milestone

AI Office v1.1.2 will add the internal Message Bus.
'@

Write-NewFile ".\docs\AI-Office-v1.1.1-Identity-Guide.md" $Guide

$ReleaseNotes = @'
# AI Office v1.1.1 Release Notes

## Release

Identity System

## Added

- Formal office identity
- Mission statement
- Operating principles
- Capability catalog
- Restricted capability catalog
- Version metadata
- Identity envelope schema
- Identity index and export
- Full validation suite

## Next

v1.1.2 Message Bus
'@

Write-NewFile ".\docs\AI-Office-v1.1.1-Release-Notes.md" $ReleaseNotes

Write-Host ""
Write-Host "Validating v1.1.1 JSON files..." -ForegroundColor Cyan

@(
    ".\config\identity\office.json",
    ".\config\identity\capabilities.json",
    ".\config\identity\version.json",
    ".\config\identity\api-schema.json",
    ".\workspace\identity\identity-index.json"
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
        "Installers\AI-Office-v1.1.1-Identity-Install.ps1"

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
Write-Host "AI Office v1.1.1 Identity System installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\identity\Test-AIOfficeIdentity.ps1"'
Write-Host ""
