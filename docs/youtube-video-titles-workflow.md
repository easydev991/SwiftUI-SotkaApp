# YouTube Video Titles Workflow

## Для чего это нужно

Заголовки YouTube-видео сохраняются локально в JSON, чтобы показывать их в инфопостах без runtime-запросов к YouTube.

Источники ссылок:

- `SwiftUI-SotkaApp/SupportingFiles/book/**/*.html`
- `SwiftUI-SotkaApp/SupportingFiles/youtube_list.txt`

Артефакт:

- `SwiftUI-SotkaApp/SupportingFiles/youtube_video_titles.json`

Видео обычно не меняются, поэтому файл обновляется редко и только при необходимости.

## Как настроено

- Скрипт `scripts/get_video_titles.py` собирает уникальные `videoId` из HTML и `youtube_list.txt`.
- По YouTube Data API запрашиваются заголовки.
- Результат сохраняется в `youtube_video_titles.json` и используется приложением офлайн.

## Как запустить обновление

1. Локально сохранить ключ в `.env.youtube.local`:

```dotenv
YOUTUBE_API_KEY=your_key_here
```

2. Выполнить:

```bash
set -a
source .env.youtube.local
set +a
make get_video_titles
```

Опционально проверить тесты скрипта:

```bash
make test_get_video_titles_script
```

## Что проверить после обновления

1. Обновился файл `SwiftUI-SotkaApp/SupportingFiles/youtube_video_titles.json`.
2. В JSON есть поля `version`, `generatedAt`, `items`.
3. В инфопостах:

- для day-видео показывается найденный title; если его нет — fallback `#моястодневка от Антона Кучумова`;
- для embedded-видео title показывается над кнопкой, если найден.

## Если что-то пошло не так

- `YOUTUBE_API_KEY` не установлен: заново экспортировать через `.env.youtube.local`.
- Квота API исчерпана: повторить запуск позже.
- Часть видео недоступна: такие записи могут остаться без title, кнопка перехода при этом работает.
