# Переименовать суперпользователя старого кластера (admin или postgres) в crm_pg_app
# и выставить пароль из корневого .env. Запуск из корня репозитория:
#   powershell -ExecutionPolicy Bypass -File scripts/postgres-migrate-role.ps1
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$EnvFile = Join-Path $Root ".env"
if (-not (Test-Path $EnvFile)) {
  Write-Error "Нет файла .env — скопируйте .env.example в .env и заполните."
}

Get-Content $EnvFile | ForEach-Object {
  if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
  if ($_ -match '^\s*([^=]+)=(.*)$') {
    $name = $matches[1].Trim()
    $val = $matches[2].Trim().Trim('"')
    [Environment]::SetEnvironmentVariable($name, $val, "Process")
  }
}

$NewUser = $env:POSTGRES_USER
$NewPass = $env:POSTGRES_PASSWORD
if (-not $NewUser -or -not $NewPass) {
  Write-Error "В .env должны быть POSTGRES_USER и POSTGRES_PASSWORD."
}

function Sql-Escape([string]$s) { return $s -replace "'", "''" }
$EscPass = Sql-Escape $NewPass

function Test-PgUser([string]$user) {
  $r = docker compose exec -T postgres psql -U $user -d postgres -tAc "SELECT 1" 2>$null
  return ($LASTEXITCODE -eq 0)
}

$OldSuper = $null
foreach ($u in @("admin", "postgres")) {
  if (Test-PgUser $u) { $OldSuper = $u; break }
}
if (-not $OldSuper) {
  Write-Error "Не удалось подключиться как admin или postgres. Удалите ./crm-tg-app-postgress/postgres и создайте кластер заново."
}

$hasNew = (docker compose exec -T postgres psql -U $OldSuper -d postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname = '$NewUser' LIMIT 1").Trim()
if ($hasNew -eq "1") {
  Write-Host "Роль $NewUser уже есть — обновляю только пароль."
  docker compose exec -T postgres psql -U $NewUser -d postgres -v ON_ERROR_STOP=1 -c "DROP ROLE IF EXISTS _tg_crm_role_sync_tmp;"
  docker compose exec -T postgres psql -U $NewUser -d postgres -v ON_ERROR_STOP=1 -c "ALTER ROLE `"$NewUser`" WITH PASSWORD '$EscPass';"
  Write-Host "Готово."
  exit 0
}

$Tmp = "_tg_crm_role_sync_tmp"
Write-Host "Найден суперпользователь: $OldSuper → переименование в $NewUser (временная роль $Tmp)"
docker compose exec -T postgres psql -U $OldSuper -d postgres -v ON_ERROR_STOP=1 -c "DROP ROLE IF EXISTS $Tmp;"
docker compose exec -T postgres psql -U $OldSuper -d postgres -v ON_ERROR_STOP=1 -c "CREATE ROLE $Tmp WITH LOGIN SUPERUSER;"
docker compose exec -T postgres psql -U $Tmp -d postgres -v ON_ERROR_STOP=1 -c "ALTER ROLE `"$OldSuper`" RENAME TO `"$NewUser`";"
docker compose exec -T postgres psql -U $NewUser -d postgres -v ON_ERROR_STOP=1 -c "ALTER ROLE `"$NewUser`" WITH PASSWORD '$EscPass';"
docker compose exec -T postgres psql -U $NewUser -d postgres -v ON_ERROR_STOP=1 -c "DROP ROLE $Tmp;"
Write-Host "Готово."
