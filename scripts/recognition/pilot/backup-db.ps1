param([Parameter(Mandatory = $true)][string]$Database)
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Set-Location $root
if ($Database -notmatch '^[A-Za-z0-9_]+$') { Write-Host '[LỖI] Tên database không hợp lệ.' -ForegroundColor Red; exit 1 }
$userLine = Select-String -Path (Join-Path $root '.env') -Pattern '^\s*POSTGRES_USER=(.*)$' | Select-Object -First 1
$pgUser = if ($userLine) { $userLine.Matches[0].Groups[1].Value.Trim() } else { 'postgres' }
$compose = @('compose', '--env-file', '.env', '-f', 'infrastructure/compose.yaml')
$directory = Join-Path $root '.local\backups'
New-Item -ItemType Directory -Force $directory | Out-Null
$name = '{0}-{1}.dump' -f $Database, (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$remote = "/tmp/$name"
$target = Join-Path $directory $name
$code = 1
try {
  & docker @compose exec -T postgres pg_dump -U $pgUser -d $Database --format=custom --no-owner "--file=$remote"
  if ($LASTEXITCODE -ne 0) { throw 'pg_dump thất bại.' }
  & docker @compose exec -T postgres pg_restore --list --file=/dev/null $remote
  if ($LASTEXITCODE -ne 0) { throw 'Bản sao lưu không đọc lại được.' }
  & docker @compose cp "postgres:$remote" $target
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path $target)) { throw 'Không chép được bản sao lưu ra máy.' }
  $hash = (Get-FileHash -Algorithm SHA256 $target).Hash.ToLower()
  [System.IO.File]::WriteAllText("$target.sha256", "$hash  $name`n")
  Write-Host "[OK]  Đã sao lưu: $target" -ForegroundColor Green
  $code = 0
} catch {
  Write-Host "[LỖI] $($_.Exception.Message)" -ForegroundColor Red
} finally {
  & docker @compose exec -T postgres rm -f $remote
}
exit $code
