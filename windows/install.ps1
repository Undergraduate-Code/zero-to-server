# Creator : BrotherZhafif
# Maintainer :

# Created : 8 February 2025

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# 1. CHECK ADMIN
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "⚠️  MUST RUN AS ADMINISTRATOR!" -ForegroundColor Red; Start-Sleep 3; Exit
}

Clear-Host
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   SETUP WINDOWS SERVER (FIXED)          " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 2. INSTALL WSL & UBUNTU
Write-Host "[1/7] Enabling WSL..." -ForegroundColor Green
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
wsl --install -d Ubuntu
wsl --update

# 3. INSTALL OPENSSH WINDOWS
Write-Host "[2/7] Installing Windows SSH Server..." -ForegroundColor Green
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# 4. INSTALL APPS (CHOCO)
Write-Host "[3/7] Installing Tools (Git, Python, TightVNC)..." -ForegroundColor Green
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}
choco install git python tightvnc cloudflared -y --no-progress

# 5. SETUP INTERNAL UBUNTU SSH (PORT 2022)
Write-Host "[4/7] Creating Ubuntu Setup Script..." -ForegroundColor Green
$Path = "C:\ServerLab"
New-Item -ItemType Directory -Force -Path $Path | Out-Null
New-Item -ItemType Directory -Force -Path "$Path\secrets" | Out-Null
Set-Location $Path

# This script will be run manually by the user after restart
$WSLScript = @"
echo '--- UBUNTU SSH SETUP ---'
sudo apt update && sudo apt install openssh-server -y
sudo mkdir -p /run/sshd
if sudo grep -qE '^\s*#?\s*Port\s+' /etc/ssh/sshd_config; then
    sudo sed -i 's/^\s*#\?\s*Port\s\+.*/Port 2022/' /etc/ssh/sshd_config
else
    echo 'Port 2022' | sudo tee -a /etc/ssh/sshd_config >/dev/null
fi
if sudo grep -qE '^\s*#?\s*PasswordAuthentication\s+' /etc/ssh/sshd_config; then
    sudo sed -i 's/^\s*#\?\s*PasswordAuthentication\s\+.*/PasswordAuthentication no/' /etc/ssh/sshd_config
else
    echo 'PasswordAuthentication no' | sudo tee -a /etc/ssh/sshd_config >/dev/null
fi
if sudo grep -qE '^\s*#?\s*PermitRootLogin\s+' /etc/ssh/sshd_config; then
    sudo sed -i 's/^\s*#\?\s*PermitRootLogin\s\+.*/PermitRootLogin no/' /etc/ssh/sshd_config
else
    echo 'PermitRootLogin no' | sudo tee -a /etc/ssh/sshd_config >/dev/null
fi
sudo ssh-keygen -A
sudo service ssh restart || true
echo '✅ Ubuntu SSH Ready on Port 2022'
"@
Set-Content -Path "$Path\setup_wsl_internal.sh" -Value $WSLScript

# 6. SETUP DISPLAY (noVNC)
Write-Host "[5/7] Preparing Web Display..." -ForegroundColor Green
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
Write-Host "[6/7] Finalizing..." -ForegroundColor Green
$SecureToken = Read-Host "Paste Cloudflare Tunnel Token" -AsSecureString
$EncryptedToken = ConvertFrom-SecureString $SecureToken
Set-Content -Path "$Path\secrets\cloudflared.token.enc" -Value $EncryptedToken

# FIX: Use 127.0.0.1 to avoid Loopback Restriction
$LauncherPs1 = @"
Set-StrictMode -Version Latest


$TokenFile = 'C:\ServerLab\secrets\cloudflared.token.enc'
if (!(Test-Path $TokenFile)) {
    Write-Host 'Missing token file. Run install.ps1 again.' -ForegroundColor Red
    exit 1
}

$SecureToken = Get-Content -Path $TokenFile | ConvertTo-SecureString
$TokenPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureToken)
$Token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($TokenPtr)

Write-Host '==========================================' -ForegroundColor Cyan
Write-Host '   STARTING ALL SERVICES...' -ForegroundColor Cyan
Write-Host '==========================================' -ForegroundColor Cyan

Write-Host '[+] Starting Cloudflare...'
Start-Process -WindowStyle Hidden -FilePath 'cloudflared' -ArgumentList @('tunnel', 'run', '--token', $Token)

Write-Host '[+] Starting Web Display...'
Start-Process -WindowStyle Hidden -FilePath 'python' -ArgumentList @('-m', 'websockify', '--web', 'C:\ServerLab\noVNC', '6080', '127.0.0.1:5900')

Write-Host '[+] Starting Ubuntu SSH...'
wsl -d Ubuntu -- sudo /usr/sbin/sshd -D
"@
Set-Content -Path "$Path\start_server.ps1" -Value $LauncherPs1

$Bat = @"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File C:\ServerLab\start_server.ps1
pause
"@
Set-Content -Path "$Path\start_server.bat" -Value $Bat

# 8. LOCAL USER OPTION (MICROSOFT ACCOUNT SOLUTION)
Write-Host ""
Write-Host "⚠️  ADVICE: Microsoft Accounts often FAIL SSH login." -ForegroundColor Yellow
$CreateUser = Read-Host "Create dedicated local SSH user now? (Y/N)"
if ($CreateUser -eq 'Y') {
    $SshUser = Read-Host "Enter local username (example: devops)"
    if ([string]::IsNullOrWhiteSpace($SshUser)) {
        Write-Host "Skipped user creation: username was empty." -ForegroundColor Yellow
    }
    elseif (Get-LocalUser -Name $SshUser -ErrorAction SilentlyContinue) {
        Write-Host "User '$SshUser' already exists. Skipping creation." -ForegroundColor Yellow
    }
    else {
        $SshPassword = Read-Host "Enter strong password for '$SshUser'" -AsSecureString
        New-LocalUser -Name $SshUser -Password $SshPassword -PasswordNeverExpires -AccountNeverExpires | Out-Null
        Add-LocalGroupMember -Group "Users" -Member $SshUser -ErrorAction SilentlyContinue
        Write-Host "✅ User '$SshUser' created. Use this user for SSH." -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "✅ INSTALLATION COMPLETE!" -ForegroundColor Cyan
Write-Host "1. RESTART Laptop now."
Write-Host "2. Open Folder C:\ServerLab."
Write-Host "3. Right Click -> Open Terminal -> Type: wsl -d Ubuntu -- bash setup_wsl_internal.sh"
Write-Host "4. Run start_server.ps1 (or start_server.bat wrapper)"