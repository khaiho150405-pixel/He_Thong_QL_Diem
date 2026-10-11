# Bật toàn bộ môi trường thử nhận dạng bằng một lệnh (Docker, 5 dịch vụ, kiểm tra sức khỏe, điện thoại USB).
# Dùng:  powershell -NoProfile -ExecutionPolicy Bypass -File scripts/recognition/pilot/up.ps1 [-Usb] [-InstallApp] [-Serial <id>] [-NoBrowser]
#   -Usb         chuyển cổng 8080/3000/9000 sang điện thoại cắm USB (adb reverse)
#   -InstallApp  build và cài app Android (bản debug, API = localhost qua USB); cần -Usb
#   -Serial      mã thiết bị khi cắm nhiều điện thoại
#   -NoBrowser   không mở trình duyệt máy tính
# Không sửa .env, không mở cổng ra mạng LAN. Chỉ tắt tiến trình node/python lạ đang chiếm cổng 3000/8080/8000.
param(
  [switch]$Usb,
  [switch]$InstallApp,
  [string]$Serial = '',
  [switch]$NoBrowser
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Set-Location $root
. (Join-Path $PSScriptRoot 'usb-common.ps1')
$stack = Join-Path $PSScriptRoot 'stack.ps1'
$pilotDir = Join-Path $root '.local\pilot'
$pidDir = Join-Path $pilotDir 'pids'
$logDir = Join-Path $pilotDir 'logs'
New-Item -ItemType Directory -Force $pilotDir | Out-Null

function Step([string]$t) { Write-Host ''; Write-Host "== $t ==" -ForegroundColor Cyan }
function Ok([string]$t) { Write-Host "[OK]  $t" -ForegroundColor Green }
function Warn([string]$t) { Write-Host "[!]   $t" -ForegroundColor Yellow }

function Show-Log([string]$name) {
  foreach ($kind in 'err', 'out') {
    $f = Join-Path $logDir "$name.$kind.log"
    if ((Test-Path $f) -and (Get-Item $f).Length -gt 0) {
      Write-Host "  --- $name.$kind.log (20 dòng cuối) ---" -ForegroundColor DarkGray
      Get-Content $f -Tail 20 | ForEach-Object { Write-Host "  $_" }
    }
  }
}

function Wait-Http([string]$url, [int]$seconds) {
  $deadline = (Get-Date).AddSeconds($seconds)
  while ((Get-Date) -lt $deadline) {
    try {
      $r = Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec 5
      if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 300) { return $true }
    } catch { }
    Start-Sleep -Seconds 2
  }
  return $false
}

