# ============================================================
# AI Office v1.2 - Part A
# Department Intelligence Architecture
# Repository: E:\AI\AI-Office
# Requires: AI Office v1.1.4 Chief of Staff Integration
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

$RequiredPrevious = @(
    ".\config\identity\office.json",
    ".\config\chief-of-staff\release-manifest.json",
    ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffDispatch.ps1",
    ".\scripts\messaging\New-AIOfficeMessage.ps1",
    ".\scripts\collaboration\New-AIOfficeAgent.ps1"
)

foreach ($RequiredPath in $RequiredPrevious) {
    if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
        throw "AI Office v1.1.4 is required. Missing: $RequiredPath"
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
    ".\config\departments",
    ".\workspace\departments",
    ".\workspace\departments\index",
    ".\workspace\departments\shared-context",
    ".\workspace\departments\certification",
    ".\workspace\templates",
    ".\scripts\departments",
    ".\docs",
    ".\Installers"
) | ForEach-Object { Ensure-Directory $_ }

foreach ($Department in $Departments) {
    @(
        ".\config\departments\$Department",
        ".\workspace\departments\$Department",
        ".\workspace\departments\$Department\inbox",
        ".\workspace\departments\$Department\plans",
        ".\workspace\departments\$Department\work",
        ".\workspace\departments\$Department\knowledge",
        ".\workspace\departments\$Department\reports",
        ".\workspace\departments\$Department\history"
    ) | ForEach-Object { Ensure-Directory $_ }
}

$Now = (Get-Date).ToString("o")

$DepartmentPolicy = @"
{
  "schema_version": "1.0.0",
  "version": "1.2.0",
  "part": "A",
  "departments": [
    "marketing",
    "creative",
    "website",
    "analytics",
    "finance",
    "business",
    "side-hustles",
    "youtube",
    "personal-assistant"
  ],
  "governance": {
    "reports_to": "chief-of-staff",
    "require_message_bus": true,
    "require_department_identity": true,
    "require_capability_match": true,
    "require_audit_history": true,
    "allow_cross_department_handoffs": true,
    "allow_openclaw_dispatch": true
  },
  "operating_model": {
    "default_status": "ready",
    "default_priority": "normal",
    "maximum_open_work_items_per_department": 100,
    "maximum_active_agents_per_department": 10
  },
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\departments\department-intelligence-policy.json" $DepartmentPolicy

$DepartmentSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/department-profile-schema.json",
  "title": "AI Office Department Profile",
  "type": "object",
  "required": [
    "department_id",
    "name",
    "version",
    "status",
    "reports_to",
    "mission",
    "capabilities",
    "responsibilities",
    "kpis",
    "created_at",
    "updated_at"
  ]
}
'@

Write-NewFile ".\config\departments\department-profile-schema.json" $DepartmentSchema

$CapabilitySchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/department-capability-schema.json",
  "title": "AI Office Department Capability",
  "type": "object",
  "required": [
    "capability_id",
    "department",
    "name",
    "description",
    "risk_level",
    "approval_required",
    "execution_modes"
  ]
}
'@

Write-NewFile ".\config\departments\department-capability-schema.json" $CapabilitySchema

