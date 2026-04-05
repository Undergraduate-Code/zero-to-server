Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$passCount = 0
$failCount = 0
$totalCount = 0

function Report-Check {
    param(
        [Parameter(Mandatory = $true)][string]$Component,
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Detail
    )

    $script:totalCount++
    if ($Condition) {
        $script:passCount++
        Write-Output "PASS|$Component|$Detail"
    }
    else {
        $script:failCount++
        Write-Output "FAIL|$Component|$Detail"
    }
}

try {
    Report-Check -Component "token_file" -Condition (Test-Path "C:\ServerLab\secrets\cloudflared.token.enc") -Detail "encrypted token present"
    Report-Check -Component "novnc_dir" -Condition (Test-Path "C:\ServerLab\noVNC") -Detail "noVNC directory present"
    Report-Check -Component "cloudflared_process" -Condition [bool](Get-Process -Name cloudflared -ErrorAction SilentlyContinue) -Detail "cloudflared process running"

    $websockifyProc = Get-CimInstance Win32_Process -Filter "Name='python.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match 'websockify' }
    Report-Check -Component "websockify_process" -Condition ($null -ne $websockifyProc) -Detail "websockify process running"

    $sshdService = Get-Service -Name sshd -ErrorAction SilentlyContinue
    Report-Check -Component "sshd_service" -Condition ($sshdService -and $sshdService.Status -eq 'Running') -Detail "Windows sshd service running"

    $port6080 = Get-NetTCPConnection -State Listen -LocalPort 6080 -ErrorAction SilentlyContinue
    Report-Check -Component "port_6080" -Condition ($null -ne $port6080) -Detail "port 6080 listening"

    if ($failCount -gt 0) {
        Write-Output "RESULT|FAIL|passed=$passCount;failed=$failCount;total=$totalCount"
        exit 1
    }

    Write-Output "RESULT|PASS|passed=$passCount;failed=$failCount;total=$totalCount"
    exit 0
}
catch {
    Write-Output "RESULT|ERROR|$($_.Exception.Message)"
    exit 2
}
