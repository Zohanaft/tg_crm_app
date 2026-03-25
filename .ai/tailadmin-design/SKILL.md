---
name: tailadmin-design
description: >-
  Applies TailAdmin-like dashboard styling in crm-tg-app using only Tailwind and
  Nuxt/UI. Use when changing or adding UI so it matches the reference design:
  light theme, sidebar layout, card style, consistent spacing and colors. Never
  change the site logo.
---

# Дизайн по референсу TailAdmin (crm-tg-app)

## Когда применять

При любых правках или добавлении UI во фронтенде **crm-tg-app**: приводить стили к референсу (приложенное изображение TailAdmin). Использовать **только** Tailwind и Nuxt/UI; не добавлять свои библиотеки и не придумывать новые визуальные элементы — работать с тем, что уже есть в проекте.

## Запрет: логотип

**Не менять логотип сайта.** Текущий логотип (`/images/logo.svg`, вывод через `<img>` в шапке) оставлять как есть: не заменять файл, не менять разметку/alt, не подставлять другой бренд или текст (например «TailAdmin»).

## Стили по референсу

- **Фон основной области:** светлый серый `bg-gray-50` (или Nuxt UI `bg-gray-50` / `#F8FAFC`). Тёмная тема: `dark:bg-gray-900`.
- **Карточки и шапка/сайдбар:** белый фон `bg-white`, тёмная тема `dark:bg-gray-900`. Карточки: скругление `rounded-lg` или `rounded-xl`, тень `shadow` / `shadow-sm`.
- **Акцент:** синий в духе `blue-500` / `#3B82F6` для активных пунктов меню, кнопок primary, прогресса. Зелёный для положительных изменений (`text-green-600`), красный для отрицательных (`text-red-600`).
- **Текст:** заголовки — `text-gray-900 dark:text-white`, основной текст — `text-gray-700 dark:text-gray-200`, вторичный — `text-gray-500` / `text-muted-foreground`.
- **Отступы:** единообразно `p-4`, `p-6`, `gap-4`, `gap-6`, `space-y-4`; контейнер контента — `container mx-auto` с горизонтальным паддингом.

Подробные токены (цвета, тени, отступы) — в [reference.md](reference.md).

## Компоненты Nuxt/UI

Использовать существующие компоненты, не изобретать свои:

- Карточки: `UCard` (header + default slot), без лишних обёрток.
- Кнопки: `UButton` (variant: `solid`, `outline`, `ghost`; color: `primary`, `gray`).
- Поля: `UInput`, `UForm`, `UFormField` с label/placeholder из i18n.
- Навигация: ссылки и при необходимости `UDropdownMenu`; активное состояние — `bg-blue-50 dark:bg-blue-900/20` и граница/текст синим.
- Иконки: через Nuxt UI / Lucide (например `i-lucide-*`), без замены на другие наборы.
- Аватар: `UAvatar`; уведомления/бейджи — стандартные варианты `UBadge` или компоненты Nuxt UI.

## Шрифты: анализ и рекомендации

В референсе — чёткий sans-serif, хорошая читаемость, нейтральный тон. Сейчас в проекте по умолчанию системный стек (`system-ui, -apple-system, ...`).

**Рекомендации по смене шрифта (опционально):**

1. **Inter** — универсальный UI-шрифт, переменный, отлично сочетается с Nuxt UI и Tailwind. Предпочтительный вариант для дашборда.
2. **Plus Jakarta Sans** — чуть более «дружелюбный», подходит для дашбордов и админок.
3. **Figtree** или **Manrope** — современные геометрические sans-serif, при необходимости более выразительный вид.

**Как подключить (например Inter):** в `app.head.link` в `nuxt.config.ts` добавить Google Fonts, в `app.config.ts` (или в глобальных стилях через Nuxt UI theme) задать `fontFamily.sans: ['Inter', 'sans-serif']`. Не менять шрифт в логотипе — только системный текст интерфейса.

## Checklist при правках UI

- [ ] Стили только Tailwind + Nuxt/UI, без новых зависимостей.
- [ ] Логотип не тронут.
- [ ] Фоны и карточки соответствуют референсу (белый/серый, скругления, тень).
- [ ] Цвета акцента и текста из палитры выше.
- [ ] Отступы и сетка единообразны (p-4/p-6, gap-4/gap-6).
