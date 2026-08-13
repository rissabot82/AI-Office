param()

$ErrorActionPreference = "Stop"

$Checks = New-Object System.Collections.Generic.List[object]

function Add-SelfHostingCertificationCheck {
    param([string]$Name,[bool]$Passed,[string]$Details)
    $Checks.Add([pscustomobject]@{ name=$Name; passed=$Passed; details=$Details })
}

function Invoke-SelfHostingValidation {
    param([string]$Name,[string]$ScriptPath,[string]$ExpectedText)
    try {
        $Output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath 2>&1
        $ExitCode = $LASTEXITCODE
        $Text = ($Output | Out-String).Trim()
        $Passed = ($ExitCode -eq 0 -and $Text -like ("*" + $ExpectedText + "*"))
        Add-SelfHostingCertificationCheck -Name $Name -Passed $Passed -Details $(if ($Passed) { "Validation passed." } else { $Text })
    }
    catch {
        Add-SelfHostingCertificationCheck -Name $Name -Passed $false -Details $_.Exception.Message
    }
}

Invoke-SelfHostingValidation `
    -Name "Part A Local Inference Architecture" `
    -ScriptPath "E:\AI\AI-Office\scripts\self-hosting\Test-AIOfficeSelfHostingArchitecture.ps1" `
    -ExpectedText "All Self-Hosted AI Office Part A Local Inference Architecture checks passed."

Invoke-SelfHostingValidation `
    -Name "Part B Local Inference Runtime" `
    -ScriptPath "E:\AI\AI-Office\scripts\self-hosting\Test-AIOfficeLocalInferenceRuntime.ps1" `
    -ExpectedText "All Self-Hosted AI Office Part B Local Inference Runtime checks passed."

try {
    & "E:\AI\AI-Office\scripts\self-hosting\Test-AIOfficeSelfHostingDashboard.ps1" | Out-Null
    Add-SelfHostingCertificationCheck -Name "Self-Hosting Dashboard" -Passed $true -Details "Dashboard validation passed."
}
catch {
    Add-SelfHostingCertificationCheck -Name "Self-Hosting Dashboard" -Passed $false -Details $_.Exception.Message
}

try {
    $Manifest = Get-Content -LiteralPath "E:\AI\AI-Office\config\self-hosting\release-manifest.json" -Raw | ConvertFrom-Json
    $ManifestPassed = ([string]$Manifest.phase -eq "Self-Hosted AI Office" -and [string]$Manifest.part -eq "C")
    Add-SelfHostingCertificationCheck -Name "Release Manifest" -Passed $ManifestPassed -Details ("status=" + [string]$Manifest.status)
}
catch {
    Add-SelfHostingCertificationCheck -Name "Release Manifest" -Passed $false -Details $_.Exception.Message
}

$PassedCount = @($Checks | Where-Object { $_.passed -eq $true }).Count
$FailedCount = @($Checks | Where-Object { $_.passed -ne $true }).Count
$Status = if ($FailedCount -eq 0) { "certified" } else { "failed" }

$Certification = [pscustomobject]@{
    certification_id = "CERT-SH-" + (Get-Date).ToString("yyyyMMdd-HHmmss")
    phase = "Self-Hosted AI Office"
    release_name = "Self-Hosted AI Office Foundation"
    certified_at = (Get-Date).ToString("o")
    status = $Status
    passed_checks = $PassedCount
    failed_checks = $FailedCount
    checks = @($Checks | ForEach-Object { $_ })
}

$Directory = "E:\AI\AI-Office\workspace\self-hosting\certifications"
New-Item -ItemType Directory -Path $Directory -Force | Out-Null

$Certification | ConvertTo-Json -Depth 50 | Set-Content -LiteralPath (Join-Path $Directory ($Certification.certification_id + ".json")) -Encoding UTF8

Write-Host ""
Write-Host "Self-Hosted AI Office certification: $Status | $PassedCount passed, $FailedCount failed" `
    -ForegroundColor $(if ($Status -eq "certified") { "Green" } else { "Red" })

return $Certification
