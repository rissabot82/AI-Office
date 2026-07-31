# ============================================================
# AI Office v1.2 - Part B
# Department Inbox and Work Intake
# Repository: E:\AI\AI-Office
# Requires: AI Office v1.2 Part A
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

$RequiredPrevious = @(
    ".\config\departments\department-intelligence-policy.json",
    ".\scripts\departments\AIOfficeDepartments.Common.ps1",
    ".\scripts\departments\Update-AIOfficeDepartmentIndex.ps1",
    ".\scripts\messaging\Receive-AIOfficeMessage.ps1",
    ".\scripts\messaging\Get-AIOfficeMessage.ps1",
    ".\scripts\messaging\Complete-AIOfficeMessage.ps1",
    ".\scripts\messaging\Fail-AIOfficeMessage.ps1"
)

foreach ($RequiredPath in $RequiredPrevious) {
    if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
        throw "AI Office v1.2 Part A is required. Missing: $RequiredPath"
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

foreach ($Department in $Departments) {
    @(
        ".\workspace\departments\$Department\processed-inbox",
        ".\workspace\departments\$Department\failed-inbox",
        ".\workspace\departments\$Department\classifications"
    ) | ForEach-Object { Ensure-Directory $_ }
}

$Now = (Get-Date).ToString("o")

$InboxPolicy = @"
{
  "schema_version": "1.0.0",
  "version": "1.2.0",
  "part": "B",
  "message_types": [
    "handoff",
    "request",
    "execution_request",
    "execution_result",
    "status",
    "error",
    "information",
    "event"
  ],
  "intake": {
    "default_limit": 10,
    "maximum_limit": 100,
    "create_work_item": true,
    "complete_message_after_intake": true,
    "reject_capability_mismatch": false,
    "send_mismatch_to_chief_of_staff": true
  },
  "work_item": {
    "default_status": "queued",
    "default_priority": "normal",
    "default_risk_level": "medium",
    "require_objective": true,
    "require_deliverables": true,
    "require_source_message": true
  },
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\departments\department-inbox-policy.json" $InboxPolicy

$WorkSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/department-work-item-schema.json",
  "title": "AI Office Department Work Item",
  "type": "object",
  "required": [
    "work_item_id",
    "department",
    "source_message_id",
    "title",
    "objective",
    "deliverables",
    "priority",
    "risk_level",
    "status",
    "created_at",
    "updated_at",
    "history"
  ]
}
'@

Write-NewFile ".\config\departments\department-work-item-schema.json" $WorkSchema

$ClassificationSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/department-intake-classification-schema.json",
  "title": "AI Office Department Intake Classification",
  "type": "object",
  "required": [
    "classification_id",
    "department",
    "message_id",
    "accepted",
    "matched_capabilities",
    "missing_capabilities",
    "created_at"
  ]
}
'@

Write-NewFile ".\config\departments\department-intake-classification-schema.json" $ClassificationSchema

$WorkTemplate = @'
{
  "work_item_id": "DWI-YYYYMMDD-HHMMSS-ABC123",
  "department": "marketing",
  "source_message_id": "MSG-YYYYMMDD-HHMMSS-ABC123",
  "title": "",
  "objective": "",
  "deliverables": [],
  "priority": "normal",
  "risk_level": "medium",
  "approval_status": "not_required",
  "status": "queued",
  "workflow_id": "",
  "conversation_id": "",
  "correlation_id": "",
  "created_at": "",
  "updated_at": "",
  "history": []
}
'@

Write-NewFile ".\workspace\templates\department-work-item-template.json" $WorkTemplate

$Common = @'
. (Join-Path $PSScriptRoot "AIOfficeDepartments.Common.ps1")

