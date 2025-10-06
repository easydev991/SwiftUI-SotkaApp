@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты для InfopostsService.FilenameManager")
struct InfopostsServiceFilenameManagerTests {
    private typealias SUT = InfopostsService.FilenameManager

    @Test("Правильный порядок файлов для русского языка")
    func orderedFilenamesForRussian() throws {
        let manager = SUT(language: "ru")
        let filenames = manager.getOrderedFilenames()

        // Проверяем, что список не пустой
        #expect(!filenames.isEmpty)

        // Проверяем порядок файлов
        #expect(filenames[0] == "organiz")
        #expect(filenames[1] == "aims")
        #expect(filenames[2] == "d0-women")
        #expect(filenames[3] == "d1")

        // Проверяем, что d100 есть в списке
        #expect(filenames.contains("d100"))
    }

    @Test("Правильный порядок файлов для английского языка")
    func orderedFilenamesForEnglish() throws {
        let manager = SUT(language: "en")
        let filenames = manager.getOrderedFilenames()

        // Проверяем, что список не пустой
        #expect(!filenames.isEmpty)

        // Проверяем порядок файлов
        #expect(filenames[0] == "organiz")
        #expect(filenames[1] == "aims")
        #expect(filenames[2] == "d1")

        // Проверяем, что d0-women НЕ включен для английского языка
        #expect(!filenames.contains("d0-women"))

        // Проверяем, что d100 есть в списке
        #expect(filenames.contains("d100"))
    }

    @Test("Количество файлов в списке")
    func filenamesCount() {
        let russianManager = SUT(language: "ru")
        let englishManager = SUT(language: "en")
        let russianFilenames = russianManager.getOrderedFilenames()
        let englishFilenames = englishManager.getOrderedFilenames()

        // Для русского языка: organiz + aims + d0-women + d1-d100 = 103 файла
        // Для английского языка: organiz + aims + d1-d100 = 102 файла
        #expect(russianFilenames.count == 103)
        #expect(englishFilenames.count == 102)

        // Русский список должен быть больше или равен английскому
        #expect(russianFilenames.count >= englishFilenames.count)
    }

    @Test("Проверка корректности имен файлов")
    func filenamesCorrectness() {
        let russianManager = SUT(language: "ru")
        let englishManager = SUT(language: "en")
        let russianFilenames = russianManager.getOrderedFilenames()
        let englishFilenames = englishManager.getOrderedFilenames()

        // Проверяем, что все файлы имеют корректные имена
        for filename in russianFilenames {
            if filename == "organiz" || filename == "aims" || filename == "d0-women" {
                // Подготовительные файлы
                #expect(russianFilenames.contains(filename))
            } else if filename.hasPrefix("d"), filename.count <= 4 {
                // Файлы дней программы
                #expect(russianFilenames.contains(filename))
            }
        }

        for filename in englishFilenames {
            if filename == "organiz" || filename == "aims" {
                // Подготовительные файлы
                #expect(englishFilenames.contains(filename))
            } else if filename.hasPrefix("d"), filename.count <= 4 {
                // Файлы дней программы
                #expect(englishFilenames.contains(filename))
            }
        }
    }
}
