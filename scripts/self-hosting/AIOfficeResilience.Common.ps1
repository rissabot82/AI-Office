$script:AIOfficeResilienceRoot = "E:\AI\AI-Office"

function Get-AIOfficeResiliencePolicy {
    return Get-Content `
        -LiteralPath "E:\AI\AI-Office\config\self-hosting\resilience-policy.json" `
        -Raw |
        ConvertFrom-Json
}

function Test-AIOfficeTcpPort {
    param(
        [Parameter(Mandatory=$true)][string]$ComputerName,
        [Parameter(Mandatory=$true)][int]$Port,
        [int]$TimeoutMilliseconds = 1000
    )

    try {
        $Client = New-Object System.Net.Sockets.TcpClient
        $Async = $Client.BeginConnect($ComputerName, $Port, $null, $null)
        $Ready = $Async.AsyncWaitHandle.WaitOne($TimeoutMilliseconds, $false)

        if (-not $Ready) {
            $Client.Close()
            return $false
        }

        $Client.EndConnect($Async)
        $Client.Close()
        return $true
    }
    catch {
        return $false
    }
}

function Get-AIOfficeDriveFreeGb {
    param([Parameter(Mandatory=$true)][string]$DriveLetter)

    $Drive = Get-PSDrive -Name $DriveLetter.TrimEnd(":") -ErrorAction SilentlyContinue

    if ($null -eq $Drive) {
        return 0
    }

    return [math]::Round(([double]$Drive.Free / 1GB), 2)
}
