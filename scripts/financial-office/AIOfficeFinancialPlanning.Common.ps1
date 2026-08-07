$script:AIOfficeFinancialPlanningRoot = "E:\AI\AI-Office"

function Get-AIOfficeFinancialPlanningPolicy {
    return Get-Content `
        -LiteralPath "E:\AI\AI-Office\config\financial-office\planning-policy.json" `
        -Raw |
        ConvertFrom-Json
}

function New-AIOfficeFinancialPlanningId {
    param([Parameter(Mandatory=$true)][string]$Prefix)

    return (
        $Prefix + "-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}