$Profiles = @{
    "marketing" = @{
        Name = "Marketing Department"
        Mission = "Plan, execute, and optimize dealership and business marketing initiatives."
        Capabilities = @(
            "campaign_strategy",
            "google_ads",
            "meta_ads",
            "email_marketing",
            "seo",
            "vendor_management",
            "offer_development",
            "marketing_copy"
        )
        Responsibilities = @(
            "Dealership campaign planning",
            "Paid media strategy",
            "Promotional offer packaging",
            "Email and social campaign development",
            "Marketing vendor coordination"
        )
        KPIs = @(
            "cost_per_lead",
            "conversion_rate",
            "impression_share",
            "return_on_ad_spend",
            "lead_volume"
        )
    }
    "creative" = @{
        Name = "Creative Studio"
        Mission = "Produce branded visual and multimedia assets for AI Office projects."
        Capabilities = @(
            "graphic_design",
            "image_generation",
            "claymation_campaigns",
            "video_concepts",
            "brand_systems",
            "print_assets",
            "social_assets"
        )
        Responsibilities = @(
            "Campaign creative",
            "Brand consistency",
            "Image-generation prompts",
            "Web and social assets",
            "Production-ready visual specifications"
        )
        KPIs = @(
            "asset_turnaround_time",
            "revision_rate",
            "brand_compliance",
            "asset_completion_rate"
        )
    }
    "website" = @{
        Name = "Website Department"
        Mission = "Build, maintain, and optimize dealership and business web experiences."
        Capabilities = @(
            "html",
            "css",
            "javascript",
            "dealer_dot_com",
            "dealeron",
            "wordpress",
            "accessibility",
            "conversion_optimization",
            "technical_website_support"
        )
        Responsibilities = @(
            "Website content deployment",
            "Landing page implementation",
            "Platform-safe code",
            "Accessibility compliance",
            "Conversion-path improvements"
        )
        KPIs = @(
            "page_speed",
            "conversion_rate",
            "accessibility_score",
            "deployment_success_rate",
            "error_rate"
        )
    }
    "analytics" = @{
        Name = "Analytics Department"
        Mission = "Measure performance, diagnose tracking, and produce decision-ready reporting."
        Capabilities = @(
            "ga4",
            "google_tag_manager",
            "meta_pixel",
            "conversion_tracking",
            "looker_studio",
            "attribution",
            "campaign_analysis",
            "executive_reporting"
        )
        Responsibilities = @(
            "Tracking implementation",
            "Conversion diagnostics",
            "KPI reporting",
            "Attribution review",
            "Executive insights"
        )
        KPIs = @(
            "tracking_accuracy",
            "report_freshness",
            "conversion_coverage",
            "data_quality",
            "issue_resolution_time"
        )
    }
    "finance" = @{
        Name = "Finance Department"
        Mission = "Support personal and business financial planning, tracking, and decision-making."
        Capabilities = @(
            "budgeting",
            "cash_flow",
            "expense_tracking",
            "income_tracking",
            "side_hustle_finance",
            "savings_plans",
            "vehicle_fund_planning",
            "operating_cost_analysis"
        )
        Responsibilities = @(
            "Budget management",
            "Cash-flow forecasting",
            "Savings-goal tracking",
            "Side-hustle profitability",
            "Financial decision support"
        )
        KPIs = @(
            "monthly_surplus",
            "savings_rate",
            "goal_progress",
            "side_hustle_margin",
            "budget_variance"
        )
    }
    "business" = @{
        Name = "Business Incubator"
        Mission = "Evaluate, plan, and develop new business opportunities."
        Capabilities = @(
            "business_planning",
            "pricing",
            "proposal_creation",
            "opportunity_scoring",
            "service_design",
            "client_workflows",
            "revenue_modeling"
        )
        Responsibilities = @(
            "Business idea evaluation",
            "Offer design",
            "Proposal development",
            "Pricing support",
            "Opportunity prioritization"
        )
        KPIs = @(
            "qualified_opportunities",
            "proposal_conversion_rate",
            "project_margin",
            "time_to_launch"
        )
    }
    "side-hustles" = @{
        Name = "Side Hustles Department"
        Mission = "Track, optimize, and recommend flexible income opportunities."
        Capabilities = @(
            "user_testing_tracking",
            "user_interviews_tracking",
            "doordash_analysis",
            "gig_profitability",
            "opportunity_recommendations",
            "schedule_optimization"
        )
        Responsibilities = @(
            "Platform tracking",
            "Income analysis",
            "Opportunity ranking",
            "Time-to-income optimization",
            "Weekly side-hustle recommendations"
        )
        KPIs = @(
            "hourly_income",
            "weekly_income",
            "acceptance_rate",
            "payout_pipeline",
            "time_efficiency"
        )
    }
    "youtube" = @{
        Name = "YouTube Studio"
        Mission = "Develop and operate scalable AI-assisted YouTube channels."
        Capabilities = @(
            "channel_strategy",
            "topic_research",
            "script_development",
            "thumbnail_planning",
            "production_workflows",
            "publishing_calendars",
            "performance_analysis"
        )
        Responsibilities = @(
            "Channel development",
            "Content planning",
            "Script workflows",
            "Thumbnail strategy",
            "Performance optimization"
        )
        KPIs = @(
            "videos_published",
            "watch_time",
            "click_through_rate",
            "subscriber_growth",
            "revenue"
        )
    }
    "personal-assistant" = @{
        Name = "Personal Assistant"
        Mission = "Coordinate personal scheduling, household priorities, reminders, and life administration."
        Capabilities = @(
            "calendar_management",
            "reminders",
            "household_planning",
            "family_scheduling",
            "shopping_plans",
            "travel_planning",
            "personal_project_tracking"
        )
        Responsibilities = @(
            "Calendar coordination",
            "Reminder management",
            "Household planning",
            "Personal task organization",
            "Family logistics"
        )
        KPIs = @(
            "task_completion_rate",
            "missed_deadlines",
            "schedule_conflicts",
            "reminder_success_rate"
        )
    }
}

