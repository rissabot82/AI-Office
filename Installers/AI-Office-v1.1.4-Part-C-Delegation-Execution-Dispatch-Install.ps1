# ============================================================
# AI Office v1.1.4 - Part C
# Delegation and Execution Dispatch
# Repository: E:\AI\AI-Office
# Requires: v1.1.4 Parts A and B
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

$RequiredPrevious = @(
    ".\config\chief-of-staff\chief-of-staff-policy.json",
    ".\config\chief-of-staff\inbox-policy.json",
    ".\scripts\chief-of-staff\AIOfficeChiefOfStaff.Common.ps1",
    ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffPlan.ps1",
    ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffPlanFromMessage.ps1",
    ".\scripts\chief-of-staff\Search-AIOfficeChiefOfStaffPlans.ps1",
    ".\scripts\messaging\New-AIOfficeMessage.ps1",
    ".\scripts\bridge\New-AIOfficeBridgeRequest.ps1"
)

foreach ($RequiredPath in $RequiredPrevious) {
    if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
        throw "AI Office v1.1.4 Parts A and B are required. Missing: $RequiredPath"
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
    ".\workspace\chief-of-staff\routing",
    ".\workspace\chief-of-staff\dispatch",
    ".\workspace\chief-of-staff\work-packages",
    ".\workspace\chief-of-staff\execution-monitor",
    ".\workspace\chief-of-staff\escalations"
) | ForEach-Object { Ensure-Directory $_ }

$Now = (Get-Date).ToString("o")

$DelegationPolicy = @"
{
  "schema_version": "1.0.0",
  "version": "1.1.4",
  "part": "C",
  "routing": {
    "default_department": "executive",
    "openclaw_department": "openclaw-bridge",
    "department_keywords": {
      "marketing": [
        "campaign",
        "facebook",
        "meta",
        "google ads",
        "email",
        "seo",
        "promotion",
        "sale",
        "offer"
      ],
      "creative": [
        "image",
        "graphic",
        "banner",
        "claymation",
        "design",
        "video",
        "logo",
        "creative"
      ],
      "website": [
        "website",
        "landing page",
        "html",
        "css",
        "dealer.com",
        "dealeron",
        "wordpress",
        "page"
      ],
      "analytics": [
        "analytics",
        "tracking",
        "conversion",
        "gtm",
        "ga4",
        "pixel",
        "report",
        "dashboard"
      ],
      "finance": [
        "budget",
        "cash flow",
        "financial",
        "expense",
        "income",
        "savings",
        "debt"
      ],
      "business": [
        "pricing",
        "proposal",
        "business plan",
        "client",
        "side project",
        "quote"
      ],
      "side-hustles": [
        "doordash",
        "user testing",
        "userinterviews",
        "side hustle",
        "gig"
      ],
      "youtube": [
        "youtube",
        "channel",
        "video script",
        "thumbnail",
        "content plan"
      ],
      "personal-assistant": [
        "appointment",
        "reminder",
        "calendar",
        "personal",
        "schedule"
      ],
      "openclaw-bridge": [
        "browser",
        "execute",
        "openclaw",
        "screen",
        "system",
        "automation"
      ]
    }
  },
  "delegation": {
    "create_work_package": true,
    "create_message": true,
    "maximum_departments_per_plan": 8,
    "maximum_steps_per_work_package": 25,
    "require_approval_before_dispatch_for": [
      "high",
      "critical"
    ]
  },
  "dispatch": {
    "message_type": "handoff",
    "queue": "outbox",
    "openclaw_message_type": "execution_request",
    "execution_status": "queued"
  },
  "monitoring": {
    "stale_after_hours": 24,
    "escalate_after_hours": 48,
    "critical_escalation_after_hours": 4
  },
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\chief-of-staff\delegation-policy.json" $DelegationPolicy

$DelegationSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/chief-of-staff-delegation-schema.json",
  "title": "AI Office Chief of Staff Delegation",
  "type": "object",
  "required": [
    "delegation_id",
    "plan_id",
    "department",
    "assigned_to",
    "status",
    "priority",
    "risk_level",
    "approval_status",
    "created_at",
    "updated_at",
    "work_package_id",
    "message_id",
    "history"
  ]
}
'@

