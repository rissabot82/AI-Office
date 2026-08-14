param(
    [Parameter(Mandatory=$true)][string]$Prefix
)

$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$Suffix = ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()

return "$Prefix-$Stamp-$Suffix"
