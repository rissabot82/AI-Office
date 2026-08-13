$script:AIOfficeHybridRoutingRoot = "E:\AI\AI-Office"

function Get-AIOfficeHybridRoutingPolicy {
    return Get-Content `
        -LiteralPath "E:\AI\AI-Office\config\self-hosting\hybrid-routing-policy.json" `
        -Raw |
        ConvertFrom-Json
}

function Get-AIOfficeLatestLocalHealth {
    $Directory = "E:\AI\AI-Office\workspace\self-hosting\health"

    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        return $null
    }

    $File = Get-ChildItem `
        -LiteralPath $Directory `
        -Filter "SHHEALTH-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -eq $File) {
        return $null
    }

    try {
        return Get-Content -LiteralPath $File.FullName -Raw | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function Get-AIOfficeDefaultLocalModel {
    try {
        $Policy = Get-Content `
            -LiteralPath "E:\AI\AI-Office\config\self-hosting\runtime-policy.json" `
            -Raw |
            ConvertFrom-Json

        return [string]$Policy.default_model
    }
    catch {
        return "qwen2.5:3b"
    }
}
