param(
    [switch]$Persist
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"
. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeResilience.Common.ps1"

$Policy = Get-AIOfficeResiliencePolicy
$Computer = Get-CimInstance Win32_ComputerSystem
$OperatingSystem = Get-CimInstance Win32_OperatingSystem
$Processor = Get-CimInstance Win32_Processor | Select-Object -First 1

$CpuPercent = if ($null -ne $Processor.LoadPercentage) { [double]$Processor.LoadPercentage } else { 0 }

$TotalMemory = [double]$Computer.TotalPhysicalMemory
$FreeMemory = [double]$OperatingSystem.FreePhysicalMemory * 1KB
$UsedMemory = [math]::Max([double]0, ([double]$TotalMemory - [double]$FreeMemory))
$MemoryPercent = if ($TotalMemory -gt 0) { ($UsedMemory / $TotalMemory) * 100 } else { 0 }

$Gpu = [ordered]@{
    available = $false
    name = ""
    memory_used_mb = 0
    memory_total_mb = 0
    memory_percent = 0
    utilization_percent = 0
    temperature_c = 0
}

try {
    $Smi = & nvidia-smi `
        --query-gpu=name,memory.used,memory.total,utilization.gpu,temperature.gpu `
        --format=csv,noheader,nounits 2>$null

    if (-not [string]::IsNullOrWhiteSpace(($Smi | Out-String))) {
        $Line = @($Smi)[0]
        $Parts = @($Line -split "," | ForEach-Object { $_.Trim() })

        if ($Parts.Count -ge 5) {
            $Gpu.available = $true
            $Gpu.name = [string]$Parts[0]
            $Gpu.memory_used_mb = [double]$Parts[1]
            $Gpu.memory_total_mb = [double]$Parts[2]
            $Gpu.utilization_percent = [double]$Parts[3]
            $Gpu.temperature_c = [double]$Parts[4]
            $Gpu.memory_percent = if ($Gpu.memory_total_mb -gt 0) {
                [math]::Round(($Gpu.memory_used_mb / $Gpu.memory_total_mb) * 100, 2)
            } else { 0 }
        }
    }
}
catch {
}

$Warnings = New-Object System.Collections.Generic.List[string]

$SystemFree = Get-AIOfficeDriveFreeGb -DriveLetter "C:"
$AiFree = Get-AIOfficeDriveFreeGb -DriveLetter "E:"

if ($SystemFree -lt [double]$Policy.resources.minimum_free_system_drive_gb) {
    $Warnings.Add("System drive free space is below configured minimum.")
}

if ($AiFree -lt [double]$Policy.resources.minimum_free_ai_drive_gb) {
    $Warnings.Add("AI drive free space is below configured minimum.")
}

if ($MemoryPercent -gt [double]$Policy.resources.maximum_system_memory_percent) {
    $Warnings.Add("System memory utilization is above configured maximum.")
}

if ($CpuPercent -gt [double]$Policy.resources.maximum_cpu_percent) {
    $Warnings.Add("CPU utilization is above configured maximum.")
}

if ($Gpu.available -and $Gpu.memory_percent -gt [double]$Policy.resources.maximum_gpu_memory_percent) {
    $Warnings.Add("GPU memory utilization is above configured maximum.")
}

if ($Gpu.available -and $Gpu.temperature_c -gt [double]$Policy.resources.warning_gpu_temperature_c) {
    $Warnings.Add("GPU temperature is above configured warning threshold.")
}

$Id = New-AIOfficeSelfHostingId -Prefix "SHRES"

$Snapshot = [ordered]@{
    resource_snapshot_id = $Id
    hostname = [string]$env:COMPUTERNAME
    cpu_percent = [math]::Round($CpuPercent,2)
    memory_percent = [math]::Round($MemoryPercent,2)
    memory_total_gb = [math]::Round(($TotalMemory / 1GB),2)
    gpu = $Gpu
    system_drive_free_gb = $SystemFree
    ai_drive_free_gb = $AiFree
    warnings = @($Warnings | ForEach-Object { $_ })
    created_at = (Get-Date).ToString("o")
}

if ($Persist) {
    Write-AIOfficeSelfHostingJson `
        -Value $Snapshot `
        -Path "E:\AI\AI-Office\workspace\self-hosting\resource-snapshots\$Id.json"
}

Write-Host "Resource snapshot: CPU=$($Snapshot.cpu_percent)% | RAM=$($Snapshot.memory_percent)% | C=$SystemFree GB | E=$AiFree GB" -ForegroundColor Green
return [pscustomobject]$Snapshot

