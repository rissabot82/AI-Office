$script:AIOfficeModelSelectionRoot = "E:\AI\AI-Office"

function Get-AIOfficeModelSelectionPolicy {
    return Get-Content `
        -LiteralPath "E:\AI\AI-Office\config\self-hosting\model-selection-policy.json" `
        -Raw |
        ConvertFrom-Json
}

function Get-AIOfficeReadyLocalModels {
    . "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"

    return @(
        Get-AIOfficeSelfHostingCollection `
            -Directory "E:\AI\AI-Office\workspace\self-hosting\models" `
            -Filter "SHMODEL-*.json" |
        Where-Object { [string]$_.status -eq "ready" }
    )
}

function Get-AIOfficeWorkloadMetrics {
    . "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"

    return @(
        Get-AIOfficeSelfHostingCollection `
            -Directory "E:\AI\AI-Office\workspace\self-hosting\workload-metrics" `
            -Filter "SHMET-*.json"
    )
}

function Get-AIOfficeHistoricalModelStats {
    param(
        [Parameter(Mandatory=$true)][string]$Model,
        [string]$TaskType = ""
    )

    $Metrics = Get-AIOfficeWorkloadMetrics

    $Matching = @(
        $Metrics |
        Where-Object {
            [string]$_.model -eq $Model -and
            (
                [string]::IsNullOrWhiteSpace($TaskType) -or
                [string]$_.task_type -eq $TaskType
            )
        }
    )

    if ($Matching.Count -eq 0) {
        return [pscustomobject]@{
            samples = 0
            success_rate = 0.5
            average_elapsed_ms = 0
        }
    }

    $Success = @(
        $Matching |
        Where-Object { [string]$_.status -eq "completed" }
    ).Count

    $AverageElapsed = (
        $Matching |
        Measure-Object -Property elapsed_ms -Average
    ).Average

    return [pscustomobject]@{
        samples = $Matching.Count
        success_rate = if ($Matching.Count -gt 0) { [double]$Success / [double]$Matching.Count } else { 0.5 }
        average_elapsed_ms = if ($null -ne $AverageElapsed) { [double]$AverageElapsed } else { 0 }
    }
}
