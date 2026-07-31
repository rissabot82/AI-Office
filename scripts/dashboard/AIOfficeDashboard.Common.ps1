$script:AIOfficeDashboardRoot = $null

function Get-AIOfficeDashboardRoot {
    if (-not [string]::IsNullOrWhiteSpace($script:AIOfficeDashboardRoot)) {
        return $script:AIOfficeDashboardRoot
    }

    $candidate = Resolve-Path (
        Join-Path $PSScriptRoot "..\.."
    )

    $script:AIOfficeDashboardRoot = $candidate.Path
    return $script:AIOfficeDashboardRoot
}

function ConvertTo-AIOfficeDashboardArray {
    param(
        [AllowNull()]
        $Value
    )

    if ($null -eq $Value) {
        return @()
    }

    return @($Value)
}

function Get-AIOfficePropertyValue {
    param(
        [AllowNull()]
        $Object,

        [Parameter(Mandatory = $true)]
        [string[]]$Names,

        [AllowNull()]
        $Default = $null
    )

    if ($null -eq $Object) {
        return $Default
    }

    foreach ($name in $Names) {
        $property = $Object.PSObject.Properties[$name]

        if ($null -ne $property) {
            return $property.Value
        }
    }

    return $Default
}

function ConvertTo-AIOfficeDashboardDate {
    param(
        [AllowNull()]
        $Value
    )

    if ($null -eq $Value) {
        return $null
    }

    $text = [string]$Value

    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }

    $parsed = [datetime]::MinValue

    if ([datetime]::TryParse($text, [ref]$parsed)) {
        return $parsed
    }

    return $null
}

function Read-AIOfficeJsonFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

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

function Get-AIOfficeJsonFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return @()
    }

    return @(
        Get-ChildItem `
            -LiteralPath $Path `
            -Filter "*.json" `
            -File `
            -Recurse `
            -ErrorAction SilentlyContinue
    )
}

function Get-AIOfficeDashboardStatus {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Score,

        [Parameter(Mandatory = $true)]
        $Policy
    )

    $healthyMinimum = [int]$Policy.health_thresholds.healthy_minimum
    $attentionMinimum = [int]$Policy.health_thresholds.attention_minimum

    if ($Score -ge $healthyMinimum) {
        return "healthy"
    }

    if ($Score -ge $attentionMinimum) {
        return "attention"
    }

    return "critical"
}

function New-AIOfficeDashboardRisk {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RiskId,

        [Parameter(Mandatory = $true)]
        [string]$Severity,

        [Parameter(Mandatory = $true)]
        [string]$Category,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$Detail,

        [Parameter(Mandatory = $true)]
        [string]$RecommendedAction
    )

    return [ordered]@{
        risk_id = $RiskId
        severity = $Severity
        category = $Category
        title = $Title
        detail = $Detail
        recommended_action = $RecommendedAction
    }
}

function ConvertTo-AIOfficeHtmlText {
    param(
        [AllowNull()]
        $Value
    )

    if ($null -eq $Value) {
        return ""
    }

    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}
