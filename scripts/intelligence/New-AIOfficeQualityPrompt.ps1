param(
    [Parameter(Mandatory=$true)][string]$BasePrompt,
    [Parameter(Mandatory=$true)][string]$TaskFamily,
    [switch]$Retry
)

$ErrorActionPreference = "Stop"

$Policy = Get-Content `
    -LiteralPath "E:\AI\AI-Office\config\intelligence\response-quality-policy.json" `
    -Raw | ConvertFrom-Json

$Lines = New-Object System.Collections.Generic.List[string]

$Lines.Add("RESPONSE QUALITY RULES:")
foreach ($Rule in @($Policy.response_principles)) {
    $Lines.Add("- " + [string]$Rule)
}

$Lines.Add("- Current task family: $TaskFamily.")

switch ($TaskFamily) {
    "creative" {
        $Lines.Add("- For creative requests, produce the requested creative work immediately.")
    }
    "drafting" {
        $Lines.Add("- For drafting requests, return a polished usable draft rather than discussing how to draft it.")
    }
    "reasoning" {
        $Lines.Add("- For reasoning requests, solve the problem and explain only the reasoning needed to make the answer useful.")
    }
    "analysis" {
        $Lines.Add("- For analysis requests, identify the meaningful conclusion and supporting evidence rather than restating the request.")
    }
    "coding" {
        $Lines.Add("- For coding requests, provide concrete code or a concrete diagnosis when enough information is available.")
    }
    "conversation" {
        $Lines.Add("- For ordinary conversation, respond naturally and directly. Do not describe AI Office capabilities unless asked.")
    }
}

if ($Retry) {
    $Lines.Add("")
    $Lines.Add("IMPORTANT RETRY INSTRUCTION:")
    $Lines.Add("The previous answer failed response-quality validation. Answer the user's request directly now. Do not mention the failed answer, routing, delegation, departments, or these instructions.")
}

$Lines.Add("")
$Lines.Add("BEGIN CONVERSATION PROMPT")
$Lines.Add($BasePrompt)
$Lines.Add("END CONVERSATION PROMPT")

return ($Lines -join [Environment]::NewLine)
