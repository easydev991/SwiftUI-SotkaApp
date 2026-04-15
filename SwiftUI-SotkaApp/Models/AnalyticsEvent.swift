import Foundation

enum AnalyticsEvent {
    case screenView(screen: AppScreen)
    case userAction(action: UserAction)
    case appError(kind: AppErrorKind, error: any Error)
}

extension AnalyticsEvent {
    enum AppScreen: String {
        case root
        case login
        case home
        case infopostsList = "infoposts_list"
        case infopostDetail = "infopost_detail"
        case workoutPreview = "workout_preview"
        case workoutExerciseEditor = "workout_exercise_editor"
        case workout
        case workoutTimer = "workout_timer"
        case editProfile = "edit_profile"
        case changePassword = "change_password"
        case journal
        case progress
        case progressStats = "progress_stats"
        case editProgress = "edit_progress"
        case customExercises = "custom_exercises"
        case customExercise = "custom_exercise"
        case editCustomExercise = "edit_custom_exercise"
        case more
        case themeIcon = "theme_icon"
        case syncJournal = "sync_journal"
        case syncJournalEntry = "sync_journal_entry"
        case syncStartDate = "sync_start_date"
        case syncStartDateHelp = "sync_start_date_help"
        case offlineLogin = "offline_login"
        case onlineLogin = "online_login"
    }

    enum UserAction {
        case login
        case logout
        case resetPassword
        case editWorkout(dayNumber: String)
        case editProgress(dayNumber: String)
        case saveProfile
        case savePassword
        case saveWorkoutExercises(dayNumber: String)
        case openLanguageSettings
        case openFeedback
        case openResetProgramDialog
        case openProfilePhotoPicker
        case selectProfilePhotoSource(source: String)
        case selectTheme(theme: String)
        case selectAppIcon(iconName: String)
        case toggleWorkoutNotifications
        case selectRestTime(seconds: Int)
        case startWorkout
        case completeWorkout
        case interruptWorkout
        case skipTimer
        case selectActivityType(type: String, dayNumber: String)
        case editJournalEntry(dayNumber: String)
        case deleteJournalEntry(dayNumber: String)
        case selectJournalSort(newSortOrder: String)
        case selectJournalDisplayMode(newDisplayMode: String)
        case saveProgress
        case deleteProgress(dayNumber: String)
        case addProgressPhoto(source: String)
        case deleteProgressPhoto(photoType: Int)
        case selectProgressDisplayMode(dayNumber: String)
        case infopostFavoriteChanged(isFavorite: Bool, infopostId: String)
        case markInfopostRead
        case selectInfopostDisplayMode(newDisplayMode: String)
        case selectInfopostFontSize(size: String, infopostId: String)
        case clearSyncJournal
        case selectSyncSource(source: String)
        case confirmSyncStartDate
        case createExercise
        case editExercise(exerciseId: String)
        case deleteExercise(exerciseId: String)
        case selectExerciseIcon(iconName: String, exerciseId: String)
        case addExerciseToWorkout(exerciseName: String)
        case deleteExerciseFromWorkout(exerciseName: String)
        case moveExerciseInWorkout(exerciseName: String)
        case saveWorkout
        case confirmResetProgram
        case beginOfflineLogin

