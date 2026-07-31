$script:AIOfficeIdentityRoot = $null

function Get-AIOfficeIdentityRoot {
    if ($script:AIOfficeIdentityRoot) {
        return $script:AIOfficeIdentityRoot
    }

    $script:AIOfficeIdentityRoot = (
        Resolve-Path (Join-Path $PSScriptRoot "..\..")
    ).Path

    return $script:AIOfficeIdentityRoot
}

function Read-AIOfficeIdentityJson {
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

function Write-AIOfficeIdentityJson {
    param(
        [Parameter(Mandatory=$true)]$Value,
        [Parameter(Mandatory=$true)][string]$Path
    )

    $Value |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-AIOfficeIdentity {
    $Root = Get-AIOfficeIdentityRoot

    return Read-AIOfficeIdentityJson `
        -Path (Join-Path $Root "config\identity\office.json")
}

function Get-AIOfficeIdentityCapabilities {
    $Root = Get-AIOfficeIdentityRoot

    return Read-AIOfficeIdentityJson `
        -Path (Join-Path $Root "config\identity\capabilities.json")
}

function New-AIOfficeIdentityEnvelope {
    param(
        [Parameter(Mandatory=$true)][string]$MessageType,
        [Parameter(Mandatory=$true)]$Payload,
        [string]$SourceComponent = "AI Office",
        [string]$TargetComponent = "",
        [string]$CorrelationId = ""
    )

    $Identity = Get-AIOfficeIdentity

    if ($null -eq $Identity) {
        throw "AI Office identity could not be loaded."
    }

    if ([string]::IsNullOrWhiteSpace($CorrelationId)) {
        $CorrelationId = "COR-" + (
            [guid]::NewGuid().ToString("N").Substring(0,12)
        ).ToUpperInvariant()
    }

    return [ordered]@{
        office_id = [string]$Identity.office_id
        office_name = [string]$Identity.name
        office_version = [string]$Identity.version
        message_type = $MessageType
        created_at = (Get-Date).ToString("o")
        correlation_id = $CorrelationId
        source_component = $SourceComponent
        target_component = $TargetComponent
        payload = $Payload
    }
}
