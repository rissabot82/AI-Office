$script:AIOfficeAutonomousWorkflowRoot = $null

function Get-AIOfficeAutonomousWorkflowRoot {
    if ($script:AIOfficeAutonomousWorkflowRoot) {
        return $script:AIOfficeAutonomousWorkflowRoot
    }

    $script:AIOfficeAutonomousWorkflowRoot = (
        Resolve-Path (Join-Path $PSScriptRoot "..\..")
    ).Path

    return $script:AIOfficeAutonomousWorkflowRoot
}

function Read-AIOfficeAutonomousWorkflowJson {
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

function Write-AIOfficeAutonomousWorkflowJson {
    param(
        [Parameter(Mandatory=$true)]$Value,
        [Parameter(Mandatory=$true)][string]$Path
    )

    $Parent = Split-Path -Parent $Path

    if ($Parent -and -not (Test-Path -LiteralPath $Parent -PathType Container)) {
        New-Item -ItemType Directory -Path $Parent -Force | Out-Null
    }

    $Value |
        ConvertTo-Json -Depth 80 |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-AIOfficeAutonomousWorkflowPolicy {
    $Root = Get-AIOfficeAutonomousWorkflowRoot

    return Read-AIOfficeAutonomousWorkflowJson `
        -Path (
            Join-Path `
                $Root `
                "config\autonomous-workflows\autonomous-workflow-policy.json"
        )
}

function New-AIOfficeAutonomousGoalId {
    return (
        "GOAL-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeAutonomousPlanId {
    return (
        "APL-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeAutonomousRunId {
    return (
        "RUN-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeAutonomousCheckpointId {
    return (
        "CHK-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeAutonomousGoal {
    param([Parameter(Mandatory=$true)][string]$GoalId)

    $Root = Get-AIOfficeAutonomousWorkflowRoot
    $Path = Join-Path `
        $Root `
        ("workspace\autonomous-workflows\goals\" + $GoalId + ".json")

    $Goal = Read-AIOfficeAutonomousWorkflowJson -Path $Path

    if ($null -eq $Goal) {
        throw "Autonomous goal not found: $GoalId"
    }

    return $Goal
}

function Get-AIOfficeAutonomousPlan {
    param([Parameter(Mandatory=$true)][string]$AutonomousPlanId)

    $Root = Get-AIOfficeAutonomousWorkflowRoot
    $Path = Join-Path `
        $Root `
        (
            "workspace\autonomous-workflows\plans\" +
            $AutonomousPlanId +
            ".json"
        )

    $Plan = Read-AIOfficeAutonomousWorkflowJson -Path $Path

    if ($null -eq $Plan) {
        throw "Autonomous plan not found: $AutonomousPlanId"
    }

    return $Plan
}
