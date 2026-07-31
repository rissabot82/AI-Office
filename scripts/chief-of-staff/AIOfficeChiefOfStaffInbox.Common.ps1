. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaff.Common.ps1")

function Get-AIOfficeChiefOfStaffInboxPolicy {
    $Root = Get-AIOfficeChiefOfStaffRoot

    return Read-AIOfficeChiefOfStaffJson `
        -Path (Join-Path $Root "config\chief-of-staff\inbox-policy.json")
}

function New-AIOfficeChiefOfStaffClassificationId {
    return (
        "CLS-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeChiefOfStaffClassificationRule {
    param(
        [Parameter(Mandatory=$true)][string]$MessageType
    )

    $Policy = Get-AIOfficeChiefOfStaffInboxPolicy

    if ($null -eq $Policy) {
        throw "Chief of Staff inbox policy could not be loaded."
    }

    $Rule = @(
        $Policy.classification_rules |
            Where-Object {
                @($_.message_types) -contains $MessageType
            }
    ) | Select-Object -First 1

    return $Rule
}