try {
  if (-not (Test-Path (Join-Path $root '.env'))) { throw 'Chưa có file .env ở thư mục gốc. Chạy "pnpm setup:local" trước.' }
  if ($InstallApp -and -not $Usb) { $Usb = $true }

  # ---------------------------------------------------------------- 1. Docker
  Step 'Docker (PostgreSQL, Redis, MinIO)'
  $docker = (Get-Command docker -ErrorAction SilentlyContinue).Source
  if (-not $docker) {
    $fallback = Join-Path $env:ProgramFiles 'Docker\Docker\resources\bin\docker.exe'
    if (Test-Path $fallback) { $docker = $fallback } else { throw 'Không tìm thấy Docker. Cài Docker Desktop trước.' }
  }
  function Test-Docker {
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $global:LASTEXITCODE = 1
    & $docker info 2>&1 | Out-Null
    $ok = ($LASTEXITCODE -eq 0)
    $ErrorActionPreference = $old
    return $ok
  }
  if (-not (Test-Docker)) {
    $desktop = Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'
    if (-not (Test-Path $desktop)) { throw "Docker chưa chạy và không thấy $desktop. Hãy mở Docker Desktop." }
    Warn 'Docker chưa chạy, đang mở Docker Desktop (có thể mất 1–2 phút)...'
    Start-Process $desktop | Out-Null
    $deadline = (Get-Date).AddSeconds(180)
    while (-not (Test-Docker)) {
      if ((Get-Date) -gt $deadline) { throw 'Docker Desktop chưa sẵn sàng sau 3 phút. Mở Docker Desktop, chờ chạy xong rồi bấm lại.' }
      Start-Sleep -Seconds 3
    }
  }
  Ok 'Docker đang chạy'
  & $docker compose --env-file .env -f infrastructure/compose.yaml up -d --wait postgres redis minio
  if ($LASTEXITCODE -ne 0) { throw 'Không bật được PostgreSQL/Redis/MinIO (docker compose).' }
  Ok 'PostgreSQL / Redis / MinIO sẵn sàng'

  # ---------------------------------------------------------------- 2. Dọn cổng bị tiến trình lạ chiếm
  Step 'Kiểm tra cổng 3000 / 8080 / 8000'
  $ourPids = @()
  if (Test-Path $pidDir) {
    Get-ChildItem $pidDir -Filter *.pid | ForEach-Object {
      $v = Get-Content $_.FullName -ErrorAction SilentlyContinue | Select-Object -First 1
      if ($v -match '^\d+$') { $ourPids += [int]$v }
    }
  }
  function Test-Ours([int]$procId) {
    # Tiến trình (hoặc tổ tiên của nó, vd python.exe của venv sinh tiến trình con) do stack.ps1 bật.
    $cur = $procId
    for ($i = 0; $i -lt 6 -and $cur -gt 0; $i++) {
      if ($ourPids -contains $cur) { return $true }
      $p = Get-CimInstance Win32_Process -Filter "ProcessId=$cur" -ErrorAction SilentlyContinue
      if (-not $p) { break }
      $cur = [int]$p.ParentProcessId
    }
    return $false
  }
  $killed = $false
  foreach ($port in 3000, 8080, 8000) {
    $owners = @(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue |
      Select-Object -ExpandProperty OwningProcess -Unique)
    foreach ($owner in $owners) {
      $owner = [int]$owner
      if ($owner -le 4 -or (Test-Ours $owner)) { continue }
      $p = Get-CimInstance Win32_Process -Filter "ProcessId=$owner" -ErrorAction SilentlyContinue
      $name = if ($p) { $p.Name } else { '?' }
      Warn "Cổng $port bị tiến trình lạ chiếm: PID $owner ($name)"
      if ($p -and $p.CommandLine) { Write-Host "      $($p.CommandLine)" -ForegroundColor DarkGray }
      if ($name -notmatch '^(node|python|pythonw)(\.exe)?$') {
        throw "Cổng $port đang bị chương trình '$name' (PID $owner) dùng. Hãy tắt chương trình đó rồi bấm lại."
      }
      $target = $owner
      if ($p) {
        $parent = Get-CimInstance Win32_Process -Filter "ProcessId=$($p.ParentProcessId)" -ErrorAction SilentlyContinue
        if ($parent -and $parent.Name -match '^node(\.exe)?$' -and $parent.CommandLine -match 'watch|pnpm') {
          $target = [int]$parent.ProcessId
        }
      }
      $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
      & taskkill /PID $target /T /F 2>&1 | Out-Null
      $ErrorActionPreference = $old
      Ok "Đã tắt PID $target"
      $killed = $true
    }
  }
  if ($killed) { Start-Sleep -Seconds 2 } else { Ok 'Không có tiến trình lạ' }

  # ---------------------------------------------------------------- 3. Trọng số, venv, bản build web
  Step 'Trọng số mô hình và môi trường'
  $wFile = Join-Path $pilotDir 'weights-dir.txt'
  $weights = $env:PILOT_WEIGHTS_DIR
  if (-not $weights -and (Test-Path $wFile)) { $weights = (Get-Content $wFile -Raw).Trim() }
  if (-not $weights -and (Test-Path 'D:\HocTap\KhoaLuan\App\weights')) { $weights = 'D:\HocTap\KhoaLuan\App\weights' }
  if (-not $weights) { $weights = (Read-Host 'Nhập đường dẫn thư mục chứa 3 file trọng số (.pth)').Trim().Trim('"') }
  $need = 'crnn_num_best_dot5.pth', 'vietocr_best_tang4.pth', 'vietocr_vgg_seq2seq_pretrained.pth'
  $missing = @($need | Where-Object { -not (Test-Path (Join-Path $weights $_)) })
  if ($missing.Count -gt 0) {
    if (Test-Path $wFile) { Remove-Item $wFile }
    throw "Thư mục '$weights' thiếu: $($missing -join ', '). Bấm lại và nhập đúng thư mục."
  }
  [System.IO.File]::WriteAllText($wFile, $weights, (New-Object System.Text.UTF8Encoding($false)))
  $env:PILOT_WEIGHTS_DIR = $weights
  Ok "Trọng số: $weights"
  if (-not (Test-Path (Join-Path $root '.local\venv-ml\Scripts\python.exe'))) {
    throw 'Chưa có môi trường Python .local\venv-ml. Làm bước B1 trong docs/development/phase-7-huong-dan-chay.md.'
  }
  Ok 'Python venv-ml'
  $webIndex = Join-Path $root 'apps\client_flutter\build\web\index.html'
  if (-not (Test-Path $webIndex)) {
    Warn 'Chưa có bản build web, đang build (vài phút)...'
    Push-Location (Join-Path $root 'apps\client_flutter')
    try {
      & flutter build web --dart-define-from-file=config/development.json
      if ($LASTEXITCODE -ne 0) { throw 'flutter build web thất bại.' }
    } finally { Pop-Location }
  }
  Ok 'Bản build web'

  # ---------------------------------------------------------------- 4. Bật 5 dịch vụ
  Step 'Bật dịch vụ (recognition, api, dispatcher, worker, web)'
  & powershell -NoProfile -ExecutionPolicy Bypass -File $stack start
  if ($LASTEXITCODE -ne 0) { throw 'stack.ps1 start thất bại.' }

  # ---------------------------------------------------------------- 5. Kiểm tra sức khỏe
  Step 'Kiểm tra sức khỏe (lần đầu có thể mất ~30 giây)'
  $allOk = $true
  $checks = @(
    @{ Name = 'recognition'; Url = 'http://127.0.0.1:8000/health/live' },
    @{ Name = 'api'; Url = 'http://127.0.0.1:3000/api/v1/health/ready' },
    @{ Name = 'web'; Url = 'http://127.0.0.1:8080/' }
  )
  foreach ($c in $checks) {
    if (Wait-Http $c.Url 90) { Ok $c.Name } else { Write-Host "[LỖI] $($c.Name) không phản hồi ($($c.Url))" -ForegroundColor Red; Show-Log $c.Name; $allOk = $false }
  }
  $status = & powershell -NoProfile -ExecutionPolicy Bypass -File $stack status
  foreach ($svc in 'dispatcher', 'worker') {
    if ($status -match "^${svc}: running") { Ok $svc } else { Write-Host "[LỖI] $svc không chạy" -ForegroundColor Red; Show-Log $svc; $allOk = $false }
  }
  if (-not $allOk) { throw 'Có dịch vụ lỗi (xem log ở trên). Thử chạy Tat-nhan-dang.bat rồi bấm lại.' }

  # ---------------------------------------------------------------- 6. Điện thoại USB
  $serialUsed = ''
  if ($Usb) {
    Step 'Điện thoại qua USB'
    $adb = Find-Adb
    if (-not $adb) { throw 'Không tìm thấy adb. Cài Android SDK Platform-Tools (Android Studio > SDK Manager).' }
    $serialUsed = Get-UsbSerial $adb $Serial
    $list = Set-UsbReverse $adb $serialUsed
    Ok "Đã nối cổng 8080/3000/9000 tới điện thoại $serialUsed"
    $list | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }
  }

  # ---------------------------------------------------------------- 7. Cài app Android (tùy chọn)
  if ($InstallApp) {
    Step 'Build và cài app Android (lần đầu mất vài phút)'
    $clientDir = Join-Path $root 'apps\client_flutter'
    $usbConfig = Join-Path $clientDir 'config\android-usb.json'
    if (-not (Test-Path $usbConfig)) {
      [System.IO.File]::WriteAllText($usbConfig, '{"APP_ENV":"development","API_BASE_URL":"http://localhost:3000"}' + "`n",
        (New-Object System.Text.UTF8Encoding($false)))
    }
    Push-Location $clientDir
    try {
      & flutter build apk --debug --flavor development --dart-define-from-file=config/android-usb.json
      if ($LASTEXITCODE -ne 0) { throw 'flutter build apk thất bại.' }
      $apk = Get-ChildItem 'build\app\outputs\flutter-apk' -Filter '*development*debug*.apk' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
      if (-not $apk) { throw 'Không tìm thấy file APK sau khi build.' }
      & $adb -s $serialUsed install -r $apk.FullName
      if ($LASTEXITCODE -ne 0) { throw 'Cài APK thất bại (xem thông báo của adb ở trên).' }
    } finally { Pop-Location }
    Ok 'Đã cài app lên điện thoại'
  }

  # ---------------------------------------------------------------- 8. Tóm tắt
  Step 'SẴN SÀNG'
  Write-Host '  Máy tính:   http://localhost:8080' -ForegroundColor Green
  if ($Usb) { Write-Host '  Điện thoại: mở app, hoặc trình duyệt http://localhost:8080 (giữ dây USB)' -ForegroundColor Green }
  $pilotJson = Join-Path $pilotDir 'pilot.json'
  if (Test-Path $pilotJson) {
    $pilot = Get-Content $pilotJson -Raw -Encoding UTF8 | ConvertFrom-Json
    Write-Host "  Tài khoản giáo viên thử: $($pilot.teacherUsername) (mật khẩu: teacherPassword trong .local\pilot\pilot.json)"
  }
  Write-Host '  Rút dây rồi cắm lại: bấm Noi-lai-dien-thoai.bat. Xong việc: bấm Tat-nhan-dang.bat.'
  if (-not $NoBrowser) { Start-Process 'http://localhost:8080' | Out-Null }
  exit 0
} catch {
  Write-Host ''
  Write-Host "[LỖI] $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}
