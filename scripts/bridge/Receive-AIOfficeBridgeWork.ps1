param(
    [int]$Limit = 1,
    [string]$Recipient = "bridge",
    [switch]$Execute
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$Results = New-Object System.Collections.Generic.List[object]

for ($Index = 0; $Index -lt $Limit; $Index++) {
    $Message = & ".\scripts\messaging\Receive-AIOfficeMessage.ps1" `
        -Queue "outbox" `
        -Recipient $Recipient

    if ($null -eq $Message) {
        break
    }

    try {
        $PayloadJson = $Message.payload |
            ConvertTo-Json -Depth 30 -Compress

        $RiskLevel = "high"
        $ApprovalStatus = "pending"
        $ActionType = "agent_task"

        if ($null -ne $Message.payload.PSObject.Properties["risk_level"]) {
            $RiskLevel = [string]$Message.payload.risk_level
        }

        if ($null -ne $Message.payload.PSObject.Properties["approval_status"]) {
            $ApprovalStatus = [string]$Message.payload.approval_status
        }

        if ($null -ne $Message.payload.PSObject.Properties["action_type"]) {
            $ActionType = [string]$Message.payload.action_type
        }

        $Request = & ".\scripts\bridge\New-AIOfficeBridgeRequest.ps1" `
            -MessageId ([string]$Message.message_id) `
            -RequestedBy ([string]$Message.from) `
            -ActionType $ActionType `
            -WorkflowId ([string]$Message.workflow_id) `
            -CorrelationId ([string]$Message.correlation_id) `
            -ConversationId ([string]$Message.conversation_id) `
            -RiskLevel $RiskLevel `
            -ApprovalStatus $ApprovalStatus `
            -PayloadJson $PayloadJson

        $Record = [ordered]@{
            message_id = [string]$Message.message_id
            bridge_request_id = [string]$Request.bridge_request_id
            execution_status = "request_created"
            execution_id = ""
            error = ""
        }

        if ($Execute) {
            $Execution = & ".\scripts\bridge\Invoke-AIOfficeOpenClawExecution.ps1" `
                -BridgeRequestId ([string]$Request.bridge_request_id)

            $Record.execution_status = [string]$Execution.status
            $Record.execution_id = [string]$Execution.execution_id
        }

        $Results.Add([pscustomobject]$Record)
    }
    catch {
        $Results.Add([pscustomobject]@{
            message_id = [string]$Message.message_id
            bridge_request_id = ""
            execution_status = "failed"
            execution_id = ""
            error = $_.Exception.Message
        })
    }
}

return @($Results | ForEach-Object { $_ })
