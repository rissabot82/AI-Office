param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v1.9 Part B Operational Runtime and External Intake..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\operations-integrations\runtime-policy.json",
    ".\config\operations-integrations\dispatch-schema.json",
    ".\config\operations-integrations\job-run-schema.json",
    ".\config\operations-integrations\integration-health-schema.json",
    ".\config\operations-integrations\discord-intake-schema.json",
    ".\workspace\templates\operations-dispatch-template.json",
    ".\workspace\templates\operations-job-run-template.json",
    ".\workspace\templates\operations-integration-health-template.json",
    ".\workspace\templates\operations-discord-intake-template.json"
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
    ".\scripts\operations-integrations\AIOfficeOperationalRuntime.Common.ps1",
    ".\scripts\operations-integrations\ConvertFrom-AIOfficeDiscordTask.ps1",
    ".\scripts\operations-integrations\New-AIOfficeOperationalDispatch.ps1",
    ".\scripts\operations-integrations\Invoke-AIOfficeOperationalDispatch.ps1",
    ".\scripts\operations-integrations\Retry-AIOfficeOperationalDispatch.ps1",
    ".\scripts\operations-integrations\Test-AIOfficeIntegrationHealth.ps1",
    ".\scripts\operations-integrations\Invoke-AIOfficeOperationalJob.ps1",
    ".\scripts\operations-integrations\New-AIOfficeMonthlyReportingJob.ps1",
    ".\scripts\operations-integrations\Test-AIOfficeOperationalRuntime.ps1"
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
    $Discord = & ".\scripts\operations-integrations\ConvertFrom-AIOfficeDiscordTask.ps1" `
        -AuthorId "cert-user-001" `
        -ChannelId "cert-channel-001" `
        -Content "Create a certification task from mobile Discord." `
        -Priority "high" `
        -RequestedDepartment "chief-of-staff"

    $Created.Add([pscustomobject]@{ type="discord"; id=[string]$Discord.discord.discord_intake_id })
    $Created.Add([pscustomobject]@{ type="intake"; id=[string]$Discord.intake.intake_id })

    Write-Host "[DISCORD OK] $($Discord.discord.discord_intake_id)" -ForegroundColor Green

    $Dispatch = & ".\scripts\operations-integrations\New-AIOfficeOperationalDispatch.ps1" `
        -IntakeId ([string]$Discord.intake.intake_id)

    $Created.Add([pscustomobject]@{ type="dispatch"; id=[string]$Dispatch.dispatch_id })

    $DispatchResult = & ".\scripts\operations-integrations\Invoke-AIOfficeOperationalDispatch.ps1" `
        -DispatchId ([string]$Dispatch.dispatch_id)

    if ([string]$DispatchResult.status -ne "completed") {
        throw "Operational dispatch did not complete."
    }

    Write-Host "[DISPATCH OK] $($Dispatch.dispatch_id)" -ForegroundColor Green

    $Integration = & ".\scripts\operations-integrations\New-AIOfficeIntegrationRecord.ps1" `
        -Name "Certification Discord Runtime" `
        -IntegrationType "discord" `
        -Status "configured" `
        -CapabilitiesJson '["task_intake","notifications"]'

    $Created.Add([pscustomobject]@{ type="integration"; id=[string]$Integration.integration_id })

    $Health = & ".\scripts\operations-integrations\Test-AIOfficeIntegrationHealth.ps1" `
        -IntegrationId ([string]$Integration.integration_id)

    $Created.Add([pscustomobject]@{ type="health"; id=[string]$Health.health_check_id })

    if ([string]$Health.status -ne "healthy") {
        throw "Integration health check did not return healthy."
    }

    Write-Host "[HEALTH OK] $($Health.health_check_id)" -ForegroundColor Green

    $Job = & ".\scripts\operations-integrations\New-AIOfficeMonthlyReportingJob.ps1" `
        -Schedule "monthly-certification"

    $Created.Add([pscustomobject]@{ type="job"; id=[string]$Job.job_id })

    $Run = & ".\scripts\operations-integrations\Invoke-AIOfficeOperationalJob.ps1" `
        -JobId ([string]$Job.job_id)

    $Created.Add([pscustomobject]@{ type="job-run"; id=[string]$Run.job_run_id })

    if ([string]$Run.status -ne "completed") {
        throw "Monthly Reporting job did not complete."
    }

    if ([string]$Run.result.status -ne "workflow_ready") {
        throw "Monthly Reporting workflow was not initialized."
    }

    Write-Host "[REPORTING OK] $($Run.job_run_id)" -ForegroundColor Green

    $Index = & ".\scripts\operations-integrations\Update-AIOfficeOperationsIndex.ps1"

    if (
        [int]$Index.intake_count -lt 1 -or
        [int]$Index.integration_count -lt 1 -or
        [int]$Index.job_count -lt 1
    ) {
        throw "Operational runtime index did not contain certification records."
    }

    Write-Host "[INDEX OK] Operational runtime aggregation passed." -ForegroundColor Green
}
catch {
    Write-Host "[RUNTIME ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

foreach ($Item in $Created) {
    $Path = ""

    switch ([string]$Item.type) {
        "discord" {
            $Path = ".\workspace\operations-integrations\discord-intake\$($Item.id).json"
        }
        "intake" {
            $Path = ".\workspace\operations-integrations\intake\$($Item.id).json"
        }
        "dispatch" {
            $Path = ".\workspace\operations-integrations\dispatch\$($Item.id).json"
        }
        "integration" {
            $Path = ".\workspace\operations-integrations\integrations\$($Item.id).json"
        }
        "health" {
            $Path = ".\workspace\operations-integrations\health\$($Item.id).json"
        }
        "job" {
            $Path = ".\workspace\operations-integrations\jobs\$($Item.id).json"
        }
        "job-run" {
            $Path = ".\workspace\operations-integrations\job-runs\$($Item.id).json"
        }
    }

    if ($Path -and (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Remove-Item -LiteralPath $Path -Force
    }
}

& ".\scripts\operations-integrations\Update-AIOfficeOperationsIndex.ps1" | Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Operational Runtime and External Intake error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.9 Part B Operational Runtime and External Intake checks passed." -ForegroundColor Green
