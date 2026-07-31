param(
    [Parameter(Mandatory=$true)][string]$MemoryId,
    [switch]$TrackAccess
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryRecall.Common.ps1")

$File = Find-AIOfficeMemoryFile -MemoryId $MemoryId

if ($null -eq $File) {
    throw "Long-term memory record not found: $MemoryId"
}

$Record = Read-AIOfficeMemoryJson -Path $File.FullName

if ($TrackAccess) {
    $Record.access_count = [int]$Record.access_count + 1
    $Record.last_accessed_at = (Get-Date).ToString("o")
    $Record.updated_at = (Get-Date).ToString("o")

    Write-AIOfficeMemoryJson -Value $Record -Path $File.FullName
}

return $Record
