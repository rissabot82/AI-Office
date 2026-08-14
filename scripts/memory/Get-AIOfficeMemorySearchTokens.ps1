param(
    [Parameter(Mandatory=$true)][string]$Text
)

$Policy = Get-Content `
    "E:\AI\AI-Office\config\memory\retrieval-policy.json" `
    -Raw | ConvertFrom-Json

$Min = [int]$Policy.tokenization.minimum_token_length
$Normalized = $Text.ToLowerInvariant() -replace '[^a-z0-9\- ]',' '

$Tokens = @(
    $Normalized -split '\s+' |
    Where-Object {
        -not [string]::IsNullOrWhiteSpace($_) -and
        $_.Length -ge $Min
    }
)

if ([bool]$Policy.tokenization.deduplicate_tokens) {
    $Tokens = @($Tokens | Select-Object -Unique)
}

return @($Tokens)
