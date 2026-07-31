param(
    [Parameter(Mandatory=$true)][string]$Department
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartments.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$Profile = Get-AIOfficeDepartmentProfile -Department $Department

$Capabilities = Read-AIOfficeDepartmentJson `
    -Path ".\config\departments\$Department\capabilities.json"

$Index = Read-AIOfficeDepartmentJson `
    -Path ".\workspace\departments\$Department\department-index.json"

return [pscustomobject]@{
    profile = $Profile
    capabilities = $Capabilities
    index = $Index
}