Write-NewFile ".\config\chief-of-staff\delegation-schema.json" $DelegationSchema

$WorkPackageSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/chief-of-staff-work-package-schema.json",
  "title": "AI Office Chief of Staff Work Package",
  "type": "object",
  "required": [
    "work_package_id",
    "plan_id",
    "department",
    "title",
    "objective",
    "deliverables",
    "priority",
    "risk_level",
    "approval_status",
    "status",
    "created_at",
    "updated_at"
  ]
}
'@

Write-NewFile ".\config\chief-of-staff\work-package-schema.json" $WorkPackageSchema

$DelegationTemplate = @'
{
  "delegation_id": "DLG-YYYYMMDD-HHMMSS-ABC123",
  "plan_id": "PLAN-YYYYMMDD-HHMMSS-ABC123",
  "department": "marketing",
  "assigned_to": "marketing",
  "status": "queued",
  "priority": "normal",
  "risk_level": "medium",
  "approval_status": "not_required",
  "created_at": "",
  "updated_at": "",
  "work_package_id": "WPK-YYYYMMDD-HHMMSS-ABC123",
  "message_id": "",
  "history": []
}
'@

Write-NewFile ".\workspace\templates\chief-of-staff-delegation-template.json" $DelegationTemplate

$WorkPackageTemplate = @'
{
  "work_package_id": "WPK-YYYYMMDD-HHMMSS-ABC123",
  "plan_id": "PLAN-YYYYMMDD-HHMMSS-ABC123",
  "department": "marketing",
  "title": "",
  "objective": "",
  "deliverables": [],
  "priority": "normal",
  "risk_level": "medium",
  "approval_status": "not_required",
  "status": "draft",
  "created_at": "",
  "updated_at": "",
  "steps": []
}
'@

Write-NewFile ".\workspace\templates\chief-of-staff-work-package-template.json" $WorkPackageTemplate

$Common = @'
. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaff.Common.ps1")

