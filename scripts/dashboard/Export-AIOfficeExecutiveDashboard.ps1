param(
    [string]$SnapshotId = "",
    [switch]$CreateNew,
    [switch]$Open
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDashboard.Common.ps1")

$root = Get-AIOfficeDashboardRoot
Set-Location $root

if ($CreateNew) {
    & ".\scripts\dashboard\New-AIOfficeExecutiveSnapshot.ps1" |
        Out-Null
}

& ".\scripts\dashboard\Update-AIOfficeDashboardIndex.ps1" |
    Out-Null

$index = Read-AIOfficeJsonFile `
    -Path ".\workspace\dashboard\dashboard-index.json"

if ($null -eq $index -or [int]$index.snapshot_count -eq 0) {
    throw "No dashboard snapshots are available."
}

$snapshotFile = ""

if ([string]::IsNullOrWhiteSpace($SnapshotId)) {
    $snapshotFile = [string]$index.latest_snapshot
}
else {
    $match = @(
        $index.snapshots |
        Where-Object {
            $_.snapshot_id -eq $SnapshotId -or
            $_.file -eq $SnapshotId
        }
    ) | Select-Object -First 1

    if ($null -eq $match) {
        throw "Dashboard snapshot not found: $SnapshotId"
    }

    $snapshotFile = [string]$match.file
}

$snapshotPath = Join-Path `
    ".\workspace\dashboard\snapshots" `
    $snapshotFile

$snapshot = Read-AIOfficeJsonFile -Path $snapshotPath

if ($null -eq $snapshot) {
    throw "Dashboard snapshot could not be loaded."
}

$statusClass = [string]$snapshot.overall_health.status
$riskRows = New-Object System.Collections.Generic.List[string]
$recommendationRows = New-Object System.Collections.Generic.List[string]

if (@($snapshot.risks).Count -eq 0) {
    $riskRows.Add(
        '<div class="empty">No material risks detected.</div>'
    )
}
else {
    foreach ($risk in @($snapshot.risks)) {
        $riskRows.Add(
            '<article class="risk ' +
            (ConvertTo-AIOfficeHtmlText $risk.severity) +
            '"><div class="risk-head"><span class="badge">' +
            (ConvertTo-AIOfficeHtmlText $risk.severity) +
            '</span><strong>' +
            (ConvertTo-AIOfficeHtmlText $risk.title) +
            '</strong></div><p>' +
            (ConvertTo-AIOfficeHtmlText $risk.detail) +
            '</p><p class="action">Action: ' +
            (ConvertTo-AIOfficeHtmlText $risk.recommended_action) +
            '</p></article>'
        )
    }
}

if (@($snapshot.recommendations).Count -eq 0) {
    $recommendationRows.Add(
        '<li>No immediate corrective actions are required.</li>'
    )
}
else {
    foreach ($recommendation in @($snapshot.recommendations)) {
        $recommendationRows.Add(
            '<li>' +
            (ConvertTo-AIOfficeHtmlText $recommendation) +
            '</li>'
        )
    }
}

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>AI Office Executive Dashboard</title>
<style>
:root {
  --bg: #f3f5f7;
  --card: #ffffff;
  --text: #17212b;
  --muted: #5d6b78;
  --line: #d8dee4;
  --healthy: #167447;
  --attention: #986800;
  --critical: #b42318;
  --accent: #1e4f8a;
}
* { box-sizing: border-box; }
body {
  margin: 0;
  background: var(--bg);
  color: var(--text);
  font-family: "Segoe UI", Arial, sans-serif;
}
.wrap {
  max-width: 1240px;
  margin: 0 auto;
  padding: 28px;
}
header {
  background: #102a43;
  color: white;
  border-radius: 14px;
  padding: 28px;
  margin-bottom: 20px;
}
header h1 { margin: 0 0 8px; font-size: 30px; }
header p { margin: 0; opacity: .88; }
.health {
  margin-top: 20px;
  display: flex;
  align-items: center;
  gap: 18px;
}
.score {
  width: 94px;
  height: 94px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  font-size: 27px;
  font-weight: 700;
  background: white;
}
.score.healthy { color: var(--healthy); }
.score.attention { color: var(--attention); }
.score.critical { color: var(--critical); }
.status { font-size: 20px; text-transform: uppercase; font-weight: 700; }
.summary, .section {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 12px;
  padding: 22px;
  margin-bottom: 20px;
}
h2 { margin-top: 0; font-size: 20px; }
.metrics {
  display: grid;
  grid-template-columns: repeat(auto-fit,minmax(210px,1fr));
  gap: 14px;
}
.metric {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 12px;
  padding: 18px;
}
.metric h3 { margin: 0 0 13px; font-size: 16px; color: var(--accent); }
.metric .big { font-size: 30px; font-weight: 700; }
.metric p { margin: 7px 0 0; color: var(--muted); }
.risk {
  border: 1px solid var(--line);
  border-left-width: 6px;
  border-radius: 9px;
  padding: 16px;
  margin: 12px 0;
}
.risk.critical { border-left-color: var(--critical); }
.risk.high { border-left-color: #c2410c; }
.risk.medium { border-left-color: var(--attention); }
.risk.low { border-left-color: #1e6f9f; }
.risk-head { display: flex; gap: 10px; align-items: center; }
.badge {
  font-size: 11px;
  text-transform: uppercase;
  border: 1px solid var(--line);
  border-radius: 999px;
  padding: 3px 8px;
}
.risk p { margin: 10px 0 0; }
.action { color: var(--muted); }
.empty { color: var(--muted); }
footer {
  color: var(--muted);
  font-size: 12px;
  text-align: center;
  padding: 10px;
}
</style>
</head>
<body>
<div class="wrap">
<header>
  <h1>AI Office Executive Dashboard</h1>
  <p>Generated $(ConvertTo-AIOfficeHtmlText $snapshot.generated_at)</p>
  <div class="health">
    <div class="score $statusClass">$(ConvertTo-AIOfficeHtmlText $snapshot.overall_health.score)/100</div>
    <div>
      <div class="status">$(ConvertTo-AIOfficeHtmlText $snapshot.overall_health.status)</div>
      <div>$(ConvertTo-AIOfficeHtmlText $snapshot.overall_health.risk_count) operational risk(s)</div>
    </div>
  </div>
</header>

<section class="summary">
  <h2>Executive Summary</h2>
  <p>$(ConvertTo-AIOfficeHtmlText $snapshot.executive_summary)</p>
</section>

<section class="metrics">
  <article class="metric">
    <h3>Workflows</h3>
    <div class="big">$(ConvertTo-AIOfficeHtmlText $snapshot.metrics.workflows.active)</div>
    <p>Active of $(ConvertTo-AIOfficeHtmlText $snapshot.metrics.workflows.total) total</p>
    <p>$(ConvertTo-AIOfficeHtmlText $snapshot.metrics.workflows.blocked) blocked · $(ConvertTo-AIOfficeHtmlText $snapshot.metrics.workflows.overdue) overdue</p>
  </article>
  <article class="metric">
    <h3>Approvals</h3>
    <div class="big">$(ConvertTo-AIOfficeHtmlText $snapshot.metrics.approvals.pending)</div>
    <p>Pending of $(ConvertTo-AIOfficeHtmlText $snapshot.metrics.approvals.total) total</p>
    <p>$(ConvertTo-AIOfficeHtmlText $snapshot.metrics.approvals.approved) approved</p>
  </article>
  <article class="metric">
    <h3>Calendar</h3>
    <div class="big">$(ConvertTo-AIOfficeHtmlText $snapshot.metrics.calendar.next_7_days)</div>
    <p>Scheduled in next 7 days</p>
    <p>$(ConvertTo-AIOfficeHtmlText $snapshot.metrics.calendar.today) today · $(ConvertTo-AIOfficeHtmlText $snapshot.metrics.calendar.overdue) overdue</p>
  </article>
  <article class="metric">
    <h3>Knowledge</h3>
    <div class="big">$(ConvertTo-AIOfficeHtmlText $snapshot.metrics.knowledge.active)</div>
    <p>Active of $(ConvertTo-AIOfficeHtmlText $snapshot.metrics.knowledge.total) total</p>
    <p>$(ConvertTo-AIOfficeHtmlText $snapshot.metrics.knowledge.stale) stale</p>
  </article>
  <article class="metric">
    <h3>System Health</h3>
    <div class="big">$(ConvertTo-AIOfficeHtmlText $snapshot.metrics.system.json_files_checked)</div>
    <p>JSON files checked</p>
    <p>$(ConvertTo-AIOfficeHtmlText $snapshot.metrics.system.invalid_json_files) invalid · $(ConvertTo-AIOfficeHtmlText $snapshot.metrics.system.required_components_missing) missing components</p>
  </article>
</section>

<section class="section">
  <h2>Risks</h2>
  $($riskRows -join "`r`n")
</section>

<section class="section">
  <h2>Recommendations</h2>
  <ul>
    $($recommendationRows -join "`r`n")
  </ul>
</section>

<footer>
Snapshot $(ConvertTo-AIOfficeHtmlText $snapshot.snapshot_id)
</footer>
</div>
</body>
</html>
"@

$reportFile = (
    [System.IO.Path]::GetFileNameWithoutExtension($snapshotFile) +
    ".html"
)

$reportPath = Join-Path `
    ".\workspace\dashboard\reports" `
    $reportFile

Set-Content `
    -LiteralPath $reportPath `
    -Value $html `
    -Encoding UTF8

Write-Host "Executive dashboard HTML report created: $reportPath" `
    -ForegroundColor Green

if ($Open) {
    Start-Process $reportPath
}

return $reportPath