function Get-AIOfficeDepartmentInboxPolicy {
    $Root = Get-AIOfficeDepartmentRoot

    return Read-AIOfficeDepartmentJson `
        -Path (Join-Path $Root "config\departments\department-inbox-policy.json")
}

function New-AIOfficeDepartmentWorkItemId {
    return (
        "DWI-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeDepartmentClassificationId {
    return (
        "DCL-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeRequestedCapabilities {
    param([AllowNull()]$Payload)

    if ($null -eq $Payload) {
        return @()
    }

    if ($null -ne $Payload.PSObject.Properties["required_capabilities"]) {
        return @($Payload.required_capabilities)
    }

    if ($null -ne $Payload.PSObject.Properties["capabilities"]) {
        return @($Payload.capabilities)
    }

    return @()
}
'@

Write-NewFile ".\scripts\departments\AIOfficeDepartmentInbox.Common.ps1" $Common

$Classify = @'
param(
    [Parameter(Mandatory=$true)][string]$Department,
    [Parameter(Mandatory=$true)][string]$MessageId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentInbox.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$Profile = Get-AIOfficeDepartmentProfile -Department $Department
$Message = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
    -MessageId $MessageId

$Requested = @(
    Get-AIOfficeRequestedCapabilities -Payload $Message.payload
)

$Matched = New-Object System.Collections.Generic.List[string]
$Missing = New-Object System.Collections.Generic.List[string]

foreach ($Capability in $Requested) {
    if (@($Profile.capabilities) -contains [string]$Capability) {
        $Matched.Add([string]$Capability)
    }
    else {
        $Missing.Add([string]$Capability)
    }
}

$Accepted = ($Missing.Count -eq 0)

$Classification = [ordered]@{
    classification_id = New-AIOfficeDepartmentClassificationId
    department = $Department
    message_id = $MessageId
    accepted = $Accepted
    matched_capabilities = @($Matched)
    missing_capabilities = @($Missing)
    created_at = (Get-Date).ToString("o")
}

$Path = Join-Path `
    ".\workspace\departments\$Department\classifications" `
    ([string]$Classification.classification_id + ".json")

Write-AIOfficeDepartmentJson `
    -Value $Classification `
    -Path $Path

Write-Host (
    "Department intake classified: " +
    $MessageId +
    " | accepted=" +
    [string]$Accepted
) -ForegroundColor Green

return [pscustomobject]$Classification
'@

Write-NewFile ".\scripts\departments\Test-AIOfficeDepartmentWorkAcceptance.ps1" $Classify

$NewWork = @'
param(
    [Parameter(Mandatory=$true)][string]$Department,
    [Parameter(Mandatory=$true)][string]$MessageId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentInbox.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$Policy = Get-AIOfficeDepartmentInboxPolicy
$Message = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
    -MessageId $MessageId

$Classification = & `
    ".\scripts\departments\Test-AIOfficeDepartmentWorkAcceptance.ps1" `
    -Department $Department `
    -MessageId $MessageId

$Title = [string]$Message.subject

if ([string]::IsNullOrWhiteSpace($Title)) {
    $Title = "Department work from " + [string]$Message.from
}

$Objective = ""

foreach ($PropertyName in @(
    "objective",
    "instruction",
    "request",
    "summary",
    "message"
)) {
    if ($null -ne $Message.payload.PSObject.Properties[$PropertyName] -and
        -not [string]::IsNullOrWhiteSpace([string]$Message.payload.$PropertyName)) {
        $Objective = [string]$Message.payload.$PropertyName
        break
    }
}

if ([string]::IsNullOrWhiteSpace($Objective)) {
    $Objective = "Complete department work from message " + $MessageId + "."
}

$Deliverables = @()

if ($null -ne $Message.payload.PSObject.Properties["deliverables"]) {
    $Deliverables = @($Message.payload.deliverables)
}
elseif ($null -ne $Message.payload.PSObject.Properties["success_criteria"]) {
    $Deliverables = @($Message.payload.success_criteria)
}

if ($Deliverables.Count -lt 1) {
    $Deliverables = @(
        "Review the assigned request",
        "Produce the required output",
        "Return a result to the Chief of Staff"
    )
}

$RiskLevel = "medium"
$ApprovalStatus = "not_required"

if ($null -ne $Message.payload.PSObject.Properties["risk_level"]) {
    $RiskLevel = [string]$Message.payload.risk_level
}

if ($null -ne $Message.payload.PSObject.Properties["approval_status"]) {
    $ApprovalStatus = [string]$Message.payload.approval_status
}

$Now = (Get-Date).ToString("o")
$WorkItemId = New-AIOfficeDepartmentWorkItemId

$WorkItem = [ordered]@{
    work_item_id = $WorkItemId
    department = $Department
    source_message_id = $MessageId
    title = $Title
    objective = $Objective
    deliverables = $Deliverables
    priority = [string]$Message.priority
    risk_level = $RiskLevel
    approval_status = $ApprovalStatus
    status = if ([bool]$Classification.accepted) { "queued" } else { "capability_review" }
    workflow_id = [string]$Message.workflow_id
    conversation_id = [string]$Message.conversation_id
    correlation_id = [string]$Message.correlation_id
    created_at = $Now
    updated_at = $Now
    matched_capabilities = @($Classification.matched_capabilities)
    missing_capabilities = @($Classification.missing_capabilities)
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = $Department
            details = "Department work item created from Message Bus intake."
        }
    )
}

