$script:AIOfficeEnterpriseRuntimeRoot = "E:\AI\AI-Office"

function Get-AIOfficeEnterpriseRuntimePolicy {
    return Get-Content `
        -LiteralPath "E:\AI\AI-Office\config\autonomous-enterprise\orchestration-policy.json" `
        -Raw |
        ConvertFrom-Json
}

function New-AIOfficeEnterpriseRuntimeId {
    param([Parameter(Mandatory=$true)][string]$Prefix)

    return (
        $Prefix + "-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeEnterprisePlanById {
    param([Parameter(Mandatory=$true)][string]$EnterprisePlanId)

    . "E:\AI\AI-Office\scripts\autonomous-enterprise\AIOfficeEnterprise.Common.ps1"

    $Path = "E:\AI\AI-Office\workspace\autonomous-enterprise\plans\$EnterprisePlanId.json"
    $Plan = Read-AIOfficeEnterpriseJson -Path $Path

    if ($null -eq $Plan) {
        throw "Enterprise plan not found: $EnterprisePlanId"
    }

    return $Plan
}

function Get-AIOfficeEnterpriseRunById {
    param([Parameter(Mandatory=$true)][string]$EnterpriseRunId)

    . "E:\AI\AI-Office\scripts\autonomous-enterprise\AIOfficeEnterprise.Common.ps1"

    $Path = "E:\AI\AI-Office\workspace\autonomous-enterprise\runs\$EnterpriseRunId.json"
    $Run = Read-AIOfficeEnterpriseJson -Path $Path

    if ($null -eq $Run) {
        throw "Enterprise run not found: $EnterpriseRunId"
    }

    return $Run
}
