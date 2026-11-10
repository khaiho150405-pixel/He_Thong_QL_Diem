param(
  [Parameter(Mandatory = $true)][ValidateSet('start', 'stop', 'status', 'restart')][string]$Action,
  [string]$Service = 'all'
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Set-Location $root
$pidDir = Join-Path $root '.local\pilot\pids'
$logDir = Join-Path $root '.local\pilot\logs'
New-Item -ItemType Directory -Force $pidDir, $logDir | Out-Null

$weights = if ($env:PILOT_WEIGHTS_DIR) { $env:PILOT_WEIGHTS_DIR } else { 'D:\HocTap\KhoaLuan\App\weights' }
$crnnSha = 'a685425e61662ccfda06ca35db54d539ae8599accd4c48bbd4b394958c0e3e62'
$vietocrSha = '32999513a94f822f4ba4c302749a8d97be0e065631cedceacc0134327f9a73c9'
$nameSha = '0921503a41375a0584268e23ef3d414ea478a8fe8777865c7745d38f2d0bc5db'
$testDatabase = if ($env:PILOT_DATABASE) { $env:PILOT_DATABASE } else { 'qld_phase7_test' }
if (-not $testDatabase.EndsWith('_test')) { throw 'PILOT_DATABASE phải kết thúc bằng _test' }
$timeoutMs = if ($env:PILOT_RECOGNITION_TIMEOUT_MS) { $env:PILOT_RECOGNITION_TIMEOUT_MS } else { '120000' }
$all = 'recognition', 'api', 'dispatcher', 'worker', 'web'

function Import-DotEnv {
  Get-Content (Join-Path $root '.env') | ForEach-Object {
    if ($_ -match '^\s*([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
      [Environment]::SetEnvironmentVariable($Matches[1], $Matches[2].Trim(), 'Process')
    }
  }
}

function Set-PilotEnvironment {
  Import-DotEnv
  $m = $env:MIGRATION_PASSWORD; $r = $env:RUNTIME_PASSWORD
  $env:APP_ENV = 'development'
  if ($env:PILOT_DEPLOY -ne '1') {
    $env:DATABASE_URL = "postgresql://app_runtime:$r@127.0.0.1:5433/$testDatabase"
    $env:MIGRATION_DATABASE_URL = "postgresql://app_migration:$m@127.0.0.1:5433/$testDatabase"
    $env:TEST_MIGRATION_URL = $env:MIGRATION_DATABASE_URL
    $env:TEST_RUNTIME_URL = $env:DATABASE_URL
  }
  $env:RECOGNITION_SERVICE_URL = 'http://127.0.0.1:8000'
  $env:RECOGNITION_MODEL_MODE = 'weights'
  $env:RECOGNITION_CRNN_WEIGHTS = Join-Path $weights 'crnn_num_best_dot6.pth'
  $env:RECOGNITION_CRNN_SHA256 = $crnnSha
  $env:RECOGNITION_VIETOCR_WEIGHTS = Join-Path $weights 'vietocr_best_tang4.pth'
  $env:RECOGNITION_VIETOCR_SHA256 = $vietocrSha
  $env:RECOGNITION_NAME_WEIGHTS = Join-Path $weights 'vietocr_vgg_seq2seq_pretrained.pth'
  $env:RECOGNITION_NAME_SHA256 = $nameSha
  $env:RECOGNITION_DEVICE = 'cpu'
  $env:RECOGNITION_STT_CHECK = '1'
  $env:RECOGNITION_TIMEOUT_MS = $timeoutMs
  $env:PYTHONIOENCODING = 'utf-8'
}

function Get-Command-Line([string]$name) {
  switch ($name) {
    'recognition' { @{ File = (Join-Path $root '.local\venv-ml\Scripts\python.exe'); Args = @('-m', 'uvicorn', 'src.api.main:app', '--app-dir', 'apps/recognition-service', '--host', '127.0.0.1', '--port', '8000') } }
    'api' { @{ File = 'node'; Args = @('--import', 'tsx', 'apps/api/src/main.ts') } }
    'dispatcher' { @{ File = 'node'; Args = @('--import', 'tsx', 'apps/api/src/modules/recognition/dispatch.ts') } }
    'worker' { @{ File = 'node'; Args = @('--import', 'tsx', 'apps/api/src/modules/recognition/run-worker.ts') } }
    'web' { @{ File = 'node'; Args = @('scripts/serve-web.mjs') } }
  }
}

function Test-Running([string]$name) {
  $file = Join-Path $pidDir "$name.pid"
  if (-not (Test-Path $file)) { return $false }
  $id = [int](Get-Content $file)
  return [bool](Get-Process -Id $id -ErrorAction SilentlyContinue)
}

function Start-Service-Pilot([string]$name) {
  if (Test-Running $name) { Write-Output "${name}: running"; return }
  $cmd = Get-Command-Line $name
  $p = Start-Process -FilePath $cmd.File -ArgumentList $cmd.Args -WorkingDirectory $root -WindowStyle Hidden -PassThru `
    -RedirectStandardOutput (Join-Path $logDir "$name.out.log") -RedirectStandardError (Join-Path $logDir "$name.err.log")
  Set-Content -Path (Join-Path $pidDir "$name.pid") -Value $p.Id
  Write-Output "${name}: started (PID $($p.Id))"
}

function Stop-Service-Pilot([string]$name) {
  $file = Join-Path $pidDir "$name.pid"
  if (Test-Path $file) {
    $id = [int](Get-Content $file)
    if (Get-Process -Id $id -ErrorAction SilentlyContinue) { & taskkill /PID $id /T /F | Out-Null; Write-Output "${name}: stopped" }
    else { Write-Output "${name}: not running" }
    Remove-Item $file
  } else { Write-Output "${name}: no PID file" }
}

$targets = if ($Service -eq 'all') { $all } else { @($Service) }
switch ($Action) {
  'start' { Set-PilotEnvironment; foreach ($t in $targets) { Start-Service-Pilot $t } }
  'stop' { foreach ($t in @($targets | Sort-Object { [array]::IndexOf($all, $_) } -Descending)) { Stop-Service-Pilot $t } }
  'restart' { Set-PilotEnvironment; foreach ($t in $targets) { Stop-Service-Pilot $t }; foreach ($t in $targets) { Start-Service-Pilot $t } }
  'status' { foreach ($t in $targets) { Write-Output ("{0}: {1}" -f $t, $(if (Test-Running $t) { 'running' } else { 'stopped' })) } }
}
