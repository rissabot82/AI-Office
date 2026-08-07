param(
    [Parameter(Mandatory=$true)][string]$IntakeId,
    [string]$DestinationType = "department",
    [string]$Destination = ""
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\operations-integrations\AIOfficeOperations.Common.ps1"
. "E:\AI\AI-Office\scripts\operations-integrations\AIOfficeOperationalRuntime.Common.ps1"

$Intake = Get-AIOfficeOperationalIntakeById -IntakeId $IntakeId

if ([string]::IsNullOrWhiteSpace($Destination)) {
    if (-not [string]::IsNullOrWhiteSpace([string]$Intake.requested_agent)) {
        $DestinationType = "agent"
        $Destination = [string]$Intake.requested_agent
    }
    elseif (-not [string]::IsNullOrWhiteSpace([string]$Intake.requested_department)) {
        $DestinationType = "department"
        $Destination = [string]$Intake.requested_department
    }
    else {
        $DestinationType = "department"
        $Destination = "chief-of-staff"
    }
}

$Id = New-AIOfficeOperationalRuntimeId -Prefix "OPSDSP"
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    dispatch_id = $Id
    intake_id = $IntakeId
    intake_title = [string]$Intake.title
    destination_type = $DestinationType
    destination = $Destination
    status = "queued"
    attempts = 0
    last_error = ""
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeOperationsJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\operations-integrations\dispatch\$Id.json"

Write-Host "Operational dispatch created: $Id | $DestinationType -> $Destination" -ForegroundColor Green
return [pscustomobject]$Record
