param()
$ErrorActionPreference="Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "AI OFFICE v2.5.1 HOTFIX CERTIFICATION" -ForegroundColor Cyan
Write-Host "====================================="
Write-Host ""

$Checks=New-Object System.Collections.Generic.List[object]
function Add-Check{param([string]$Name,[bool]$Passed,[string]$Details)
    $Checks.Add([pscustomobject]@{name=$Name;passed=$Passed;details=$Details})
}

try{
    $Base=& ".\scripts\intelligence\Certify-AIOfficeIntelligenceUpgrade.ps1"
    if([string]$Base.status-ne"passed"-or[int]$Base.failed_checks-ne0){throw "Base v2.5 certification failed."}
    Add-Check "Base v2.5 Certification" $true "Base certification passed."
}catch{Add-Check "Base v2.5 Certification" $false $_.Exception.Message}

try{
    $R=Get-Content ".\scripts\discord-office\AIOfficeDiscordRuntime.Common.ps1" -Raw
    if(-not $R.Contains("[System.Text.Encoding]::UTF8.GetBytes")){throw "UTF8.GetBytes missing."}
    if(-not $R.Contains("application/json; charset=utf-8")){throw "UTF-8 content type missing."}
    Add-Check "Discord UTF-8 Transport" $true "Explicit UTF-8 JSON transport present."
}catch{Add-Check "Discord UTF-8 Transport" $false $_.Exception.Message}

try{
    $W=Get-Content ".\scripts\discord-office\Invoke-AIOfficeDiscordWorker.ps1" -Raw
    foreach($M in @("failed-messages","quarantined_at","last_message_id")){
        if(-not $W.Contains($M)){throw "Missing poison-message marker: $M"}
    }
    Add-Check "Poison-Message Protection" $true "Failed messages are quarantined and advanced."
}catch{Add-Check "Poison-Message Protection" $false $_.Exception.Message}

try{
    $V=Get-Content ".\scripts\intelligence\Test-AIOfficeResponseQuality.ps1" -Raw
    foreach($M in @("BEGIN CONVERSATION PROMPT","END CONVERSATION PROMPT","IMPORTANT RETRY INSTRUCTION:")){
        if(-not $V.Contains($M)){throw "Missing validator marker: $M"}
    }
    $Leak=& ".\scripts\intelligence\Test-AIOfficeResponseQuality.ps1" -Response "Dinner text.`nUSER: internal`nEND CONVERSATION PROMPT"
    if([bool]$Leak.passed){throw "Prompt-leak sample incorrectly passed."}
    Add-Check "Prompt-Leak Validation" $true "Prompt leakage is rejected."
}catch{Add-Check "Prompt-Leak Validation" $false $_.Exception.Message}

try{
    $Q=Get-Content ".\scripts\intelligence\Invoke-AIOfficeQualityControlledInference.ps1" -Raw
    foreach($M in @("output_sanitized","FirstLeakIndex","Final user-facing output boundary")){
        if(-not $Q.Contains($M)){throw "Missing sanitizer marker: $M"}
    }
    Add-Check "Final Output Sanitizer" $true "Final output boundary present."
}catch{Add-Check "Final Output Sanitizer" $false $_.Exception.Message}

try{
    $Ops=& ".\scripts\discord-office\Get-AIOfficeDiscordOperationsStatus.ps1"
    if(-not[bool]$Ops.discord_connected){throw "Discord disconnected."}
    if([string]$Ops.worker_status-ne"running"){throw "Worker not running."}
    if([string]$Ops.self_hosting_status-ne"healthy"){throw "Self-hosting unhealthy."}
    Add-Check "Discord Runtime Health" $true ("connected; worker=running; errors="+$Ops.worker_errors)
}catch{Add-Check "Discord Runtime Health" $false $_.Exception.Message}

$Passed=@($Checks|Where-Object{$_.passed}).Count
$Failed=@($Checks|Where-Object{-not $_.passed}).Count
$Status=if($Failed-eq0){"passed"}else{"failed"}

foreach($C in $Checks){
    if($C.passed){
        $Prefix = "[PASS] "
        $Color = "Green"
    }
    else{
        $Prefix = "[FAIL] "
        $Color = "Red"
    }

    Write-Host ($Prefix + $C.name) -ForegroundColor $Color
}

$Result=[ordered]@{
    certification_id="CERT-HOTFIX-"+(Get-Date -Format "yyyyMMdd-HHmmss")
    version="2.5.1"
    release_name="Discord Reliability Hotfix"
    status=$Status
    passed_checks=$Passed
    failed_checks=$Failed
    checks=$Checks.ToArray()
    certified_at=(Get-Date).ToString("o")
}

$Dir=".\workspace\intelligence\certifications"
New-Item -ItemType Directory -Path $Dir -Force|Out-Null
$Path=Join-Path $Dir ($Result.certification_id+".json")
$Result|ConvertTo-Json -Depth 50|Set-Content $Path -Encoding UTF8

Write-Host ""
if($Failed -eq 0){
    $StatusColor = "Green"
}
else{
    $StatusColor = "Red"
}

Write-Host ("Status: "+$Status+" | Passed="+$Passed+" | Failed="+$Failed) -ForegroundColor $StatusColor
Write-Host ("Certification: "+$Path) -ForegroundColor Cyan
return [pscustomobject]$Result

