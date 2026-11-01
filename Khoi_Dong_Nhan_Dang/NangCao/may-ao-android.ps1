# Chạy app Android trên MÁY ẢO (emulator) của máy tính, tự build lại khi code đổi — giống Bat-nhan-dang.bat.
# Dùng:  powershell -NoProfile -ExecutionPolicy Bypass -File may-ao-android.ps1 [-Avd <tên máy ảo>] [-Rebuild] [-NoStack]
#   -Avd      chọn máy ảo (mặc định: máy ảo đã dùng lần trước, hoặc máy ảo đầu tiên tìm thấy)
#   -Rebuild  bắt buộc build lại APK dù code không đổi
#   -NoStack  không bật lại 5 dịch vụ (khi đã bật bằng Bat-nhan-dang.bat)
# Thứ tự: build APK (khi máy còn nhiều RAM) -> bật hệ thống (up.ps1) -> bật máy ảo -> nối cổng -> cài app -> mở app.
# App dùng cùng cấu hình với điện thoại USB (config/android-usb.json, API = localhost) và adb reverse cổng 8080/3000/9000.
param(
  [string]$Avd = '',
  [switch]$Rebuild,
  [switch]$NoStack
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

function Step([string]$t) { Write-Host ''; Write-Host "== $t ==" -ForegroundColor Cyan }
function Ok([string]$t) { Write-Host "[OK]  $t" -ForegroundColor Green }
function Warn([string]$t) { Write-Host "[!]   $t" -ForegroundColor Yellow }

# Chạy lệnh ngoài mà không để chữ in ra stderr làm dừng script (PowerShell 5.1).
function Invoke-Quiet([scriptblock]$block) {
  $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  try { return (& $block 2>&1 | ForEach-Object { "$_" }) } finally { $ErrorActionPreference = $old }
}

try {
  $repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\He_Thong_QL_Diem') -ErrorAction SilentlyContinue)
  if (-not $repo) { $repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..') -ErrorAction SilentlyContinue) }
  if (-not $repo -or -not (Test-Path (Join-Path $repo.Path 'scripts\recognition\pilot\up.ps1'))) { throw 'Không tìm thấy thư mục dự án. Đặt Khoi_Dong_Nhan_Dang bên trong thư mục dự án.' }
  $repo = $repo.Path
  $pilotScripts = Join-Path $repo 'scripts\recognition\pilot'
  . (Join-Path $pilotScripts 'usb-common.ps1')
  $client = Join-Path $repo 'apps\client_flutter'
  $pilotDir = Join-Path $repo '.local\pilot'
  New-Item -ItemType Directory -Force $pilotDir | Out-Null
  $package = 'vn.edu.quanlydiem.client_flutter.dev'
  $apk = Join-Path $client 'build\app\outputs\flutter-apk\app-development-debug.apk'
  $configFile = Join-Path $client 'config\android-usb.json'

  # ---------------------------------------------------------------- 1. Android SDK và máy ảo
  Step 'Android SDK và máy ảo'
  $sdk = @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT, (Join-Path $env:LOCALAPPDATA 'Android\Sdk')) |
    Where-Object { $_ -and (Test-Path (Join-Path $_ 'platform-tools\adb.exe')) } | Select-Object -First 1
  $adb = if ($sdk) { Join-Path $sdk 'platform-tools\adb.exe' } else { Find-Adb }
  if (-not $adb) { throw 'Không tìm thấy adb. Cài Android Studio > SDK Manager > SDK Tools > "Android SDK Platform-Tools".' }
  if (-not $sdk) { $sdk = Split-Path (Split-Path $adb -Parent) -Parent }
  $emulator = Join-Path $sdk 'emulator\emulator.exe'
  if (-not (Test-Path $emulator)) { throw "Không thấy $emulator. Cài Android Studio > SDK Manager > SDK Tools > ""Android Emulator""." }
  Ok "Android SDK: $sdk"

  $avdFile = Join-Path $pilotDir 'avd.txt'
  $avds = @(Invoke-Quiet { & $emulator -list-avds } | Where-Object { $_ -and $_ -notmatch '^(INFO|WARNING|ERROR)\b' } | ForEach-Object { $_.Trim() })
  if ($avds.Count -eq 0) {
    throw ('Chưa có máy ảo nào. Mở Android Studio > Device Manager > Create Virtual Device: chọn Pixel 7 (hoặc tương tự), ' +
      'ảnh hệ thống API 34/35 x86_64 (Google APIs), RAM 2048 MB, rồi bấm lại file .bat này.')
  }
  if (-not $Avd -and $env:PILOT_AVD) { $Avd = $env:PILOT_AVD }
  if (-not $Avd -and (Test-Path $avdFile)) { $Avd = (Get-Content $avdFile -Raw).Trim() }
  if (-not $Avd -or ($avds -notcontains $Avd)) {
    if ($Avd) { Warn "Không có máy ảo '$Avd'." }
    $Avd = $avds[0]
  }
  [System.IO.File]::WriteAllText($avdFile, $Avd, (New-Object System.Text.UTF8Encoding($false)))
  Ok "Máy ảo: $Avd   (có: $($avds -join ', '); đổi bằng: Bat-may-ao-android.bat -Avd <tên>)"

  # ---------------------------------------------------------------- 2. Giới hạn RAM cho Gradle
  # Máy 16 GB: Gradle mặc định của dự án xin tới 8 GB nên dễ treo khi hệ thống + máy ảo cùng chạy.
  # Chỉ thêm vào file của NGƯỜI DÙNG (~/.gradle/gradle.properties) khi file đó chưa đặt jvmargs; không sửa file dự án.
  $userGradle = Join-Path $env:USERPROFILE '.gradle\gradle.properties'
  $hasJvm = (Test-Path $userGradle) -and (Select-String -Path $userGradle -Pattern '^\s*org\.gradle\.jvmargs' -Quiet)
  if (-not $hasJvm) {
    New-Item -ItemType Directory -Force (Split-Path $userGradle -Parent) | Out-Null
    Add-Content -Path $userGradle -Encoding ASCII -Value "`r`norg.gradle.jvmargs=-Xmx3G -XX:MaxMetaspaceSize=1G -XX:ReservedCodeCacheSize=256m`r`n"
    Warn "Đã giới hạn RAM Gradle 3 GB trong $userGradle"
  }

  # ---------------------------------------------------------------- 3. Build APK khi code mới hơn bản build
  Step 'Build app Android (chỉ khi code thay đổi)'
  $needApk = $Rebuild -or -not (Test-Path $apk)
  if (-not $needApk) {
    $builtAt = (Get-Item $apk).LastWriteTimeUtc
    $srcDirs = @('apps\client_flutter\lib', 'apps\client_flutter\android\app\src', 'packages\api_client_dart\lib') |
      ForEach-Object { Join-Path $repo $_ } | Where-Object { Test-Path $_ }
    $srcFiles = @('apps\client_flutter\pubspec.yaml', 'apps\client_flutter\pubspec.lock', 'apps\client_flutter\config\android-usb.json',
      'apps\client_flutter\android\app\build.gradle.kts') | ForEach-Object { Join-Path $repo $_ } | Where-Object { Test-Path $_ }
    $newer = @(Get-ChildItem -Recurse -File $srcDirs) + @($srcFiles | ForEach-Object { Get-Item $_ }) |
      Where-Object { $_.LastWriteTimeUtc -gt $builtAt } | Select-Object -First 1
    if ($newer) { $needApk = $true; Warn "Code mới hơn bản APK ($($newer.Name)), build lại..." }
  }
  if ($needApk) {
    if (-not (Test-Path $configFile)) {
      [System.IO.File]::WriteAllText($configFile, '{"APP_ENV":"development","API_BASE_URL":"http://localhost:3000"}' + "`n",
        (New-Object System.Text.UTF8Encoding($false)))
    }
    Warn 'Đang build APK (lần đầu 5–15 phút; sau đó 1–3 phút). Nếu đứng yên quá 20 phút: Ctrl+C, đóng bớt chương trình rồi bấm lại.'
    # Plugin Gradle của Flutter 3.35.7 đọc sai flutter_build.d khi đường dẫn có dấu cách (Ho Si Khai) nên build dừng.
    # File này tự sinh lại mỗi lần build, nên xóa trước khi build (lỗi: ancestor C:/Users/Ho is not a directory).
    Get-ChildItem (Join-Path $client 'build\app\intermediates\flutter') -Recurse -Filter 'flutter_build.d' -ErrorAction SilentlyContinue | Remove-Item -Force
    Push-Location $client
    try {
      & flutter build apk --debug --flavor development --dart-define-from-file=config/android-usb.json
      if ($LASTEXITCODE -ne 0) { throw 'flutter build apk thất bại (xem thông báo ở trên).' }
    } finally { Pop-Location }
  }
  if (-not (Test-Path $apk)) { throw "Không thấy file APK: $apk" }
  Ok "APK: $apk"

  # ---------------------------------------------------------------- 4. Bật hệ thống (Docker, migrate, build web, 5 dịch vụ)
  if ($NoStack) {
    Warn 'Bỏ qua bước bật hệ thống (-NoStack).'
  } else {
    Step 'Bật hệ thống (giống Bat-nhan-dang.bat)'
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $pilotScripts 'up.ps1') -NoBrowser
    if ($LASTEXITCODE -ne 0) { throw 'Bật hệ thống thất bại (xem [LỖI] ở trên). Thử Tat-nhan-dang.bat rồi bấm lại.' }
  }

  # ---------------------------------------------------------------- 5. Bật máy ảo
  Step 'Bật máy ảo Android'
  $emuDevice = @(Get-AdbDevices $adb | Where-Object { $_.Serial -like 'emulator-*' }) | Select-Object -First 1
  if (-not $emuDevice) {
    Start-Process -FilePath $emulator -ArgumentList @('-avd', $Avd, '-netdelay', 'none', '-netspeed', 'full') | Out-Null
    Warn 'Đang khởi động máy ảo (lần đầu 1–3 phút)...'
  }
  $deadline = (Get-Date).AddSeconds(300)
  $serial = $null
  while (-not $serial) {
    if ((Get-Date) -gt $deadline) { throw 'Máy ảo chưa lên sau 5 phút. Mở Android Studio > Device Manager kiểm tra máy ảo, rồi bấm lại.' }
    $d = @(Get-AdbDevices $adb | Where-Object { $_.Serial -like 'emulator-*' -and $_.State -eq 'device' }) | Select-Object -First 1
    if ($d) { $serial = $d.Serial } else { Start-Sleep -Seconds 3 }
  }
  while (((Invoke-Quiet { & $adb -s $serial shell getprop sys.boot_completed }) -join '').Trim() -ne '1') {
    if ((Get-Date) -gt $deadline) { throw 'Máy ảo khởi động quá lâu. Đóng cửa sổ máy ảo rồi bấm lại.' }
    Start-Sleep -Seconds 3
  }
  Ok "Máy ảo sẵn sàng: $serial"

  # ---------------------------------------------------------------- 6. Nối cổng như điện thoại USB
  $list = Set-UsbReverse $adb $serial
  Ok 'Đã nối cổng 8080/3000/9000 từ máy ảo về máy tính'
  $list | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }

  # ---------------------------------------------------------------- 7. Cài app (bỏ qua nếu bản đã cài trùng)
  Step 'Cài app lên máy ảo'
  $sha = if (Test-Path "$apk.sha1") { (Get-Content "$apk.sha1" -Raw).Trim() } else { (Get-FileHash $apk -Algorithm SHA1).Hash }
  $stamp = Join-Path $pilotDir "emulator-$Avd.sha1"
  $installed = ((Invoke-Quiet { & $adb -s $serial shell pm path $package }) -join '') -match 'package:'
  $sameApk = (Test-Path $stamp) -and ((Get-Content $stamp -Raw).Trim() -eq $sha)
  if ($installed -and $sameApk) {
    Ok 'App trên máy ảo đã là bản mới nhất'
  } else {
    Warn 'Đang cài APK (khoảng 1 phút)...'
    $out = Invoke-Quiet { & $adb -s $serial install -r $apk }
    if (($out -join ' ') -match 'INSTALL_FAILED_UPDATE_INCOMPATIBLE|INSTALL_FAILED_VERSION_DOWNGRADE') {
      Warn 'Bản cũ khác chữ ký, gỡ rồi cài lại (dữ liệu đăng nhập trên máy ảo sẽ mất)...'
      Invoke-Quiet { & $adb -s $serial uninstall $package } | Out-Null
      $out = Invoke-Quiet { & $adb -s $serial install $apk }
    }
    if (($out -join ' ') -notmatch 'Success') { $out | ForEach-Object { Write-Host "  $_" }; throw 'Cài APK thất bại (xem thông báo ở trên).' }
    [System.IO.File]::WriteAllText($stamp, $sha, (New-Object System.Text.UTF8Encoding($false)))
    Ok 'Đã cài app'
  }

  # ---------------------------------------------------------------- 8. Mở app
  Invoke-Quiet { & $adb -s $serial shell am force-stop $package } | Out-Null
  Invoke-Quiet { & $adb -s $serial shell monkey -p $package -c android.intent.category.LAUNCHER 1 } | Out-Null
  Step 'SẴN SÀNG'
  Write-Host "  App đã mở trên máy ảo $Avd ($serial)." -ForegroundColor Green
  Write-Host '  Máy tính vẫn dùng được http://localhost:8080'
  $pilotJson = Join-Path $pilotDir 'pilot.json'
  if (Test-Path $pilotJson) {
    $pilot = Get-Content $pilotJson -Raw -Encoding UTF8 | ConvertFrom-Json
    Write-Host "  Tài khoản giáo viên thử: $($pilot.teacherUsername) (mật khẩu: teacherPassword trong .local\pilot\pilot.json)"
  }
  Write-Host '  Ảnh bảng điểm để thử nhận dạng: kéo thả file ảnh vào cửa sổ máy ảo (lưu vào Download), rồi chọn "Chọn ảnh" trong app.'
  Write-Host '  Code giao diện đổi: bấm lại file này (tự build và cài bản mới). Xong việc: Tat-nhan-dang.bat và đóng cửa sổ máy ảo.'
  exit 0
} catch {
  Write-Host ''
  Write-Host "[LỖI] $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}
