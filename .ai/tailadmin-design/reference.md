# Референс TailAdmin — токены для Tailwind + Nuxt/UI

Использовать при применении скилла [SKILL.md](SKILL.md).

## Цвета

| Назначение           | Light (Tailwind)              | Dark                    |
|----------------------|-------------------------------|--------------------------|
| Основной фон         | `bg-gray-50` (#F8FAFC)        | `dark:bg-gray-900`       |
| Карточки, шапка      | `bg-white`                    | `dark:bg-gray-900`       |
| Границы              | `border-gray-200`             | `dark:border-gray-800`   |
| Текст заголовков     | `text-gray-900`               | `dark:text-white`       |
| Текст основной       | `text-gray-700`               | `dark:text-gray-200`    |
| Текст вторичный      | `text-gray-500`               | `dark:text-gray-400`     |
| Плейсхолдер          | `text-gray-400`               | —                       |
| Акцент / primary     | `blue-500` (#3B82F6)          | `blue-400`               |
| Активное меню        | `bg-blue-50`                  | `dark:bg-blue-900/20`    |
| Успех / рост         | `text-green-600` (#22C55E)    | —                       |
| Ошибка / падение     | `text-red-600` (#EF4444)      | —                       |
| Бейдж «NEW»          | `bg-green-100 text-green-800` | —                       |

## Отступы и сетка

- Карточки: `p-4` или `p-6`.
- Между карточками/блоками: `gap-4`, `gap-6`, `space-y-4`, `space-y-6`.
- Контейнер: `container mx-auto px-4` (или `px-6`).
- Шапка: высота `h-14`, внутренние отступы `px-4`.
- Сайдбар (если будет): ширина ~`w-64` (250–280px).

## Типографика

- Заголовок страницы: `text-3xl font-bold` или `text-2xl font-bold`.
- Заголовок карточки/секции: `text-xl font-semibold` или `text-lg font-medium`.
- Описание: `text-sm text-gray-500` / `text-muted-foreground`.
- Крупные числа (метрики): `text-3xl font-bold` или `text-4xl font-bold`.
- Мелкий текст: `text-xs` или `text-sm`.

## Компоненты

- Карточка: `UCard`, обёртка с `rounded-lg shadow` (или дефолтные стили UCard).
- Кнопки: размеры `sm`/`md`, без лишних кастомных классов.
- Поле поиска: `UInput` с иконкой слева, `rounded-lg`, placeholder серый.
- Пункт навигации активный: левая граница или фон `bg-blue-50`, текст жирнее.

## Шрифты (рекомендации)

Подключение одного шрифта для всего UI (кроме логотипа):

- **Inter:**  
  `link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet"`  
  В теме: `fontFamily.sans: ['Inter', 'sans-serif']`.

- **Plus Jakarta Sans:**  
  `family=Plus+Jakarta+Sans:wght@400;500;600;700`  
  В теме: `fontFamily.sans: ['Plus Jakarta Sans', 'sans-serif']`.

Логотип не переопределять — он остаётся в текущем виде (изображение/шрифт в самом logo.svg).
