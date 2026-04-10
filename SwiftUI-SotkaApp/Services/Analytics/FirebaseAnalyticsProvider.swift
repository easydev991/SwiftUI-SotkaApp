import FirebaseAnalytics
import Foundation

struct FirebaseAnalyticsProvider: AnalyticsProvider {
    func log(event: AnalyticsEvent) {
        switch event {
        case let .screenView(screen):
            let screenName = screen.rawValue
            Analytics.logEvent(
                AnalyticsEventScreenView,
                parameters: [
                    AnalyticsParameterScreenName: screenName
                ]
            )
        case let .userAction(action):
            var params: [String: Any] = ["action": action.name]
            switch action {
            case let .tapEdit(entityId):
                params["entity_id"] = entityId
            case let .tapDelete(entityId):
                params["entity_id"] = entityId
            case let .selectAppIcon(iconName):
                params["icon_name"] = iconName
            case let .infopostFavoriteChanged(isFavorite, number):
                params["is_favorite"] = isFavorite
                params["infopost_number"] = number
            case let .selectInfopostFontSize(size, number):
                params["font_size"] = size
                params["infopost_number"] = number
            case let .selectSyncSource(source):
                params["source"] = source
            case let .selectRestTime(seconds):
                params["rest_time"] = seconds
            case let .selectActivityType(type, dayNumber):
                params["activity_type"] = type
                params["day_number"] = dayNumber
            case let .editJournalEntry(dayNumber):
                params["day_number"] = dayNumber
            case let .deleteJournalEntry(dayNumber):
                params["day_number"] = dayNumber
            case let .selectJournalSort(newSortOrder):
                params["new_sort_order"] = newSortOrder
            case let .selectJournalDisplayMode(newDisplayMode):
                params["new_display_mode"] = newDisplayMode
            case let .deleteProgress(dayNumber):
                params["day_number"] = dayNumber
            case let .addProgressPhoto(source):
                params["source"] = source
            case let .deleteProgressPhoto(photoType):
                params["photo_type"] = photoType
            case let .selectProgressDisplayMode(dayNumber):
                params["day_number"] = dayNumber
            case let .selectInfopostDisplayMode(newDisplayMode):
                params["new_display_mode"] = newDisplayMode
            case let .addExerciseToWorkout(exerciseName):
                params["exercise_name"] = exerciseName
            case let .deleteExerciseFromWorkout(exerciseName):
                params["exercise_name"] = exerciseName
            case let .moveExerciseInWorkout(exerciseName):
                params["exercise_name"] = exerciseName
            case let .selectTheme(theme):
                params["theme"] = theme
            case let .editExercise(exerciseId):
                params["exercise_id"] = exerciseId
            case let .deleteExercise(exerciseId):
                params["exercise_id"] = exerciseId
            case let .selectExerciseIcon(iconName, exerciseId):
                params["icon_name"] = iconName
                params["exercise_id"] = exerciseId
            default:
                break
            }
            Analytics.logEvent("user_action", parameters: params)
        case let .appError(kind, error):
            let nsError = error as NSError
            Analytics.logEvent(
                "app_error",
                parameters: [
                    "operation": kind.rawValue,
                    "error_domain": nsError.domain,
                    "error_code": nsError.code
                ]
            )
        }
    }
}
