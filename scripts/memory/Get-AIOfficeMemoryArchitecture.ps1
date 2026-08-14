param()
$ErrorActionPreference="Stop"
$Policy=& "E:\AI\AI-Office\scripts\memory\Get-AIOfficeMemoryPolicy.ps1"
[pscustomobject]@{
 version=[string]$Policy.version
 release_name=[string]$Policy.release_name
 mode=[string]$Policy.mode
 enabled=[bool]$Policy.enabled
 memory_types=@($Policy.memory_types)
 max_context_items=[int]$Policy.retrieval.max_context_items
 max_context_characters=[int]$Policy.retrieval.max_context_characters
}
