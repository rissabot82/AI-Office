# ============================================================
# AI Office Dashboard v1 Installer
# Local browser dashboard and JSON API
# Repository: E:\AI\AI-Office
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

function Ensure-Directory {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
    }
}

function Write-File {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][AllowEmptyString()][string]$Content
    )

    $Parent = Split-Path -Parent $Path

    if ($Parent -and -not (Test-Path -LiteralPath $Parent -PathType Container)) {
        New-Item -ItemType Directory -Path $Parent -Force | Out-Null
    }

    Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
    Write-Host "[WRITTEN] $Path" -ForegroundColor Green
}

@(
    ".\config\dashboard",
    ".\dashboard",
    ".\dashboard\public",
    ".\dashboard\runtime",
    ".\scripts\dashboard",
    ".\workspace\dashboard",
    ".\workspace\dashboard\logs",
    ".\workspace\dashboard\snapshots",
    ".\docs",
    ".\Installers"
) | ForEach-Object { Ensure-Directory $_ }

$Config = @'
{
  "schema_version": "1.0.0",
  "dashboard_name": "AI Office Control Center",
  "host": "127.0.0.1",
  "port": 18880,
  "refresh_seconds": 15,
  "openclaw_gateway_port": 18789,
  "repository": "E:\\AI\\AI-Office",
  "read_only": true
}
'@

Write-File ".\config\dashboard\dashboard-config.json" $Config

$Server = @'
param(
    [string]$HostAddress = "127.0.0.1",
    [int]$Port = 18880
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$PublicDirectory = Join-Path $Root "dashboard\public"
$LogDirectory = Join-Path $Root "workspace\dashboard\logs"
$PidPath = Join-Path $Root "dashboard\runtime\dashboard.pid"

if (-not (Test-Path -LiteralPath $PublicDirectory -PathType Container)) {
    throw "Dashboard public directory not found."
}

function Read-JsonSafe {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function Get-LatestJson {
    param(
        [Parameter(Mandatory=$true)][string]$Directory,
        [string]$Filter = "*.json"
    )

    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        return $null
    }

    $File = Get-ChildItem `
        -LiteralPath $Directory `
        -Filter $Filter `
        -File `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -eq $File) {
        return $null
    }

    return Read-JsonSafe -Path $File.FullName
}

function Test-Port {
    param([int]$PortNumber)

    try {
        $Client = New-Object System.Net.Sockets.TcpClient
        $Async = $Client.BeginConnect("127.0.0.1", $PortNumber, $null, $null)
        $Connected = $Async.AsyncWaitHandle.WaitOne(500, $false)

        if ($Connected) {
            $Client.EndConnect($Async)
        }

        $Client.Close()
        return $Connected
    }
    catch {
        return $false
    }
}

function Get-CountFromIndex {
    param(
        $Index,
        [string]$Property,
        [int]$Default = 0
    )

    if ($null -eq $Index) {
        return $Default
    }

    $Match = $Index.PSObject.Properties |
        Where-Object { $_.Name -eq $Property } |
        Select-Object -First 1

    if ($null -eq $Match -or $null -eq $Match.Value) {
        return $Default
    }

    return [int]$Match.Value
}

