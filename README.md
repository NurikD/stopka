# Стопка

Приложение-спутник для тех, кто учит английский на очных курсах. Диктант
слов до нуля ошибок, интервальное повторение (FSRS), практика в
предложениях — весь основной цикл работает офлайн; ИИ (Gemini) нужен
только для распознавания фото со словами и обогащения карточек.

## Стек

- Flutter (stable) / Dart 3, Material 3
- Riverpod — состояние и DI, `go_router` — навигация
- `drift` (SQLite) — локальная база, миграции по версиям схемы
- `fsrs` — интервальное повторение
- Gemini API (`dio`) — распознавание фото и обогащение карточек, ключ хранится в `flutter_secure_storage`
- `flutter_tts` — офлайн-озвучка

## Структура

Монорепо: `stopka_flutter/` — приложение, `stopka_server/` и `stopka_client/` —
сервер на Serverpod и сгенерированный клиент (появляются по этапам B0–B6).

## Запуск приложения

```
cd stopka_flutter
flutter pub get
flutter run
```

Ключ Gemini вводится в приложении (Настройки → Gemini API), не в коде и не
в git. Получить ключ: [ai.google.dev](https://ai.google.dev/gemini-api/docs/api-key).

## Разработка

```
cd stopka_flutter
flutter analyze
flutter test
```

Приоритетная платформа — Android; iOS не должен ломаться, но не тестируется
в первую очередь.
