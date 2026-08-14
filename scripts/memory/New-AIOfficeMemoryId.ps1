param(
    [ValidateSet("MEM","CTX")][string]$Prefix = "MEM"
)

return ($Prefix + "-" + (Get-Date -Format "yyyyMMdd-HHmmss") + "-" + [guid]::NewGuid().ToString("N").Substring(0,6).ToUpperInvariant())
