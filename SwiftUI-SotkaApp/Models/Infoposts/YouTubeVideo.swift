import Foundation

/// Модель YouTube видео для инфопостов
struct YouTubeVideo: Identifiable, Equatable {
    /// Уникальный идентификатор (номер дня)
    let id: Int

    /// Номер дня программы
    let dayNumber: Int

    /// URL для встраивания видео
    let url: String

    /// Заголовок видео
    let title: String

    init(dayNumber: Int, url: String, title: String = "#моястодневка от Антона Кучумова") {
        self.id = dayNumber
        self.dayNumber = dayNumber
        self.url = url
        self.title = title
    }
}
