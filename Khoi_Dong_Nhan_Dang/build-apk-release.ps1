$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
function Ok([string]$t) { Write-Host "[OK]  $t" -ForegroundColor Green }
function Warn([string]$t) { Write-Host "[!]   $t" -ForegroundColor Yellow }
try {
  $repo = (Resolve-Path (Join-Path $PSScriptRoot '..\He_Thong_QL_Diem') -ErrorAction SilentlyContinue)
  if (-not $repo) { $repo = Resolve-Path (Join-Path $PSScriptRoot '..') }
  $repo = $repo.Path
  $client = Join-Path $repo 'apps\client_flutter'
  $android = Join-Path $client 'android'
  $props = Join-Path $android 'key.properties'
  $jks = Join-Path $android 'app-release.jks'

  if (-not (Test-Path $props)) {
    $keytool = @()
    if ($env:JAVA_HOME) { $keytool += Join-Path $env:JAVA_HOME 'bin\keytool.exe' }
    $keytool += @('C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe', 'C:\Program Files\Android\Android Studio1\jbr\bin\keytool.exe')
    $cmd = Get-Command keytool -ErrorAction SilentlyContinue
    if ($cmd) { $keytool += $cmd.Source }
    $keytool = $keytool | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
    if (-not $keytool) { throw 'Không tìm thấy keytool. Cài Android Studio (có sẵn JDK) hoặc đặt JAVA_HOME.' }
    if (Test-Path $jks) { throw "Đã có $jks nhưng thiếu key.properties. Tạo key.properties thủ công hoặc xóa file .jks cũ (nếu chưa phát hành)." }
    Warn 'Chưa có khóa ký, đang tạo khóa mới...'
    $pw = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 24 | ForEach-Object { [char]$_ })
    & $keytool -genkeypair -v -keystore $jks -storetype PKCS12 -alias eduscore -keyalg RSA -keysize 2048 -validity 10000 `
      -storepass $pw -keypass $pw -dname 'CN=EduScore, OU=KLCN, O=EduScore, C=VN'
    if ($LASTEXITCODE -ne 0) { throw 'keytool thất bại.' }
    $text = "storePassword=$pw`nkeyPassword=$pw`nkeyAlias=eduscore`nstoreFile=app-release.jks`n"
    [System.IO.File]::WriteAllText($props, $text, (New-Object System.Text.UTF8Encoding($false)))
    Ok "Đã tạo khóa: $jks  (SAO LƯU file này và key.properties ra nơi an toàn)"
  }

  $buildDir = Join-Path $client 'build'
  $pathMark = Join-Path $client '.dart_tool\build-root.txt'
  $lastRoot = if (Test-Path $pathMark) { (Get-Content $pathMark -Raw).Trim() } else { $null }
  if ((Test-Path $buildDir) -and $lastRoot -ne $client) {
    Warn 'Phát hiện thư mục dự án đã đổi đường dẫn, xóa cache build cũ...'
    Remove-Item $buildDir -Recurse -Force
    $flutterBuild = Join-Path $client '.dart_tool\flutter_build'
    if (Test-Path $flutterBuild) { Remove-Item $flutterBuild -Recurse -Force }
  }

  Warn 'Đang build APK release (vài phút)...'
  Get-ChildItem (Join-Path $client 'build\app\intermediates\flutter') -Recurse -Filter 'flutter_build.d' -ErrorAction SilentlyContinue | Remove-Item -Force
  Push-Location $client
  try {
    & flutter build apk --release --flavor production --dart-define-from-file=config/production.json
    if ($LASTEXITCODE -ne 0) { throw 'flutter build apk thất bại (xem thông báo ở trên).' }
    New-Item -ItemType Directory -Force (Split-Path $pathMark) | Out-Null
    [System.IO.File]::WriteAllText($pathMark, $client, (New-Object System.Text.UTF8Encoding($false)))
  } finally { Pop-Location }

  $apk = Join-Path $client 'build\app\outputs\flutter-apk\app-production-release.apk'
  if (-not (Test-Path $apk)) { throw "Không thấy file APK: $apk" }
  $out = Join-Path $PSScriptRoot 'APK'
  New-Item -ItemType Directory -Force $out | Out-Null
  $dest = Join-Path $out 'EduScore.apk'
  Copy-Item $apk $dest -Force
  Ok "APK sẵn sàng: $dest ($([math]::Round((Get-Item $dest).Length/1MB,1)) MB)"
  Write-Host '  Gửi file này cho điện thoại (Zalo/Drive/USB), mở lên và cho phép "cài từ nguồn không rõ".'
  exit 0
} catch {
  Write-Host "[LỖI] $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}
