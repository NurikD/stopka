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

## Релиз

Приложение само находит новые релизы на GitHub (`NurikD/stopka`), предлагает
обновиться на главном экране и ставит APK поверх — прогресс сохраняется.

1. Поднять версию в `stopka_flutter/pubspec.yaml`: и версию, и номер сборки
   после `+` (`0.1.1+2` → `0.2.0+3`). Без роста номера Android не поставит
   обновление поверх.
2. Собрать (ключ подписи — в `android/key.properties`, в git его нет):
   ```
   cd stopka_flutter
   flutter build apk --release --split-per-abi --dart-define=STOPKA_DIRECT_GEMINI=true
   ```
3. Закоммитить, поставить тег `v0.2.0`, запушить ветку и тег.
4. На GitHub: Releases → New release → тег `v0.2.0`, описание, приложить
   `app-arm64-v8a-release.apk` и `app-armeabi-v7a-release.apk` из
   `stopka_flutter/build/app/outputs/flutter-apk/` (или переименованные в
   `stopka-0.2.0-arm64.apk` / `stopka-0.2.0-armv7.apk` — в имени должно
   остаться `arm64` / `armv7`). Черновики (draft) приложение не видит,
   pre-release — видит.

Ключ подписи (`C:\Users\user\.stopka-keys\`) хранить в резервной копии: без
него обновление поверх установленного приложения невозможно.

Иконка рисуется из логотипа скриптом `python tool/make_icon.py` (из
`stopka_flutter/`, нужен Pillow).

## Разработка

```
cd stopka_flutter
flutter analyze
flutter test
```

Приоритетная платформа — Android; iOS не должен ломаться, но не тестируется
в первую очередь.
