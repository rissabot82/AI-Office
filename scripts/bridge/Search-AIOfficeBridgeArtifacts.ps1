param(
    [string]$ExecutionId = "",
    [string]$ArtifactType = "",
    [int]$Limit = 100
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeBridgeResults.Common.ps1")

$Root = Get-AIOfficeBridgeRoot
Set-Location $Root

$Results = New-Object System.Collections.Generic.List[object]

foreach ($File in @(
    Get-ChildItem `
        -LiteralPath ".\workspace\bridge\artifacts\manifests" `
        -Filter "AMF-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)) {
    $Manifest = Read-AIOfficeBridgeJson -Path $File.FullName

    if ($null -eq $Manifest) {
        continue
    }

    if ($ExecutionId -and
        [string]$Manifest.execution_id -ne $ExecutionId) {
        continue
    }

    foreach ($Artifact in @($Manifest.artifacts)) {
        if ($ArtifactType -and
            [string]$Artifact.type -ne $ArtifactType) {
            continue
        }

        $Results.Add([pscustomobject]@{
            manifest_id = [string]$Manifest.artifact_manifest_id
            execution_id = [string]$Manifest.execution_id
            artifact_id = [string]$Artifact.artifact_id
            type = [string]$Artifact.type
            file_name = [string]$Artifact.file_name
            stored_path = [string]$Artifact.stored_path
            size_bytes = [int64]$Artifact.size_bytes
            sha256 = [string]$Artifact.sha256
            created_at = [string]$Artifact.created_at
        })
    }
}

return @(
    $Results |
        Sort-Object created_at -Descending |
        Select-Object -First $Limit
)
