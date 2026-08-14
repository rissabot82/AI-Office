param()

$ErrorActionPreference = "Stop"

function Add-ReleaseSection {
    param(
        [string]$Path,
        [string]$Heading,
        [string[]]$Lines
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $Content = Get-Content -LiteralPath $Path -Raw

    if ($Content -notmatch [regex]::Escape($Heading)) {
        $Content = $Content.TrimEnd()
        $Content += [Environment]::NewLine
        $Content += [Environment]::NewLine
        $Content += $Heading
        $Content += [Environment]::NewLine
        $Content += [Environment]::NewLine
        $Content += ($Lines -join [Environment]::NewLine)
        $Content += [Environment]::NewLine

        Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
    }
}

$Readme = "E:\AI\AI-Office\README.md"

if (Test-Path -LiteralPath $Readme) {
    $Content = Get-Content -LiteralPath $Readme -Raw

    $Content = [regex]::Replace(
        $Content,
        '\*\*Current Version:\*\*.*',
        '**Current Version:** v2.5.0 - Intelligence Upgrade',
        1
    )

    $Content = [regex]::Replace(
        $Content,
        '\*\*Next Release:\*\*.*',
        '**Next Release:** v2.6.0 - Memory and Context Integration',
        1
    )

    Set-Content -LiteralPath $Readme -Value $Content -Encoding UTF8
}

Add-ReleaseSection `
    -Path $Readme `
    -Heading "## AI Office v2.5 - Intelligence Upgrade" `
    -Lines @(
        "**Status:** Certified / Operational",
        "**Version:** 2.5.0",
        "",
        "AI Office now uses benchmark-driven model selection, task-family routing, response-quality control, quality escalation, external-provider architecture, and cost guardrails.",
        "",
        "Final certification: **14 passed / 0 failed**.",
        "",
        "**Next:** v2.6 - Memory and Context Integration."
    )

Add-ReleaseSection `
    -Path "E:\AI\AI-Office\PROJECT-STATUS.md" `
    -Heading "## Current Release - v2.5.0" `
    -Lines @(
        "**Release:** Intelligence Upgrade",
        "**Status:** Certified / Operational",
        "**Certification:** 14 passed / 0 failed",
        "",
        "The conversational runtime is benchmark-driven, quality-controlled, and able to identify when current local intelligence is insufficient.",
        "",
        "**Next release:** v2.6.0 - Memory and Context Integration."
    )

Add-ReleaseSection `
    -Path "E:\AI\AI-Office\ROADMAP.md" `
    -Heading "## v2.5 - Intelligence Upgrade" `
    -Lines @(
        "**Status: COMPLETE**",
        "",
        "Delivered model benchmarking, intelligent model selection, live integration, response-quality control, escalation architecture, provider abstraction, cost guardrails, and end-to-end certification.",
        "",
        "### Next",
        "**v2.6 - Memory and Context Integration**"
    )

Add-ReleaseSection `
    -Path "E:\AI\AI-Office\VISION.md" `
    -Heading "## Intelligence State After v2.5" `
    -Lines @(
        "AI Office now measures local model capability, selects models by task family, validates response behavior, and identifies work that exceeds current local capability.",
        "",
        "The next intelligence leap is contextual: v2.6 will connect conversations to durable project, dealership, organization, workflow, and user-approved context."
    )

$ProjectStatusPath = "E:\AI\AI-Office\config\project-status.json"

if (Test-Path -LiteralPath $ProjectStatusPath) {
    $Status = Get-Content -LiteralPath $ProjectStatusPath -Raw | ConvertFrom-Json

    $Status.version = "2.5.0"
    $Status.current_phase = "Intelligence Upgrade Complete"
    $Status.current_milestone = "Benchmark-Driven Intelligence Certified and Operational"
    $Status.release_status = "operational"
    $Status.next_release = "2.6.0"
    $Status.next_milestone = "Memory and Context Integration"
    $Status.resume_component = "v2.6 Part A"
    $Status.updated_at = (Get-Date).ToString("yyyy-MM-dd")

    $Status |
        ConvertTo-Json -Depth 50 |
        Set-Content -LiteralPath $ProjectStatusPath -Encoding UTF8
}

Write-Host "[DOCS SYNCED] README, PROJECT-STATUS, ROADMAP, VISION, project-status.json" -ForegroundColor Green
