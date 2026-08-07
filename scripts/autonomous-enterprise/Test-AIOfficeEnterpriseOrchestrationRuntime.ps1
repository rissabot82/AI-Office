param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.0 Part B Enterprise Orchestration Runtime..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\autonomous-enterprise\orchestration-policy.json",
    ".\config\autonomous-enterprise\enterprise-run-schema.json",
    ".\config\autonomous-enterprise\enterprise-step-result-schema.json",
    ".\config\autonomous-enterprise\enterprise-checkpoint-schema.json",
    ".\workspace\templates\enterprise-run-template.json",
    ".\workspace\templates\enterprise-step-result-template.json",
    ".\workspace\templates\enterprise-checkpoint-template.json"
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
    ".\scripts\autonomous-enterprise\AIOfficeEnterpriseRuntime.Common.ps1",
    ".\scripts\autonomous-enterprise\New-AIOfficeEnterpriseRun.ps1",
    ".\scripts\autonomous-enterprise\New-AIOfficeEnterpriseCheckpoint.ps1",
    ".\scripts\autonomous-enterprise\Get-AIOfficeEnterpriseContext.ps1",
    ".\scripts\autonomous-enterprise\Invoke-AIOfficeEnterpriseStep.ps1",
    ".\scripts\autonomous-enterprise\Invoke-AIOfficeEnterpriseRun.ps1",
    ".\scripts\autonomous-enterprise\Resume-AIOfficeEnterpriseRun.ps1",
    ".\scripts\autonomous-enterprise\Test-AIOfficeEnterpriseOrchestrationRuntime.ps1"
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
    $Work = & ".\scripts\autonomous-enterprise\New-AIOfficeEnterpriseWork.ps1" `
        -Title "Certification orchestration objective" `
        -Domain "chief-of-staff" `
        -Objective "Validate cross-department enterprise execution." `
        -Priority "high" `
        -RequestedBy "v2-runtime-certification"

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
        },
        [ordered]@{
            step_id = "STEP-004"
            department = "financial-office"
            action = "review"
            depends_on = @("STEP-002")
        },
        [ordered]@{
            step_id = "STEP-005"
            department = "business-incubator"
            action = "review"
            depends_on = @("STEP-003","STEP-004")
        }
    ) | ConvertTo-Json -Depth 20 -Compress

    $Plan = & ".\scripts\autonomous-enterprise\New-AIOfficeEnterprisePlan.ps1" `
        -EnterpriseWorkId ([string]$Work.enterprise_work_id) `
        -StepsJson $Steps `
        -ParticipatingDepartmentsJson '["chief-of-staff","analytics","operations-integrations","financial-office","business-incubator"]'

    $Created.Add([pscustomobject]@{ type="plan"; id=[string]$Plan.enterprise_plan_id })

    $Run = & ".\scripts\autonomous-enterprise\New-AIOfficeEnterpriseRun.ps1" `
        -EnterprisePlanId ([string]$Plan.enterprise_plan_id)

    $Created.Add([pscustomobject]@{ type="run"; id=[string]$Run.enterprise_run_id })

    $CompletedRun = & ".\scripts\autonomous-enterprise\Invoke-AIOfficeEnterpriseRun.ps1" `
        -EnterpriseRunId ([string]$Run.enterprise_run_id)

    if ([string]$CompletedRun.status -ne "completed") {
        throw "Enterprise run did not complete."
    }

    if (@($CompletedRun.completed_steps).Count -ne 5) {
        throw "Enterprise run did not complete all five certification steps."
    }

    $StepResults = @(
        Get-ChildItem `
            -LiteralPath ".\workspace\autonomous-enterprise\step-results" `
            -Filter "ENTSTEP-*.json" `
            -File `
            -ErrorAction SilentlyContinue |
        ForEach-Object {
            try {
                Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
            }
            catch {
            }
        } |
        Where-Object {
            $null -ne $_ -and
            [string]$_.enterprise_run_id -eq [string]$Run.enterprise_run_id
        }
    )

    if ($StepResults.Count -ne 5) {
        throw "Expected five enterprise step results."
    }

    $Checkpoints = @(
        Get-ChildItem `
            -LiteralPath ".\workspace\autonomous-enterprise\checkpoints" `
            -Filter "ENTCHK-*.json" `
            -File `
            -ErrorAction SilentlyContinue |
        ForEach-Object {
            try {
                Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
            }
            catch {
            }
        } |
        Where-Object {
            $null -ne $_ -and
            [string]$_.enterprise_run_id -eq [string]$Run.enterprise_run_id
        }
    )

    if ($Checkpoints.Count -lt 5) {
        throw "Enterprise runtime did not create expected checkpoints."
    }

    Write-Host "[RUN OK] $($Run.enterprise_run_id)" -ForegroundColor Green
    Write-Host "[STEPS OK] 5 enterprise steps completed." -ForegroundColor Green
    Write-Host "[CHECKPOINT OK] $($Checkpoints.Count) checkpoint(s)." -ForegroundColor Green
    Write-Host "[CONTEXT OK] Enterprise context assembled." -ForegroundColor Green
}
catch {
    Write-Host "[RUNTIME ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

foreach ($Item in $Created) {
    switch ([string]$Item.type) {
        "work" {
            $Path = ".\workspace\autonomous-enterprise\work-items\$($Item.id).json"
        }
        "plan" {
            $Path = ".\workspace\autonomous-enterprise\plans\$($Item.id).json"
        }
        "run" {
            $Path = ".\workspace\autonomous-enterprise\runs\$($Item.id).json"
        }
        default {
            $Path = ""
        }
    }

    if ($Path -and (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Remove-Item -LiteralPath $Path -Force
    }
}

if ($Created.Count -gt 0) {
    $RunIds = @(
        $Created |
        Where-Object { [string]$_.type -eq "run" } |
        ForEach-Object { [string]$_.id }
    )

    foreach ($RunId in $RunIds) {
        foreach ($Directory in @(
            ".\workspace\autonomous-enterprise\step-results",
            ".\workspace\autonomous-enterprise\checkpoints"
        )) {
            if (Test-Path -LiteralPath $Directory -PathType Container) {
                Get-ChildItem -LiteralPath $Directory -Filter "*.json" -File |
                ForEach-Object {
                    try {
                        $Data = Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
                        if ([string]$Data.enterprise_run_id -eq $RunId) {
                            Remove-Item -LiteralPath $_.FullName -Force
                        }
                    }
                    catch {
                    }
                }
            }
        }
    }
}

& ".\scripts\autonomous-enterprise\Update-AIOfficeEnterpriseIndex.ps1" | Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Enterprise Orchestration Runtime error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v2.0 Part B Enterprise Orchestration Runtime checks passed." -ForegroundColor Green
