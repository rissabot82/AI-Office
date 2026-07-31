. (Join-Path $PSScriptRoot "AIOfficeAutonomousWorkflows.Common.ps1")

function Get-AIOfficeAutonomousExecutionPolicy {
    $Root = Get-AIOfficeAutonomousWorkflowRoot

    return Read-AIOfficeAutonomousWorkflowJson `
        -Path (
            Join-Path `
                $Root `
                "config\autonomous-workflows\autonomous-execution-policy.json"
        )
}

function New-AIOfficeAutonomousStepResultId {
    return (
        "SR-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeAutonomousApprovalId {
    return (
        "APRWF-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeAutonomousRecoveryId {
    return (
        "REC-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeAutonomousRun {
    param([Parameter(Mandatory=$true)][string]$RunId)

    $Root = Get-AIOfficeAutonomousWorkflowRoot
    $Path = Join-Path `
        $Root `
        ("workspace\autonomous-workflows\runs\" + $RunId + ".json")

    $Run = Read-AIOfficeAutonomousWorkflowJson -Path $Path

    if ($null -eq $Run) {
        throw "Autonomous run not found: $RunId"
    }

    return $Run
}

function Save-AIOfficeAutonomousRun {
    param([Parameter(Mandatory=$true)]$Run)

    $Root = Get-AIOfficeAutonomousWorkflowRoot

    Write-AIOfficeAutonomousWorkflowJson `
        -Value $Run `
        -Path (
            Join-Path `
                $Root `
                ("workspace\autonomous-workflows\runs\" + [string]$Run.run_id + ".json")
        )
}

function Save-AIOfficeAutonomousPlan {
    param([Parameter(Mandatory=$true)]$Plan)

    $Root = Get-AIOfficeAutonomousWorkflowRoot

    Write-AIOfficeAutonomousWorkflowJson `
        -Value $Plan `
        -Path (
            Join-Path `
                $Root `
                (
                    "workspace\autonomous-workflows\plans\" +
                    [string]$Plan.autonomous_plan_id +
                    ".json"
                )
        )
}

function Test-AIOfficeAutonomousStepDependencies {
    param(
        [Parameter(Mandatory=$true)]$Step,
        [Parameter(Mandatory=$true)]$Plan
    )

    $Dependencies = @($Step.depends_on)

    if ($Dependencies.Count -lt 1) {
        return $true
    }

    foreach ($DependencyId in $Dependencies) {
        $Dependency = @(
            $Plan.steps |
                Where-Object { [string]$_.step_id -eq [string]$DependencyId }
        ) | Select-Object -First 1

        if ($null -eq $Dependency -or [string]$Dependency.status -ne "completed") {
            return $false
        }
    }

    return $true
}
