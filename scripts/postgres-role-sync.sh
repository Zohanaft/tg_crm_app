#!/bin/sh
# Одноразовый контейнер: выровнять роль с POSTGRES_USER (docker-compose: network_mode: service:postgres -> 127.0.0.1 + trust).
set -eu
export PGHOST="${PGHOST:-127.0.0.1}"
export PGPORT="${PGPORT:-5432}"

NEW_USER="${POSTGRES_USER:?POSTGRES_USER required}"
NEW_PASS="${POSTGRES_PASSWORD:?POSTGRES_PASSWORD required}"
DB="${POSTGRES_DB:-app}"

sql_escape() {
  printf '%s' "$1" | sed "s/'/''/g"
}
ESC_PASS="$(sql_escape "$NEW_PASS")"

try_psql() {
  _u="$1"
  _d="$2"
  psql -U "$_u" -d "$_d" -tAc 'SELECT 1' >/dev/null 2>&1
}

diag_fail() {
  echo "postgres-role-sync: не удалось подключиться как $NEW_USER, admin или postgres." >&2
  echo "postgres-role-sync: PGHOST=$PGHOST PGPORT=$PGPORT" >&2
  for u in "$NEW_USER" admin postgres; do
    for d in "$DB" postgres template1; do
      echo "postgres-role-sync: проба user=$u db=$d" >&2
      psql -U "$u" -d "$d" -c 'SELECT 1' 2>&1 || true
    done
  done
}

pick_super() {
  for u in "$NEW_USER" admin postgres; do
    for d in "$DB" postgres template1; do
      if try_psql "$u" "$d"; then
        printf '%s %s' "$u" "$d"
        return 0
      fi
    done
  done
  return 1
}

READ="$(pick_super)" || {
  diag_fail
  exit 1
}

OLD_SUPER="${READ% *}"
PSQL_DB="${READ#* }"

HAS_NEW="$(psql -U "$OLD_SUPER" -d "$PSQL_DB" -tAc "SELECT 1 FROM pg_roles WHERE rolname = '$NEW_USER' LIMIT 1" | tr -d '[:space:]')"

if [ "$HAS_NEW" = "1" ]; then
  echo "postgres-role-sync: роль $NEW_USER уже есть - обновляю пароль."
  psql -U "$NEW_USER" -d "$PSQL_DB" -v ON_ERROR_STOP=1 -c "DROP ROLE IF EXISTS _tg_crm_role_sync_tmp;"
  psql -U "$NEW_USER" -d "$PSQL_DB" -v ON_ERROR_STOP=1 -c "ALTER ROLE \"$NEW_USER\" WITH PASSWORD '$ESC_PASS';"
  echo "postgres-role-sync: готово."
  exit 0
fi

# Нельзя RENAME роли, под которой открыта сессия -> временная суперроль.
TMP="_tg_crm_role_sync_tmp"
echo "postgres-role-sync: переименование $OLD_SUPER -> $NEW_USER (временная роль $TMP)."
psql -U "$OLD_SUPER" -d "$PSQL_DB" -v ON_ERROR_STOP=1 -c "DROP ROLE IF EXISTS $TMP;"
psql -U "$OLD_SUPER" -d "$PSQL_DB" -v ON_ERROR_STOP=1 -c "CREATE ROLE $TMP WITH LOGIN SUPERUSER;"
psql -U "$TMP" -d "$PSQL_DB" -v ON_ERROR_STOP=1 -c "ALTER ROLE \"$OLD_SUPER\" RENAME TO \"$NEW_USER\";"
psql -U "$NEW_USER" -d "$PSQL_DB" -v ON_ERROR_STOP=1 -c "ALTER ROLE \"$NEW_USER\" WITH PASSWORD '$ESC_PASS';"
psql -U "$NEW_USER" -d "$PSQL_DB" -v ON_ERROR_STOP=1 -c "DROP ROLE $TMP;"
echo "postgres-role-sync: готово."
