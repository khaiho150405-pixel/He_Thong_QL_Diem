$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
. (Join-Path $PSScriptRoot 'usb-common.ps1')
try {
  & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'stack.ps1') stop
  $adb = Find-Adb
  if ($adb) { Remove-UsbReverse $adb; Write-Host '[OK]  Đã gỡ chuyển cổng USB (nếu có điện thoại đang cắm)' -ForegroundColor Green }
  Write-Host '[OK]  Đã tắt các dịch vụ thử nhận dạng. Docker vẫn chạy; có thể tắt Docker Desktop nếu muốn.' -ForegroundColor Green
  exit 0
} catch {
  Write-Host "[LỖI] $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}
