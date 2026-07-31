param(
    [Parameter(Mandatory=$true)][string]$Department,
    [int]$Limit = 10
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentInbox.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$Policy = Get-AIOfficeDepartmentInboxPolicy

if ($Limit -lt 1) {
    $Limit = 1
}

if ($Limit -gt [int]$Policy.intake.maximum_limit) {
    $Limit = [int]$Policy.intake.maximum_limit
}

$Results = New-Object System.Collections.Generic.List[object]

for ($Index = 0; $Index -lt $Limit; $Index++) {
    $Message = & ".\scripts\messaging\Receive-AIOfficeMessage.ps1" `
        -Queue "outbox" `
        -Recipient $Department

    if ($null -eq $Message) {
        break
    }

    try {
        $WorkItem = & ".\scripts\departments\New-AIOfficeDepartmentWorkItem.ps1" `
            -Department $Department `
            -MessageId ([string]$Message.message_id)

        $Record = [ordered]@{
            processed_at = (Get-Date).ToString("o")
            department = $Department
            message_id = [string]$Message.message_id
            work_item_id = [string]$WorkItem.work_item_id
            status = "accepted"
        }

        Write-AIOfficeDepartmentJson `
            -Value $Record `
            -Path (
                ".\workspace\departments\" +
                $Department +
                "\processed-inbox\" +
                [string]$Message.message_id +
                ".json"
            )

        & ".\scripts\messaging\Complete-AIOfficeMessage.ps1" `
            -MessageId ([string]$Message.message_id) `
            -Actor $Department `
            -Details "Department work intake completed." |
            Out-Null

        $Results.Add([pscustomobject]$Record)
    }
    catch {
        $Failure = [ordered]@{
            failed_at = (Get-Date).ToString("o")
            department = $Department
            message_id = [string]$Message.message_id
            error = $_.Exception.Message
        }

        Write-AIOfficeDepartmentJson `
            -Value $Failure `
            -Path (
                ".\workspace\departments\" +
                $Department +
                "\failed-inbox\" +
                [string]$Message.message_id +
                ".json"
            )

        try {
            & ".\scripts\messaging\Fail-AIOfficeMessage.ps1" `
                -MessageId ([string]$Message.message_id) `
                -Reason $_.Exception.Message `
                -Actor $Department |
                Out-Null
        }
        catch {
        }

        $Results.Add([pscustomobject]@{
            processed_at = (Get-Date).ToString("o")
            department = $Department
            message_id = [string]$Message.message_id
            work_item_id = ""
            status = "failed"
        })
    }
}

& ".\scripts\departments\Update-AIOfficeDepartmentIndex.ps1" |
    Out-Null

return @($Results | ForEach-Object { $_ })
