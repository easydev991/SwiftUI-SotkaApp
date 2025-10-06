import Foundation

/// Модель данных инфопоста
struct Infopost: Identifiable, Equatable {
    /// Уникальный идентификатор инфопоста (например, "d1", "d50", "aims", "organiz")
    let id: String

    /// Заголовок инфопоста
    let title: String

    /// HTML содержимое инфопоста
    let content: String

    /// Секция, к которой относится инфопост
    let section: InfopostSection

    /// Номер дня для постов с номерами дней (nil для специальных постов)
    let dayNumber: Int?

    /// Язык инфопоста
    let language: String

    /// Дата последнего изменения файла
    let lastModified: Date

    /// Пол, для которого предназначен инфопост (nil для универсальных постов)
    let gender: Gender?

    /// Доступность функции добавления в избранное (`false` для поста "about")
    let isFavoriteAvailable: Bool

    /// Имя файла с суффиксом языка для загрузки из бандла (например, "d1_ru")
    var filenameWithLanguage: String {
        "\(id)_\(language)"
    }

    /// Получает YouTube видео для этого инфопоста
    /// - Parameter youtubeService: Сервис для работы с YouTube видео
    /// - Returns: YouTube видео или nil, если не найдено
    func youtubeVideo(using youtubeService: YouTubeVideoService) -> YouTubeVideo? {
        guard let dayNumber, dayNumber > 0 else { return nil }
        return try? youtubeService.getVideo(for: dayNumber)
    }

    /// Проверяет, есть ли YouTube видео для этого инфопоста
    /// - Parameter youtubeService: Сервис для работы с YouTube видео
    /// - Returns: true, если видео существует
    func hasYouTubeVideo(using youtubeService: YouTubeVideoService) -> Bool {
        youtubeVideo(using: youtubeService) != nil
    }

    init(
        id: String,
        title: String,
        content: String,
        section: InfopostSection,
        dayNumber: Int? = nil,
        language: String,
        lastModified: Date = Date(),
        gender: Gender? = nil,
        isFavoriteAvailable: Bool = true
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.section = section
        self.dayNumber = dayNumber
        self.language = language
        self.lastModified = lastModified
        self.gender = gender
        self.isFavoriteAvailable = isFavoriteAvailable
    }

    /// Создает инфопост из имени файла
    static func from(
        filename: String,
        title: String,
        content: String,
        language: String,
        lastModified: Date = Date()
    ) -> Infopost {
        let section = InfopostSection.section(for: filename)

        // Определяем номер дня для файлов вида "d1", "d2", etc.
        let dayNumber: Int?
        if filename.hasPrefix("d") {
            let dayString = String(filename.dropFirst())
            dayNumber = Int(dayString)
        } else {
            dayNumber = nil
        }

        // Определяем пол для специальных файлов (например, "d0-women")
        let gender: Gender? = filename.contains("-women") ? .female : nil
        let isFavoriteAvailable = !filename.contains("about")

        return Infopost(
            id: filename,
            title: title,
            content: content,
            section: section,
            dayNumber: dayNumber,
            language: language,
            lastModified: lastModified,
            gender: gender,
            isFavoriteAvailable: isFavoriteAvailable
        )
    }
}
