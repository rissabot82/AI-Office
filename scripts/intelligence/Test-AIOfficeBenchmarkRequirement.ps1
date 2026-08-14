param(
    [Parameter(Mandatory=$true)][string]$Requirement,
    [Parameter(Mandatory=$true)][string]$Response
)

$Text = $Response.Trim()
$Lower = $Text.ToLowerInvariant()

switch ($Requirement) {
    "direct_answer" {
        return (-not [string]::IsNullOrWhiteSpace($Text))
    }
    "natural_language" {
        return ($Text.Length -ge 10)
    }
    "no_fake_delegation" {
        foreach ($Phrase in @(
            "appropriate department",
            "will coordinate",
            "does not belong in the ai office",
            "need more information to proceed"
        )) {
            if ($Lower.Contains($Phrase)) { return $false }
        }
        return $true
    }
    "correct_answer" {
        return ($Lower -match '(^|\D)84(\D|$)')
    }
    "fulfills_request" {
        return (-not [string]::IsNullOrWhiteSpace($Text) -and $Text.Length -ge 20)
    }
    "creative_output" {
        $LineCount = @($Text -split "`r?`n").Count
        return ($LineCount -ge 2 -or $Text.Length -ge 80)
    }
    "professional" {
        return ($Text.Length -ge 40 -and $Lower -notmatch '\blol\b|\blmao\b')
    }
    "concise" {
        return ($Text.Length -le 1200)
    }
    "three_distinct_ideas" {
        $Numbered = [regex]::Matches($Text, '(?m)^\s*(?:\d+[\.\)]|[-*])\s+').Count
        return ($Numbered -ge 3)
    }
    "automotive_relevance" {
        return ($Lower -match 'car|vehicle|dealership|drive|auto')
    }
    "non_generic" {
        return ($Text.Length -ge 120)
    }
    "correct_math" {
        return ($Lower -match '40' -and $Lower -match '30')
    }
    "comparison" {
        return ($Lower -match 'campaign|efficient|cost per lead|cpl')
    }
    "direct_conclusion" {
        return ($Lower -match 'second|campaign 2|more efficient|better')
    }
    "technical_accuracy" {
        return ($Lower -match 'variable|parser|colon')
    }
    "correct_example" {
        return ($Text -match '\$\{[A-Za-z_][A-Za-z0-9_]*\}')
    }
    "marketing_or_drafting_classification" {
        return ($Lower -match 'marketing|drafting|copywriting|content')
    }
    default {
        return (-not [string]::IsNullOrWhiteSpace($Text))
    }
}
