# 1. CEK ADMIN
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "⚠️  HARUS RUN AS ADMINISTRATOR!" -ForegroundColor Red; Start-Sleep 3; Exit
}

Clear-Host
Write-Host "⚠️  PERINGATAN KERAS!" -ForegroundColor Red
Write-Host "Ini akan menghapus:"
Write-Host "1. UBUNTU WSL (Semua data Linux hilang)"
Write-Host "2. Folder C:\ServerLab"
Write-Host ""
$confirm = Read-Host "Ketik 'HAPUS' jika yakin"

if ($confirm -ne 'HAPUS') {
    Write-Host "Dibatalkan."
    Exit
}

Write-Host "--- 1. MEMATIKAN SERVICES ---" -ForegroundColor Yellow
Stop-Service sshd -ErrorAction SilentlyContinue
Stop-Process -Name "cloudflared" -ErrorAction SilentlyContinue
Stop-Process -Name "tvnserver" -ErrorAction SilentlyContinue
Stop-Process -Name "python" -ErrorAction SilentlyContinue
Stop-Process -Name "websockify" -ErrorAction SilentlyContinue

Write-Host "--- 2. MENGHAPUS WSL (UBUNTU) ---" -ForegroundColor Yellow
wsl --unregister Ubuntu
Write-Host "Ubuntu WSL berhasil dihapus." -ForegroundColor Gray

Write-Host "--- 3. MENGHAPUS FILE SERVER ---" -ForegroundColor Yellow
if (Test-Path "C:\ServerLab") {
    Remove-Item -Path "C:\ServerLab" -Recurse -Force
    Write-Host "Folder C:\ServerLab dihapus."
}

Write-Host ""
Write-Host "--- 4. CLEANUP APLIKASI (OPSIONAL) ---" -ForegroundColor Cyan
$hapusApps = Read-Host "Mau uninstall Cloudflared & TightVNC juga? (Y/N)"
if ($hapusApps -eq 'Y') {
    choco uninstall cloudflared tightvnc -y
}

Write-Host ""
Write-Host "✅ BERSIH! Laptop sudah bebas dari Server." -ForegroundColor Green