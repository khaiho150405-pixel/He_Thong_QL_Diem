# Kiem tra JSON chi tiet phieu nhan dang so voi openapi (chi in ten truong, khong in ho ten).
# Dung: powershell -NoProfile -File scripts/recognition/pilot/check-ticket.ps1 <ma phieu>
param([Parameter(Mandatory = $true)][int]$TicketId)
$ErrorActionPreference = 'Stop'
Set-Location (Resolve-Path "$PSScriptRoot\..\..\..")
$p = Get-Content .local/pilot/pilot.json -Raw -Encoding UTF8 | ConvertFrom-Json
$base = 'http://localhost:3000/api/v1'
$body = @{ username = $p.teacherUsername; password = $p.teacherPassword } | ConvertTo-Json
$login = Invoke-RestMethod -Method Post -Uri "$base/identity/login" -ContentType 'application/json; charset=utf-8' -Body $body -Headers @{ 'x-client-platform' = 'native' }
$h = @{ 'authorization' = "Bearer $($login.token)"; 'x-client-platform' = 'native' }
try {
  $r = Invoke-WebRequest -UseBasicParsing -Uri "$base/gradebooks/$($p.gradebookId)/recognition-tickets/$TicketId" -Headers $h
} catch {
  "HTTP ERROR: $($_.Exception.Response.StatusCode.value__)"; $_.ErrorDetails.Message; exit 1
}
"HTTP $($r.StatusCode)"
$json = [System.Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
$t = $json | ConvertFrom-Json
$api = Get-Content docs/api/openapi.json -Raw -Encoding UTF8 | ConvertFrom-Json
function Check($obj, $schemaName, $where) {
  $sc = $api.components.schemas.$schemaName
  foreach ($f in $sc.required) {
    $prop = $sc.properties.$f
    if (-not ($obj.PSObject.Properties.Name -contains $f)) { "MISSING  $where.$f"; continue }
    $v = $obj.$f
    if ($null -eq $v) { if (-not $prop.nullable) { "NULL_NOT_ALLOWED  $where.$f" }; continue }
    if ($prop.enum -and ($prop.enum -notcontains $v)) { "BAD_ENUM  $where.$f = $v" }
    if ($prop.type -eq 'number' -and -not ($v -is [ValueType])) { "NOT_NUMBER  $where.$f ($($v.GetType().Name))" }
    if ($prop.type -eq 'string' -and -not ($v -is [string]) -and -not ($v -is [datetime])) { "NOT_STRING  $where.$f ($($v.GetType().Name))" }
    if ($prop.type -eq 'array' -and -not ($v -is [array])) { "NOT_ARRAY  $where.$f" }
  }
}
Check $t 'RecognitionTicketDetailDto' 'ticket'
"status=$($t.status) errorCode=$($t.errorCode) rows=$(@($t.rows).Count) declaredRows=$($t.declaredRows) detectedRows=$($t.detectedRows) G/Y/R=$($t.greenRows)/$($t.yellowRows)/$($t.redRows)"
foreach ($row in @($t.rows)) { Check $row 'RecognitionEvidenceRowDto' "row[order=$($row.order)]" }
"model=$($t.modelVersion)"
"order stt cmp level num chu final match"
foreach ($row in @($t.rows)) { "$($row.order) $($row.stt) $($row.comparison) $($row.reviewLevel) $($row.numericValue) $($row.writtenValue) $($row.finalValue) $($row.matchConfidence)" }
"DONE"