function Get-DashboardStatus {
    $MessageIndex = Read-JsonSafe `
        -Path (Join-Path $Root "workspace\messages\message-index.json")

    $BridgeIndex = Read-JsonSafe `
        -Path (Join-Path $Root "workspace\bridge\bridge-index.json")

    $MemoryIndex = Read-JsonSafe `
        -Path (Join-Path $Root "workspace\memory\indexes\memory-index.json")

    $WorkflowIndex = Read-JsonSafe `
        -Path (
            Join-Path `
                $Root `
                "workspace\autonomous-workflows\indexes\autonomous-workflow-index.json"
        )

    $DepartmentIndex = Read-JsonSafe `
        -Path (
            Join-Path `
                $Root `
                "workspace\departments\department-intelligence-index.json"
        )

    $LatestMonitoring = Get-LatestJson `
        -Directory (Join-Path $Root "workspace\autonomous-workflows\monitoring") `
        -Filter "MON-*.json"

    $LatestMemoryHealth = Get-LatestJson `
        -Directory (Join-Path $Root "workspace\memory\health") `
        -Filter "MEMHEALTH-*.json"

    $LatestWorker = Get-LatestJson `
        -Directory (Join-Path $Root "workspace\autonomous-workflows\workers\history") `
        -Filter "WKC-*.json"

    $Departments = @()

    foreach ($Department in @(
        "marketing",
        "creative",
        "website",
        "analytics",
        "finance",
        "business",
        "side-hustles",
        "youtube",
        "personal-assistant"
    )) {
        $IndexPath = Join-Path `
            $Root `
            ("workspace\departments\" + $Department + "\department-index.json")

        $Index = Read-JsonSafe -Path $IndexPath

        $Departments += [ordered]@{
            id = $Department
            name = (
                $Department -split "-" |
                ForEach-Object {
                    if ($_.Length -gt 0) {
                        $_.Substring(0,1).ToUpper() + $_.Substring(1)
                    }
                }
            ) -join " "
            status = if ($null -ne $Index) { "online" } else { "not_initialized" }
            active_work = Get-CountFromIndex -Index $Index -Property "active_work_count"
            plans = Get-CountFromIndex -Index $Index -Property "plan_count"
            inbox = Get-CountFromIndex -Index $Index -Property "inbox_count"
        }
    }

    $QueueCounts = [ordered]@{}

    foreach ($Queue in @(
        "inbox",
        "outbox",
        "processing",
        "processed",
        "failed",
        "dead-letter",
        "archive"
    )) {
        $Directory = Join-Path $Root ("workspace\messages\" + $Queue)
        $QueueCounts[$Queue] = if (Test-Path -LiteralPath $Directory) {
            @(
                Get-ChildItem `
                    -LiteralPath $Directory `
                    -Filter "MSG-*.json" `
                    -File `
                    -ErrorAction SilentlyContinue
            ).Count
        }
        else {
            0
        }
    }

    $RecentMemory = @(
        Get-ChildItem `
            -LiteralPath (Join-Path $Root "workspace\memory") `
            -Recurse `
            -Filter "MEM-*.json" `
            -File `
            -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 8 |
        ForEach-Object {
            $Record = Read-JsonSafe -Path $_.FullName

            if ($null -ne $Record) {
                [ordered]@{
                    memory_id = [string]$Record.memory_id
                    title = [string]$Record.title
                    scope = [string]$Record.scope
                    type = [string]$Record.memory_type
                    confidence = [double]$Record.confidence
                    updated_at = [string]$Record.updated_at
                }
            }
        }
    )

    $RecentRuns = @(
        Get-ChildItem `
            -LiteralPath (Join-Path $Root "workspace\autonomous-workflows\runs") `
            -Filter "RUN-*.json" `
            -File `
            -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 8 |
        ForEach-Object {
            $Record = Read-JsonSafe -Path $_.FullName

            if ($null -ne $Record) {
                [ordered]@{
                    run_id = [string]$Record.run_id
                    goal_id = [string]$Record.goal_id
                    status = [string]$Record.status
                    current_step = [int]$Record.current_step
                    updated_at = [string]$Record.updated_at
                }
            }
        }
    )

    return [ordered]@{
        generated_at = (Get-Date).ToString("o")
        system = [ordered]@{
            ai_office = "online"
            dashboard = "online"
            openclaw = if (Test-Port -PortNumber 18789) { "online" } else { "offline" }
            bridge = if ($null -ne $BridgeIndex) { [string]$BridgeIndex.status } else { "unknown" }
            memory = if ($null -ne $MemoryIndex) { [string]$MemoryIndex.status } else { "unknown" }
            autonomous_workflows = if ($null -ne $WorkflowIndex) { [string]$WorkflowIndex.status } else { "unknown" }
        }
        counts = [ordered]@{
            total_messages = Get-CountFromIndex -Index $MessageIndex -Property "total_message_count"
            total_memory = Get-CountFromIndex -Index $MemoryIndex -Property "total_memory_count"
            active_memory = Get-CountFromIndex -Index $MemoryIndex -Property "active_memory_count"
            goals = Get-CountFromIndex -Index $WorkflowIndex -Property "goal_count"
            open_goals = Get-CountFromIndex -Index $WorkflowIndex -Property "open_goal_count"
            active_runs = Get-CountFromIndex -Index $WorkflowIndex -Property "active_run_count"
            failed_runs = Get-CountFromIndex -Index $WorkflowIndex -Property "failed_run_count"
            waiting_approval = Get-CountFromIndex -Index $WorkflowIndex -Property "waiting_approval_count"
        }
        queues = $QueueCounts
        departments = $Departments
        recent_memory = $RecentMemory
        recent_runs = $RecentRuns
        monitoring = $LatestMonitoring
        memory_health = $LatestMemoryHealth
        latest_worker_cycle = $LatestWorker
        raw = [ordered]@{
            bridge_index = $BridgeIndex
            memory_index = $MemoryIndex
            workflow_index = $WorkflowIndex
            department_index = $DepartmentIndex
        }
    }
}

