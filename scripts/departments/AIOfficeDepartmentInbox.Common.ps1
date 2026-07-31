. (Join-Path $PSScriptRoot "AIOfficeDepartments.Common.ps1")

function Get-AIOfficeDepartmentInboxPolicy {
    $Root = Get-AIOfficeDepartmentRoot

    return Read-AIOfficeDepartmentJson `
        -Path (Join-Path $Root "config\departments\department-inbox-policy.json")
}

function New-AIOfficeDepartmentWorkItemId {
    return (
        "DWI-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeDepartmentClassificationId {
    return (
        "DCL-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeRequestedCapabilities {
    param([AllowNull()]$Payload)

    if ($null -eq $Payload) {
        return @()
    }

    if ($null -ne $Payload.PSObject.Properties["required_capabilities"]) {
        return @($Payload.required_capabilities)
    }

    if ($null -ne $Payload.PSObject.Properties["capabilities"]) {
        return @($Payload.capabilities)
    }

    return @()
}
