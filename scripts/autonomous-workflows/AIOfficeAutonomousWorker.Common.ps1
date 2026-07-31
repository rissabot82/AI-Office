. (Join-Path $PSScriptRoot "AIOfficeAutonomousExecution.Common.ps1")

function Get-AIOfficeAutonomousWorkerPolicy {
    $Root = Get-AIOfficeAutonomousWorkflowRoot

    return Read-AIOfficeAutonomousWorkflowJson `
        -Path (
            Join-Path `
                $Root `
                "config\autonomous-workflows\autonomous-worker-policy.json"
        )
}

function New-AIOfficeAutonomousWorkerCycleId {
    return (
        "WKC-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeAutonomousMonitoringId {
    return (
        "MON-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}
