$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

function Test-KeywordMatch {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [string]$Keyword
    )

    return (
        $Text.IndexOf(
            $Keyword,
            [System.StringComparison]::OrdinalIgnoreCase
        ) -ge 0
    )
}

function Get-TestRoutingResult {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        $RoutingRules,

        [Parameter(Mandatory = $true)]
        $Policy
    )

    $scores = @()

    foreach ($rule in $RoutingRules.rules) {
        $score = 0

        foreach ($keywordValue in $rule.keywords) {
            $keyword = [string]$keywordValue

            if (Test-KeywordMatch -Text $Title -Keyword $keyword) {
                $score += [int]$Policy.weights.title_keyword

                if ($keyword.Contains(" ")) {
                    $score += [int]$Policy.weights.multiword_bonus
                }
            }

            if (Test-KeywordMatch -Text $Description -Keyword $keyword) {
                $score += [int]$Policy.weights.description_keyword

                if ($keyword.Contains(" ")) {
                    $score += [int]$Policy.weights.multiword_bonus
                }
            }
        }

        $scores += [PSCustomObject]@{
            agent = [string]$rule.agent
            department = [string]$rule.department
            score = $score
        }
    }

    $positive = @(
        $scores |
        Where-Object {
            $_.score -gt 0
        } |
        Sort-Object `
            @{ Expression = "score"; Descending = $true },
            @{ Expression = "agent"; Descending = $false }
    )

    if ($positive.Count -eq 0) {
        return [string]$Policy.default_agent
    }

    $highestScore = $positive[0].score
    $topMatches = @(
        $positive | Where-Object {
            $_.score -eq $highestScore
        }
    )

    if (
        $topMatches.Count -gt 1 -and
        $Policy.rules.send_ties_to_chief_of_staff
    ) {
        return [string]$Policy.mixed_task_agent
    }

    $strongDepartments = @(
        $positive | Where-Object {
            $_.score -ge 4
        }
    )

    if ($strongDepartments.Count -ge 3) {
        return [string]$Policy.mixed_task_agent
    }

    return [string]$positive[0].agent
}

Write-Host ""
Write-Host "Testing AI Office routing engine..." -ForegroundColor Cyan
Write-Host ""

$requiredJsonFiles = @(
    ".\config\tasks\routing-rules.json",
    ".\config\tasks\routing-policy.json",
    ".\config\tasks\routing-test-cases.json",
    ".\config\agents\registry.json"
)

$errorsFound = 0

foreach ($file in $requiredJsonFiles) {
    try {
        Get-Content -LiteralPath $file -Raw |
            ConvertFrom-Json |
            Out-Null

        Write-Host "[VALID JSON] $file" -ForegroundColor Green
    }
    catch {
        Write-Host "[INVALID   ] $file" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $errorsFound++
    }
}

if ($errorsFound -gt 0) {
    Write-Host ""
    Write-Host "JSON validation failed. Routing tests were not run." -ForegroundColor Red
    exit 1
}

$routingRules = Get-Content `
    -LiteralPath ".\config\tasks\routing-rules.json" `
    -Raw |
    ConvertFrom-Json

$policy = Get-Content `
    -LiteralPath ".\config\tasks\routing-policy.json" `
    -Raw |
    ConvertFrom-Json

$testCases = Get-Content `
    -LiteralPath ".\config\tasks\routing-test-cases.json" `
    -Raw |
    ConvertFrom-Json

$registry = Get-Content `
    -LiteralPath ".\config\agents\registry.json" `
    -Raw |
    ConvertFrom-Json

Write-Host ""
Write-Host "Checking routing rules against agent registry..." -ForegroundColor Cyan

foreach ($rule in $routingRules.rules) {
    $matchingAgent = @(
        $registry.agents | Where-Object {
            $_.id -eq $rule.agent
        }
    )

    if ($matchingAgent.Count -eq 0) {
        Write-Host (
            "[MISSING AGENT] {0}" -f $rule.agent
        ) -ForegroundColor Red

        $errorsFound++
    }
    else {
        Write-Host (
            "[REGISTERED   ] {0}" -f $rule.agent
        ) -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Running routing test cases..." -ForegroundColor Cyan
Write-Host ""

foreach ($testCase in $testCases.cases) {
    $actualAgent = Get-TestRoutingResult `
        -Title ([string]$testCase.title) `
        -Description ([string]$testCase.description) `
        -RoutingRules $routingRules `
        -Policy $policy

    if ($actualAgent -eq $testCase.expected_agent) {
        Write-Host (
            "[PASS] {0} -> {1}" -f
            $testCase.title,
            $actualAgent
        ) -ForegroundColor Green
    }
    else {
        Write-Host (
            "[FAIL] {0}" -f $testCase.title
        ) -ForegroundColor Red

        Write-Host (
            "       Expected: {0}" -f
            $testCase.expected_agent
        ) -ForegroundColor Red

        Write-Host (
            "       Actual:   {0}" -f
            $actualAgent
        ) -ForegroundColor Red

        $errorsFound++
    }
}

Write-Host ""

if ($errorsFound -eq 0) {
    Write-Host "All routing engine checks passed." -ForegroundColor Green
}
else {
    Write-Host (
        "{0} routing error or errors were found." -f
        $errorsFound
    ) -ForegroundColor Red

    exit 1
}