foreach ($Department in $Departments) {
    $Profile = $Profiles[$Department]

    $DepartmentId = (
        "DEPT-" +
        $Department.ToUpperInvariant().Replace("-", "_")
    )

    $ProfileJson = [ordered]@{
        schema_version = "1.0.0"
        department_id = $DepartmentId
        slug = $Department
        name = $Profile.Name
        version = "1.2.0"
        status = "ready"
        reports_to = "chief-of-staff"
        mission = $Profile.Mission
        capabilities = $Profile.Capabilities
        responsibilities = $Profile.Responsibilities
        kpis = $Profile.KPIs
        execution_modes = @(
            "internal_reasoning",
            "message_bus",
            "openclaw_bridge"
        )
        created_at = $Now
        updated_at = $Now
    } | ConvertTo-Json -Depth 20

    Write-NewFile ".\config\departments\$Department\department-profile.json" $ProfileJson

    $CapabilityRecords = @()

    foreach ($Capability in $Profile.Capabilities) {
        $CapabilityRecords += [ordered]@{
            capability_id = (
                "CAP-" +
                $Department.ToUpperInvariant().Replace("-", "_") +
                "-" +
                $Capability.ToUpperInvariant()
            )
            department = $Department
            name = $Capability
            description = (
                "Department capability for " +
                $Capability.Replace("_", " ") +
                "."
            )
            risk_level = "medium"
            approval_required = $false
            execution_modes = @(
                "internal_reasoning",
                "message_bus",
                "openclaw_bridge"
            )
        }
    }

    $CapabilitiesJson = [ordered]@{
        schema_version = "1.0.0"
        department = $Department
        version = "1.2.0"
        capabilities = $CapabilityRecords
        updated_at = $Now
    } | ConvertTo-Json -Depth 20

    Write-NewFile ".\config\departments\$Department\capabilities.json" $CapabilitiesJson

    $DepartmentIndex = [ordered]@{
        schema_version = "1.0.0"
        department = $Department
        updated_at = ""
        status = "ready"
        inbox_count = 0
        plan_count = 0
        active_work_count = 0
        knowledge_item_count = 0
        report_count = 0
        latest_work_id = ""
    } | ConvertTo-Json -Depth 10

    Write-NewFile ".\workspace\departments\$Department\department-index.json" $DepartmentIndex
}

$GlobalIndex = @'
{
  "schema_version": "1.0.0",
  "version": "1.2.0",
  "updated_at": "",
  "status": "ready",
  "department_count": 9,
  "active_department_count": 9,
  "total_inbox_count": 0,
  "total_plan_count": 0,
  "total_active_work_count": 0,
  "total_knowledge_item_count": 0,
  "departments": []
}
'@

Write-NewFile ".\workspace\departments\index\department-intelligence-index.json" $GlobalIndex

$ProfileTemplate = @'
{
  "schema_version": "1.0.0",
  "department_id": "DEPT-EXAMPLE",
  "slug": "example",
  "name": "Example Department",
  "version": "1.2.0",
  "status": "ready",
  "reports_to": "chief-of-staff",
  "mission": "",
  "capabilities": [],
  "responsibilities": [],
  "kpis": [],
  "execution_modes": [
    "internal_reasoning",
    "message_bus",
    "openclaw_bridge"
  ],
  "created_at": "",
  "updated_at": ""
}
'@

Write-NewFile ".\workspace\templates\department-profile-template.json" $ProfileTemplate

$Common = @'
$script:AIOfficeDepartmentRoot = $null

function Get-AIOfficeDepartmentRoot {
    if ($script:AIOfficeDepartmentRoot) {
        return $script:AIOfficeDepartmentRoot
    }

    $script:AIOfficeDepartmentRoot = (
        Resolve-Path (Join-Path $PSScriptRoot "..\..")
    ).Path

    return $script:AIOfficeDepartmentRoot
}

