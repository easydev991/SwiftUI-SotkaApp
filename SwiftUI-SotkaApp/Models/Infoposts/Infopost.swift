import Foundation

/// Модель данных инфопоста
struct Infopost: Identifiable, Equatable {
    /// Уникальный идентификатор инфопоста (например, "d1", "d50", "about", "aims", "organiz")
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

    /// Имя файла с суффиксом языка для загрузки из бандла (например, "d1_ru")
    var filenameWithLanguage: String {
        "\(id)_\(language)"
    }

    init(
        id: String,
        title: String,
        content: String,
        section: InfopostSection,
        dayNumber: Int? = nil,
        language: String,
        lastModified: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.section = section
        self.dayNumber = dayNumber
        self.language = language
        self.lastModified = lastModified
    }

    /// Создает инфопост из имени файла
    static func from(filename: String, title: String, content: String, language: String, lastModified: Date = Date()) -> Infopost {
        let section = InfopostSection.section(for: filename)
        // Определяем номер дня для файлов вида "d1", "d2", etc.
        let dayNumber: Int?
        if filename.hasPrefix("d") {
            let dayString = String(filename.dropFirst())
            dayNumber = Int(dayString)
        } else {
            dayNumber = nil
        }
        return Infopost(
            id: filename,
            title: title,
            content: content,
            section: section,
            dayNumber: dayNumber,
            language: language,
            lastModified: lastModified
        )
    }
}
