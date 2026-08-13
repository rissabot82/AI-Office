param(
    [switch]$Save
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"

$Cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$Computer = Get-CimInstance Win32_ComputerSystem
$GpuRecords = @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue)

$Gpu = @(
    foreach ($Item in $GpuRecords) {
        [ordered]@{
            name = [string]$Item.Name
            adapter_ram_bytes = if ($null -ne $Item.AdapterRAM) { [int64]$Item.AdapterRAM } else { 0 }
            driver_version = [string]$Item.DriverVersion
        }
    }
)

$Id = New-AIOfficeSelfHostingId -Prefix "SHHW"

$Profile = [ordered]@{
    hardware_profile_id = $Id
    hostname = [string]$env:COMPUTERNAME
    cpu = [ordered]@{
        name = [string]$Cpu.Name
        logical_processors = [int]$Computer.NumberOfLogicalProcessors
        cores = [int]$Computer.NumberOfProcessors
    }
    memory = [ordered]@{
        total_bytes = [int64]$Computer.TotalPhysicalMemory
        total_gb = [math]::Round(([double]$Computer.TotalPhysicalMemory / 1GB),2)
    }
    gpu = $Gpu
    captured_at = (Get-Date).ToString("o")
}

if ($Save) {
    Write-AIOfficeSelfHostingJson `
        -Value $Profile `
        -Path "E:\AI\AI-Office\workspace\self-hosting\hardware\$Id.json"

    & "E:\AI\AI-Office\scripts\self-hosting\Update-AIOfficeSelfHostingIndex.ps1" | Out-Null
    Write-Host "Hardware profile saved: $Id" -ForegroundColor Green
}

return [pscustomobject]$Profile
