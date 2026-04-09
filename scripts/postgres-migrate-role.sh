#!/usr/bin/env sh
# Переименовать суперпользователя старого кластера (admin или postgres) в crm_pg_app
# и выставить пароль из корневого .env. Запуск из корня репозитория:
#   sh scripts/postgres-migrate-role.sh
set -e
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ ! -f .env ]; then
  echo "Нет файла .env в $ROOT — скопируйте .env.example в .env и заполните." >&2
  exit 1
fi

# shellcheck source=/dev/null
. ./.env

if [ -z "${POSTGRES_USER:-}" ] || [ -z "${POSTGRES_PASSWORD:-}" ]; then
  echo "В .env должны быть POSTGRES_USER и POSTGRES_PASSWORD." >&2
  exit 1
fi

NEW_USER="$POSTGRES_USER"
NEW_PASS="$POSTGRES_PASSWORD"

sql_escape() {
  printf '%s' "$1" | sed "s/'/''/g"
}
ESC_PASS="$(sql_escape "$NEW_PASS")"

detect_super() {
  for u in admin postgres; do
    if docker compose exec -T postgres psql -U "$u" -d postgres -tAc 'SELECT 1' >/dev/null 2>&1; then
      echo "$u"
      return 0
    fi
  done
  return 1
}

OLD_SUPER="$(detect_super)" || {
  echo "Не удалось подключиться к Postgres как admin или postgres (локальный trust внутри контейнера)." >&2
  echo "Если кластер пустой или сломан — удалите данные: ./crm-tg-app-postgress/postgres и поднимите postgres заново." >&2
  exit 1
}

HAS_NEW="$(docker compose exec -T postgres psql -U "$OLD_SUPER" -d postgres -tAc \
  "SELECT 1 FROM pg_roles WHERE rolname = '$NEW_USER' LIMIT 1;" | tr -d '[:space:]')"

if [ "$HAS_NEW" = "1" ]; then
  echo "Роль $NEW_USER уже есть — обновляю только пароль."
  docker compose exec -T postgres psql -U "$NEW_USER" -d postgres -v ON_ERROR_STOP=1 -c \
    "DROP ROLE IF EXISTS _tg_crm_role_sync_tmp;"
  docker compose exec -T postgres psql -U "$NEW_USER" -d postgres -v ON_ERROR_STOP=1 -c \
    "ALTER ROLE \"$NEW_USER\" WITH PASSWORD '$ESC_PASS';"
  echo "Готово."
  exit 0
fi

TMP="_tg_crm_role_sync_tmp"
echo "Найден суперпользователь: $OLD_SUPER → переименование в $NEW_USER (временная роль $TMP)"

docker compose exec -T postgres psql -U "$OLD_SUPER" -d postgres -v ON_ERROR_STOP=1 -c "DROP ROLE IF EXISTS $TMP;"
docker compose exec -T postgres psql -U "$OLD_SUPER" -d postgres -v ON_ERROR_STOP=1 -c "CREATE ROLE $TMP WITH LOGIN SUPERUSER;"
docker compose exec -T postgres psql -U "$TMP" -d postgres -v ON_ERROR_STOP=1 -c \
  "ALTER ROLE \"$OLD_SUPER\" RENAME TO \"$NEW_USER\";"
docker compose exec -T postgres psql -U "$NEW_USER" -d postgres -v ON_ERROR_STOP=1 -c \
  "ALTER ROLE \"$NEW_USER\" WITH PASSWORD '$ESC_PASS';"
docker compose exec -T postgres psql -U "$NEW_USER" -d postgres -v ON_ERROR_STOP=1 -c "DROP ROLE $TMP;"

echo "Готово: роль $NEW_USER и пароль из .env применены."
