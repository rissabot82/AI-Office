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
