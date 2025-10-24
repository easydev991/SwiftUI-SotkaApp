@testable import SwiftUI_SotkaApp
import Testing

extension AllInfopostsTests {
    struct InfopostAvailabilityManagerTests {
        @Test
        func preparationPostsAlwaysAvailable() {
            let manager = InfopostAvailabilityManager(currentDay: 1, maxReadInfoPostDay: 0)
            let preparationPost = createInfopost(section: .preparation, dayNumber: nil)

            #expect(manager.isInfopostAvailable(preparationPost))
        }

        @Test
        func currentDayLimitsAvailability() {
            let manager = InfopostAvailabilityManager(currentDay: 10, maxReadInfoPostDay: 0)
            let day5Post = createInfopost(section: .base, dayNumber: 5)
            let day15Post = createInfopost(section: .base, dayNumber: 15)

            #expect(manager.isInfopostAvailable(day5Post))
            #expect(!manager.isInfopostAvailable(day15Post))
        }

        @Test
        func maxReadInfoPostDayOverridesCurrentDay() {
            let manager = InfopostAvailabilityManager(currentDay: 5, maxReadInfoPostDay: 20)
            let day15Post = createInfopost(section: .base, dayNumber: 15)
            let day25Post = createInfopost(section: .advanced, dayNumber: 25)

            #expect(manager.isInfopostAvailable(day15Post))
            #expect(!manager.isInfopostAvailable(day25Post))
        }

        @Test
        func maxAvailableDayCalculation() {
            let manager1 = InfopostAvailabilityManager(currentDay: 10, maxReadInfoPostDay: 5)
            #expect(manager1.maxAvailableDay == 10)

            let manager2 = InfopostAvailabilityManager(currentDay: 5, maxReadInfoPostDay: 15)
            #expect(manager2.maxAvailableDay == 15)
        }

        @Test
        func infopostWithoutDayNumber() {
            let manager = InfopostAvailabilityManager(currentDay: 10, maxReadInfoPostDay: 0)
            let postWithoutDay = createInfopost(section: .preparation, dayNumber: nil)

            #expect(manager.isInfopostAvailable(postWithoutDay))
        }

        @Test
        func filterAvailablePosts() {
            let manager = InfopostAvailabilityManager(currentDay: 10, maxReadInfoPostDay: 0)
            let posts = [
                createInfopost(section: .preparation, dayNumber: nil),
                createInfopost(section: .base, dayNumber: 5),
                createInfopost(section: .base, dayNumber: 15),
                createInfopost(section: .advanced, dayNumber: 25)
            ]

            let availablePosts = manager.filterAvailablePosts(posts)
            #expect(availablePosts.count == 2)
        }

        @Test
        func getAvailablePostsBySection() throws {
            let manager = InfopostAvailabilityManager(currentDay: 10, maxReadInfoPostDay: 0)
            let posts = [
                createInfopost(section: .preparation, dayNumber: nil),
                createInfopost(section: .base, dayNumber: 5),
                createInfopost(section: .base, dayNumber: 15),
                createInfopost(section: .advanced, dayNumber: 25)
            ]

            let postsBySection = manager.getAvailablePostsBySection(posts)
            let preparationPosts = try #require(postsBySection[.preparation])
            let basePosts = try #require(postsBySection[.base])

            #expect(preparationPosts.count == 1)
            #expect(basePosts.count == 1)
            #expect(postsBySection[.advanced] == nil, "Секция не добавляется в словарь, если нет доступных постов")
        }

        @Test
        func edgeCaseCurrentDayZero() {
            let manager = InfopostAvailabilityManager(currentDay: 0, maxReadInfoPostDay: 0)
            let preparationPost = createInfopost(section: .preparation, dayNumber: nil)
            let day1Post = createInfopost(section: .base, dayNumber: 1)

            #expect(manager.isInfopostAvailable(preparationPost))
            #expect(!manager.isInfopostAvailable(day1Post))
        }

        @Test
        func edgeCaseMaxReadInfoPostDayNegative() {
            let manager = InfopostAvailabilityManager(currentDay: 5, maxReadInfoPostDay: -1)
            let day3Post = createInfopost(section: .base, dayNumber: 3)
            let day6Post = createInfopost(section: .base, dayNumber: 6)

            #expect(manager.isInfopostAvailable(day3Post))
            #expect(!manager.isInfopostAvailable(day6Post))
        }

        // Вспомогательная функция для создания тестовых инфопостов
        private func createInfopost(section: InfopostSection, dayNumber: Int?) -> Infopost {
            Infopost(
                id: "test_\(section.rawValue)_\(dayNumber ?? 0)",
                title: "Test Post",
                content: "<p>Test content</p>",
                section: section,
                dayNumber: dayNumber,
                language: "ru"
            )
        }
    }
}
