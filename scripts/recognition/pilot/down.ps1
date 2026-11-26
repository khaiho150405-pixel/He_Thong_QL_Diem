$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
. (Join-Path $PSScriptRoot 'usb-common.ps1')
try {
  & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'stack.ps1') stop
  $adb = Find-Adb
  if ($adb) { Remove-UsbReverse $adb; Write-Host '[OK]  Đã gỡ chuyển cổng USB (nếu có điện thoại đang cắm)' -ForegroundColor Green }
  Write-Host '[OK]  Đã tắt các dịch vụ thử nhận dạng. Docker vẫn chạy; có thể tắt Docker Desktop nếu muốn.' -ForegroundColor Green
  $tunnel = Get-Service cloudflared -ErrorAction SilentlyContinue
  if ($tunnel -and $tunnel.Status -eq 'Running') {
    Write-Host '[!]   Tunnel cloudflared vẫn chạy: MinIO (cổng 9000) và mọi chương trình nghe cổng 3000/8080 vẫn truy cập được từ Internet.' -ForegroundColor Yellow
    Write-Host '      Để đóng hẳn: mở PowerShell quyền Administrator và chạy Stop-Service cloudflared.' -ForegroundColor Yellow
  }
  exit 0
} catch {
  Write-Host "[LỖI] $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}
