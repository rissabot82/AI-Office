$script:AIOfficeOperationalRuntimeRoot = "E:\AI\AI-Office"

function Get-AIOfficeOperationalRuntimePolicy {
    return Get-Content `
        -LiteralPath "E:\AI\AI-Office\config\operations-integrations\runtime-policy.json" `
        -Raw |
        ConvertFrom-Json
}

function New-AIOfficeOperationalRuntimeId {
    param([Parameter(Mandatory=$true)][string]$Prefix)

    return (
        $Prefix + "-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeOperationalIntakeById {
    param([Parameter(Mandatory=$true)][string]$IntakeId)

    . "E:\AI\AI-Office\scripts\operations-integrations\AIOfficeOperations.Common.ps1"

    $Path = "E:\AI\AI-Office\workspace\operations-integrations\intake\$IntakeId.json"
    $Item = Read-AIOfficeOperationsJson -Path $Path

    if ($null -eq $Item) {
        throw "Operational intake not found: $IntakeId"
    }

    return $Item
}

function Get-AIOfficeOperationalIntegrationById {
    param([Parameter(Mandatory=$true)][string]$IntegrationId)

    . "E:\AI\AI-Office\scripts\operations-integrations\AIOfficeOperations.Common.ps1"

    $Path = "E:\AI\AI-Office\workspace\operations-integrations\integrations\$IntegrationId.json"
    $Item = Read-AIOfficeOperationsJson -Path $Path

    if ($null -eq $Item) {
        throw "Integration not found: $IntegrationId"
    }

    return $Item
}