function Write-Response {
    param(
        [Parameter(Mandatory=$true)]$Context,
        [int]$StatusCode = 200,
        [string]$ContentType = "text/plain; charset=utf-8",
        [byte[]]$Body
    )

    $Context.Response.StatusCode = $StatusCode
    $Context.Response.ContentType = $ContentType
    $Context.Response.ContentLength64 = $Body.Length
    $Context.Response.OutputStream.Write($Body, 0, $Body.Length)
    $Context.Response.OutputStream.Close()
}

function Get-ContentType {
    param([string]$Path)

    switch ([IO.Path]::GetExtension($Path).ToLowerInvariant()) {
        ".html" { return "text/html; charset=utf-8" }
        ".css"  { return "text/css; charset=utf-8" }
        ".js"   { return "application/javascript; charset=utf-8" }
        ".json" { return "application/json; charset=utf-8" }
        ".svg"  { return "image/svg+xml" }
        ".png"  { return "image/png" }
        default { return "application/octet-stream" }
    }
}

$Listener = New-Object System.Net.HttpListener
$Prefix = "http://" + $HostAddress + ":" + $Port + "/"
$Listener.Prefixes.Add($Prefix)
$Listener.Start()

Set-Content -LiteralPath $PidPath -Value $PID -Encoding ASCII

$LogPath = Join-Path `
    $LogDirectory `
    ("dashboard-" + (Get-Date -Format "yyyyMMdd") + ".log")

Add-Content `
    -LiteralPath $LogPath `
    -Value ("[" + (Get-Date).ToString("o") + "] Started " + $Prefix)

Write-Host ""
Write-Host "AI Office Dashboard is running." -ForegroundColor Green
Write-Host $Prefix -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop." -ForegroundColor Yellow
Write-Host ""

