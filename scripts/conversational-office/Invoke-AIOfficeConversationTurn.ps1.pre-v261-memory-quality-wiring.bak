param(
    [Parameter(Mandatory=$true)][string]$SessionId,
    [Parameter(Mandatory=$true)][string]$Content,
    [ValidateSet("private","sensitive","normal","public")][string]$Sensitivity = "normal",
    [string]$MemoryScope = "global"
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\conversational-office\AIOfficeConversation.Common.ps1"
. "E:\AI\AI-Office\scripts\conversational-office\AIOfficeConversationRuntime.Common.ps1"

$SessionPath = "E:\AI\AI-Office\workspace\conversational-office\sessions\$SessionId.json"

if (-not (Test-Path -LiteralPath $SessionPath -PathType Leaf)) {
    throw "Conversation session not found: $SessionId"
}

$UserMessage = & "E:\AI\AI-Office\scripts\conversational-office\New-AIOfficeConversationMessage.ps1" `
    -SessionId $SessionId `
    -Role "user" `
    -Content $Content

$Turn = & "E:\AI\AI-Office\scripts\conversational-office\New-AIOfficeConversationTurn.ps1" `
    -SessionId $SessionId `
    -UserMessageId ([string]$UserMessage.message_id)

$TurnPath = "E:\AI\AI-Office\workspace\conversational-office\turns\$($Turn.turn_id).json"

try {
    # v2.6 Part H explicit durable-memory capture. Failure is non-fatal.
    $MemoryCapture = & "E:\AI\AI-Office\scripts\memory\Invoke-AIOfficeExplicitMemoryCaptureForTurn.ps1" `
        -Content $Content `
        -Scope $MemoryScope

    $TaskProfile = Get-AIOfficeConversationTaskProfile -Content $Content
    $BasePrompt = New-AIOfficeConversationPrompt `
        -SessionId $SessionId `
        -CurrentUserContent $Content

    $Prompt = $BasePrompt
    $MemoryContext = $null
    $MemoryUsed = $false
    $MemoryContextId = ""
    $MemoryResultCount = 0
    $MemoryFailure = ""

    $MemoryIntegrationPolicy = Get-Content `
        "E:\AI\AI-Office\config\memory\live-integration-policy.json" `
        -Raw | ConvertFrom-Json

    if ([bool]$MemoryIntegrationPolicy.enabled) {
        try {
            $MemoryContext = & "E:\AI\AI-Office\scripts\memory\Get-AIOfficeConversationMemoryContext.ps1" `
                -Content $Content `
                -Scope $MemoryScope

            if ([bool]$MemoryContext.used) {
                $Prompt = & "E:\AI\AI-Office\scripts\memory\Add-AIOfficeMemoryContextToPrompt.ps1" `
                    -BasePrompt $BasePrompt `
                    -MemoryContext ([string]$MemoryContext.context_text)

                $MemoryUsed = $true
                $MemoryContextId = [string]$MemoryContext.context_id
                $MemoryResultCount = [int]$MemoryContext.result_count
            }
        }
        catch {
            $MemoryFailure = $_.Exception.Message

            if (-not [bool]$MemoryIntegrationPolicy.fallback_to_memory_free_runtime_on_failure) {
                throw
            }

            # fallback_to_memory_free_runtime_on_failure
            $Prompt = $BasePrompt
            $MemoryUsed = $false
        }
    }

    $IntelligencePolicy = Get-Content `
        -LiteralPath "E:\AI\AI-Office\config\intelligence\live-integration-policy.json" `
        -Raw |
        ConvertFrom-Json

    $IntelligentSelection = $null
    $Execution = $null
    $IntelligenceFallbackUsed = $false
    $IntelligenceFallbackReason = ""

    if ([bool]$IntelligencePolicy.live_integration.enabled) {
        try {
            $IntelligentSelection = & "E:\AI\AI-Office\scripts\intelligence\Select-AIOfficeIntelligentModel.ps1" `
                -Content $Content `
                -Persist

            $Execution = & "E:\AI\AI-Office\scripts\intelligence\Invoke-AIOfficeQualityControlledInference.ps1" `
                -Model ([string]$IntelligentSelection.selected_model) `
                -Prompt $Prompt `
                -TaskFamily ([string]$IntelligentSelection.task_family)
        }
        catch {
            if (-not [bool]$IntelligencePolicy.live_integration.preserve_v24_fallback) {
                throw
            }

            $IntelligenceFallbackUsed = $true
            $IntelligenceFallbackReason = $_.Exception.Message
        }
    }

    if ($null -eq $Execution) {
        $Execution = & "E:\AI\AI-Office\scripts\self-hosting\Invoke-AIOfficeOptimizedInference.ps1" `
            -Prompt $Prompt `
            -TaskType ([string]$TaskProfile.task_type) `
            -Sensitivity $Sensitivity `
            -Complexity ([string]$TaskProfile.complexity) `
            -WorkloadProfile ([string]$TaskProfile.workload_profile)
    }

    $ResponseText = [string]$Execution.response

    if ([string]::IsNullOrWhiteSpace($ResponseText)) {
        throw "AI Office conversational runtime returned an empty response."
    }

    if ($ResponseText -eq "CLOUD_OPTIMIZED_ROUTE_READY") {
        throw "Conversation selected a cloud route that is not yet connected to live response execution."
    }

    $Metadata = [ordered]@{
        provider = [string]$Execution.provider
        model = [string]$Execution.model
        task_type = [string]$TaskProfile.task_type
        complexity = [string]$TaskProfile.complexity
        workload_profile = [string]$TaskProfile.workload_profile
        optimized_execution_id = [string]$Execution.optimized_execution_id
        memory_used = $MemoryUsed
        memory_context_id = $MemoryContextId
        memory_result_count = $MemoryResultCount
    }

    if (-not [string]::IsNullOrWhiteSpace($MemoryFailure)) {
        $Metadata.memory_failure = $MemoryFailure
    }

    $AssistantMessage = & "E:\AI\AI-Office\scripts\conversational-office\New-AIOfficeConversationMessage.ps1" `
        -SessionId $SessionId `
        -Role "assistant" `
        -Content $ResponseText `
        -MetadataJson ($Metadata | ConvertTo-Json -Compress)

    $StoredTurn = Get-Content -LiteralPath $TurnPath -Raw | ConvertFrom-Json
    $StoredTurn.assistant_message_id = [string]$AssistantMessage.message_id
    $StoredTurn.status = "completed"
    $StoredTurn.routing = [ordered]@{
        provider = [string]$Execution.provider
        model = [string]$Execution.model
        task_type = [string]$TaskProfile.task_type
    }
    $StoredTurn.execution = [ordered]@{
        optimized_execution_id = [string]$Execution.optimized_execution_id
        elapsed_ms = [double]$Execution.elapsed_ms
        workload_profile = [string]$TaskProfile.workload_profile
        memory_used = $MemoryUsed
        memory_context_id = $MemoryContextId
        memory_result_count = $MemoryResultCount
    }
    $StoredTurn.completed_at = (Get-Date).ToString("o")

    Write-AIOfficeConversationJson -Value $StoredTurn -Path $TurnPath

    $Result = [ordered]@{
        session_id = $SessionId
        turn_id = [string]$Turn.turn_id
        user_message_id = [string]$UserMessage.message_id
        assistant_message_id = [string]$AssistantMessage.message_id
        provider = [string]$Execution.provider
        model = [string]$Execution.model
        memory_used = $MemoryUsed
        memory_context_id = $MemoryContextId
        memory_result_count = $MemoryResultCount
        status = "completed"
        response = $ResponseText
        created_at = (Get-Date).ToString("o")
    }

    Write-Host (
        "Conversation turn completed: " +
        $Turn.turn_id +
        " | " +
        $Execution.provider +
        " | " +
        $Execution.model +
        " | memory=" +
        $MemoryUsed
    ) -ForegroundColor Green

    return [pscustomobject]$Result
}
catch {
    if (Test-Path -LiteralPath $TurnPath -PathType Leaf) {
        $StoredTurn = Get-Content -LiteralPath $TurnPath -Raw | ConvertFrom-Json
        $StoredTurn.status = "failed"
        $StoredTurn.execution = [ordered]@{
            error = $_.Exception.Message
        }
        $StoredTurn.completed_at = (Get-Date).ToString("o")
        Write-AIOfficeConversationJson -Value $StoredTurn -Path $TurnPath
    }

    throw
}


