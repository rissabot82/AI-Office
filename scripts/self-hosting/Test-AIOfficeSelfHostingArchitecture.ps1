param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing Self-Hosted AI Office Part A Local Inference Architecture..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\self-hosting\self-hosting-policy.json",
    ".\config\self-hosting\provider-schema.json",
    ".\config\self-hosting\model-profile-schema.json",
    ".\config\self-hosting\routing-rule-schema.json",
    ".\config\self-hosting\hardware-profile-schema.json",
    ".\workspace\self-hosting\indexes\self-hosting-index.json",
    ".\workspace\templates\self-hosting-provider-template.json",
    ".\workspace\templates\self-hosting-model-profile-template.json",
    ".\workspace\templates\self-hosting-routing-rule-template.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw | ConvertFrom-Json | Out-Null
        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $File" -ForegroundColor Red
        $Errors.Add("Invalid JSON: $File")
    }
}

$Scripts = @(
    ".\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1",
    ".\scripts\self-hosting\New-AIOfficeSelfHostedProvider.ps1",
    ".\scripts\self-hosting\New-AIOfficeLocalModelProfile.ps1",
    ".\scripts\self-hosting\New-AIOfficeModelRoutingRule.ps1",
    ".\scripts\self-hosting\Get-AIOfficeHardwareProfile.ps1",
    ".\scripts\self-hosting\Update-AIOfficeSelfHostingIndex.ps1",
    ".\scripts\self-hosting\Initialize-AIOfficeSelfHostingArchitecture.ps1",
    ".\scripts\self-hosting\Test-AIOfficeSelfHostingArchitecture.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING] $Script" -ForegroundColor Red
        $Errors.Add("Missing script: $Script")
    }
}

$Created = New-Object System.Collections.Generic.List[object]

try {
    $Provider = & ".\scripts\self-hosting\New-AIOfficeSelfHostedProvider.ps1" `
        -Name "Certification Local Runtime" `
        -ProviderType "ollama" `
        -Endpoint "http://127.0.0.1:11434" `
        -Status "connected"

    $Created.Add([pscustomobject]@{ type="provider"; id=[string]$Provider.provider_id })

    $Model = & ".\scripts\self-hosting\New-AIOfficeLocalModelProfile.ps1" `
        -ProviderId ([string]$Provider.provider_id) `
        -ModelName "certification-model" `
        -Status "ready" `
        -CapabilitiesJson '["chat","classification","summarization"]' `
        -ResourceProfileJson '{"vram_gb":4,"ram_gb":8}'

    $Created.Add([pscustomobject]@{ type="model"; id=[string]$Model.model_profile_id })

    $Rule = & ".\scripts\self-hosting\New-AIOfficeModelRoutingRule.ps1" `
        -Name "Certification Route" `
        -Priority 1 `
        -ConditionsJson '{"task_type":"certification"}' `
        -DestinationJson ('{"mode":"local_only","provider_id":"' + [string]$Provider.provider_id + '","model_profile_id":"' + [string]$Model.model_profile_id + '"}')

    $Created.Add([pscustomobject]@{ type="route"; id=[string]$Rule.routing_rule_id })

    $Hardware = & ".\scripts\self-hosting\Get-AIOfficeHardwareProfile.ps1" -Save
    $Created.Add([pscustomobject]@{ type="hardware"; id=[string]$Hardware.hardware_profile_id })

    if ([double]$Hardware.memory.total_gb -le 0) {
        throw "Hardware memory inventory failed."
    }

    $Index = & ".\scripts\self-hosting\Update-AIOfficeSelfHostingIndex.ps1"

    if (
        [int]$Index.provider_count -lt 1 -or
        [int]$Index.model_count -lt 1 -or
        [int]$Index.routing_rule_count -lt 1 -or
        [int]$Index.hardware_profile_count -lt 1
    ) {
        throw "Self-hosting index did not contain certification records."
    }

    Write-Host "[PROVIDER OK] $($Provider.provider_id)" -ForegroundColor Green
    Write-Host "[MODEL OK] $($Model.model_profile_id)" -ForegroundColor Green
    Write-Host "[ROUTING OK] $($Rule.routing_rule_id)" -ForegroundColor Green
    Write-Host "[HARDWARE OK] $($Hardware.hostname) | RAM=$($Hardware.memory.total_gb) GB" -ForegroundColor Green
    Write-Host "[INDEX OK] Self-hosting aggregation passed." -ForegroundColor Green
}
catch {
    Write-Host "[SELF-HOST ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

foreach ($Item in $Created) {
    $Path = ""

    switch ([string]$Item.type) {
        "provider" { $Path = ".\workspace\self-hosting\providers\$($Item.id).json" }
        "model" { $Path = ".\workspace\self-hosting\models\$($Item.id).json" }
        "route" { $Path = ".\workspace\self-hosting\routing-rules\$($Item.id).json" }
        "hardware" { $Path = ".\workspace\self-hosting\hardware\$($Item.id).json" }
    }

    if ($Path -and (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Remove-Item -LiteralPath $Path -Force
    }
}

& ".\scripts\self-hosting\Update-AIOfficeSelfHostingIndex.ps1" | Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Self-Hosting architecture error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All Self-Hosted AI Office Part A Local Inference Architecture checks passed." -ForegroundColor Green
