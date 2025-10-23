import Foundation

/// Enum для управления навигацией в экране прогресса
enum ProgressDestination: Hashable {
    case editProgress(UserProgress)
    case editPhotos(UserProgress)
}