$Path = Join-Path `
    ".\workspace\departments\$Department\work" `
    ($WorkItemId + ".json")

Write-AIOfficeDepartmentJson -Value $WorkItem -Path $Path

Write-Host "Department work item created: $WorkItemId" `
    -ForegroundColor Green

return [pscustomobject]$WorkItem
'@

Write-NewFile ".\scripts\departments\New-AIOfficeDepartmentWorkItem.ps1" $NewWork

$ProcessInbox = @'
param(
    [Parameter(Mandatory=$true)][string]$Department,
    [int]$Limit = 10
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentInbox.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$Policy = Get-AIOfficeDepartmentInboxPolicy

if ($Limit -lt 1) {
    $Limit = 1
}

if ($Limit -gt [int]$Policy.intake.maximum_limit) {
    $Limit = [int]$Policy.intake.maximum_limit
}

$Results = New-Object System.Collections.Generic.List[object]

for ($Index = 0; $Index -lt $Limit; $Index++) {
    $Message = & ".\scripts\messaging\Receive-AIOfficeMessage.ps1" `
        -Queue "outbox" `
        -Recipient $Department

    if ($null -eq $Message) {
        break
    }

    try {
        $WorkItem = & ".\scripts\departments\New-AIOfficeDepartmentWorkItem.ps1" `
            -Department $Department `
            -MessageId ([string]$Message.message_id)

        $Record = [ordered]@{
            processed_at = (Get-Date).ToString("o")
            department = $Department
            message_id = [string]$Message.message_id
            work_item_id = [string]$WorkItem.work_item_id
            status = "accepted"
        }

        Write-AIOfficeDepartmentJson `
            -Value $Record `
            -Path (
                ".\workspace\departments\" +
                $Department +
                "\processed-inbox\" +
                [string]$Message.message_id +
                ".json"
            )

        & ".\scripts\messaging\Complete-AIOfficeMessage.ps1" `
            -MessageId ([string]$Message.message_id) `
            -Actor $Department `
            -Details "Department work intake completed." |
            Out-Null

        $Results.Add([pscustomobject]$Record)
    }
    catch {
        $Failure = [ordered]@{
            failed_at = (Get-Date).ToString("o")
            department = $Department
            message_id = [string]$Message.message_id
            error = $_.Exception.Message
        }

        Write-AIOfficeDepartmentJson `
            -Value $Failure `
            -Path (
                ".\workspace\departments\" +
                $Department +
                "\failed-inbox\" +
                [string]$Message.message_id +
                ".json"
            )

        try {
            & ".\scripts\messaging\Fail-AIOfficeMessage.ps1" `
                -MessageId ([string]$Message.message_id) `
                -Reason $_.Exception.Message `
                -Actor $Department |
                Out-Null
        }
        catch {
        }

        $Results.Add([pscustomobject]@{
            processed_at = (Get-Date).ToString("o")
            department = $Department
            message_id = [string]$Message.message_id
            work_item_id = ""
            status = "failed"
        })
    }
}

& ".\scripts\departments\Update-AIOfficeDepartmentIndex.ps1" |
    Out-Null

return @($Results | ForEach-Object { $_ })
'@

Write-NewFile ".\scripts\departments\Invoke-AIOfficeDepartmentInbox.ps1" $ProcessInbox

$SearchWork = @'
param(
    [Parameter(Mandatory=$true)][string]$Department,
    [string]$Status = "",
    [string]$Priority = "",
    [string]$RiskLevel = "",
    [int]$Limit = 100
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartments.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$Results = New-Object System.Collections.Generic.List[object]

foreach ($File in @(
    Get-ChildItem `
        -LiteralPath ".\workspace\departments\$Department\work" `
        -Filter "DWI-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)) {
    $WorkItem = Read-AIOfficeDepartmentJson -Path $File.FullName

    if ($null -eq $WorkItem) {
        continue
    }

    if ($Status -and [string]$WorkItem.status -ne $Status) {
        continue
    }

    if ($Priority -and [string]$WorkItem.priority -ne $Priority) {
        continue
    }

    if ($RiskLevel -and [string]$WorkItem.risk_level -ne $RiskLevel) {
        continue
    }

    $Results.Add([pscustomobject]@{
        work_item_id = [string]$WorkItem.work_item_id
        department = [string]$WorkItem.department
        title = [string]$WorkItem.title
        priority = [string]$WorkItem.priority
        risk_level = [string]$WorkItem.risk_level
        approval_status = [string]$WorkItem.approval_status
        status = [string]$WorkItem.status
        source_message_id = [string]$WorkItem.source_message_id
        created_at = [string]$WorkItem.created_at
    })
}

return @(
    $Results |
        Sort-Object created_at -Descending |
        Select-Object -First $Limit
)
'@

Write-NewFile ".\scripts\departments\Search-AIOfficeDepartmentWork.ps1" $SearchWork

$Test = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.2 Part B Department Inbox and Work Intake..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\departments\department-inbox-policy.json",
    ".\config\departments\department-work-item-schema.json",
    ".\config\departments\department-intake-classification-schema.json",
    ".\workspace\templates\department-work-item-template.json"
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
    ".\scripts\departments\AIOfficeDepartmentInbox.Common.ps1",
    ".\scripts\departments\Test-AIOfficeDepartmentWorkAcceptance.ps1",
    ".\scripts\departments\New-AIOfficeDepartmentWorkItem.ps1",
    ".\scripts\departments\Invoke-AIOfficeDepartmentInbox.ps1",
    ".\scripts\departments\Search-AIOfficeDepartmentWork.ps1",
    ".\scripts\departments\Test-AIOfficeDepartmentInbox.ps1"
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

$MessageId = ""
$WorkItemId = ""

try {
    $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "chief-of-staff" `
        -To "marketing" `
        -MessageType "handoff" `
        -Priority "high" `
        -Subject "Create dealership campaign plan" `
        -ConversationTopic "DEPT-INBOX-TEST" `
        -Queue "outbox" `
        -PayloadJson '{"objective":"Create an August dealership campaign.","deliverables":["Campaign strategy","Offer structure"],"required_capabilities":["campaign_strategy","marketing_copy"],"risk_level":"low","approval_status":"not_required"}'

    $MessageId = [string]$Message.message_id

    $Results = @(
        & ".\scripts\departments\Invoke-AIOfficeDepartmentInbox.ps1" `
            -Department "marketing" `
            -Limit 1
    )

    if ($Results.Count -ne 1 -or
        [string]::IsNullOrWhiteSpace([string]$Results[0].work_item_id)) {
        throw "Department inbox did not create a work item."
    }

    $WorkItemId = [string]$Results[0].work_item_id

    Write-Host "[INBOX OK   ] $WorkItemId" -ForegroundColor Green
}
catch {
    Write-Host "[INBOX ERR  ] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Department inbox failed: " + $_.Exception.Message)
}

