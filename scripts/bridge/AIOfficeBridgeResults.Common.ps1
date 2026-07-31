. (Join-Path $PSScriptRoot "AIOfficeBridge.Common.ps1")

function Get-AIOfficeBridgeResultPolicy {
    $Root = Get-AIOfficeBridgeRoot

    return Read-AIOfficeBridgeJson `
        -Path (Join-Path $Root "config\bridge\result-policy.json")
}

function New-AIOfficeNormalizedResultId {
    return (
        "NRR-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeArtifactManifestId {
    return (
        "AMF-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeFileSha256 {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return ""
    }

    return [string](
        Get-FileHash -LiteralPath $Path -Algorithm SHA256
    ).Hash
}

function Get-AIOfficeArtifactType {
    param([Parameter(Mandatory=$true)][string]$Path)

    $Extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()

    switch ($Extension) {
        ".png" { return "screenshot" }
        ".jpg" { return "screenshot" }
        ".jpeg" { return "screenshot" }
        ".webp" { return "screenshot" }
        ".pdf" { return "report" }
        ".json" { return "json" }
        ".log" { return "log" }
        ".txt" { return "log" }
        default { return "file" }
    }
}

function Get-AIOfficeArtifactDestinationFolder {
    param([Parameter(Mandatory=$true)][string]$ArtifactType)

    $Root = Get-AIOfficeBridgeRoot

    switch ($ArtifactType) {
        "screenshot" {
            return Join-Path $Root "workspace\bridge\artifacts\screenshots"
        }
        "download" {
            return Join-Path $Root "workspace\bridge\artifacts\downloads"
        }
        "report" {
            return Join-Path $Root "workspace\bridge\artifacts\reports"
        }
        default {
            return Join-Path $Root "workspace\bridge\artifacts\files"
        }
    }
}

function ConvertTo-AIOfficeArtifactArray {
    param([AllowNull()]$Value)

    if ($null -eq $Value) {
        return @()
    }

    return @($Value | ForEach-Object { $_ })
}

function Find-AIOfficeArtifactCandidates {
    param([AllowNull()]$Value)

    $Results = New-Object System.Collections.Generic.List[object]

    function Visit-AIOValue {
        param(
            [AllowNull()]$Current,
            [string]$PropertyName = ""
        )

        if ($null -eq $Current) {
            return
        }

        if ($Current -is [string]) {
            $Text = [string]$Current

            if (Test-Path -LiteralPath $Text -PathType Leaf) {
                $Results.Add([pscustomobject]@{
                    path = (Resolve-Path -LiteralPath $Text).Path
                    source_property = $PropertyName
                })
            }

            return
        }

        if ($Current -is [System.Collections.IDictionary]) {
            foreach ($Key in $Current.Keys) {
                Visit-AIOValue `
                    -Current $Current[$Key] `
                    -PropertyName ([string]$Key)
            }

            return
        }

        if ($Current -is [System.Collections.IEnumerable] -and
            -not ($Current -is [string])) {
            foreach ($Item in $Current) {
                Visit-AIOValue `
                    -Current $Item `
                    -PropertyName $PropertyName
            }

            return
        }

        foreach ($Property in $Current.PSObject.Properties) {
            Visit-AIOValue `
                -Current $Property.Value `
                -PropertyName ([string]$Property.Name)
        }
    }

    Visit-AIOValue -Current $Value

    return @(
        $Results |
            Sort-Object path -Unique
    )
}

function Get-AIOfficeResultSummary {
    param(
        [Parameter(Mandatory=$true)]$Execution
    )

    if ([string]$Execution.status -eq "failed") {
        if ($null -ne $Execution.error -and
            -not [string]::IsNullOrWhiteSpace([string]$Execution.error.message)) {
            return [string]$Execution.error.message
        }

        return "OpenClaw execution failed."
    }

    $Payload = $Execution.response_payload

    if ($null -eq $Payload) {
        return "OpenClaw execution completed without a response payload."
    }

    foreach ($PropertyName in @(
        "summary",
        "text",
        "message",
        "result",
        "output",
        "content"
    )) {
        $Property = $Payload.PSObject.Properties[$PropertyName]

        if ($null -ne $Property -and
            $Property.Value -is [string] -and
            -not [string]::IsNullOrWhiteSpace([string]$Property.Value)) {
            return [string]$Property.Value
        }
    }

    return "OpenClaw execution completed successfully."
}
