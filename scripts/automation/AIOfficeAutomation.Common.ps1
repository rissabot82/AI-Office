$script:AIOfficeAutomationRoot = $null

function Get-AIOfficeAutomationRoot {
    if (-not [string]::IsNullOrWhiteSpace($script:AIOfficeAutomationRoot)) {
        return $script:AIOfficeAutomationRoot
    }

    $resolved = Resolve-Path (Join-Path $PSScriptRoot "..\..")
    $script:AIOfficeAutomationRoot = $resolved.Path
    return $script:AIOfficeAutomationRoot
}

function Read-AIOfficeAutomationJson {
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

function Write-AIOfficeAutomationJson {
    param(
        [Parameter(Mandatory=$true)]$Value,
        [Parameter(Mandatory=$true)][string]$Path
    )

    $parent = Split-Path -Parent $Path

    if (-not [string]::IsNullOrWhiteSpace($parent) -and
        -not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $Value |
        ConvertTo-Json -Depth 30 |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function ConvertTo-AIOfficeAutomationArray {
    param([AllowNull()]$Value)

    if ($null -eq $Value) {
        return @()
    }

    return @($Value | ForEach-Object { $_ })
}

function Get-AIOfficeAutomationProperty {
    param(
        [AllowNull()]$Object,
        [Parameter(Mandatory=$true)][string[]]$Names,
        [AllowNull()]$Default = $null
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

function New-AIOfficeAutomationId {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("AUT","EVT","RUN")]
        [string]$Prefix
    )

    $stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
    $suffix = ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    return $Prefix + "-" + $stamp + "-" + $suffix
}

function Get-AIOfficeAutomationFingerprint {
    param(
        [Parameter(Mandatory=$true)][string]$TriggerType,
        [Parameter(Mandatory=$true)][string]$Source,
        [AllowNull()]$Payload
    )

    $payloadText = ""

    if ($null -ne $Payload) {
        $payloadText = $Payload | ConvertTo-Json -Depth 20 -Compress
    }

    $inputText = $TriggerType + "|" + $Source + "|" + $payloadText
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($inputText)
    $sha = [System.Security.Cryptography.SHA256]::Create()

    try {
        $hash = $sha.ComputeHash($bytes)
    }
    finally {
        $sha.Dispose()
    }

    return ([System.BitConverter]::ToString($hash)).Replace("-","")
}

function Test-AIOfficeAutomationCondition {
    param(
        [Parameter(Mandatory=$true)]$Condition,
        [Parameter(Mandatory=$true)]$Event
    )

    $field = [string](Get-AIOfficeAutomationProperty -Object $Condition -Names @("field"))
    $operator = [string](Get-AIOfficeAutomationProperty -Object $Condition -Names @("operator") -Default "equals")
    $expected = Get-AIOfficeAutomationProperty -Object $Condition -Names @("value")

    if ([string]::IsNullOrWhiteSpace($field)) {
        return $true
    }

    $actual = $Event.payload

    foreach ($segment in $field.Split(".")) {
        if ($null -eq $actual) {
            break
        }

        $property = $actual.PSObject.Properties[$segment]

        if ($null -eq $property) {
            $actual = $null
            break
        }

        $actual = $property.Value
    }

    switch ($operator.ToLowerInvariant()) {
        "equals" { return [string]$actual -eq [string]$expected }
        "not_equals" { return [string]$actual -ne [string]$expected }
        "contains" { return ([string]$actual).Contains([string]$expected) }
        "greater_than" { return [double]$actual -gt [double]$expected }
        "less_than" { return [double]$actual -lt [double]$expected }
        "exists" { return $null -ne $actual }
        "not_exists" { return $null -eq $actual }
        default { throw "Unsupported condition operator: $operator" }
    }
}

function Add-AIOfficeAutomationExecutionLog {
    param([Parameter(Mandatory=$true)]$Record)

    $root = Get-AIOfficeAutomationRoot
    $fileName = [string]$Record.run_id + ".json"
    $path = Join-Path $root ("workspace\automation\execution-log\" + $fileName)

    Write-AIOfficeAutomationJson -Value $Record -Path $path
    return $path
}
