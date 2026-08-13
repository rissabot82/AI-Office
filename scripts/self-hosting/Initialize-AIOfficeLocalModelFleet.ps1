param(
    [switch]$SkipOptionalModels
)

$ErrorActionPreference = "Stop"

$Policy = & "E:\AI\AI-Office\scripts\self-hosting\Get-AIOfficeModelFleetPolicy.ps1"

$Results = New-Object System.Collections.Generic.List[object]

foreach ($Definition in @($Policy.profiles)) {
    if ([bool]$Definition.required) {
        $Result = & "E:\AI\AI-Office\scripts\self-hosting\Install-AIOfficeFleetModel.ps1" `
            -Model ([string]$Definition.model)

        $Results.Add($Result)
    }
    elseif (-not $SkipOptionalModels) {
        $Result = & "E:\AI\AI-Office\scripts\self-hosting\Install-AIOfficeFleetModel.ps1" `
            -Model ([string]$Definition.model) `
            -Optional

        $Results.Add($Result)
    }
}

& "E:\AI\AI-Office\scripts\self-hosting\Sync-AIOfficeSpecializedModelProfiles.ps1" | Out-Null
$Fleet = & "E:\AI\AI-Office\scripts\self-hosting\New-AIOfficeModelFleetSnapshot.ps1"

if ([string]$Fleet.status -ne "ready") {
    throw "Required local model fleet members are missing."
}

Write-Host "Local model fleet initialized." -ForegroundColor Green
return [pscustomobject]@{
    results = @($Results | ForEach-Object { $_ })
    fleet = $Fleet
}
