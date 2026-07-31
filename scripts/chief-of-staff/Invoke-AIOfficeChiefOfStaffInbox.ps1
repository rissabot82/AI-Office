param(
    [int]$Limit = 10,
    [switch]$CreatePlans
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffInbox.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Results = New-Object System.Collections.Generic.List[object]

for ($Index = 0; $Index -lt $Limit; $Index++) {
    $Message = & ".\scripts\messaging\Receive-AIOfficeMessage.ps1" `
        -Queue "inbox" `
        -Recipient "chief-of-staff"

    if ($null -eq $Message) {
        break
    }

    try {
        $Classification = & `
            ".\scripts\chief-of-staff\Classify-AIOfficeChiefOfStaffMessage.ps1" `
            -MessageId ([string]$Message.message_id)

        $PlanId = ""

        if ($CreatePlans) {
            $InboxPolicy = Get-AIOfficeChiefOfStaffInboxPolicy

            if (@($InboxPolicy.planning.auto_create_plan_for) -contains
                [string]$Classification.classification) {
                $Plan = & `
                    ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffPlanFromMessage.ps1" `
                    -MessageId ([string]$Message.message_id)

                $PlanId = [string]$Plan.plan_id
            }
        }

        $Record = [ordered]@{
            processed_at = (Get-Date).ToString("o")
            message_id = [string]$Message.message_id
            classification_id = [string]$Classification.classification_id
            classification = [string]$Classification.classification
            priority = [string]$Classification.priority
            risk_level = [string]$Classification.risk_level
            plan_id = $PlanId
            status = "processed"
        }

        $Path = Join-Path `
            ".\workspace\chief-of-staff\processed-inbox" `
            ([string]$Message.message_id + ".json")

        Write-AIOfficeChiefOfStaffJson -Value $Record -Path $Path

        & ".\scripts\messaging\Complete-AIOfficeMessage.ps1" `
            -MessageId ([string]$Message.message_id) `
            -Actor "chief-of-staff" `
            -Details "Chief of Staff inbox message processed." |
            Out-Null

        $Results.Add([pscustomobject]$Record)
    }
    catch {
        $Failure = [ordered]@{
            failed_at = (Get-Date).ToString("o")
            message_id = [string]$Message.message_id
            error = $_.Exception.Message
        }

        $FailurePath = Join-Path `
            ".\workspace\chief-of-staff\failed-inbox" `
            ([string]$Message.message_id + ".json")

        Write-AIOfficeChiefOfStaffJson `
            -Value $Failure `
            -Path $FailurePath

        try {
            & ".\scripts\messaging\Fail-AIOfficeMessage.ps1" `
                -MessageId ([string]$Message.message_id) `
                -Reason $_.Exception.Message `
                -Actor "chief-of-staff" |
                Out-Null
        }
        catch {
        }

        $Results.Add([pscustomobject]@{
            processed_at = (Get-Date).ToString("o")
            message_id = [string]$Message.message_id
            classification_id = ""
            classification = ""
            priority = ""
            risk_level = ""
            plan_id = ""
            status = "failed"
        })
    }
}

& ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1" |
    Out-Null

return @($Results | ForEach-Object { $_ })
