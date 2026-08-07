param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$Files = @(
    "E:\AI\AI-Office\config\health\health-policy.json",
    "E:\AI\AI-Office\scripts\health\Get-AIOfficeGatewayToken.ps1",
    "E:\AI\AI-Office\scripts\health\Get-AIOfficeSystemHealth.ps1",
    "E:\AI\AI-Office\scripts\health\Start-AIOffice.ps1"
)

$Errors = New-Object System.Collections.Generic.List[string]

foreach ($File in $Files) {
    if (Test-Path -LiteralPath $File -PathType Leaf) {
        Write-Host "[FOUND] $File" -ForegroundColor Green
    } else {
        Write-Host "[MISSING] $File" -ForegroundColor Red
        $Errors.Add("Missing: $File")
    }
}

Get-Content -LiteralPath "E:\AI\AI-Office\config\health\health-policy.json" -Raw | ConvertFrom-Json | Out-Null
Write-Host "[VALID JSON] health-policy.json" -ForegroundColor Green

foreach ($Script in $Files | Where-Object {$_ -like "*.ps1"}) {
    $Tokens = $null
    $ParseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($Script,[ref]$Tokens,[ref]$ParseErrors) | Out-Null

    if ($ParseErrors.Count -eq 0) {
        Write-Host "[SYNTAX OK] $Script" -ForegroundColor Green
    } else {
        $Errors.Add($Script + ": " + (($ParseErrors | ForEach-Object {$_.Message}) -join "; "))
    }
}

if ($Errors.Count -gt 0) {
    Write-Host "$($Errors.Count) health utility error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "AI Office startup and health utilities passed validation." -ForegroundColor Green