try {
    while ($Listener.IsListening) {
        $Context = $Listener.GetContext()
        $RequestPath = $Context.Request.Url.AbsolutePath

        try {
            if ($RequestPath -eq "/api/status") {
                $Payload = Get-DashboardStatus |
                    ConvertTo-Json -Depth 80

                $Bytes = [Text.Encoding]::UTF8.GetBytes($Payload)

                Write-Response `
                    -Context $Context `
                    -StatusCode 200 `
                    -ContentType "application/json; charset=utf-8" `
                    -Body $Bytes

                continue
            }

            if ($RequestPath -eq "/api/health") {
                $Payload = [ordered]@{
                    status = "ok"
                    generated_at = (Get-Date).ToString("o")
                } | ConvertTo-Json

                Write-Response `
                    -Context $Context `
                    -StatusCode 200 `
                    -ContentType "application/json; charset=utf-8" `
                    -Body ([Text.Encoding]::UTF8.GetBytes($Payload))

                continue
            }

            $RelativePath = $RequestPath.TrimStart("/")

            if ([string]::IsNullOrWhiteSpace($RelativePath)) {
                $RelativePath = "index.html"
            }

            $RelativePath = $RelativePath.Replace("/", [IO.Path]::DirectorySeparatorChar)
            $FilePath = [IO.Path]::GetFullPath((Join-Path $PublicDirectory $RelativePath))
            $PublicFull = [IO.Path]::GetFullPath($PublicDirectory)

            if (-not $FilePath.StartsWith($PublicFull, [StringComparison]::OrdinalIgnoreCase)) {
                Write-Response `
                    -Context $Context `
                    -StatusCode 403 `
                    -Body ([Text.Encoding]::UTF8.GetBytes("Forbidden"))
                continue
            }

            if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
                Write-Response `
                    -Context $Context `
                    -StatusCode 404 `
                    -Body ([Text.Encoding]::UTF8.GetBytes("Not found"))
                continue
            }

            Write-Response `
                -Context $Context `
                -StatusCode 200 `
                -ContentType (Get-ContentType -Path $FilePath) `
                -Body ([IO.File]::ReadAllBytes($FilePath))
        }
        catch {
            try {
                Write-Response `
                    -Context $Context `
                    -StatusCode 500 `
                    -Body ([Text.Encoding]::UTF8.GetBytes($_.Exception.Message))
            }
            catch {
            }

            Add-Content `
                -LiteralPath $LogPath `
                -Value ("[" + (Get-Date).ToString("o") + "] ERROR " + $_.Exception.Message)
        }
    }
}
finally {
    $Listener.Stop()
    $Listener.Close()
    Remove-Item -LiteralPath $PidPath -Force -ErrorAction SilentlyContinue

    Add-Content `
        -LiteralPath $LogPath `
        -Value ("[" + (Get-Date).ToString("o") + "] Stopped")
}
'@

Write-File ".\scripts\dashboard\Start-AIOfficeDashboardServer.ps1" $Server

$StartScript = @'
param(
    [switch]$Foreground,
    [switch]$OpenBrowser
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$Config = Get-Content `
    -LiteralPath ".\config\dashboard\dashboard-config.json" `
    -Raw |
    ConvertFrom-Json

$Url = "http://" + [string]$Config.host + ":" + [string]$Config.port + "/"
$ServerScript = Join-Path `
    $Root `
    "scripts\dashboard\Start-AIOfficeDashboardServer.ps1"

if ($Foreground) {
    & powershell.exe `
        -NoProfile `
        -ExecutionPolicy Bypass `
        -File $ServerScript `
        -HostAddress ([string]$Config.host) `
        -Port ([int]$Config.port)

    exit
}

$ExistingPidPath = Join-Path $Root "dashboard\runtime\dashboard.pid"

if (Test-Path -LiteralPath $ExistingPidPath -PathType Leaf) {
    $ExistingPid = Get-Content -LiteralPath $ExistingPidPath -Raw

    if ($ExistingPid -match "^\d+$") {
        $ExistingProcess = Get-Process `
            -Id ([int]$ExistingPid) `
            -ErrorAction SilentlyContinue

        if ($null -ne $ExistingProcess) {
            Write-Host "Dashboard is already running at $Url" `
                -ForegroundColor Yellow

            if ($OpenBrowser) {
                Start-Process $Url
            }

            return
        }
    }
}

$Process = Start-Process `
    -FilePath "powershell.exe" `
    -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", ('"' + $ServerScript + '"'),
        "-HostAddress", ([string]$Config.host),
        "-Port", ([string]$Config.port)
    ) `
    -WindowStyle Hidden `
    -PassThru

$Ready = $false

for ($Attempt = 1; $Attempt -le 20; $Attempt++) {
    Start-Sleep -Milliseconds 500

    try {
        $Response = Invoke-WebRequest `
            -Uri ($Url + "api/health") `
            -UseBasicParsing `
            -TimeoutSec 2

        if ($Response.StatusCode -eq 200) {
            $Ready = $true
            break
        }
    }
    catch {
    }
}

if (-not $Ready) {
    Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
    throw "Dashboard server did not become ready."
}

Write-Host "AI Office Dashboard started: $Url" -ForegroundColor Green

if ($OpenBrowser) {
    Start-Process $Url
}
'@

Write-File ".\scripts\dashboard\Start-AIOfficeDashboard.ps1" $StartScript

$StopScript = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$PidPath = Join-Path $Root "dashboard\runtime\dashboard.pid"

if (-not (Test-Path -LiteralPath $PidPath -PathType Leaf)) {
    Write-Host "Dashboard is not running." -ForegroundColor Yellow
    return
}

$ProcessId = (Get-Content -LiteralPath $PidPath -Raw).Trim()

if ($ProcessId -notmatch "^\d+$") {
    Remove-Item -LiteralPath $PidPath -Force
    throw "Dashboard PID file was invalid."
}

$Process = Get-Process -Id ([int]$ProcessId) -ErrorAction SilentlyContinue

if ($null -ne $Process) {
    Stop-Process -Id $Process.Id -Force
}

Remove-Item -LiteralPath $PidPath -Force -ErrorAction SilentlyContinue
Write-Host "AI Office Dashboard stopped." -ForegroundColor Green
'@

Write-File ".\scripts\dashboard\Stop-AIOfficeDashboard.ps1" $StopScript

$TaskScript = @'
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$TaskName = "AI Office Dashboard"
$StartScript = Join-Path $Root "scripts\dashboard\Start-AIOfficeDashboard.ps1"

$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument (
        '-NoProfile -ExecutionPolicy Bypass -File "' +
        $StartScript +
        '"'
    ) `
    -WorkingDirectory $Root

$Trigger = New-ScheduledTaskTrigger -AtLogOn

$Settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries

$Existing = Get-ScheduledTask `
    -TaskName $TaskName `
    -ErrorAction SilentlyContinue

if ($null -ne $Existing -and -not $Force) {
    Write-Host "Scheduled task already exists: $TaskName" `
        -ForegroundColor Yellow
    return
}

if ($null -ne $Existing) {
    Unregister-ScheduledTask `
        -TaskName $TaskName `
        -Confirm:$false
}

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Description "Starts the local AI Office dashboard at user logon." |
    Out-Null

Write-Host "Dashboard scheduled task installed." -ForegroundColor Green
'@

Write-File ".\scripts\dashboard\Install-AIOfficeDashboardTask.ps1" $TaskScript

$TestScript = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$Errors = New-Object System.Collections.Generic.List[string]

$Files = @(
    ".\config\dashboard\dashboard-config.json",
    ".\dashboard\public\index.html",
    ".\dashboard\public\styles.css",
    ".\dashboard\public\app.js",
    ".\scripts\dashboard\Start-AIOfficeDashboardServer.ps1",
    ".\scripts\dashboard\Start-AIOfficeDashboard.ps1",
    ".\scripts\dashboard\Stop-AIOfficeDashboard.ps1",
    ".\scripts\dashboard\Install-AIOfficeDashboardTask.ps1"
)

foreach ($File in $Files) {
    if (Test-Path -LiteralPath $File -PathType Leaf) {
        Write-Host "[FOUND] $File" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING] $File" -ForegroundColor Red
        $Errors.Add("Missing: $File")
    }
}

try {
    Get-Content `
        -LiteralPath ".\config\dashboard\dashboard-config.json" `
        -Raw |
        ConvertFrom-Json |
        Out-Null

    Write-Host "[VALID JSON] dashboard-config.json" -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

foreach ($Script in @(
    ".\scripts\dashboard\Start-AIOfficeDashboardServer.ps1",
    ".\scripts\dashboard\Start-AIOfficeDashboard.ps1",
    ".\scripts\dashboard\Stop-AIOfficeDashboard.ps1",
    ".\scripts\dashboard\Install-AIOfficeDashboardTask.ps1"
)) {
    $Tokens = $null
    $ParseErrors = $null

    [System.Management.Automation.Language.Parser]::ParseFile(
        (Resolve-Path $Script),
        [ref]$Tokens,
        [ref]$ParseErrors
    ) | Out-Null

    if ($ParseErrors.Count -eq 0) {
        Write-Host "[SYNTAX OK] $Script" -ForegroundColor Green
    }
    else {
        $Errors.Add(
            $Script + ": " +
            (($ParseErrors | ForEach-Object { $_.Message }) -join "; ")
        )
    }
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) dashboard validation error(s) found." `
        -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "AI Office Dashboard validation passed." -ForegroundColor Green
'@

Write-File ".\scripts\dashboard\Test-AIOfficeDashboard.ps1" $TestScript

$Html = @'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>AI Office Control Center</title>
  <link rel="stylesheet" href="/styles.css">
</head>
<body>
  <div class="shell">
    <header class="topbar">
      <div>
        <p class="eyebrow">LOCAL OPERATIONS</p>
        <h1>AI Office Control Center</h1>
      </div>
      <div class="header-actions">
        <span id="lastUpdated">Waiting for data</span>
        <button id="refreshButton" type="button">Refresh</button>
      </div>
    </header>

    <section id="systemStatus" class="status-strip"></section>

    <main>
      <section class="hero-grid">
        <article class="hero-card">
          <p class="eyebrow">WORKFLOW OPERATIONS</p>
          <div class="hero-number" id="activeRuns">0</div>
          <h2>Active autonomous runs</h2>
          <p id="workflowSummary">No workflow data loaded.</p>
        </article>

        <article class="hero-card">
          <p class="eyebrow">LONG-TERM MEMORY</p>
          <div class="hero-number" id="memoryCount">0</div>
          <h2>Persistent memory records</h2>
          <p id="memorySummary">No memory data loaded.</p>
        </article>

        <article class="hero-card attention">
          <p class="eyebrow">NEEDS ATTENTION</p>
          <div class="hero-number" id="attentionCount">0</div>
          <h2>Approvals and failures</h2>
          <p id="attentionSummary">No alerts detected.</p>
        </article>
      </section>

      <section class="two-column">
        <article class="panel">
          <div class="panel-heading">
            <div>
              <p class="eyebrow">ORGANIZATION</p>
              <h2>Departments</h2>
            </div>
          </div>
          <div id="departments" class="department-grid"></div>
        </article>

        <article class="panel">
          <div class="panel-heading">
            <div>
              <p class="eyebrow">MESSAGE BUS</p>
              <h2>Queue activity</h2>
            </div>
          </div>
          <div id="queues" class="queue-list"></div>
        </article>
      </section>

      <section class="two-column">
        <article class="panel">
          <div class="panel-heading">
            <div>
              <p class="eyebrow">CURRENT CONTEXT</p>
              <h2>Recent memory</h2>
            </div>
          </div>
          <div id="recentMemory" class="timeline"></div>
        </article>

        <article class="panel">
          <div class="panel-heading">
            <div>
              <p class="eyebrow">EXECUTION HISTORY</p>
              <h2>Recent workflow runs</h2>
            </div>
          </div>
          <div id="recentRuns" class="timeline"></div>
        </article>
      </section>
    </main>
  </div>

  <script src="/app.js"></script>
</body>
</html>
'@

Write-File ".\dashboard\public\index.html" $Html

$Css = @'
:root {
  --bg: #081016;
  --surface: #101b24;
  --surface-2: #152430;
  --line: #263946;
  --text: #f4f7f8;
  --muted: #95a8b3;
  --accent: #7ad7c4;
  --accent-2: #9cb7ff;
  --warning: #f2c36b;
  --danger: #ff8d8d;
  --radius: 22px;
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  min-height: 100vh;
  background:
    radial-gradient(circle at top left, rgba(122, 215, 196, 0.11), transparent 34%),
    radial-gradient(circle at top right, rgba(156, 183, 255, 0.10), transparent 32%),
    var(--bg);
  color: var(--text);
}

button {
  font: inherit;
}

.shell {
  width: min(1500px, calc(100% - 36px));
  margin: 0 auto;
  padding: 30px 0 60px;
}

.topbar,
.panel-heading,
.header-actions,
.status-item,
.department-head,
.timeline-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 18px;
}

.topbar {
  margin-bottom: 26px;
}

h1,
h2,
p {
  margin-top: 0;
}

h1 {
  margin-bottom: 0;
  font-size: clamp(2rem, 5vw, 4rem);
  line-height: 0.95;
  letter-spacing: -0.055em;
}

h2 {
  margin-bottom: 8px;
  letter-spacing: -0.025em;
}

.eyebrow {
  margin-bottom: 8px;
  color: var(--accent);
  font-size: 0.72rem;
  font-weight: 800;
  letter-spacing: 0.17em;
}

.header-actions {
  color: var(--muted);
  font-size: 0.9rem;
}

button {
  border: 1px solid var(--line);
  border-radius: 999px;
  padding: 10px 16px;
  background: var(--surface);
  color: var(--text);
  cursor: pointer;
}

button:hover {
  border-color: var(--accent);
}

.status-strip {
  display: grid;
  grid-template-columns: repeat(5, minmax(0, 1fr));
  gap: 10px;
  margin-bottom: 18px;
}

.status-item {
  justify-content: flex-start;
  padding: 13px 16px;
  border: 1px solid var(--line);
  border-radius: 999px;
  background: rgba(16, 27, 36, 0.72);
  color: var(--muted);
  font-size: 0.86rem;
}

.status-dot {
  width: 9px;
  height: 9px;
  border-radius: 50%;
  background: var(--danger);
  box-shadow: 0 0 16px currentColor;
}

.status-dot.online,
.status-dot.ready,
.status-dot.healthy {
  background: var(--accent);
}

.hero-grid {
  display: grid;
  grid-template-columns: 1.35fr 1fr 1fr;
  gap: 16px;
  margin-bottom: 16px;
}

.hero-card,
.panel {
  border: 1px solid var(--line);
  border-radius: var(--radius);
  background: linear-gradient(145deg, rgba(21, 36, 48, 0.96), rgba(12, 22, 29, 0.96));
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.18);
}

.hero-card {
  min-height: 270px;
  padding: 28px;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
}

.hero-card.attention {
  background:
    linear-gradient(145deg, rgba(67, 49, 26, 0.92), rgba(22, 24, 25, 0.96));
}

.hero-number {
  font-size: clamp(4rem, 8vw, 7rem);
  line-height: 0.9;
  font-weight: 800;
  letter-spacing: -0.08em;
  margin: 18px 0;
}

.hero-card p:last-child {
  margin-bottom: 0;
  color: var(--muted);
}

.two-column {
  display: grid;
  grid-template-columns: 1.45fr 1fr;
  gap: 16px;
  margin-bottom: 16px;
}

.panel {
  padding: 24px;
}

.panel-heading {
  margin-bottom: 22px;
}

.department-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
}

