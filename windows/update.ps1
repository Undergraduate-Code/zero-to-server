if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "⚠️  HARUS RUN AS ADMINISTRATOR!" -ForegroundColor Red; Start-Sleep 3; Exit
}

Write-Host "--- MEMATIKAN SERVER ---" -ForegroundColor Yellow
Stop-Process -Name "cloudflared" -ErrorAction SilentlyContinue
Stop-Process -Name "python" -ErrorAction SilentlyContinue
Stop-Process -Name "websockify" -ErrorAction SilentlyContinue

Write-Host "--- UPDATE APPS WINDOWS ---" -ForegroundColor Cyan
if (Get-Command choco -ErrorAction SilentlyContinue) {
    choco upgrade all -y --limit-output
}
pip install --upgrade websockify

Write-Host "--- UPDATE UBUNTU (WSL) ---" -ForegroundColor Cyan
wsl -d Ubuntu -u root -- bash -c "apt update && apt upgrade -y && apt autoremove -y"

Write-Host "--- MENYALAKAN SERVER ---" -ForegroundColor Green
$ServerScript = "C:\ServerLab\start_server.bat"
if (Test-Path $ServerScript) { Invoke-Item $ServerScript }