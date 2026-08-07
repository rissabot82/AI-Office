param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v1.9 Part A Operations and Integrations Architecture..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\operations-integrations\operations-policy.json",
    ".\config\operations-integrations\intake-schema.json",
    ".\config\operations-integrations\integration-schema.json",
    ".\config\operations-integrations\job-schema.json",
    ".\config\operations-integrations\notification-schema.json",
    ".\config\operations-integrations\queue-schema.json",
    ".\workspace\operations-integrations\indexes\operations-index.json",
    ".\workspace\templates\operations-intake-template.json",
    ".\workspace\templates\operations-integration-template.json",
    ".\workspace\templates\operations-job-template.json",
    ".\workspace\templates\operations-notification-template.json"
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
    ".\scripts\operations-integrations\AIOfficeOperations.Common.ps1",
    ".\scripts\operations-integrations\New-AIOfficeOperationalIntake.ps1",
    ".\scripts\operations-integrations\New-AIOfficeIntegrationRecord.ps1",
    ".\scripts\operations-integrations\New-AIOfficeOperationalJob.ps1",
    ".\scripts\operations-integrations\New-AIOfficeNotification.ps1",
    ".\scripts\operations-integrations\Update-AIOfficeOperationsIndex.ps1",
    ".\scripts\operations-integrations\Show-AIOfficeOperationsStatus.ps1",
    ".\scripts\operations-integrations\Test-AIOfficeOperationsArchitecture.ps1"
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
    $Intake = & ".\scripts\operations-integrations\New-AIOfficeOperationalIntake.ps1" `
        -Channel "discord" `
        -Title "Certification mobile task" `
        -Description "Validate operational intake." `
        -Priority "high" `
        -RequestedDepartment "chief-of-staff" `
        -SourceRef "certification"

    $Created.Add([pscustomobject]@{ type="intake"; id=[string]$Intake.intake_id })

    $Integration = & ".\scripts\operations-integrations\New-AIOfficeIntegrationRecord.ps1" `
        -Name "Certification Discord" `
        -IntegrationType "discord" `
        -Status "connected" `
        -CapabilitiesJson '["task_intake","notifications"]'

    $Created.Add([pscustomobject]@{ type="integration"; id=[string]$Integration.integration_id })

    $Job = & ".\scripts\operations-integrations\New-AIOfficeOperationalJob.ps1" `
        -Name "Certification Monthly Reporting" `
        -JobType "reporting" `
        -Schedule "monthly" `
        -Handler "monthly-reporting" `
        -Department "monthly-reporting"

    $Created.Add([pscustomobject]@{ type="job"; id=[string]$Job.job_id })

    $Notification = & ".\scripts\operations-integrations\New-AIOfficeNotification.ps1" `
        -Title "Certification Notification" `
        -Message "Operations architecture validation." `
        -Priority "normal" `
        -Channel "dashboard" `
        -SourceRef ([string]$Intake.intake_id)

    $Created.Add([pscustomobject]@{ type="notification"; id=[string]$Notification.notification_id })

    $Index = & ".\scripts\operations-integrations\Update-AIOfficeOperationsIndex.ps1"

    if (
        [int]$Index.intake_count -lt 1 -or
        [int]$Index.integration_count -lt 1 -or
        [int]$Index.job_count -lt 1 -or
        [int]$Index.notification_count -lt 1
    ) {
        throw "Operations index did not contain certification records."
    }

    if ([int]$Index.connected_integration_count -lt 1) {
        throw "Connected integration aggregation failed."
    }

    Write-Host "[INTAKE OK] $($Intake.intake_id)" -ForegroundColor Green
    Write-Host "[INTEGRATION OK] $($Integration.integration_id)" -ForegroundColor Green
    Write-Host "[JOB OK] $($Job.job_id)" -ForegroundColor Green
    Write-Host "[NOTIFICATION OK] $($Notification.notification_id)" -ForegroundColor Green
    Write-Host "[INDEX OK] Operations aggregation passed." -ForegroundColor Green
}
catch {
    Write-Host "[OPERATIONS ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

foreach ($Item in $Created) {
    $Path = ""

    switch ([string]$Item.type) {
        "intake" {
            $Path = ".\workspace\operations-integrations\intake\$($Item.id).json"
        }
        "integration" {
            $Path = ".\workspace\operations-integrations\integrations\$($Item.id).json"
        }
        "job" {
            $Path = ".\workspace\operations-integrations\jobs\$($Item.id).json"
        }
        "notification" {
            $Path = ".\workspace\operations-integrations\notifications\$($Item.id).json"
        }
    }

    if ($Path -and (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Remove-Item -LiteralPath $Path -Force
    }
}

& ".\scripts\operations-integrations\Update-AIOfficeOperationsIndex.ps1" | Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Operations and Integrations architecture error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.9 Part A Operations and Integrations Architecture checks passed." -ForegroundColor Green
