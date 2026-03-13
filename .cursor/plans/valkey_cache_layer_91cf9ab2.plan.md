---
name: Valkey cache layer
overview: "Введение кэша в Valkey (Redis-совместимый) для снижения нагрузки на Postgres: кэширование профиля пользователя по id и планов по id с инвалидацией при изменении данных."
todos: []
isProject: false
---

# План: кэширование в Valkey для разгрузки Postgres

## Текущее состояние

- **Valkey** уже в [docker-compose.yml](docker-compose.yml) (`VALKEY_URL=redis://valkey:6379`), в коде бэкенда не используется.
- Основные обращения к Postgres:
  - **getProfileById(userId)** — вызывается при каждом запросе с JWT ([JwtStrategy.validate](crm-tg-app-backend/src/auth/jwt.strategy.ts) → [AuthService.getProfileById](crm-tg-app-backend/src/auth/auth.service.ts)). Самый горячий путь.
  - **Plan по id** — в [WorkspaceService.create](crm-tg-app-backend/src/workspace/workspace.service.ts) (user + plan + _count). Планов 3, меняются редко.
  - Остальное: login (findOrCreateUser), список ботов, создание workspace — менее частые операции.

Цель: кэшировать чтения по user id и plan id в Valkey, инвалидировать при записи.

---

## 1. Подключение Valkey и слой кэша

- Зависимости: клиент Redis-совместимый для Node (например **ioredis**). Опционально: **@nestjs/cache-manager** + **cache-manager-ioredis-yet** (или **cache-manager-redis-store**) для интеграции с Nest.
- Рекомендация: отдельный **CacheModule** с сервисом, который:
  - читает `VALKEY_URL` (или `REDIS_URL`) из env;
  - при старте создаёт подключение к Valkey (ioredis);
  - экспортирует методы: `get<T>(key)`, `set(key, value, ttlSec?)`, `del(key)`.
- Сериализация: JSON. Для User учесть **BigInt** (telegramId) и **Date** (createdAt, updatedAt, planExpiresAt) — при записи в кэш приводить к строкам/ISO, при чтении — восстанавливать типы.

---

## 2. Что кэшировать


| Сущность                   | Ключ             | TTL                     | Инвалидация                                 |
| -------------------------- | ---------------- | ----------------------- | ------------------------------------------- |
| Профиль пользователя по id | `user:${userId}` | 5–15 мин (настраиваемо) | При обновлении пользователя (логин/профиль) |
| План по id                 | `plan:${planId}` | 1 ч (или без TTL)       | По TTL; при изменении планов — редко        |


Приоритет: сначала **user**, затем **plan** — дают максимальное снижение запросов к Postgres (каждый JWT-запрос + создание workspace).

---

## 3. Интеграция в AuthService

- В [auth.service.ts](crm-tg-app-backend/src/auth/auth.service.ts):
  - **getProfileById(userId)**:
    1. Попытка чтения из кэша `user:${userId}`.
    2. При попадании — десериализация (BigInt, Date) и возврат.
    3. При промахе — `prisma.user.findUnique`, запись в кэш, возврат.
  - **Инвалидация**: при любом обновлении пользователя удалять `user:${userId}`:
    - в ветке `findOrCreateUser` (update существующего user);
    - при создании нового user кэш не нужен (ещё не было запросов по нему).
- getProfileFromAccessToken по сути вызывает тот же getProfileById после верификации JWT — кэш уже покрывает этот путь.

---

## 4. Интеграция в WorkspaceService и Plan

- **План по id**: в [workspace.service.ts](crm-tg-app-backend/src/workspace/workspace.service.ts) при необходимости плана (create):
  - Сначала попытка получить план из кэша `plan:${id}`.
  - При промахе — `prisma.plan.findUnique`, запись в кэш (TTL 1 ч), использование.
- Альтернатива: общий сервис/хелпер `getPlanById(id)` с кэшем, использовать его в WorkspaceService и при необходимости в других местах.

---

## 5. Структура модулей и зависимостей

- **CacheModule** (новый): провайдер CacheService (ioredis), опционально экспорт готового кэш-менеджера. Подключение к Valkey по `VALKEY_URL`, обработка ошибок (при недоступности Valkey — fallback на запрос к Postgres без кэша или логирование и продолжение без кэша).
- **AuthModule**: импорт CacheModule, внедрение CacheService в AuthService.
- **WorkspaceModule** (или общий модуль): использование кэша для планов; при необходимости вынести получение плана в отдельный PlanService с кэшем.

---

## 6. Сериализация User для кэша

- При записи в Valkey: объект пользователя преобразовать в JSON-совместимый вид (например, `telegramId` → string, `planExpiresAt`/`createdAt`/`updatedAt` → ISO string или null).
- При чтении: парсить JSON и восстанавливать типы (BigInt для telegramId, Date для полей дат), чтобы тип совпадал с тем, что возвращает Prisma (JwtStrategy и остальной код ожидают user с такими полями).

---

## 7. Конфигурация и окружение

- TTL для user и plan вынести в конфиг (env или константы): например `USER_CACHE_TTL_SEC=300`, `PLAN_CACHE_TTL_SEC=3600`.
- Если `VALKEY_URL` не задан (локальный запуск без Docker): не поднимать подключение к Valkey, все запросы идут только в Postgres (graceful degradation).

---

## 8. Порядок реализации

1. Добавить зависимость **ioredis**, при желании — **@nestjs/cache-manager** и store для Redis/Valkey.
2. Реализовать **CacheModule** и **CacheService** (connect, get, set, del, сериализация/десериализация с учётом BigInt/Date).
3. В **AuthService**: кэш в getProfileById, инвалидация при update пользователя в findOrCreateUser.
4. Кэш для **Plan** (в WorkspaceService или отдельном PlanService): getPlanById с кэшем, использование при создании workspace.
5. Подключить CacheModule в AppModule и в модули, использующие кэш (Auth, при необходимости Workspace/Plan).
6. Добавить в README или env.example переменные: `VALKEY_URL`, `USER_CACHE_TTL_SEC`, `PLAN_CACHE_TTL_SEC`.

После этого большинство запросов с JWT будут брать профиль из Valkey, а обращения к планам при создании workspace — тоже из кэша, что снизит число запросов к Postgres.