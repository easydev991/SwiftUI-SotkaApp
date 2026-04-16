import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты модели ReviewMilestone")
struct ReviewMilestoneTests {
    @Test("Milestone 1 поддерживается")
    func milestoneFirstSupported() throws {
        let milestone = ReviewMilestone(rawValue: 1)
        let unwrapped = try #require(milestone)
        #expect(unwrapped == .first)
    }

    @Test("Milestone 10 поддерживается")
    func milestoneTenthSupported() throws {
        let milestone = ReviewMilestone(rawValue: 10)
        let unwrapped = try #require(milestone)
        #expect(unwrapped == .tenth)
    }

    @Test("Milestone 30 поддерживается")
    func milestoneThirtiethSupported() throws {
        let milestone = ReviewMilestone(rawValue: 30)
        let unwrapped = try #require(milestone)
        #expect(unwrapped == .thirtieth)
    }

    @Test("Значения не из milestone не поддерживаются", arguments: [0, 2, 5, 9, 11, 29, 31, 50, 100])
    func nonMilestoneValuesNotSupported(rawValue: Int) {
        let milestone = ReviewMilestone(rawValue: rawValue)
        #expect(milestone == nil)
    }

    @Test("Все milestone доступны через allCases")
    func allCasesContainsAllMilestones() {
        #expect(ReviewMilestone.allCases == [.first, .tenth, .thirtieth])
    }

    @Test("Milestone возвращает корректное rawValue")
    func milestoneRawValues() {
        #expect(ReviewMilestone.first.rawValue == 1)
        #expect(ReviewMilestone.tenth.rawValue == 10)
        #expect(ReviewMilestone.thirtieth.rawValue == 30)
    }

    @Test("isMilestoneWorkoutCount возвращает false для count=0")
    func isMilestoneWorkoutCountReturnsFalseForZero() {
        #expect(!ReviewMilestone.isMilestoneWorkoutCount(0))
    }

    @Test("isMilestoneWorkoutCount возвращает true только для milestone значений")
    func isMilestoneWorkoutCountReturnsTrueOnlyForMilestones() {
        #expect(ReviewMilestone.isMilestoneWorkoutCount(1))
        #expect(ReviewMilestone.isMilestoneWorkoutCount(10))
        #expect(ReviewMilestone.isMilestoneWorkoutCount(30))
        #expect(!ReviewMilestone.isMilestoneWorkoutCount(5))
        #expect(!ReviewMilestone.isMilestoneWorkoutCount(15))
        #expect(!ReviewMilestone.isMilestoneWorkoutCount(100))
    }

    @Test("milestone(forCompletedWorkoutCount:) возвращает milestone для поддерживаемого значения")
    func milestoneForCompletedWorkoutCountReturnsMilestone() throws {
        let milestone = ReviewMilestone.milestone(forCompletedWorkoutCount: 10)
        let unwrapped = try #require(milestone)
        #expect(unwrapped == .tenth)
    }

    @Test("milestone(forCompletedWorkoutCount:) возвращает .first для count=7")
    func milestoneForCount7ReturnsFirst() {
        let milestone = ReviewMilestone.milestone(forCompletedWorkoutCount: 7)
        #expect(milestone == .first)
    }

    @Test("milestone(forCompletedWorkoutCount:) возвращает ближайший milestone при count > milestone")
    func milestone10EligibleWhenCount11() {
        let milestone = ReviewMilestone.milestone(forCompletedWorkoutCount: 11)
        #expect(milestone == .tenth)
    }

    @Test("milestone(forCompletedWorkoutCount:) возвращает ближайший не-attempted milestone")
    func milestone30EligibleWhenCount35() {
        let milestone = ReviewMilestone.milestone(forCompletedWorkoutCount: 35)
        #expect(milestone == .thirtieth)
    }

    @Test("milestone(forCompletedWorkoutCount:) возвращает nil для count < first milestone")
    func milestoneForCountLessThanFirstReturnsNil() {
        #expect(ReviewMilestone.milestone(forCompletedWorkoutCount: 0) == nil)
    }
}