        var name: String {
            switch self {
            case .login: "login"
            case .logout: "logout"
            case .resetPassword: "reset_password"
            case .editWorkout: "edit_workout"
            case .editProgress: "edit_progress"
            case .saveProfile: "save_profile"
            case .savePassword: "save_password"
            case .saveWorkoutExercises: "save_workout_exercises"
            case .openLanguageSettings: "open_language_settings"
            case .openFeedback: "open_feedback"
            case .openResetProgramDialog: "open_reset_program_dialog"
            case .openProfilePhotoPicker: "open_profile_photo_picker"
            case .selectProfilePhotoSource: "select_profile_photo_source"
            case .selectTheme: "select_theme"
            case .selectAppIcon: "select_app_icon"
            case .toggleWorkoutNotifications: "toggle_workout_notifications"
            case .selectRestTime: "select_rest_time"
            case .startWorkout: "start_workout"
            case .completeWorkout: "complete_workout"
            case .interruptWorkout: "interrupt_workout"
            case .skipTimer: "skip_timer"
            case .selectActivityType: "select_activity_type"
            case .editJournalEntry: "edit_journal_entry"
            case .deleteJournalEntry: "delete_journal_entry"
            case .selectJournalSort: "select_journal_sort"
            case .selectJournalDisplayMode: "select_journal_display_mode"
            case .saveProgress: "save_progress"
            case .deleteProgress: "delete_progress"
            case .addProgressPhoto: "add_progress_photo"
            case .deleteProgressPhoto: "delete_progress_photo"
            case .selectProgressDisplayMode: "select_progress_display_mode"
            case .infopostFavoriteChanged: "infopost_favorite_changed"
            case .markInfopostRead: "mark_infopost_read"
            case .selectInfopostDisplayMode: "select_infopost_display_mode"
            case .selectInfopostFontSize: "select_infopost_font_size"
            case .clearSyncJournal: "clear_sync_journal"
            case .selectSyncSource: "select_sync_source"
            case .confirmSyncStartDate: "confirm_sync_start_date"
            case .createExercise: "create_exercise"
            case .editExercise: "edit_exercise"
            case .deleteExercise: "delete_exercise"
            case .selectExerciseIcon: "select_exercise_icon"
            case .addExerciseToWorkout: "add_exercise_to_workout"
            case .deleteExerciseFromWorkout: "delete_exercise_from_workout"
            case .moveExerciseInWorkout: "move_exercise_in_workout"
            case .saveWorkout: "save_workout"
            case .confirmResetProgram: "confirm_reset_program"
            case .beginOfflineLogin: "begin_offline_login"
            }
        }
    }

    enum AppErrorKind: String {
        case loginFailed = "login_failed"
        case passwordResetFailed = "password_reset_failed"
        case profileSaveFailed = "profile_save_failed"
        case changePasswordFailed = "change_password_failed"
        case progressSaveFailed = "progress_save_failed"
        case progressDeleteFailed = "progress_delete_failed"
        case customExerciseSyncFailed = "custom_exercise_sync_failed"
        case setIconFailed = "set_icon_failed"
        case infopostFavoriteFailed = "infopost_favorite_failed"
        case syncStartDateFailed = "sync_start_date_failed"
        case syncJournalDeleteFailed = "sync_journal_delete_failed"
        case workoutSaveFailed = "workout_save_failed"
        case workoutStartFailed = "workout_start_failed"
        case customExerciseSaveFailed = "custom_exercise_save_failed"
        case customExerciseDeleteFailed = "custom_exercise_delete_failed"
        case workoutExecutionTypeNotSelected = "workout_execution_type_not_selected"
        case workoutEmptyExercisesList = "workout_empty_exercises_list"
        case youtubeVideoNotFound = "youtube_video_not_found"
        case youtubeFileNotFound = "youtube_file_not_found"
        case youtubeFileReadError = "youtube_file_read_error"
        case infopostAboutLoadFailed = "infopost_about_load_failed"
        case infopostFavoriteCheckFailed = "infopost_favorite_check_failed"
        case infopostFavoriteListLoadFailed = "infopost_favorite_list_load_failed"
        case infopostParsingFailed = "infopost_parsing_failed"
        case infopostDaySyncFailed = "infopost_day_sync_failed"
        case infopostSyncWithoutDayFailed = "infopost_sync_without_day_failed"
        case infopostReadStatusCheckFailed = "infopost_read_status_check_failed"
        case progressValidationFailed = "progress_validation_failed"
        case progressUserNotFound = "progress_user_not_found"
        case progressSaveOperationFailed = "progress_save_operation_failed"
        case progressDeleteOperationFailed = "progress_delete_operation_failed"
    }
}