.department-card {
  padding: 16px;
  border: 1px solid var(--line);
  border-radius: 16px;
  background: rgba(8, 16, 22, 0.44);
}

.department-card h3 {
  margin: 0;
  font-size: 1rem;
}

.department-card p {
  margin: 14px 0 0;
  color: var(--muted);
  font-size: 0.82rem;
}

.queue-list {
  display: grid;
  gap: 9px;
}

.queue-row {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 16px;
  padding: 13px 0;
  border-bottom: 1px solid var(--line);
}

.queue-row:last-child {
  border-bottom: 0;
}

.queue-value {
  font-weight: 800;
}

.timeline {
  display: grid;
}

.timeline-row {
  align-items: flex-start;
  padding: 14px 0;
  border-bottom: 1px solid var(--line);
}

.timeline-row:last-child {
  border-bottom: 0;
}

.timeline-title {
  margin-bottom: 5px;
  font-weight: 750;
}

.timeline-meta {
  color: var(--muted);
  font-size: 0.8rem;
}

.badge {
  border: 1px solid var(--line);
  border-radius: 999px;
  padding: 5px 9px;
  color: var(--muted);
  font-size: 0.72rem;
  white-space: nowrap;
}

.badge.completed,
.badge.online,
.badge.active,
.badge.promoted {
  color: var(--accent);
  border-color: rgba(122, 215, 196, 0.38);
}

