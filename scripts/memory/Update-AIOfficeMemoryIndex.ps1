param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemory.Common.ps1")

$Root = Get-AIOfficeMemoryRoot
Set-Location $Root

$Policy = Get-AIOfficeMemoryPolicy

if ($null -eq $Policy) {
    throw "Memory policy could not be loaded."
}

$Records = New-Object System.Collections.Generic.List[object]
$ScopeCounts = [ordered]@{}
$TypeCounts = [ordered]@{}
$DepartmentCounts = [ordered]@{}

$ScopePaths = @(
    @{ Scope = "global"; Path = ".\workspace\memory\global" },
    @{ Scope = "chief-of-staff"; Path = ".\workspace\memory\chief-of-staff" },
    @{ Scope = "personal"; Path = ".\workspace\memory\personal" },
    @{ Scope = "business"; Path = ".\workspace\memory\business" },
    @{ Scope = "shared"; Path = ".\workspace\memory\shared" }
)

foreach ($ScopePath in $ScopePaths) {
    foreach ($File in @(
        Get-ChildItem `
            -LiteralPath $ScopePath.Path `
            -Filter "MEM-*.json" `
            -File `
            -ErrorAction SilentlyContinue
    )) {
        $Record = Read-AIOfficeMemoryJson -Path $File.FullName

        if ($null -ne $Record) {
            $Records.Add($Record)
        }
    }
}

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
    $DepartmentRecords = New-Object System.Collections.Generic.List[object]

    foreach ($File in @(
        Get-ChildItem `
            -LiteralPath ".\workspace\memory\departments\$Department\records" `
            -Filter "MEM-*.json" `
            -File `
            -ErrorAction SilentlyContinue
    )) {
        $Record = Read-AIOfficeMemoryJson -Path $File.FullName

        if ($null -ne $Record) {
            $Records.Add($Record)
            $DepartmentRecords.Add($Record)
        }
    }

    $DepartmentCounts[$Department] = $DepartmentRecords.Count

    $DepartmentTypeCounts = [ordered]@{}

    foreach ($Record in $DepartmentRecords) {
        $Type = [string]$Record.memory_type

        if (-not $DepartmentTypeCounts.Contains($Type)) {
            $DepartmentTypeCounts[$Type] = 0
        }

        $DepartmentTypeCounts[$Type] = [int]$DepartmentTypeCounts[$Type] + 1
    }

    $DepartmentIndex = [ordered]@{
        schema_version = "1.0.0"
        version = "1.3.0"
        department = $Department
        updated_at = (Get-Date).ToString("o")
        status = "ready"
        active_memory_count = @(
            $DepartmentRecords | Where-Object { $_.status -eq "active" }
        ).Count
        archived_memory_count = @(
            $DepartmentRecords | Where-Object { $_.status -eq "archived" }
        ).Count
        type_counts = $DepartmentTypeCounts
        latest_memory_id = if ($DepartmentRecords.Count -gt 0) {
            [string](
                $DepartmentRecords |
                    Sort-Object updated_at -Descending |
                    Select-Object -First 1
            ).memory_id
        }
        else {
            ""
        }
    }

    Write-AIOfficeMemoryJson `
        -Value $DepartmentIndex `
        -Path ".\workspace\memory\departments\$Department\indexes\memory-index.json"
}

foreach ($Record in $Records) {
    $Scope = [string]$Record.scope
    $Type = [string]$Record.memory_type

    if (-not $ScopeCounts.Contains($Scope)) {
        $ScopeCounts[$Scope] = 0
    }

    if (-not $TypeCounts.Contains($Type)) {
        $TypeCounts[$Type] = 0
    }

    $ScopeCounts[$Scope] = [int]$ScopeCounts[$Scope] + 1
    $TypeCounts[$Type] = [int]$TypeCounts[$Type] + 1
}

$Latest = @(
    $Records |
        Sort-Object updated_at -Descending |
        Select-Object -First 1
)

$Index = [ordered]@{
    schema_version = "1.0.0"
    version = "1.3.0"
    updated_at = (Get-Date).ToString("o")
    status = "ready"
    total_memory_count = $Records.Count
    active_memory_count = @(
        $Records | Where-Object { $_.status -eq "active" }
    ).Count
    archived_memory_count = @(
        $Records | Where-Object { $_.status -eq "archived" }
    ).Count
    scope_counts = $ScopeCounts
    type_counts = $TypeCounts
    department_counts = $DepartmentCounts
    latest_memory_id = if ($Latest.Count -gt 0) {
        [string]$Latest[0].memory_id
    }
    else {
        ""
    }
}

Write-AIOfficeMemoryJson `
    -Value $Index `
    -Path ".\workspace\memory\indexes\memory-index.json"

Write-Host (
    "Long-Term Memory index updated: " +
    $Records.Count.ToString() +
    " memory record(s)"
) -ForegroundColor Green

return [pscustomobject]$Index
