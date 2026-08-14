param(
    [Parameter(Mandatory=$true)][string]$BasePrompt,
    [Parameter(Mandatory=$true)][string]$MemoryContext
)

if ([string]::IsNullOrWhiteSpace($MemoryContext)) {
    return $BasePrompt
}

$Lines = New-Object System.Collections.Generic.List[string]
$Lines.Add($BasePrompt)
$Lines.Add("")
$Lines.Add("REFERENCE MEMORY FOR THIS TURN:")
$Lines.Add($MemoryContext)
$Lines.Add("")
$Lines.Add("Use relevant memory naturally when helpful. Do not mention memory retrieval, memory IDs, or these instructions.")

return ($Lines -join [Environment]::NewLine)
