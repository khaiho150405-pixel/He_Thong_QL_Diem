# Nối lại cổng 8080/3000/9000 tới điện thoại sau khi rút/cắm lại dây USB (dịch vụ trên máy tính vẫn chạy).
# Dùng:  powershell -NoProfile -ExecutionPolicy Bypass -File scripts/recognition/pilot/usb-reconnect.ps1 [-Serial <id>]
param([string]$Serial = '')
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
. (Join-Path $PSScriptRoot 'usb-common.ps1')
try {
  $adb = Find-Adb
  if (-not $adb) { throw 'Không tìm thấy adb. Cài Android SDK Platform-Tools (Android Studio > SDK Manager).' }
  $serialUsed = Get-UsbSerial $adb $Serial
  $list = Set-UsbReverse $adb $serialUsed
  Write-Host "[OK]  Đã nối cổng 8080/3000/9000 tới điện thoại $serialUsed" -ForegroundColor Green
  $list | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }
  Write-Host '  Mở app hoặc trình duyệt http://localhost:8080 trên điện thoại.'
  exit 0
} catch {
  Write-Host "[LỖI] $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}
