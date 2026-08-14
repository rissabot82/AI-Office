param()
$ErrorActionPreference="Stop"
Set-Location "E:\AI\AI-Office"

$Checks=New-Object System.Collections.Generic.List[object]

function Add-CertCheck {
    param([string]$Name,[bool]$Passed,[string]$Details)
    $Checks.Add([pscustomobject]@{name=$Name;passed=$Passed;details=$Details})
}

function Invoke-ScriptCert {
    param([string]$Name,[string]$Script,[string]$Expected,[string[]]$Arguments=@())
    try {
        $Output=& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Script @Arguments 2>&1
        $ExitCode=$LASTEXITCODE
        $Text=($Output|Out-String).Trim()
        $Passed=($ExitCode -eq 0 -and $Text -like ("*"+$Expected+"*"))
        Add-CertCheck -Name $Name -Passed $Passed -Details $(if($Passed){"Validation passed."}else{$Text})
    } catch {
        Add-CertCheck -Name $Name -Passed $false -Details $_.Exception.Message
    }
}

Invoke-ScriptCert "Part A Discord Gateway Architecture" "E:\AI\AI-Office\scripts\discord-office\Test-AIOfficeDiscordGatewayArchitecture.ps1" "All AI Office v2.4 Part A Discord Gateway Architecture checks passed."
Invoke-ScriptCert "Part B Live Discord Intake" "E:\AI\AI-Office\scripts\discord-office\Test-AIOfficeDiscordLiveRuntime.ps1" "All AI Office v2.4 Part B Live Discord Intake structural checks passed."
Invoke-ScriptCert "Part C Persistent Sessions and Commands" "E:\AI\AI-Office\scripts\discord-office\Test-AIOfficeDiscordPersistentSessions.ps1" "All AI Office v2.4 Part C Persistent Sessions and Commands checks passed."
Invoke-ScriptCert "Part D Department Routing" "E:\AI\AI-Office\scripts\discord-office\Test-AIOfficeDiscordDepartmentRouting.ps1" "All AI Office v2.4 Part D Department and Agent Routing checks passed."
Invoke-ScriptCert "Part E Discord Worker Service" "E:\AI\AI-Office\scripts\discord-office\Test-AIOfficeDiscordWorker.ps1" "All AI Office v2.4 Part E Discord Worker Service checks passed."
Invoke-ScriptCert "Part F Discord Operations and Control" "E:\AI\AI-Office\scripts\discord-office\Test-AIOfficeDiscordOperationsControl.ps1" "All AI Office v2.4 Part F Discord Operations and Control checks passed."
Invoke-ScriptCert "Part G Discord Safety and Audit" "E:\AI\AI-Office\scripts\discord-office\Test-AIOfficeDiscordSafetyAudit.ps1" "All AI Office v2.4 Part G Discord Safety and Audit checks passed."
Invoke-ScriptCert "Part H Live Activation" "E:\AI\AI-Office\scripts\discord-office\Test-AIOfficeDiscordLiveActivation.ps1" "All AI Office v2.4 Part H Live Discord Activation and Certification structural checks passed."

try {
    $Readiness=& "E:\AI\AI-Office\scripts\discord-office\Test-AIOfficeDiscordActivationReadiness.ps1"
    Add-CertCheck "Live Activation Readiness" ([bool]$Readiness.ready) ("Ready={0}; Passed={1}; Failed={2}" -f $Readiness.ready,$Readiness.passed,$Readiness.failed)
} catch {
    Add-CertCheck "Live Activation Readiness" $false $_.Exception.Message
}

try {
    $Ops=& "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordOperationsStatus.ps1"
    $Passed=([bool]$Ops.discord_connected -and [string]$Ops.worker_status -eq "running" -and [string]$Ops.self_hosting_status -eq "healthy" -and [bool]$Ops.ollama -and [bool]$Ops.openclaw_gateway -and [bool]$Ops.dashboard)
    Add-CertCheck "Live End-to-End Operations" $Passed ("Discord={0}; Worker={1}; SelfHosting={2}; Ollama={3}; Gateway={4}; Dashboard={5}" -f $Ops.discord_connected,$Ops.worker_status,$Ops.self_hosting_status,$Ops.ollama,$Ops.openclaw_gateway,$Ops.dashboard)
} catch {
    Add-CertCheck "Live End-to-End Operations" $false $_.Exception.Message
}

$PassedCount=@($Checks|Where-Object{$_.passed -eq $true}).Count
$FailedCount=@($Checks|Where-Object{$_.passed -ne $true}).Count
$Status=if($FailedCount -eq 0){"certified"}else{"failed"}

$Certification=[pscustomobject]@{
    certification_id="CERT-DISCORD-"+(Get-Date).ToString("yyyyMMdd-HHmmss")
    version="2.4.0"
    release_name="Discord Mobile Operations"
    status=$Status
    passed_checks=$PassedCount
    failed_checks=$FailedCount
    checks=$Checks.ToArray()
    certified_at=(Get-Date).ToString("o")
}

$Directory="E:\AI\AI-Office\workspace\discord-office\certifications"
New-Item -ItemType Directory -Path $Directory -Force|Out-Null
$Certification|ConvertTo-Json -Depth 100|Set-Content -LiteralPath (Join-Path $Directory ($Certification.certification_id+".json")) -Encoding UTF8

Write-Host ""
Write-Host "Discord Mobile Operations certification: $Status | $PassedCount passed, $FailedCount failed" -ForegroundColor $(if($Status -eq "certified"){"Green"}else{"Red"})
return $Certification
