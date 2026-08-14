param(
    [Parameter(Mandatory=$true)][string]$SessionId,
    [Parameter(Mandatory=$true)][string]$Content,
    [ValidateSet("private","sensitive","normal","public")][string]$Sensitivity = "normal"
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
    $TaskProfile = Get-AIOfficeConversationTaskProfile -Content $Content

    $Prompt = New-AIOfficeConversationPrompt `
        -SessionId $SessionId `
        -CurrentUserContent $Content

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
        intelligence_v25_enabled = [bool]$IntelligencePolicy.live_integration.enabled
        intelligent_task_family = if ($null -ne $IntelligentSelection) { [string]$IntelligentSelection.task_family } else { "" }
        intelligent_quality_tier = if ($null -ne $IntelligentSelection) { [string]$IntelligentSelection.quality_tier } else { "" }
        intelligent_selected_model = if ($null -ne $IntelligentSelection) { [string]$IntelligentSelection.selected_model } else { "" }
        intelligent_requires_escalation = if ($null -ne $IntelligentSelection) { [bool]$IntelligentSelection.requires_escalation } else { $false }
        intelligence_fallback_used = $IntelligenceFallbackUsed
        intelligence_fallback_reason = $IntelligenceFallbackReason
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
        intelligent_task_family = if ($null -ne $IntelligentSelection) { [string]$IntelligentSelection.task_family } else { "" }
        intelligent_quality_tier = if ($null -ne $IntelligentSelection) { [string]$IntelligentSelection.quality_tier } else { "" }
        intelligent_requires_escalation = if ($null -ne $IntelligentSelection) { [bool]$IntelligentSelection.requires_escalation } else { $false }
        intelligence_fallback_used = $IntelligenceFallbackUsed
    }
    $StoredTurn.execution = [ordered]@{
        optimized_execution_id = [string]$Execution.optimized_execution_id
        elapsed_ms = [double]$Execution.elapsed_ms
        workload_profile = [string]$TaskProfile.workload_profile
        intelligence_source = if ($IntelligenceFallbackUsed) { "v2.4-fallback" } else { [string]$Execution.source }
        fallback_reason = $IntelligenceFallbackReason
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
        task_family = if ($null -ne $IntelligentSelection) { [string]$IntelligentSelection.task_family } else { "" }
        quality_tier = if ($null -ne $IntelligentSelection) { [string]$IntelligentSelection.quality_tier } else { "" }
        requires_escalation = if ($null -ne $IntelligentSelection) { [bool]$IntelligentSelection.requires_escalation } else { $false }
        intelligence_fallback_used = $IntelligenceFallbackUsed
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
        $(if ($null -ne $IntelligentSelection) { " | family=" + $IntelligentSelection.task_family } else { "" }) +
        $(if ($IntelligenceFallbackUsed) { " | v2.4-fallback" } else { "" })
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

