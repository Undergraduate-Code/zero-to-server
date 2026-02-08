# Creator : BrotherZhafif
# Maintainer :

# Created : 8 February 2025

# 1. CEK ADMIN
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "⚠️  HARUS RUN AS ADMINISTRATOR!" -ForegroundColor Red; Start-Sleep 3; Exit
}

Clear-Host
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   SETUP WINDOWS SERVER (FIXED)          " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 2. INSTALL WSL & UBUNTU
Write-Host "[1/7] Mengaktifkan WSL..." -ForegroundColor Green
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
wsl --install -d Ubuntu
wsl --update

# 3. INSTALL OPENSSH WINDOWS
Write-Host "[2/7] Menginstall SSH Server Windows..." -ForegroundColor Green
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# 4. INSTALL APPS (CHOCO)
Write-Host "[3/7] Install Tools (Git, Python, TightVNC)..." -ForegroundColor Green
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}
choco install git python tightvnc cloudflared -y --no-progress

# 5. SETUP SSH INTERNAL UBUNTU (PORT 2022)
Write-Host "[4/7] Membuat Script Setup Ubuntu..." -ForegroundColor Green
$Path = "C:\ServerLab"
New-Item -ItemType Directory -Force -Path $Path | Out-Null
Set-Location $Path

# Script ini nanti dijalankan user manual setelah restart
$WSLScript = @"
echo '--- SETUP SSH UBUNTU ---'
sudo apt update && sudo apt install openssh-server -y
sudo mkdir -p /run/sshd
sudo sed -i 's/#Port 22/Port 2022/' /etc/ssh/sshd_config
sudo sed -i 's/Port 22/Port 2022/' /etc/ssh/sshd_config
sudo ssh-keygen -A
echo '✅ SSH Ubuntu Siap di Port 2022'
"@
Set-Content -Path "$Path\setup_wsl_internal.sh" -Value $WSLScript

# 6. SETUP DISPLAY (noVNC)
Write-Host "[5/7] Menyiapkan Display Web..." -ForegroundColor Green
if (!(Test-Path "noVNC")) { git clone --depth 1 https://github.com/novnc/noVNC.git }
pip install websockify

$HTML = @"
<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'><title>Server Lab</title>
<style>body{background:#0d1117;color:#c9d1d9;font-family:'Courier New';display:flex;flex-direction:column;align-items:center;justify-content:center;height:100vh;margin:0}
.box{text-align:center;border:1px solid #30363d;padding:40px;background:#161b22;border-radius:10px}
h1{color:#58a6ff}a{background:#238636;color:white;padding:10px 20px;text-decoration:none;border-radius:5px;font-weight:bold;margin:5px;display:inline-block}
</style></head><body><div class='box'>
<h1>SYSTEM ONLINE</h1>
<a href='vnc.html'>🖥️ DISPLAY (GUI)</a>
<p>SSH Windows (Port 22) | SSH Ubuntu (Port 2022)</p>
</div></body></html>
"@
Set-Content -Path "$Path\noVNC\index.html" -Value $HTML

# 7. LAUNCHER (BAT FILE)
Write-Host "[6/7] Finalisasi..." -ForegroundColor Green
$Token = Read-Host "Paste Token Cloudflare Tunnel"

# FIX: Pakai 127.0.0.1 biar gak kena Loopback Restriction
$Bat = @"
@echo off
title SERVER CONTROLLER
color 0B
cls
echo ==========================================
echo    MENYALAKAN SEMUA LAYANAN...
echo ==========================================
echo [+] Starting Cloudflare...
start /B cloudflared tunnel run --token $Token

echo [+] Starting Web Display...
start /B websockify --web C:\ServerLab\noVNC 6080 127.0.0.1:5900

echo [+] Starting Ubuntu SSH...
wsl -d Ubuntu -- sudo /usr/sbin/sshd -D
pause
"@
Set-Content -Path "$Path\start_server.bat" -Value $Bat

# 8. OPSI BUAT USER LOKAL (SOLUSI AKUN MICROSOFT)
Write-Host ""
Write-Host "⚠️  SARAN: Akun Microsoft sering GAGAL login SSH." -ForegroundColor Yellow
$CreateUser = Read-Host "Buat user lokal 'dev' (Pass: 123) khusus SSH? (Y/N)"
if ($CreateUser -eq 'Y') {
    net user dev 123 /add
    net localgroup administrators dev /add
    Write-Host "✅ User 'dev' dibuat! Gunakan user ini buat SSH." -ForegroundColor Green
}

Write-Host ""
Write-Host "✅ INSTALL SELESAI!" -ForegroundColor Cyan
Write-Host "1. RESTART Laptop sekarang."
Write-Host "2. Buka Folder C:\ServerLab."
Write-Host "3. Klik Kanan -> Open Terminal -> Ketik: wsl -d Ubuntu -- bash setup_wsl_internal.sh"
Write-Host "4. Jalankan start_server.bat"