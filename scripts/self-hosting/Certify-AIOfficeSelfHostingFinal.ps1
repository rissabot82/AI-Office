param()

$ErrorActionPreference = "Stop"

$Checks = New-Object System.Collections.Generic.List[object]

function Add-FinalCheck {
    param([string]$Name,[bool]$Passed,[string]$Details)

    $Checks.Add([pscustomobject]@{
        name = $Name
        passed = $Passed
        details = $Details
    })
}

function Invoke-FinalScriptCheck {
    param(
        [string]$Name,
        [string]$ScriptPath,
        [string]$ExpectedText
    )

    try {
        $Output = & powershell.exe `
            -NoProfile `
            -ExecutionPolicy Bypass `
            -File $ScriptPath 2>&1

        $ExitCode = $LASTEXITCODE
        $Text = ($Output | Out-String).Trim()
        $Passed = ($ExitCode -eq 0 -and $Text -like ("*" + $ExpectedText + "*"))

        Add-FinalCheck `
            -Name $Name `
            -Passed $Passed `
            -Details $(if ($Passed) { "Validation passed." } else { $Text })
    }
    catch {
        Add-FinalCheck -Name $Name -Passed $false -Details $_.Exception.Message
    }
}

Invoke-FinalScriptCheck `
    -Name "Part A Local Inference Architecture" `
    -ScriptPath "E:\AI\AI-Office\scripts\self-hosting\Test-AIOfficeSelfHostingArchitecture.ps1" `
    -ExpectedText "All Self-Hosted AI Office Part A Local Inference Architecture checks passed."

Invoke-FinalScriptCheck `
    -Name "Part B Local Inference Runtime" `
    -ScriptPath "E:\AI\AI-Office\scripts\self-hosting\Test-AIOfficeLocalInferenceRuntime.ps1" `
    -ExpectedText "All Self-Hosted AI Office Part B Local Inference Runtime checks passed."

Invoke-FinalScriptCheck `
    -Name "Part D Model Routing and Hybrid Execution" `
    -ScriptPath "E:\AI\AI-Office\scripts\self-hosting\Test-AIOfficeHybridRouting.ps1" `
    -ExpectedText "All Self-Hosted AI Office Part D Model Routing and Hybrid Execution checks passed."

Invoke-FinalScriptCheck `
    -Name "Part E Intelligent Model Selection" `
    -ScriptPath "E:\AI\AI-Office\scripts\self-hosting\Test-AIOfficeIntelligentModelSelection.ps1" `
    -ExpectedText "All Self-Hosted AI Office Part E Intelligent Model Selection and Workload Optimization checks passed."

Invoke-FinalScriptCheck `
    -Name "Part F Local Model Fleet" `
    -ScriptPath "E:\AI\AI-Office\scripts\self-hosting\Test-AIOfficeLocalModelFleet.ps1" `
    -ExpectedText "All Self-Hosted AI Office Part F Local Model Fleet and Specialized Models checks passed."

Invoke-FinalScriptCheck `
    -Name "Part G Resilience and Failover" `
    -ScriptPath "E:\AI\AI-Office\scripts\self-hosting\Test-AIOfficeResilience.ps1" `
    -ExpectedText "All Self-Hosted AI Office Part G Resilience, Failover and Resource Management checks passed."

try {
    & "E:\AI\AI-Office\scripts\self-hosting\Test-AIOfficeSelfHostingFinalDashboard.ps1" | Out-Null
    Add-FinalCheck -Name "Part H Final Dashboard" -Passed $true -Details "Final dashboard validation passed."
}
catch {
    Add-FinalCheck -Name "Part H Final Dashboard" -Passed $false -Details $_.Exception.Message
}

try {
    $Manifest = Get-Content `
        -LiteralPath "E:\AI\AI-Office\config\self-hosting\final-release-manifest.json" `
        -Raw |
        ConvertFrom-Json

    $Passed = (
        [string]$Manifest.version -eq "2.2.0" -and
        [string]$Manifest.status -eq "release_candidate"
    )

    Add-FinalCheck `
        -Name "Final Release Manifest" `
        -Passed $Passed `
        -Details ("version=" + [string]$Manifest.version + "; status=" + [string]$Manifest.status)
}
catch {
    Add-FinalCheck -Name "Final Release Manifest" -Passed $false -Details $_.Exception.Message
}

$PassedCount = @($Checks | Where-Object { $_.passed -eq $true }).Count
$FailedCount = @($Checks | Where-Object { $_.passed -ne $true }).Count
$Status = if ($FailedCount -eq 0) { "certified" } else { "failed" }

$Certification = [pscustomobject]@{
    certification_id = "CERT-SHFINAL-" + (Get-Date).ToString("yyyyMMdd-HHmmss")
    version = "2.2.0"
    release_name = "Self-Hosted AI Office"
    certified_at = (Get-Date).ToString("o")
    status = $Status
    passed_checks = $PassedCount
    failed_checks = $FailedCount
    checks = @($Checks | ForEach-Object { $_ })
}

$Directory = "E:\AI\AI-Office\workspace\self-hosting\certifications"
New-Item -ItemType Directory -Path $Directory -Force | Out-Null

$Certification |
    ConvertTo-Json -Depth 100 |
    Set-Content `
        -LiteralPath (Join-Path $Directory ($Certification.certification_id + ".json")) `
        -Encoding UTF8

Write-Host ""
Write-Host "Self-Hosted AI Office final certification: $Status | $PassedCount passed, $FailedCount failed" `
    -ForegroundColor $(if ($Status -eq "certified") { "Green" } else { "Red" })

return $Certification
