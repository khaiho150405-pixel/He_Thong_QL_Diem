# Hàm dùng chung cho điện thoại cắm USB (adb reverse). Được up.ps1, usb-reconnect.ps1, down.ps1 nạp bằng dot-source.

function Find-Adb {
  $candidates = @()
  if ($env:ANDROID_HOME) { $candidates += (Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe') }
  if ($env:ANDROID_SDK_ROOT) { $candidates += (Join-Path $env:ANDROID_SDK_ROOT 'platform-tools\adb.exe') }
  if ($env:LOCALAPPDATA) { $candidates += (Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe') }
  foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
  $cmd = Get-Command adb -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  return $null
}

function Get-AdbDevices([string]$Adb) {
  $old = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    & $Adb start-server 2>&1 | Out-Null
    $raw = & $Adb devices 2>$null
  } finally { $ErrorActionPreference = $old }
  $devices = @()
  foreach ($line in $raw) {
    # Dòng thiết bị dạng "<serial><TAB><trạng thái>"; bỏ dòng tiêu đề và thông báo daemon ("* ...").
    if ($line -match '^([^\s*]\S*)\t+(\S+)\s*$') {
      $devices += [pscustomobject]@{ Serial = $Matches[1]; State = $Matches[2] }
    }
  }
  return $devices
}

function Get-UsbSerial([string]$Adb, [string]$Serial) {
  $devices = @(Get-AdbDevices $Adb)
  if ($Serial) { $devices = @($devices | Where-Object { $_.Serial -eq $Serial }) }
  if ($devices.Count -eq 0) {
    throw ("Không thấy điện thoại qua USB. Kiểm tra: (1) đã bật 'Gỡ lỗi USB' trong Tùy chọn nhà phát triển, " +
      "(2) dùng dây truyền dữ liệu (không phải dây chỉ sạc), (3) chọn chế độ USB 'Truyền tệp' trên điện thoại.")
  }
  if ($devices.Count -gt 1) {
    $list = ($devices | ForEach-Object { "$($_.Serial) ($($_.State))" }) -join ', '
    throw "Có nhiều thiết bị: $list. Chạy lại với -Serial <mã thiết bị>."
  }
  $d = $devices[0]
  if ($d.State -eq 'unauthorized') {
    throw "Điện thoại chưa cho phép máy tính này. Mở khóa điện thoại và bấm 'Cho phép gỡ lỗi USB', rồi chạy lại."
  }
  if ($d.State -ne 'device') { throw "Điện thoại đang ở trạng thái '$($d.State)'. Rút ra cắm lại dây rồi chạy lại." }
  return $d.Serial
}

function Set-UsbReverse([string]$Adb, [string]$Serial) {
  $old = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    foreach ($port in 8080, 3000, 9000) {
      & $Adb -s $Serial reverse "tcp:$port" "tcp:$port" 2>&1 | Out-Null
      if ($LASTEXITCODE -ne 0) { throw "adb reverse cổng $port thất bại." }
    }
    $list = & $Adb -s $Serial reverse --list 2>$null
  } finally { $ErrorActionPreference = $old }
  return $list
}

function Remove-UsbReverse([string]$Adb) {
  $old = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    foreach ($d in @(Get-AdbDevices $Adb)) {
      if ($d.State -eq 'device') { & $Adb -s $d.Serial reverse --remove-all 2>&1 | Out-Null }
    }
  } finally { $ErrorActionPreference = $old }
}
