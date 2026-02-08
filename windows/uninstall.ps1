# 1. ADMIN CHECK
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "⚠️  MUST RUN AS ADMINISTRATOR!" -ForegroundColor Red; Start-Sleep 3; Exit
}

Clear-Host
Write-Host "⚠️  CRITICAL WARNING!" -ForegroundColor Red
Write-Host "This will delete:"
Write-Host "1. UBUNTU WSL (All Linux data will be lost)"
Write-Host "2. Folder C:\ServerLab"
Write-Host ""
$confirm = Read-Host "Type 'DELETE' to confirm"

if ($confirm -ne 'DELETE') {
    Write-Host "Cancelled."
    Exit
}

Write-Host "--- 1. STOPPING SERVICES ---" -ForegroundColor Yellow
Stop-Service sshd -ErrorAction SilentlyContinue
Stop-Process -Name "cloudflared" -ErrorAction SilentlyContinue
Stop-Process -Name "tvnserver" -ErrorAction SilentlyContinue
Stop-Process -Name "python" -ErrorAction SilentlyContinue
Stop-Process -Name "websockify" -ErrorAction SilentlyContinue

Write-Host "--- 2. REMOVING WSL (UBUNTU) ---" -ForegroundColor Yellow
wsl --unregister Ubuntu
Write-Host "Ubuntu WSL successfully removed." -ForegroundColor Gray

Write-Host "--- 3. REMOVING SERVER FILES ---" -ForegroundColor Yellow
if (Test-Path "C:\ServerLab") {
    Remove-Item -Path "C:\ServerLab" -Recurse -Force
    Write-Host "Folder C:\ServerLab deleted."
}

Write-Host ""
Write-Host "--- 4. APP CLEANUP (OPTIONAL) ---" -ForegroundColor Cyan
$removeApps = Read-Host "Do you want to uninstall Cloudflared & TightVNC as well? (Y/N)"
if ($removeApps -eq 'Y') {
    choco uninstall cloudflared tightvnc -y
}

Write-Host ""
Write-Host "✅ CLEAN! The laptop is free from Server components." -ForegroundColor Green