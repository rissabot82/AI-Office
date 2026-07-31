param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$Errors = New-Object System.Collections.Generic.List[string]

$Files = @(
    ".\config\security\gateway-token-rotation-policy.json",
    ".\scripts\utilities\Rotate-AIOfficeGatewayToken.ps1"
)

foreach ($File in $Files) {
    if (Test-Path -LiteralPath $File -PathType Leaf) {
        Write-Host "[FOUND] $File" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING] $File" -ForegroundColor Red
        $Errors.Add("Missing: $File")
    }
}

try {
    Get-Content 
        -LiteralPath ".\config\security\gateway-token-rotation-policy.json" 
        -Raw |
        ConvertFrom-Json |
        Out-Null

    Write-Host "[VALID JSON] gateway-token-rotation-policy.json" 
        -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

$Tokens = $null
$ParseErrors = $null

[System.Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path ".\scripts\utilities\Rotate-AIOfficeGatewayToken.ps1"),
    [ref]$Tokens,
    [ref]$ParseErrors
) | Out-Null

if ($ParseErrors.Count -eq 0) {
    Write-Host "[SYNTAX OK] Rotate-AIOfficeGatewayToken.ps1" 
        -ForegroundColor Green
}
else {
    $Errors.Add(($ParseErrors | ForEach-Object { $_.Message }) -join "; ")
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) utility validation error(s) found." 
        -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Gateway token rotation utility validation passed." 
    -ForegroundColor Green