.badge.failed,
.badge.offline {
  color: var(--danger);
}

.badge.waiting_approval,
.badge.attention_required {
  color: var(--warning);
}

.empty {
  padding: 28px 0;
  color: var(--muted);
}

@media (max-width: 1050px) {
  .status-strip,
  .hero-grid,
  .two-column {
    grid-template-columns: 1fr 1fr;
  }

  .hero-card:first-child {
    grid-column: 1 / -1;
  }
}

@media (max-width: 720px) {
  .shell {
    width: min(100% - 22px, 1500px);
    padding-top: 20px;
  }

  .topbar,
  .header-actions {
    align-items: flex-start;
    flex-direction: column;
  }

  .status-strip,
  .hero-grid,
  .two-column,
  .department-grid {
    grid-template-columns: 1fr;
  }

  .hero-card:first-child {
    grid-column: auto;
  }
}
'@

Write-File ".\dashboard\public\styles.css" $Css

$Js = @'
const refreshButton = document.getElementById("refreshButton");

function statusBadge(value) {
  const safe = String(value || "unknown").toLowerCase().replace(/\s+/g, "_");
  return `<span class="badge ${safe}">${value || "unknown"}</span>`;
}

function formatDate(value) {
  if (!value) return "Unknown time";

  const parsed = new Date(value);

  if (Number.isNaN(parsed.getTime())) return value;

  return parsed.toLocaleString();
}

