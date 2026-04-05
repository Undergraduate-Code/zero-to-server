Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "⚠️  MUST RUN AS ADMINISTRATOR!" -ForegroundColor Red; Start-Sleep 3; Exit
}

Write-Host "--- STOPPING SERVER ---" -ForegroundColor Yellow
Stop-Process -Name "cloudflared" -ErrorAction SilentlyContinue
Stop-Process -Name "websockify" -ErrorAction SilentlyContinue
Get-CimInstance Win32_Process -Filter "Name='python.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match 'websockify' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -ErrorAction SilentlyContinue }

Write-Host "--- UPDATING WINDOWS APPS ---" -ForegroundColor Cyan
if (Get-Command choco -ErrorAction SilentlyContinue) {
    choco upgrade all -y --limit-output
}
python -m pip install --upgrade websockify

Write-Host "--- UPDATING UBUNTU (WSL) ---" -ForegroundColor Cyan
wsl -d Ubuntu -u root -- bash -c "apt update && apt upgrade -y && apt autoremove -y"

Write-Host "--- STARTING SERVER ---" -ForegroundColor Green
$ServerScriptPs1 = "C:\ServerLab\start_server.ps1"
$ServerScriptBat = "C:\ServerLab\start_server.bat"

if (Test-Path $ServerScriptPs1) {
    powershell -NoProfile -ExecutionPolicy Bypass -File $ServerScriptPs1
}
elseif (Test-Path $ServerScriptBat) {
    Invoke-Item $ServerScriptBat
}
else {
    Write-Host "No launcher found in C:\ServerLab. Run install.ps1 first." -ForegroundColor Red
}