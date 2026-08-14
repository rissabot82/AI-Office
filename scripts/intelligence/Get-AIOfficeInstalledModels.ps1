param()

$ErrorActionPreference = "Stop"

$Models = New-Object System.Collections.Generic.List[object]

try {
    $Raw = & ollama list 2>&1
    if ($LASTEXITCODE -eq 0) {
        foreach ($Line in @($Raw | Select-Object -Skip 1)) {
            if ([string]::IsNullOrWhiteSpace([string]$Line)) { continue }

            $Parts = ([string]$Line -split '\s{2,}') | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

            if ($Parts.Count -ge 1) {
                $Models.Add([pscustomobject]@{
                    provider = "ollama"
                    model = [string]$Parts[0]
                    available = $true
                    source = "ollama list"
                })
            }
        }
    }
}
catch {
}

return @($Models.ToArray())
