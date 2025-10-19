import Foundation

/// Enum для управления навигацией в экране прогресса
enum ProgressDestination: Hashable {
    case editProgress(Progress)
    case editPhotos(Progress)
}
