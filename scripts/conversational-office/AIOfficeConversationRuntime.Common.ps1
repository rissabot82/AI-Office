$script:AIOfficeConversationRuntimeRoot = "E:\AI\AI-Office"

function Get-AIOfficeConversationRuntimePolicy {
    return Get-Content `
        -LiteralPath "E:\AI\AI-Office\config\conversational-office\runtime-policy.json" `
        -Raw |
        ConvertFrom-Json
}

function Get-AIOfficeConversationTaskProfile {
    param(
        [Parameter(Mandatory=$true)][string]$Content
    )

    $Policy = Get-AIOfficeConversationRuntimePolicy
    $Lower = $Content.ToLowerInvariant()

    $TaskType = [string]$Policy.runtime.default_task_type
    $Complexity = [string]$Policy.runtime.default_complexity
    $WorkloadProfile = [string]$Policy.runtime.default_workload_profile

    foreach ($Keyword in @($Policy.task_detection.code_keywords)) {
        if ($Lower.Contains([string]$Keyword)) {
            return [pscustomobject]@{
                task_type = "code"
                complexity = "medium"
                workload_profile = "balanced"
            }
        }
    }

    foreach ($Keyword in @($Policy.task_detection.summary_keywords)) {
        if ($Lower.Contains([string]$Keyword)) {
            return [pscustomobject]@{
                task_type = "summarization"
                complexity = "low"
                workload_profile = "quick"
            }
        }
    }

    foreach ($Keyword in @($Policy.task_detection.drafting_keywords)) {
        if ($Lower.Contains([string]$Keyword)) {
            return [pscustomobject]@{
                task_type = "drafting"
                complexity = "medium"
                workload_profile = "balanced"
            }
        }
    }

    foreach ($Keyword in @($Policy.task_detection.analysis_keywords)) {
        if ($Lower.Contains([string]$Keyword)) {
            return [pscustomobject]@{
                task_type = "simple_reasoning"
                complexity = "medium"
                workload_profile = "balanced"
            }
        }
    }

    return [pscustomobject]@{
        task_type = $TaskType
        complexity = $Complexity
        workload_profile = $WorkloadProfile
    }
}

function New-AIOfficeConversationPrompt {
    param(
        [Parameter(Mandatory=$true)][string]$SessionId,
        [Parameter(Mandatory=$true)][string]$CurrentUserContent
    )

    . "E:\AI\AI-Office\scripts\conversational-office\AIOfficeConversation.Common.ps1"

    $RuntimePolicy = Get-AIOfficeConversationRuntimePolicy
    $ContextLimit = [int]$RuntimePolicy.runtime.max_context_messages

    $Messages = @(
        Get-AIOfficeConversationCollection `
            -Directory "E:\AI\AI-Office\workspace\conversational-office\messages" `
            -Filter "MSG-*.json" |
        Where-Object { [string]$_.session_id -eq $SessionId } |
        Sort-Object { [string]$_.created_at }
    )

    $Recent = @(
        $Messages |
        Select-Object -Last $ContextLimit
    )

    $Lines = New-Object System.Collections.Generic.List[string]
    $Lines.Add([string]$RuntimePolicy.runtime.chief_of_staff_system_prompt)
    $Lines.Add("")
    $Lines.Add("Conversation context:")

    foreach ($Message in $Recent) {
        $Role = [string]$Message.role
        $Content = [string]$Message.content
        $Lines.Add(("{0}: {1}" -f $Role.ToUpperInvariant(), $Content))
    }

    if (
        $Recent.Count -eq 0 -or
        [string]$Recent[-1].role -ne "user" -or
        [string]$Recent[-1].content -ne $CurrentUserContent
    ) {
        $Lines.Add(("USER: " + $CurrentUserContent))
    }

    $Lines.Add("")
    $Lines.Add("Answer the user directly. Do not invent delegation, routing, or departmental actions.")

    return ($Lines -join [Environment]::NewLine)
}