function Read-AIOfficeDepartmentJson {
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

function Write-AIOfficeDepartmentJson {
    param(
        [Parameter(Mandatory=$true)]$Value,
        [Parameter(Mandatory=$true)][string]$Path
    )

    $Parent = Split-Path -Parent $Path

    if ($Parent -and -not (Test-Path -LiteralPath $Parent -PathType Container)) {
        New-Item -ItemType Directory -Path $Parent -Force | Out-Null
    }

    $Value |
        ConvertTo-Json -Depth 50 |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-AIOfficeDepartmentPolicy {
    $Root = Get-AIOfficeDepartmentRoot

    return Read-AIOfficeDepartmentJson `
        -Path (Join-Path $Root "config\departments\department-intelligence-policy.json")
}

function Get-AIOfficeDepartmentProfile {
    param([Parameter(Mandatory=$true)][string]$Department)

    $Root = Get-AIOfficeDepartmentRoot
    $Path = Join-Path `
        $Root `
        ("config\departments\" + $Department + "\department-profile.json")

    $Profile = Read-AIOfficeDepartmentJson -Path $Path

    if ($null -eq $Profile) {
        throw "Department profile not found: $Department"
    }

    return $Profile
}

function Test-AIOfficeDepartmentCapability {
    param(
        [Parameter(Mandatory=$true)][string]$Department,
        [Parameter(Mandatory=$true)][string]$Capability
    )

    $Profile = Get-AIOfficeDepartmentProfile -Department $Department

    return @($Profile.capabilities) -contains $Capability
}
'@

Write-NewFile ".\scripts\departments\AIOfficeDepartments.Common.ps1" $Common

$UpdateIndex = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartments.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$Policy = Get-AIOfficeDepartmentPolicy

if ($null -eq $Policy) {
    throw "Department Intelligence policy could not be loaded."
}

$DepartmentRecords = New-Object System.Collections.Generic.List[object]

$TotalInbox = 0
$TotalPlans = 0
$TotalWork = 0
$TotalKnowledge = 0
$ActiveDepartments = 0

foreach ($Department in @($Policy.departments)) {
    $Base = ".\workspace\departments\$Department"

    $Counts = [ordered]@{
        inbox = @(
            Get-ChildItem "$Base\inbox" -File -ErrorAction SilentlyContinue
        ).Count
        plans = @(
            Get-ChildItem "$Base\plans" -File -ErrorAction SilentlyContinue
        ).Count
        work = @(
            Get-ChildItem "$Base\work" -File -ErrorAction SilentlyContinue
        ).Count
        knowledge = @(
            Get-ChildItem "$Base\knowledge" -File -ErrorAction SilentlyContinue
        ).Count
        reports = @(
            Get-ChildItem "$Base\reports" -File -ErrorAction SilentlyContinue
        ).Count
    }

    $LatestWork = @(
        Get-ChildItem "$Base\work" -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
    )

    $Profile = Get-AIOfficeDepartmentProfile -Department $Department

    $Index = [ordered]@{
        schema_version = "1.0.0"
        department = $Department
        updated_at = (Get-Date).ToString("o")
        status = [string]$Profile.status
        inbox_count = [int]$Counts.inbox
        plan_count = [int]$Counts.plans
        active_work_count = [int]$Counts.work
        knowledge_item_count = [int]$Counts.knowledge
        report_count = [int]$Counts.reports
        latest_work_id = if ($LatestWork.Count -gt 0) {
            $LatestWork[0].BaseName
        }
        else {
            ""
        }
    }

    Write-AIOfficeDepartmentJson `
        -Value $Index `
        -Path "$Base\department-index.json"

    $DepartmentRecords.Add([pscustomobject]$Index)

    $TotalInbox += [int]$Counts.inbox
    $TotalPlans += [int]$Counts.plans
    $TotalWork += [int]$Counts.work
    $TotalKnowledge += [int]$Counts.knowledge

    if ([string]$Profile.status -eq "ready") {
        $ActiveDepartments++
    }
}

$Global = [ordered]@{
    schema_version = "1.0.0"
    version = "1.2.0"
    updated_at = (Get-Date).ToString("o")
    status = "ready"
    department_count = $DepartmentRecords.Count
    active_department_count = $ActiveDepartments
    total_inbox_count = $TotalInbox
    total_plan_count = $TotalPlans
    total_active_work_count = $TotalWork
    total_knowledge_item_count = $TotalKnowledge
    departments = @($DepartmentRecords | ForEach-Object { $_ })
}

Write-AIOfficeDepartmentJson `
    -Value $Global `
    -Path ".\workspace\departments\index\department-intelligence-index.json"

Write-Host (
    "Department Intelligence index updated: " +
    $DepartmentRecords.Count.ToString() +
    " department(s)"
) -ForegroundColor Green

return [pscustomobject]$Global
'@

Write-NewFile ".\scripts\departments\Update-AIOfficeDepartmentIndex.ps1" $UpdateIndex

$ShowStatus = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$Index = & ".\scripts\departments\Update-AIOfficeDepartmentIndex.ps1"

Write-Host ""
Write-Host "AI OFFICE DEPARTMENT INTELLIGENCE STATUS" -ForegroundColor Cyan
Write-Host ("=" * 72)
Write-Host ("Departments        : " + [string]$Index.department_count)
Write-Host ("Active departments : " + [string]$Index.active_department_count)
Write-Host ("Inbox items        : " + [string]$Index.total_inbox_count)
Write-Host ("Plans              : " + [string]$Index.total_plan_count)
Write-Host ("Active work        : " + [string]$Index.total_active_work_count)
Write-Host ("Knowledge items    : " + [string]$Index.total_knowledge_item_count)
Write-Host ""

$Index.departments |
    Select-Object `
        department,
        status,
        inbox_count,
        plan_count,
        active_work_count,
        knowledge_item_count |
    Format-Table -AutoSize

return $Index
'@

Write-NewFile ".\scripts\departments\Show-AIOfficeDepartmentStatus.ps1" $ShowStatus

$GetDepartment = @'
param(
    [Parameter(Mandatory=$true)][string]$Department
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartments.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$Profile = Get-AIOfficeDepartmentProfile -Department $Department

$Capabilities = Read-AIOfficeDepartmentJson `
    -Path ".\config\departments\$Department\capabilities.json"

$Index = Read-AIOfficeDepartmentJson `
    -Path ".\workspace\departments\$Department\department-index.json"

return [pscustomobject]@{
    profile = $Profile
    capabilities = $Capabilities
    index = $Index
}
'@

Write-NewFile ".\scripts\departments\Get-AIOfficeDepartment.ps1" $GetDepartment

$Test = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.2 Part A Department Intelligence Architecture..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$RequiredJson = @(
    ".\config\departments\department-intelligence-policy.json",
    ".\config\departments\department-profile-schema.json",
    ".\config\departments\department-capability-schema.json",
    ".\workspace\departments\index\department-intelligence-index.json",
    ".\workspace\templates\department-profile-template.json"
)

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
    $RequiredJson += ".\config\departments\$Department\department-profile.json"
    $RequiredJson += ".\config\departments\$Department\capabilities.json"
    $RequiredJson += ".\workspace\departments\$Department\department-index.json"
}

foreach ($File in $RequiredJson) {
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
    ".\scripts\departments\AIOfficeDepartments.Common.ps1",
    ".\scripts\departments\Update-AIOfficeDepartmentIndex.ps1",
    ".\scripts\departments\Show-AIOfficeDepartmentStatus.ps1",
    ".\scripts\departments\Get-AIOfficeDepartment.ps1",
    ".\scripts\departments\Test-AIOfficeDepartmentArchitecture.ps1"
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
    . ".\scripts\departments\AIOfficeDepartments.Common.ps1"

    $Marketing = & ".\scripts\departments\Get-AIOfficeDepartment.ps1" `
        -Department "marketing"

    if ($null -eq $Marketing -or
        [string]$Marketing.profile.slug -ne "marketing" -or
        -not (
            Test-AIOfficeDepartmentCapability `
                -Department "marketing" `
                -Capability "google_ads"
        )) {
        throw "Marketing department profile validation failed."
    }

    Write-Host "[PROFILE OK ] Marketing Department" `
        -ForegroundColor Green
}
catch {
    Write-Host "[PROFILE ERR] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Department profile test failed: " + $_.Exception.Message)
}

try {
    $Index = & ".\scripts\departments\Update-AIOfficeDepartmentIndex.ps1"

    if ($null -eq $Index -or
        [int]$Index.department_count -ne 9 -or
        [int]$Index.active_department_count -ne 9) {
        throw "Department index did not contain nine active departments."
    }

    Write-Host (
        "[INDEX OK   ] " +
        [string]$Index.department_count +
        " departments"
    ) -ForegroundColor Green
}
catch {
    Write-Host "[INDEX ERR  ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Department index failed: " + $_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Department Intelligence architecture error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.2 Part A Department Intelligence Architecture checks passed." `
    -ForegroundColor Green
'@

Write-NewFile ".\scripts\departments\Test-AIOfficeDepartmentArchitecture.ps1" $Test

$Guide = @'
# AI Office v1.2 Part A — Department Intelligence Architecture

Part A creates the formal operating structure for nine intelligent AI Office departments.

## Departments installed

- Marketing
- Creative
- Website
- Analytics
- Finance
- Business Incubator
- Side Hustles
- YouTube Studio
- Personal Assistant

## Added

- Department Intelligence governance
- Department profiles
- Capability registries
- Responsibilities
- KPIs
- Department workspaces
- Department status indexes
- Global Department Intelligence index
- Department lookup
- Capability validation
- Full architecture validation

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\departments\Test-AIOfficeDepartmentArchitecture.ps1"
```

Expected result:

```text
All AI Office v1.2 Part A Department Intelligence Architecture checks passed.
```

## Show department status

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\departments\Show-AIOfficeDepartmentStatus.ps1"
```

## Inspect one department

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\departments\Get-AIOfficeDepartment.ps1" `
    -Department "marketing"
```

## Next

Part B will add department inboxes, work-item intake, capability-based acceptance, planning, and Chief of Staff handoffs.
'@

Write-NewFile ".\docs\AI-Office-v1.2-Part-A-Department-Intelligence-Architecture.md" $Guide

$ReleaseNotes = @'
# AI Office v1.2 Part A Release Notes

## Release

Department Intelligence Architecture

## Added

- Nine intelligent department profiles
- Capability registries
- Department responsibilities
- KPI definitions
- Department workspaces
- Department status indexes
- Global Department Intelligence index
- Validation suite

## Next

v1.2 Part B — Department Inbox and Work Intake
'@

Write-NewFile ".\docs\AI-Office-v1.2-Part-A-Release-Notes.md" $ReleaseNotes

$IdentityPath = ".\config\identity\office.json"

if (Test-Path -LiteralPath $IdentityPath -PathType Leaf) {
    $Identity = Get-Content -LiteralPath $IdentityPath -Raw |
        ConvertFrom-Json

    $Identity.version = "1.2.0"
    $Identity.codename = "Department Intelligence"
    $Identity.updated_at = (Get-Date).ToString("o")

    $Identity |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $IdentityPath -Encoding UTF8

    Write-Host "[UPDATED] AI Office identity version set to 1.2.0" `
        -ForegroundColor Green
}

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw |
        ConvertFrom-Json

    $Version.version = "1.2.0"
    $Version.release_name = "Department Intelligence"
    $Version.status = "part_a_installed"
    $Version.installed_at = (Get-Date).ToString("o")
    $Version.previous_version = "1.1.4"
    $Version.next_planned_milestone = "1.2 Part B Department Inbox and Work Intake"

    $Version |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $VersionPath -Encoding UTF8

    Write-Host "[UPDATED] Identity release metadata set to v1.2 Part A" `
        -ForegroundColor Green
}

Write-Host ""
Write-Host "Validating Part A JSON files..." -ForegroundColor Cyan

Get-Content `
    ".\config\departments\department-intelligence-policy.json" `
    -Raw |
    ConvertFrom-Json |
    Out-Null

Write-Host "[VALID JSON] Department Intelligence policy" `
    -ForegroundColor Green

try {
    $Source = $MyInvocation.MyCommand.Path
    $Destination = Join-Path `
        $Repository `
        "Installers\AI-Office-v1.2-Part-A-Department-Intelligence-Architecture-Install.ps1"

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
Write-Host "AI Office v1.2 Part A installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\departments\Test-AIOfficeDepartmentArchitecture.ps1"'
Write-Host ""
