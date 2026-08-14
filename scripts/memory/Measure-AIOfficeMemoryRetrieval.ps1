param(
 [Parameter(Mandatory=$true)][string]$Query,
 [string]$Scope="global",
 [int]$MaxItems=8
)

$ErrorActionPreference="Stop"
Set-Location "E:\AI\AI-Office"

$Timer=[System.Diagnostics.Stopwatch]::StartNew()
$Results=@(
    & ".\scripts\memory\Search-AIOfficeMemory.ps1" `
        -Query $Query `
        -Scope $Scope `
        -MaxItems $MaxItems
)
$Timer.Stop()

return [pscustomobject]@{
    query=$Query
    scope=$Scope
    result_count=$Results.Count
    elapsed_ms=[math]::Round($Timer.Elapsed.TotalMilliseconds,2)
    results=$Results
}
