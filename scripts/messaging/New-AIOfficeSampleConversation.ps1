param(
    [string]$WorkflowId = "WF-SAMPLE-OPENCLAW",
    [switch]$KeepMessages
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$ConversationId = New-AIOfficeConversationId -Topic "OPENCLAW-BRIDGE"
$CorrelationId = New-AIOfficeCorrelationId

$Messages = New-Object System.Collections.Generic.List[object]

$Messages.Add(
    (& ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "chief-of-staff" `
        -To "marketing" `
        -MessageType "request" `
        -Priority "high" `
        -Subject "Prepare approved campaign workflow" `
        -WorkflowId $WorkflowId `
        -CorrelationId $CorrelationId `
        -ConversationId $ConversationId `
        -Queue "inbox" `
        -PayloadJson '{"store":"Elite Auto Sales","request":"Prepare campaign workflow"}')
)

$Messages.Add(
    (& ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "marketing" `
        -To "bridge" `
        -MessageType "execution_request" `
        -Priority "high" `
        -Subject "Submit approved browser execution request" `
        -WorkflowId $WorkflowId `
        -CorrelationId $CorrelationId `
        -ConversationId $ConversationId `
        -Queue "outbox" `
        -PayloadJson '{"execution_engine":"OpenClaw","action":"browser_task","approval_status":"approved"}')
)

$Messages.Add(
    (& ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "bridge" `
        -To "openclaw" `
        -MessageType "execution_request" `
        -Priority "high" `
        -Subject "Execute approved task" `
        -WorkflowId $WorkflowId `
        -CorrelationId $CorrelationId `
        -ConversationId $ConversationId `
        -Queue "outbox" `
        -PayloadJson '{"action":"browser_task","mode":"approved_execution"}')
)

$Messages.Add(
    (& ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "openclaw" `
        -To "bridge" `
        -MessageType "execution_result" `
        -Priority "normal" `
        -Subject "Execution completed" `
        -WorkflowId $WorkflowId `
        -CorrelationId $CorrelationId `
        -ConversationId $ConversationId `
        -Queue "inbox" `
        -PayloadJson '{"result":"success","artifact_count":1}')
)

$Messages.Add(
    (& ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "bridge" `
        -To "chief-of-staff" `
        -MessageType "status" `
        -Priority "normal" `
        -Subject "OpenClaw execution recorded" `
        -WorkflowId $WorkflowId `
        -CorrelationId $CorrelationId `
        -ConversationId $ConversationId `
        -Queue "inbox" `
        -PayloadJson '{"status":"completed","execution_engine":"OpenClaw"}')
)

$Result = [ordered]@{
    conversation_id = $ConversationId
    correlation_id = $CorrelationId
    message_count = $Messages.Count
    message_ids = @($Messages | ForEach-Object { [string]$_.message_id })
}

if (-not $KeepMessages) {
    foreach ($Message in $Messages) {
        foreach ($Queue in @(
            "inbox",
            "outbox",
            "processing",
            "processed",
            "failed",
            "dead-letter",
            "archive"
        )) {
            $Path = Join-Path `
                ".\workspace\messages\$Queue" `
                ([string]$Message.message_id + ".json")

            if (Test-Path -LiteralPath $Path -PathType Leaf) {
                Remove-Item -LiteralPath $Path -Force
            }
        }
    }

    & ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
        Out-Null
}

return [pscustomobject]$Result