function Get-AIOfficeChiefOfStaffDelegationPolicy {
    $Root = Get-AIOfficeChiefOfStaffRoot

    return Read-AIOfficeChiefOfStaffJson `
        -Path (Join-Path $Root "config\chief-of-staff\delegation-policy.json")
}

function New-AIOfficeChiefOfStaffDelegationId {
    return (
        "DLG-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeChiefOfStaffWorkPackageId {
    return (
        "WPK-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeChiefOfStaffPlan {
    param([Parameter(Mandatory=$true)][string]$PlanId)

    $Root = Get-AIOfficeChiefOfStaffRoot
    $Path = Join-Path `
        $Root `
        ("workspace\chief-of-staff\plans\" + $PlanId + ".json")

    $Plan = Read-AIOfficeChiefOfStaffJson -Path $Path

    if ($null -eq $Plan) {
        throw "Chief of Staff plan not found: $PlanId"
    }

    return $Plan
}

function Get-AIOfficeChiefOfStaffDepartment {
    param(
        [Parameter(Mandatory=$true)][string]$Text
    )

    $Policy = Get-AIOfficeChiefOfStaffDelegationPolicy

    if ($null -eq $Policy) {
        throw "Chief of Staff delegation policy could not be loaded."
    }

    $LowerText = $Text.ToLowerInvariant()
    $Scores = @{}

    foreach ($Property in $Policy.routing.department_keywords.PSObject.Properties) {
        $Score = 0

        foreach ($Keyword in @($Property.Value)) {
            if ($LowerText.Contains(([string]$Keyword).ToLowerInvariant())) {
                $Score++
            }
        }

        $Scores[[string]$Property.Name] = $Score
    }

    $Winner = $Scores.GetEnumerator() |
        Sort-Object Value -Descending |
        Select-Object -First 1

    if ($null -eq $Winner -or [int]$Winner.Value -lt 1) {
        return [string]$Policy.routing.default_department
    }

    return [string]$Winner.Key
}

function Test-AIOfficeChiefOfStaffDispatchAllowed {
    param(
        [Parameter(Mandatory=$true)][string]$RiskLevel,
        [Parameter(Mandatory=$true)][string]$ApprovalStatus
    )

    $Policy = Get-AIOfficeChiefOfStaffDelegationPolicy

    if (@($Policy.delegation.require_approval_before_dispatch_for) -contains
        $RiskLevel) {
        return $ApprovalStatus -eq "approved"
    }

    return $true
}
'@

Write-NewFile ".\scripts\chief-of-staff\AIOfficeChiefOfStaffDelegation.Common.ps1" $Common

$RoutePlan = @'
param(
    [Parameter(Mandatory=$true)][string]$PlanId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffDelegation.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Plan = Get-AIOfficeChiefOfStaffPlan -PlanId $PlanId

$RoutingText = (
    [string]$Plan.title +
    " " +
    [string]$Plan.objective +
    " " +
    ((@($Plan.success_criteria) -join " "))
)

$Department = Get-AIOfficeChiefOfStaffDepartment `
    -Text $RoutingText

$Record = [ordered]@{
    routing_id = (
        "RTE-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
    plan_id = $PlanId
    department = $Department
    routing_text = $RoutingText
    created_at = (Get-Date).ToString("o")
    created_by = "chief-of-staff"
}

$Path = Join-Path `
    ".\workspace\chief-of-staff\routing" `
    ([string]$Record.routing_id + ".json")

Write-AIOfficeChiefOfStaffJson -Value $Record -Path $Path

Write-Host (
    "Plan routed: " +
    $PlanId +
    " -> " +
    $Department
) -ForegroundColor Green

return [pscustomobject]$Record
'@

Write-NewFile ".\scripts\chief-of-staff\Route-AIOfficeChiefOfStaffPlan.ps1" $RoutePlan

$WorkPackage = @'
param(
    [Parameter(Mandatory=$true)][string]$PlanId,
    [string]$Department = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffDelegation.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Plan = Get-AIOfficeChiefOfStaffPlan -PlanId $PlanId

if ([string]::IsNullOrWhiteSpace($Department)) {
    $Route = & ".\scripts\chief-of-staff\Route-AIOfficeChiefOfStaffPlan.ps1" `
        -PlanId $PlanId

    $Department = [string]$Route.department
}

$WorkPackageId = New-AIOfficeChiefOfStaffWorkPackageId
$Now = (Get-Date).ToString("o")

$Deliverables = @($Plan.success_criteria)

$Steps = @(
    [ordered]@{
        step_number = 1
        title = "Review assigned objective"
        owner = $Department
        status = "pending"
    },
    [ordered]@{
        step_number = 2
        title = "Produce required deliverables"
        owner = $Department
        status = "pending"
    },
    [ordered]@{
        step_number = 3
        title = "Return results to Chief of Staff"
        owner = $Department
        status = "pending"
    }
)

$Package = [ordered]@{
    work_package_id = $WorkPackageId
    plan_id = $PlanId
    department = $Department
    title = [string]$Plan.title
    objective = [string]$Plan.objective
    deliverables = $Deliverables
    priority = [string]$Plan.priority
    risk_level = [string]$Plan.risk_level
    approval_status = [string]$Plan.approval_status
    status = "draft"
    created_at = $Now
    updated_at = $Now
    workflow_id = [string]$Plan.workflow_id
    conversation_id = [string]$Plan.conversation_id
    correlation_id = [string]$Plan.correlation_id
    steps = $Steps
}

$Path = Join-Path `
    ".\workspace\chief-of-staff\work-packages" `
    ($WorkPackageId + ".json")

Write-AIOfficeChiefOfStaffJson -Value $Package -Path $Path

Write-Host "Work package created: $WorkPackageId" `
    -ForegroundColor Green

return [pscustomobject]$Package
'@

Write-NewFile ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffWorkPackage.ps1" $WorkPackage

$Delegation = @'
param(
    [Parameter(Mandatory=$true)][string]$PlanId,
    [string]$Department = "",
    [string]$AssignedTo = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffDelegation.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Plan = Get-AIOfficeChiefOfStaffPlan -PlanId $PlanId

$DispatchAllowed = Test-AIOfficeChiefOfStaffDispatchAllowed `
    -RiskLevel ([string]$Plan.risk_level) `
    -ApprovalStatus ([string]$Plan.approval_status)

if (-not $DispatchAllowed) {
    throw (
        "Plan cannot be delegated until approval is granted. " +
        "Risk=" +
        [string]$Plan.risk_level +
        ", approval=" +
        [string]$Plan.approval_status
    )
}

$Package = & ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffWorkPackage.ps1" `
    -PlanId $PlanId `
    -Department $Department

if ([string]::IsNullOrWhiteSpace($AssignedTo)) {
    $AssignedTo = [string]$Package.department
}

$DelegationId = New-AIOfficeChiefOfStaffDelegationId
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    delegation_id = $DelegationId
    plan_id = $PlanId
    department = [string]$Package.department
    assigned_to = $AssignedTo
    status = "queued"
    priority = [string]$Plan.priority
    risk_level = [string]$Plan.risk_level
    approval_status = [string]$Plan.approval_status
    created_at = $Now
    updated_at = $Now
    work_package_id = [string]$Package.work_package_id
    message_id = ""
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = "chief-of-staff"
            details = "Delegation created."
        }
    )
}

$Path = Join-Path `
    ".\workspace\chief-of-staff\delegations" `
    ($DelegationId + ".json")

Write-AIOfficeChiefOfStaffJson -Value $Record -Path $Path

& ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1" |
    Out-Null

Write-Host "Delegation created: $DelegationId" `
    -ForegroundColor Green

return [pscustomobject]$Record
'@

Write-NewFile ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffDelegation.ps1" $Delegation

$Dispatch = @'
param(
    [Parameter(Mandatory=$true)][string]$DelegationId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffDelegation.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$DelegationPath = Join-Path `
    ".\workspace\chief-of-staff\delegations" `
    ($DelegationId + ".json")

$Delegation = Read-AIOfficeChiefOfStaffJson -Path $DelegationPath

if ($null -eq $Delegation) {
    throw "Delegation not found: $DelegationId"
}

$PackagePath = Join-Path `
    ".\workspace\chief-of-staff\work-packages" `
    ([string]$Delegation.work_package_id + ".json")

$Package = Read-AIOfficeChiefOfStaffJson -Path $PackagePath

if ($null -eq $Package) {
    throw "Work package not found: $($Delegation.work_package_id)"
}

$MessageType = "handoff"
$To = [string]$Delegation.assigned_to

if ([string]$Delegation.department -eq "openclaw-bridge") {
    $MessageType = "execution_request"
    $To = "bridge"
}

$Payload = [ordered]@{
    delegation_id = [string]$Delegation.delegation_id
    work_package_id = [string]$Package.work_package_id
    plan_id = [string]$Package.plan_id
    department = [string]$Package.department
    objective = [string]$Package.objective
    deliverables = @($Package.deliverables)
    steps = @($Package.steps)
    risk_level = [string]$Package.risk_level
    approval_status = [string]$Package.approval_status
    action_type = if ([string]$Delegation.department -eq "openclaw-bridge") {
        "agent_task"
    }
    else {
        "department_work"
    }
}

$Arguments = @{
    From = "chief-of-staff"
    To = $To
    MessageType = $MessageType
    Subject = [string]$Package.title
    Priority = [string]$Package.priority
    WorkflowId = [string]$Package.workflow_id
    Queue = "outbox"
    PayloadJson = ($Payload | ConvertTo-Json -Depth 30 -Compress)
}

if (-not [string]::IsNullOrWhiteSpace([string]$Package.correlation_id)) {
    $Arguments.CorrelationId = [string]$Package.correlation_id
}

if (-not [string]::IsNullOrWhiteSpace([string]$Package.conversation_id)) {
    $Arguments.ConversationId = [string]$Package.conversation_id
}

$Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" @Arguments

$Now = (Get-Date).ToString("o")
$Delegation.message_id = [string]$Message.message_id
$Delegation.status = "dispatched"
$Delegation.updated_at = $Now

$History = New-Object System.Collections.Generic.List[object]

foreach ($Entry in @($Delegation.history)) {
    $History.Add($Entry)
}

$History.Add([ordered]@{
    timestamp = $Now
    action = "dispatched"
    actor = "chief-of-staff"
    details = (
        "Delegation dispatched to " +
        $To +
        " through the Message Bus."
    )
})

$Delegation.history = @($History | ForEach-Object { $_ })

Write-AIOfficeChiefOfStaffJson `
    -Value $Delegation `
    -Path $DelegationPath

$Package.status = "dispatched"
$Package.updated_at = $Now

Write-AIOfficeChiefOfStaffJson `
    -Value $Package `
    -Path $PackagePath

$Plan = Get-AIOfficeChiefOfStaffPlan `
    -PlanId ([string]$Delegation.plan_id)

$Plan.status = "in_progress"
$Plan.updated_at = $Now

Write-AIOfficeChiefOfStaffJson `
    -Value $Plan `
    -Path (
        ".\workspace\chief-of-staff\plans\" +
        [string]$Plan.plan_id +
        ".json"
    )

& ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1" |
    Out-Null

Write-Host (
    "Delegation dispatched: " +
    $DelegationId +
    " | message " +
    [string]$Message.message_id
) -ForegroundColor Green

return [pscustomobject]@{
    delegation = $Delegation
    work_package = $Package
    message = $Message
}
'@

Write-NewFile ".\scripts\chief-of-staff\Send-AIOfficeChiefOfStaffDelegation.ps1" $Dispatch

$DispatchPlan = @'
param(
    [Parameter(Mandatory=$true)][string]$PlanId
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$Delegation = & `
    ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffDelegation.ps1" `
    -PlanId $PlanId

return & `
    ".\scripts\chief-of-staff\Send-AIOfficeChiefOfStaffDelegation.ps1" `
    -DelegationId ([string]$Delegation.delegation_id)
'@

Write-NewFile ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffDispatch.ps1" $DispatchPlan

$Monitor = @'
param(
    [switch]$IncludeCompleted
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffDelegation.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Policy = Get-AIOfficeChiefOfStaffDelegationPolicy
$Now = Get-Date
$Results = New-Object System.Collections.Generic.List[object]

foreach ($File in @(
    Get-ChildItem `
        -LiteralPath ".\workspace\chief-of-staff\delegations" `
        -Filter "DLG-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)) {
    $Delegation = Read-AIOfficeChiefOfStaffJson -Path $File.FullName

    if ($null -eq $Delegation) {
        continue
    }

    if (-not $IncludeCompleted -and
        @("completed","cancelled","archived") -contains
        [string]$Delegation.status) {
        continue
    }

    $CreatedAt = [datetime]$Delegation.created_at
    $AgeHours = ($Now - $CreatedAt).TotalHours
    $Stale = $AgeHours -ge [double]$Policy.monitoring.stale_after_hours
    $Escalate = $AgeHours -ge [double]$Policy.monitoring.escalate_after_hours

    if ([string]$Delegation.risk_level -eq "critical") {
        $Escalate = $AgeHours -ge
            [double]$Policy.monitoring.critical_escalation_after_hours
    }

    $Results.Add([pscustomobject]@{
        delegation_id = [string]$Delegation.delegation_id
        plan_id = [string]$Delegation.plan_id
        department = [string]$Delegation.department
        assigned_to = [string]$Delegation.assigned_to
        status = [string]$Delegation.status
        priority = [string]$Delegation.priority
        risk_level = [string]$Delegation.risk_level
        message_id = [string]$Delegation.message_id
        age_hours = [math]::Round($AgeHours, 2)
        stale = $Stale
        escalate = $Escalate
    })
}

return @(
    $Results |
        Sort-Object escalate, stale, priority -Descending
)
'@

Write-NewFile ".\scripts\chief-of-staff\Show-AIOfficeChiefOfStaffDelegations.ps1" $Monitor

$Test = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.4 Part C Delegation and Dispatch..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\chief-of-staff\delegation-policy.json",
    ".\config\chief-of-staff\delegation-schema.json",
    ".\config\chief-of-staff\work-package-schema.json",
    ".\workspace\templates\chief-of-staff-delegation-template.json",
    ".\workspace\templates\chief-of-staff-work-package-template.json"
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
    ".\scripts\chief-of-staff\AIOfficeChiefOfStaffDelegation.Common.ps1",
    ".\scripts\chief-of-staff\Route-AIOfficeChiefOfStaffPlan.ps1",
    ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffWorkPackage.ps1",
    ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffDelegation.ps1",
    ".\scripts\chief-of-staff\Send-AIOfficeChiefOfStaffDelegation.ps1",
    ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffDispatch.ps1",
    ".\scripts\chief-of-staff\Show-AIOfficeChiefOfStaffDelegations.ps1",
    ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaffDelegation.ps1"
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

$PlanId = ""
$DelegationId = ""
$WorkPackageId = ""
$MessageId = ""

try {
    $Plan = & ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffPlan.ps1" `
        -Title "Create Facebook campaign for Elite Auto Sales" `
        -Objective "Create and prepare a dealership Facebook campaign." `
        -SuccessCriteriaJson '["Campaign plan created","Creative assigned","Execution prepared"]' `
        -Priority "high" `
        -RiskLevel "low" `
        -ApprovalStatus "not_required"

    $PlanId = [string]$Plan.plan_id

    $Route = & ".\scripts\chief-of-staff\Route-AIOfficeChiefOfStaffPlan.ps1" `
        -PlanId $PlanId

    if ([string]$Route.department -ne "marketing") {
        throw "Expected marketing route, received $($Route.department)."
    }

    Write-Host "[ROUTE OK   ] $($Route.department)" `
        -ForegroundColor Green
}
catch {
    Write-Host "[ROUTE ERR  ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Routing failed: " + $_.Exception.Message)
}

try {
    $Dispatch = & `
        ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffDispatch.ps1" `
        -PlanId $PlanId

    $DelegationId = [string]$Dispatch.delegation.delegation_id
    $WorkPackageId = [string]$Dispatch.work_package.work_package_id
    $MessageId = [string]$Dispatch.message.message_id

    if ([string]::IsNullOrWhiteSpace($DelegationId) -or
        [string]::IsNullOrWhiteSpace($WorkPackageId) -or
        [string]::IsNullOrWhiteSpace($MessageId)) {
        throw "Dispatch did not produce expected IDs."
    }

    Write-Host (
        "[DISPATCH OK] " +
        $DelegationId +
        " | " +
        $MessageId
    ) -ForegroundColor Green
}
catch {
    Write-Host "[DISPATCH ER] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Dispatch failed: " + $_.Exception.Message)
}

try {
    $Delegations = @(
        & ".\scripts\chief-of-staff\Show-AIOfficeChiefOfStaffDelegations.ps1"
    )

    if ($Delegations.Count -lt 1) {
        throw "Delegation monitor returned no records."
    }

    Write-Host (
        "[MONITOR OK ] " +
        $Delegations.Count.ToString() +
        " delegation(s)"
    ) -ForegroundColor Green
}
catch {
    Write-Host "[MONITOR ER] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Monitoring failed: " + $_.Exception.Message)
}

foreach ($Path in @(
    ".\workspace\chief-of-staff\plans\$PlanId.json",
    ".\workspace\chief-of-staff\delegations\$DelegationId.json",
    ".\workspace\chief-of-staff\work-packages\$WorkPackageId.json"
)) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

Get-ChildItem `
    -LiteralPath ".\workspace\chief-of-staff\routing" `
    -Filter "RTE-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    ForEach-Object {
        $Route = Get-Content -LiteralPath $_.FullName -Raw |
            ConvertFrom-Json

        if ([string]$Route.plan_id -eq $PlanId) {
            Remove-Item -LiteralPath $_.FullName -Force
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

& ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1" |
    Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Delegation and Dispatch error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.4 Part C Delegation and Dispatch checks passed." `
    -ForegroundColor Green
'@

Write-NewFile ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaffDelegation.ps1" $Test

$Guide = @'
# AI Office v1.1.4 Part C — Delegation and Execution Dispatch

Part C turns Chief of Staff plans into routed work packages, delegations, and Message Bus dispatches.

## Added

- Department keyword routing
- Work package generation
- Delegation records
- Approval-gated dispatch
- Department Message Bus handoffs
- OpenClaw Bridge execution requests
- Plan status updates
- Delegation monitoring
- Stale and escalation detection
- Full validation

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaffDelegation.ps1"
```

Expected result:

```text
All AI Office v1.1.4 Part C Delegation and Dispatch checks passed.
```

## Dispatch a plan

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffDispatch.ps1" `
    -PlanId "PLAN-..."
```

## View active delegations

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\chief-of-staff\Show-AIOfficeChiefOfStaffDelegations.ps1"
```

## Next

Part D will add executive review, approval resolution, closed-loop result tracking, plan completion, complete certification, and release publication.
'@

Write-NewFile ".\docs\AI-Office-v1.1.4-Part-C-Delegation-Execution-Dispatch.md" $Guide

$ReleaseNotes = @'
# AI Office v1.1.4 Part C Release Notes

## Release

Delegation and Execution Dispatch

## Added

- Automatic department routing
- Work package generation
- Delegation records
- Approval-gated dispatch
- Message Bus handoffs
- OpenClaw Bridge execution requests
- Plan state updates
- Delegation monitoring
- Escalation detection
- Validation suite

## Next

v1.1.4 Part D — Executive Review and Closed-Loop Completion
'@

Write-NewFile ".\docs\AI-Office-v1.1.4-Part-C-Release-Notes.md" $ReleaseNotes

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw |
        ConvertFrom-Json

    $Version.version = "1.1.4"
    $Version.release_name = "Chief of Staff Integration"
    $Version.status = "part_c_installed"
    $Version.installed_at = (Get-Date).ToString("o")
    $Version.next_planned_milestone = "1.1.4 Part D Executive Review and Completion"

    $Version |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $VersionPath -Encoding UTF8

    Write-Host "[UPDATED] Identity release metadata set to v1.1.4 Part C" `
        -ForegroundColor Green
}

Write-Host ""
Write-Host "Validating Part C JSON files..." -ForegroundColor Cyan

@(
    ".\config\chief-of-staff\delegation-policy.json",
    ".\config\chief-of-staff\delegation-schema.json",
    ".\config\chief-of-staff\work-package-schema.json",
    ".\workspace\templates\chief-of-staff-delegation-template.json",
    ".\workspace\templates\chief-of-staff-work-package-template.json"
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
        "Installers\AI-Office-v1.1.4-Part-C-Delegation-Execution-Dispatch-Install.ps1"

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
Write-Host "AI Office v1.1.4 Part C installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaffDelegation.ps1"'
Write-Host ""