try {
    $Work = @(
        & ".\scripts\departments\Search-AIOfficeDepartmentWork.ps1" `
            -Department "marketing"
    )

    if ($Work.Count -lt 1) {
        throw "Department work search returned no records."
    }

    Write-Host (
        "[WORK OK    ] " +
        $Work.Count.ToString() +
        " work item(s)"
    ) -ForegroundColor Green
}
catch {
    Write-Host "[WORK ERR   ] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Department work search failed: " + $_.Exception.Message)
}

if ($WorkItemId) {
    $Path = ".\workspace\departments\marketing\work\$WorkItemId.json"

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

Get-ChildItem `
    -LiteralPath ".\workspace\departments\marketing\classifications" `
    -Filter "DCL-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    ForEach-Object {
        $Record = Get-Content -LiteralPath $_.FullName -Raw |
            ConvertFrom-Json

        if ([string]$Record.message_id -eq $MessageId) {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }

foreach ($Folder in @(
    ".\workspace\departments\marketing\processed-inbox",
    ".\workspace\departments\marketing\failed-inbox"
)) {
    $Path = Join-Path $Folder ($MessageId + ".json")

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

if ($MessageId) {
    foreach ($Queue in @(
        "inbox",
        "outbox",
        "processing",
        "processed",
        "failed",
        "dead-letter",
        "archive"
    )) {
        $Path = ".\workspace\messages\$Queue\$MessageId.json"

        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            Remove-Item -LiteralPath $Path -Force
        }
    }
}

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
    Out-Null

& ".\scripts\departments\Update-AIOfficeDepartmentIndex.ps1" |
    Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Department Inbox and Work Intake error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.2 Part B Department Inbox and Work Intake checks passed." `
    -ForegroundColor Green
'@

Write-NewFile ".\scripts\departments\Test-AIOfficeDepartmentInbox.ps1" $Test

$Guide = @'
# AI Office v1.2 Part B — Department Inbox and Work Intake

Part B connects each department to the AI Office Message Bus and turns handoffs into persistent department work items.

## Added

- Department inbox policy
- Capability-based intake classification
- Work-item creation
- Department inbox processing
- Processed and failed inbox records
- Work search
- Message completion and failure handling
- Department index updates
- Full validation

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\departments\Test-AIOfficeDepartmentInbox.ps1"
```

Expected result:

```text
All AI Office v1.2 Part B Department Inbox and Work Intake checks passed.
```

## Process a department inbox

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\departments\Invoke-AIOfficeDepartmentInbox.ps1" `
    -Department "marketing" `
    -Limit 10
```

## Search department work

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\departments\Search-AIOfficeDepartmentWork.ps1" `
    -Department "marketing"
```

## Next

Part C will add department planning, execution modes, cross-department handoffs, result publication, and Chief of Staff reporting.
'@

Write-NewFile ".\docs\AI-Office-v1.2-Part-B-Department-Inbox-Work-Intake.md" $Guide

$ReleaseNotes = @'
# AI Office v1.2 Part B Release Notes

## Release

Department Inbox and Work Intake

## Added

- Message Bus intake for all departments
- Capability matching
- Intake classification
- Persistent work items
- Processed and failed inbox records
- Work-item search
- Validation suite

## Next

v1.2 Part C — Department Planning and Execution
'@

Write-NewFile ".\docs\AI-Office-v1.2-Part-B-Release-Notes.md" $ReleaseNotes

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw |
        ConvertFrom-Json

    $Version.version = "1.2.0"
    $Version.release_name = "Department Intelligence"
    $Version.status = "part_b_installed"
    $Version.installed_at = (Get-Date).ToString("o")
    $Version.next_planned_milestone = "1.2 Part C Department Planning and Execution"

    $Version |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $VersionPath -Encoding UTF8

    Write-Host "[UPDATED] Identity release metadata set to v1.2 Part B" `
        -ForegroundColor Green
}

Write-Host ""
Write-Host "Validating Part B JSON files..." -ForegroundColor Cyan

@(
    ".\config\departments\department-inbox-policy.json",
    ".\config\departments\department-work-item-schema.json",
    ".\config\departments\department-intake-classification-schema.json",
    ".\workspace\templates\department-work-item-template.json"
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
        "Installers\AI-Office-v1.2-Part-B-Department-Inbox-Work-Intake-Install.ps1"

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
Write-Host "AI Office v1.2 Part B installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\departments\Test-AIOfficeDepartmentInbox.ps1"'
Write-Host ""
