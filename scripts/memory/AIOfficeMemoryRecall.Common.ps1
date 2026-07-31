. (Join-Path $PSScriptRoot "AIOfficeMemory.Common.ps1")

function Get-AIOfficeMemoryCaptureRecallPolicy {
    $Root = Get-AIOfficeMemoryRoot

    return Read-AIOfficeMemoryJson `
        -Path (Join-Path $Root "config\memory\memory-capture-recall-policy.json")
}

function New-AIOfficeMemoryCaptureId {
    return (
        "MCAP-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeMemoryContextPacketId {
    return (
        "CTXMEM-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeAllMemoryFiles {
    $Root = Get-AIOfficeMemoryRoot

    $Paths = @(
        "workspace\memory\global",
        "workspace\memory\chief-of-staff",
        "workspace\memory\personal",
        "workspace\memory\business",
        "workspace\memory\shared"
    )

    $Files = New-Object System.Collections.Generic.List[object]

    foreach ($RelativePath in $Paths) {
        foreach ($File in @(
            Get-ChildItem `
                -LiteralPath (Join-Path $Root $RelativePath) `
                -Filter "MEM-*.json" `
                -File `
                -ErrorAction SilentlyContinue
        )) {
            $Files.Add($File)
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
        foreach ($File in @(
            Get-ChildItem `
                -LiteralPath (
                    Join-Path $Root (
                        "workspace\memory\departments\" +
                        $Department +
                        "\records"
                    )
                ) `
                -Filter "MEM-*.json" `
                -File `
                -ErrorAction SilentlyContinue
        )) {
            $Files.Add($File)
        }
    }

    return @($Files | ForEach-Object { $_ })
}

function Find-AIOfficeMemoryFile {
    param([Parameter(Mandatory=$true)][string]$MemoryId)

    foreach ($File in @(Get-AIOfficeAllMemoryFiles)) {
        if ($File.BaseName -eq $MemoryId) {
            return $File
        }
    }

    return $null
}

function Get-AIOfficeMemorySearchText {
    param([Parameter(Mandatory=$true)]$Record)

    return (
        [string]$Record.title + " " +
        [string]$Record.summary + " " +
        (@($Record.tags) -join " ") + " " +
        (@($Record.entities) -join " ") + " " +
        (@($Record.projects) -join " ") + " " +
        ($Record.content | ConvertTo-Json -Depth 30 -Compress)
    ).ToLowerInvariant()
}
