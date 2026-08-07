param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.0 Part A Autonomous AI Enterprise Architecture..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\autonomous-enterprise\enterprise-policy.json",
    ".\config\autonomous-enterprise\enterprise-work-schema.json",
    ".\config\autonomous-enterprise\enterprise-plan-schema.json",
    ".\config\autonomous-enterprise\enterprise-department-schema.json",
    ".\config\autonomous-enterprise\enterprise-capability-schema.json",
    ".\config\autonomous-enterprise\enterprise-index-schema.json",
    ".\workspace\autonomous-enterprise\indexes\enterprise-index.json",
    ".\workspace\templates\enterprise-work-template.json",
    ".\workspace\templates\enterprise-plan-template.json",
    ".\workspace\templates\enterprise-department-template.json",
    ".\workspace\templates\enterprise-capability-template.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw | ConvertFrom-Json | Out-Null
        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $File" -ForegroundColor Red
        $Errors.Add("Invalid JSON: $File")
    }
}

$Scripts = @(
    ".\scripts\autonomous-enterprise\AIOfficeEnterprise.Common.ps1",
    ".\scripts\autonomous-enterprise\New-AIOfficeEnterpriseDepartment.ps1",
    ".\scripts\autonomous-enterprise\New-AIOfficeEnterpriseCapability.ps1",
    ".\scripts\autonomous-enterprise\New-AIOfficeEnterpriseWork.ps1",
    ".\scripts\autonomous-enterprise\New-AIOfficeEnterprisePlan.ps1",
    ".\scripts\autonomous-enterprise\Initialize-AIOfficeEnterpriseDepartments.ps1",
    ".\scripts\autonomous-enterprise\Update-AIOfficeEnterpriseIndex.ps1",
    ".\scripts\autonomous-enterprise\Show-AIOfficeEnterpriseStatus.ps1",
    ".\scripts\autonomous-enterprise\Test-AIOfficeEnterpriseArchitecture.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING] $Script" -ForegroundColor Red
        $Errors.Add("Missing script: $Script")
    }
}

$Created = New-Object System.Collections.Generic.List[object]

try {
    $Department = & ".\scripts\autonomous-enterprise\New-AIOfficeEnterpriseDepartment.ps1" `
        -Name "certification-enterprise" `
        -CapabilitiesJson '["planning","coordination","review"]'

    $Created.Add([pscustomobject]@{ type="department"; id=[string]$Department.department_id })

    $Capability = & ".\scripts\autonomous-enterprise\New-AIOfficeEnterpriseCapability.ps1" `
        -Name "certification-cross-department-planning" `
        -OwnerDepartment "certification-enterprise" `
        -Description "Validate enterprise capability registry."

    $Created.Add([pscustomobject]@{ type="capability"; id=[string]$Capability.capability_id })

    $Work = & ".\scripts\autonomous-enterprise\New-AIOfficeEnterpriseWork.ps1" `
        -Title "Certification enterprise objective" `
        -Domain "chief-of-staff" `
        -Objective "Coordinate a cross-department certification objective." `
        -Priority "high" `
        -RequestedBy "enterprise-certification" `
        -SourceRef "CERT-V2-A"

    $Created.Add([pscustomobject]@{ type="work"; id=[string]$Work.enterprise_work_id })

    $Steps = @(
        [ordered]@{
            step_id = "STEP-001"
            department = "chief-of-staff"
            action = "plan"
            depends_on = @()
        },
        [ordered]@{
            step_id = "STEP-002"
            department = "analytics"
            action = "validate"
            depends_on = @("STEP-001")
        },
        [ordered]@{
            step_id = "STEP-003"
            department = "operations-integrations"
            action = "dispatch"
            depends_on = @("STEP-002")
        }
    ) | ConvertTo-Json -Depth 20 -Compress

    $Plan = & ".\scripts\autonomous-enterprise\New-AIOfficeEnterprisePlan.ps1" `
        -EnterpriseWorkId ([string]$Work.enterprise_work_id) `
        -StepsJson $Steps `
        -ParticipatingDepartmentsJson '["chief-of-staff","analytics","operations-integrations"]'

    $Created.Add([pscustomobject]@{ type="plan"; id=[string]$Plan.enterprise_plan_id })

    if (@($Plan.steps).Count -ne 3) {
        throw "Enterprise plan did not preserve all certification steps."
    }

    $Index = & ".\scripts\autonomous-enterprise\Update-AIOfficeEnterpriseIndex.ps1"

    if (
        [int]$Index.work_item_count -lt 1 -or
        [int]$Index.plan_count -lt 1 -or
        [int]$Index.department_count -lt 1 -or
        [int]$Index.capability_count -lt 1
    ) {
        throw "Enterprise index did not contain certification records."
    }

    Write-Host "[DEPARTMENT OK] $($Department.department_id)" -ForegroundColor Green
    Write-Host "[CAPABILITY OK] $($Capability.capability_id)" -ForegroundColor Green
    Write-Host "[WORK OK] $($Work.enterprise_work_id)" -ForegroundColor Green
    Write-Host "[PLAN OK] $($Plan.enterprise_plan_id)" -ForegroundColor Green
    Write-Host "[INDEX OK] Enterprise aggregation passed." -ForegroundColor Green
}
catch {
    Write-Host "[ENTERPRISE ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

foreach ($Item in $Created) {
    $Path = ""

    switch ([string]$Item.type) {
        "department" {
            $Path = ".\workspace\autonomous-enterprise\departments\$($Item.id).json"
        }
        "capability" {
            $Path = ".\workspace\autonomous-enterprise\capabilities\$($Item.id).json"
        }
        "work" {
            $Path = ".\workspace\autonomous-enterprise\work-items\$($Item.id).json"
        }
        "plan" {
            $Path = ".\workspace\autonomous-enterprise\plans\$($Item.id).json"
        }
    }

    if ($Path -and (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Remove-Item -LiteralPath $Path -Force
    }
}

& ".\scripts\autonomous-enterprise\Update-AIOfficeEnterpriseIndex.ps1" | Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Autonomous AI Enterprise architecture error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v2.0 Part A Autonomous AI Enterprise Architecture checks passed." -ForegroundColor Green
