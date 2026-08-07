param()

$ErrorActionPreference = "Stop"

$Definitions = @(
    @{ name="chief-of-staff"; capabilities=@("routing","prioritization","approval","coordination") },
    @{ name="marketing"; capabilities=@("campaigns","copy","strategy","offers") },
    @{ name="creative"; capabilities=@("creative_direction","image_briefs","brand_assets") },
    @{ name="web-development"; capabilities=@("html","css","javascript","website_changes") },
    @{ name="analytics"; capabilities=@("ga4","gtm","measurement","validation") },
    @{ name="google-ads"; capabilities=@("search","pmax","vla","optimization") },
    @{ name="financial-office"; capabilities=@("cash_flow","budgets","debt","goals") },
    @{ name="business-incubator"; capabilities=@("idea_validation","market_analysis","launch_planning") },
    @{ name="monthly-reporting"; capabilities=@("collect","normalize","validate","populate","summarize") },
    @{ name="operations-integrations"; capabilities=@("discord_intake","job_dispatch","integration_health") },
    @{ name="personal-assistant"; capabilities=@("tasks","reminders","coordination") },
    @{ name="side-hustles"; capabilities=@("income_tracking","profitability","recommendations") },
    @{ name="youtube-studio"; capabilities=@("content_planning","production","publishing") },
    @{ name="business"; capabilities=@("pricing","operations","growth") }
)

$Created = New-Object System.Collections.Generic.List[object]

foreach ($Definition in $Definitions) {
    $CapabilitiesJson = @($Definition.capabilities) | ConvertTo-Json -Compress

    $Department = & "E:\AI\AI-Office\scripts\autonomous-enterprise\New-AIOfficeEnterpriseDepartment.ps1" `
        -Name ([string]$Definition.name) `
        -CapabilitiesJson $CapabilitiesJson

    $Created.Add($Department)
}

Write-Host "Enterprise departments initialized: $($Created.Count)" -ForegroundColor Green
return @($Created | ForEach-Object { $_ })
