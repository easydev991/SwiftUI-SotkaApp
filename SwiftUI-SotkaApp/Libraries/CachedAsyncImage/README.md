# CachedAsyncImage

SwiftUI-вьюха для загрузки картинок с кэшированием. Отдаёт изображение из кэша синхронно при перерисовке ячеек — без фазы загрузки и мерцания (в отличие от `AsyncImage` + `URLCache`).

## Возможности

- Кэш `NSCache` (синглтон `ImageCache.shared`): до 100 картинок общим весом до 100 МБ
- Два инициализатора: `url: URL?` и `stringURL: String?`
- Настраиваемые `content` (готовый `UIImage`) и `placeholder` (по умолчанию `ProgressView()`)
- Анимация перехода между состояниями, по умолчанию `.scale.combined(with: .opacity)`
- Ошибки загрузки логируются через `OSLog`, при ошибке показывается `placeholder`

## Использование

```swift
CachedAsyncImage(url: url) { uiImage in
    Image(uiImage: uiImage)
        .resizable()
        .scaledToFill()
} placeholder: {
    ProgressView()
}
```

Готовую обёртку с размерами и скруглением можно взять из `SWDesignSystem`: `CachedImage` (mode: `CachedImage.Mode`).
