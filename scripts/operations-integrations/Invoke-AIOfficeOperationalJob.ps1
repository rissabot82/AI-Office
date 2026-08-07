param(
    [Parameter(Mandatory=$true)][string]$JobId
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\operations-integrations\AIOfficeOperations.Common.ps1"
. "E:\AI\AI-Office\scripts\operations-integrations\AIOfficeOperationalRuntime.Common.ps1"

$JobPath = "E:\AI\AI-Office\workspace\operations-integrations\jobs\$JobId.json"
$Job = Read-AIOfficeOperationsJson -Path $JobPath

if ($null -eq $Job) {
    throw "Operational job not found: $JobId"
}

$RunId = New-AIOfficeOperationalRuntimeId -Prefix "OPSRUN"
$Now = (Get-Date).ToString("o")

$Run = [ordered]@{
    job_run_id = $RunId
    job_id = $JobId
    job_name = [string]$Job.name
    status = "running"
    started_at = $Now
    completed_at = ""
    updated_at = $Now
    result = [ordered]@{}
}

$RunPath = "E:\AI\AI-Office\workspace\operations-integrations\job-runs\$RunId.json"
Write-AIOfficeOperationsJson -Value $Run -Path $RunPath

try {
    $Result = [ordered]@{
        handler = [string]$Job.handler
        department = [string]$Job.department
        job_type = [string]$Job.job_type
    }

    if ([string]$Job.handler -eq "monthly-reporting") {
        $Result["reporting_stages"] = @(
            "collect",
            "normalize",
            "validate",
            "populate",
            "analyze",
            "draft_summary",
            "review"
        )
        $Result["status"] = "workflow_ready"
    }
    else {
        $Result["status"] = "completed"
    }

    $Run.status = "completed"
    $Run.completed_at = (Get-Date).ToString("o")
    $Run.updated_at = $Run.completed_at
    $Run.result = $Result

    $Job.status = "configured"
    $Job.updated_at = (Get-Date).ToString("o")
    $Job | Add-Member -NotePropertyName "last_run_id" -NotePropertyValue $RunId -Force
    $Job | Add-Member -NotePropertyName "last_run_status" -NotePropertyValue "completed" -Force

    Write-AIOfficeOperationsJson -Value $Run -Path $RunPath
    Write-AIOfficeOperationsJson -Value $Job -Path $JobPath

    Write-Host "Operational job completed: $RunId | $($Job.name)" -ForegroundColor Green
    return [pscustomobject]$Run
}
catch {
    $Run.status = "failed"
    $Run.updated_at = (Get-Date).ToString("o")
    $Run.result = [ordered]@{
        error = $_.Exception.Message
    }
    Write-AIOfficeOperationsJson -Value $Run -Path $RunPath
    throw
}
