param(
    [Parameter(Mandatory=$true)][string]$ExecutionId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeBridgeResults.Common.ps1")

$Root = Get-AIOfficeBridgeRoot
Set-Location $Root

$ExecutionPath = Join-Path `
    ".\workspace\bridge\executions" `
    ($ExecutionId + ".json")

$Execution = Read-AIOfficeBridgeJson -Path $ExecutionPath

if ($null -eq $Execution) {
    throw "Execution record not found: $ExecutionId"
}

$Policy = Get-AIOfficeBridgeResultPolicy

if ($null -eq $Policy) {
    throw "Bridge result policy could not be loaded."
}

$Candidates = @(
    Find-AIOfficeArtifactCandidates `
        -Value $Execution.response_payload
)

$Artifacts = New-Object System.Collections.Generic.List[object]

foreach ($Candidate in $Candidates) {
    $SourcePath = [string]$Candidate.path
    $Type = Get-AIOfficeArtifactType -Path $SourcePath
    $DestinationFolder = Get-AIOfficeArtifactDestinationFolder `
        -ArtifactType $Type

    $FileInfo = Get-Item -LiteralPath $SourcePath
    $MaxBytes = [int64]$Policy.artifact_handling.maximum_artifact_size_mb * 1MB

    if ($FileInfo.Length -gt $MaxBytes) {
        continue
    }

    $DestinationPath = $SourcePath

    if ([bool]$Policy.artifact_handling.copy_local_files) {
        $DestinationName = (
            $ExecutionId +
            "-" +
            [guid]::NewGuid().ToString("N").Substring(0,8) +
            "-" +
            $FileInfo.Name
        )

        $DestinationPath = Join-Path $DestinationFolder $DestinationName

        Copy-Item `
            -LiteralPath $SourcePath `
            -Destination $DestinationPath `
            -Force
    }

    $Hash = ""

    if ([bool]$Policy.artifact_handling.calculate_sha256) {
        $Hash = Get-AIOfficeFileSha256 -Path $DestinationPath
    }

    $Artifacts.Add([ordered]@{
        artifact_id = (
            "ART-" +
            ([guid]::NewGuid().ToString("N").Substring(0,12)).ToUpperInvariant()
        )
        type = $Type
        source_path = $SourcePath
        stored_path = $DestinationPath
        file_name = [System.IO.Path]::GetFileName($DestinationPath)
        extension = [System.IO.Path]::GetExtension($DestinationPath)
        size_bytes = (Get-Item -LiteralPath $DestinationPath).Length
        sha256 = $Hash
        source_property = [string]$Candidate.source_property
        created_at = (Get-Date).ToString("o")
    })
}

$ManifestId = New-AIOfficeArtifactManifestId

$Manifest = [ordered]@{
    artifact_manifest_id = $ManifestId
    execution_id = $ExecutionId
    bridge_request_id = [string]$Execution.bridge_request_id
    created_at = (Get-Date).ToString("o")
    artifact_count = $Artifacts.Count
    artifacts = @($Artifacts | ForEach-Object { $_ })
}

$ManifestPath = Join-Path `
    ".\workspace\bridge\artifacts\manifests" `
    ($ManifestId + ".json")

Write-AIOfficeBridgeJson -Value $Manifest -Path $ManifestPath

Write-Host (
    "Artifact manifest created: " +
    $ManifestId +
    " | " +
    $Artifacts.Count.ToString() +
    " artifact(s)"
) -ForegroundColor Green

return [pscustomobject]$Manifest