function renderSystem(system) {
  const host = document.getElementById("systemStatus");
  const entries = [
    ["AI Office", system.ai_office],
    ["OpenClaw", system.openclaw],
    ["Bridge", system.bridge],
    ["Memory", system.memory],
    ["Workflows", system.autonomous_workflows],
  ];

  host.innerHTML = entries.map(([label, value]) => `
    <div class="status-item">
      <span class="status-dot ${String(value).toLowerCase()}"></span>
      <strong>${label}</strong>
      <span>${value}</span>
    </div>
  `).join("");
}

function renderDepartments(items) {
  const host = document.getElementById("departments");

  if (!items || items.length === 0) {
    host.innerHTML = `<div class="empty">No departments found.</div>`;
    return;
  }

  host.innerHTML = items.map(item => `
    <div class="department-card">
      <div class="department-head">
        <h3>${item.name}</h3>
        ${statusBadge(item.status)}
      </div>
      <p>${item.active_work} active · ${item.plans} plans · ${item.inbox} inbox</p>
    </div>
  `).join("");
}

function renderQueues(queues) {
  const host = document.getElementById("queues");

  host.innerHTML = Object.entries(queues || {}).map(([name, count]) => `
    <div class="queue-row">
      <span>${name.replace("-", " ")}</span>
      <span class="queue-value">${count}</span>
    </div>
  `).join("");
}

function renderMemory(items) {
  const host = document.getElementById("recentMemory");

  if (!items || items.length === 0) {
    host.innerHTML = `<div class="empty">No persistent memory records yet.</div>`;
    return;
  }

  host.innerHTML = items.map(item => `
    <div class="timeline-row">
      <div>
        <div class="timeline-title">${item.title || item.memory_id}</div>
        <div class="timeline-meta">
          ${item.scope} · ${item.type} · ${formatDate(item.updated_at)}
        </div>
      </div>
      <span class="badge">${Math.round((item.confidence || 0) * 100)}%</span>
    </div>
  `).join("");
}

