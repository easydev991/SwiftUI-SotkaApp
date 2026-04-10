import Foundation
@testable import SwiftUI_SotkaApp
import Testing

struct AnalyticsServiceTests {
    @Test("AnalyticsService fan-out: отправляет событие всем провайдерам в правильном порядке")
    func fanOutAndOrder() {
        let recorder = AnalyticsRecorder()
        let service = AnalyticsService(
            providers: [
                AnalyticsProviderSpy(id: "A", recorder: recorder),
                AnalyticsProviderSpy(id: "B", recorder: recorder)
            ]
        )

        service.log(.screenView(screen: .home))
        service.log(.userAction(action: .saveWorkout))
        service.log(.appError(kind: .loginFailed, error: AnalyticsTestError.sample))

        #expect(
            recorder.entries == [
                "A:screen_home",
                "B:screen_home",
                "A:user_save_workout",
                "B:user_save_workout",
                "A:error_login_failed",
                "B:error_login_failed"
            ]
        )
    }

    @Test("AnalyticsService с пустым списком провайдеров не падает")
    func emptyProvidersList() {
        let service = AnalyticsService(providers: [])
        service.log(.screenView(screen: .root))
        service.log(.userAction(action: .login))
        service.log(.appError(kind: .passwordResetFailed, error: AnalyticsTestError.sample))
        #expect(true)
    }

    @Test("UserAction.name возвращает корректные значения для ключевых кейсов")
    func userActionNameMapping() {
        let values: [(AnalyticsEvent.UserAction, String)] = [
            (.login, "login"),
            (.tapEdit(entityId: "1"), "tap_edit"),
            (.selectTheme(theme: "dark"), "select_theme"),
            (.selectActivityType(type: "workout", dayNumber: "10"), "select_activity_type"),
            (.deleteProgress(dayNumber: "49"), "delete_progress"),
            (.addProgressPhoto(source: "camera"), "add_progress_photo"),
            (.deleteProgressPhoto(photoType: 2), "delete_progress_photo"),
            (.selectInfopostFontSize(size: "large", entityId: "post_1"), "select_infopost_font_size"),
            (.selectExerciseIcon(iconName: "3", exerciseId: "ex_1"), "select_exercise_icon"),
            (.confirmResetProgram, "confirm_reset_program")
        ]

        for (action, expectedName) in values {
            #expect(action.name == expectedName)
        }
    }

    @Test("AppScreen rawValue совпадает с контрактом аналитики")
    func appScreenRawValues() {
        #expect(AnalyticsEvent.AppScreen.root.rawValue == "root")
        #expect(AnalyticsEvent.AppScreen.login.rawValue == "login")
        #expect(AnalyticsEvent.AppScreen.infopostsList.rawValue == "infoposts_list")
        #expect(AnalyticsEvent.AppScreen.infopostDetail.rawValue == "infopost_detail")
        #expect(AnalyticsEvent.AppScreen.workoutPreview.rawValue == "workout_preview")
        #expect(AnalyticsEvent.AppScreen.workoutExerciseEditor.rawValue == "workout_exercise_editor")
        #expect(AnalyticsEvent.AppScreen.workoutTimer.rawValue == "workout_timer")
        #expect(AnalyticsEvent.AppScreen.editProfile.rawValue == "edit_profile")
        #expect(AnalyticsEvent.AppScreen.changePassword.rawValue == "change_password")
        #expect(AnalyticsEvent.AppScreen.progressStats.rawValue == "progress_stats")
        #expect(AnalyticsEvent.AppScreen.editProgress.rawValue == "edit_progress")
        #expect(AnalyticsEvent.AppScreen.customExercises.rawValue == "custom_exercises")
        #expect(AnalyticsEvent.AppScreen.customExercise.rawValue == "custom_exercise")
        #expect(AnalyticsEvent.AppScreen.editCustomExercise.rawValue == "edit_custom_exercise")
        #expect(AnalyticsEvent.AppScreen.themeIcon.rawValue == "theme_icon")
        #expect(AnalyticsEvent.AppScreen.syncJournal.rawValue == "sync_journal")
        #expect(AnalyticsEvent.AppScreen.syncJournalEntry.rawValue == "sync_journal_entry")
        #expect(AnalyticsEvent.AppScreen.syncStartDate.rawValue == "sync_start_date")
        #expect(AnalyticsEvent.AppScreen.syncStartDateHelp.rawValue == "sync_start_date_help")
    }

    @Test("AppErrorKind rawValue совпадает с контрактом аналитики")
    func appErrorKindRawValues() {
        #expect(AnalyticsEvent.AppErrorKind.loginFailed.rawValue == "login_failed")
        #expect(AnalyticsEvent.AppErrorKind.passwordResetFailed.rawValue == "password_reset_failed")
        #expect(AnalyticsEvent.AppErrorKind.profileSaveFailed.rawValue == "profile_save_failed")
        #expect(AnalyticsEvent.AppErrorKind.changePasswordFailed.rawValue == "change_password_failed")
        #expect(AnalyticsEvent.AppErrorKind.progressSaveFailed.rawValue == "progress_save_failed")
        #expect(AnalyticsEvent.AppErrorKind.progressDeleteFailed.rawValue == "progress_delete_failed")
        #expect(AnalyticsEvent.AppErrorKind.customExerciseSyncFailed.rawValue == "custom_exercise_sync_failed")
        #expect(AnalyticsEvent.AppErrorKind.setIconFailed.rawValue == "set_icon_failed")
        #expect(AnalyticsEvent.AppErrorKind.infopostFavoriteFailed.rawValue == "infopost_favorite_failed")
        #expect(AnalyticsEvent.AppErrorKind.syncStartDateFailed.rawValue == "sync_start_date_failed")
        #expect(AnalyticsEvent.AppErrorKind.syncJournalDeleteFailed.rawValue == "sync_journal_delete_failed")
        #expect(AnalyticsEvent.AppErrorKind.workoutSaveFailed.rawValue == "workout_save_failed")
        #expect(AnalyticsEvent.AppErrorKind.workoutStartFailed.rawValue == "workout_start_failed")
        #expect(AnalyticsEvent.AppErrorKind.customExerciseSaveFailed.rawValue == "custom_exercise_save_failed")
        #expect(AnalyticsEvent.AppErrorKind.customExerciseDeleteFailed.rawValue == "custom_exercise_delete_failed")
    }

    @Test("NoopAnalyticsProvider принимает события без побочных эффектов")
    func noopProviderAcceptsEvents() {
        let provider = NoopAnalyticsProvider()
        provider.log(event: .screenView(screen: .home))
        provider.log(event: .userAction(action: .logout))
        provider.log(event: .appError(kind: .setIconFailed, error: AnalyticsTestError.sample))
        #expect(true)
    }
}

private final class AnalyticsRecorder {
    var entries: [String] = []
}

private final class AnalyticsProviderSpy: AnalyticsProvider {
    private let id: String
    private let recorder: AnalyticsRecorder

    init(id: String, recorder: AnalyticsRecorder) {
        self.id = id
        self.recorder = recorder
    }

    func log(event: AnalyticsEvent) {
        let marker = switch event {
        case let .screenView(screen):
            "screen_\(screen.rawValue)"
        case let .userAction(action):
            "user_\(action.name)"
        case let .appError(kind, _):
            "error_\(kind.rawValue)"
        }
        recorder.entries.append("\(id):\(marker)")
    }
}

private enum AnalyticsTestError: Error {
    case sample
}
