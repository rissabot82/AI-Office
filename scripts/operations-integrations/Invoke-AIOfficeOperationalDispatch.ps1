param(
    [Parameter(Mandatory=$true)][string]$DispatchId
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\operations-integrations\AIOfficeOperations.Common.ps1"
. "E:\AI\AI-Office\scripts\operations-integrations\AIOfficeOperationalRuntime.Common.ps1"

$Policy = Get-AIOfficeOperationalRuntimePolicy
$Path = "E:\AI\AI-Office\workspace\operations-integrations\dispatch\$DispatchId.json"
$Dispatch = Read-AIOfficeOperationsJson -Path $Path

if ($null -eq $Dispatch) {
    throw "Operational dispatch not found: $DispatchId"
}

$Intake = Get-AIOfficeOperationalIntakeById -IntakeId ([string]$Dispatch.intake_id)
$MaxAttempts = [int]$Policy.dispatch.maximum_retry_attempts

$Dispatch.status = "processing"
$Dispatch.attempts = [int]$Dispatch.attempts + 1
$Dispatch.updated_at = (Get-Date).ToString("o")
Write-AIOfficeOperationsJson -Value $Dispatch -Path $Path

try {
    $Result = [ordered]@{
        routed = $true
        destination_type = [string]$Dispatch.destination_type
        destination = [string]$Dispatch.destination
        intake_id = [string]$Intake.intake_id
        title = [string]$Intake.title
    }

    $Dispatch.status = "completed"
    $Dispatch.last_error = ""
    $Dispatch.updated_at = (Get-Date).ToString("o")
    $Dispatch | Add-Member -NotePropertyName "result" -NotePropertyValue $Result -Force

    $Intake.status = "processing"
    $Intake.updated_at = (Get-Date).ToString("o")

    Write-AIOfficeOperationsJson -Value $Dispatch -Path $Path
    Write-AIOfficeOperationsJson `
        -Value $Intake `
        -Path "E:\AI\AI-Office\workspace\operations-integrations\intake\$($Intake.intake_id).json"

    Write-Host "Operational dispatch completed: $DispatchId | $($Dispatch.destination)" -ForegroundColor Green
    return [pscustomobject]$Dispatch
}
catch {
    $Dispatch.last_error = $_.Exception.Message

    if ([int]$Dispatch.attempts -ge $MaxAttempts) {
        $Dispatch.status = "failed"
    }
    else {
        $Dispatch.status = "waiting"
    }

    $Dispatch.updated_at = (Get-Date).ToString("o")
    Write-AIOfficeOperationsJson -Value $Dispatch -Path $Path
    throw
}