function renderRuns(items) {
  const host = document.getElementById("recentRuns");

  if (!items || items.length === 0) {
    host.innerHTML = `<div class="empty">No autonomous runs yet.</div>`;
    return;
  }

  host.innerHTML = items.map(item => `
    <div class="timeline-row">
      <div>
        <div class="timeline-title">${item.run_id}</div>
        <div class="timeline-meta">
          Step ${item.current_step} · ${formatDate(item.updated_at)}
        </div>
      </div>
      ${statusBadge(item.status)}
    </div>
  `).join("");
}

function renderSummary(data) {
  const counts = data.counts || {};

  document.getElementById("activeRuns").textContent = counts.active_runs || 0;
  document.getElementById("memoryCount").textContent = counts.total_memory || 0;

  const attention = (counts.failed_runs || 0) + (counts.waiting_approval || 0);
  document.getElementById("attentionCount").textContent = attention;

  document.getElementById("workflowSummary").textContent =
    `${counts.open_goals || 0} open goals across the autonomous workflow engine.`;

  document.getElementById("memorySummary").textContent =
    `${counts.active_memory || 0} active records available for recall and context.`;

  document.getElementById("attentionSummary").textContent =
    attention === 0
      ? "No approvals or failed runs currently require attention."
      : `${counts.waiting_approval || 0} approvals and ${counts.failed_runs || 0} failed runs require review.`;
}

async function loadDashboard() {
  refreshButton.disabled = true;
  refreshButton.textContent = "Refreshing";

  try {
    const response = await fetch("/api/status", { cache: "no-store" });

    if (!response.ok) {
      throw new Error(`Dashboard API returned ${response.status}`);
    }

    const data = await response.json();

    renderSystem(data.system || {});
    renderSummary(data);
    renderDepartments(data.departments || []);
    renderQueues(data.queues || {});
    renderMemory(data.recent_memory || []);
    renderRuns(data.recent_runs || []);

    document.getElementById("lastUpdated").textContent =
      `Updated ${formatDate(data.generated_at)}`;
  } catch (error) {
    document.getElementById("lastUpdated").textContent = error.message;
  } finally {
    refreshButton.disabled = false;
    refreshButton.textContent = "Refresh";
  }
}

refreshButton.addEventListener("click", loadDashboard);

loadDashboard();
setInterval(loadDashboard, 15000);
'@

Write-File ".\dashboard\public\app.js" $Js

$Guide = @'
# AI Office Dashboard

## Start and open

```powershell
Set-Location "E:\AI\AI-Office"

powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\Start-AIOfficeDashboard.ps1" `
    -OpenBrowser
```

Dashboard URL:

```text
http://127.0.0.1:18880/
```

## Stop

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\Stop-AIOfficeDashboard.ps1"
```

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\Test-AIOfficeDashboard.ps1"
```

## Start automatically at Windows logon

Run PowerShell as Administrator:

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\Install-AIOfficeDashboardTask.ps1"
```

The initial dashboard is read-only and displays:

- OpenClaw, bridge, memory, and workflow status
- Message queue counts
- Department activity
- Recent memory
- Recent autonomous runs
- Approval and failure counts
'@

Write-File ".\docs\AI-Office-Dashboard-Guide.md" $Guide

foreach ($Script in @(
    ".\scripts\dashboard\Start-AIOfficeDashboardServer.ps1",
    ".\scripts\dashboard\Start-AIOfficeDashboard.ps1",
    ".\scripts\dashboard\Stop-AIOfficeDashboard.ps1",
    ".\scripts\dashboard\Install-AIOfficeDashboardTask.ps1",
    ".\scripts\dashboard\Test-AIOfficeDashboard.ps1"
)) {
    $Tokens = $null
    $ParseErrors = $null

    [System.Management.Automation.Language.Parser]::ParseFile(
        (Resolve-Path $Script),
        [ref]$Tokens,
        [ref]$ParseErrors
    ) | Out-Null

    if ($ParseErrors.Count -gt 0) {
        throw (
            "Generated dashboard script contains syntax errors in " +
            $Script +
            ": " +
            (($ParseErrors | ForEach-Object { $_.Message }) -join "; ")
        )
    }
}

Write-Host ""
Write-Host "AI Office Dashboard installed." -ForegroundColor Green
Write-Host ""
Write-Host "Validate with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File ".\scripts\dashboard\Test-AIOfficeDashboard.ps1"'
Write-Host ""
Write-Host "Start and open with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File ".\scripts\dashboard\Start-AIOfficeDashboard.ps1" -OpenBrowser'
