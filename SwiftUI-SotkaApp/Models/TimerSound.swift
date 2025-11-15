import Foundation

enum TimerSound: String, CaseIterable {
    case ringtone1 = "Ringtone 1.mp3"
    case ringtone2 = "Ringtone 2.mp3"
    case ringtone3 = "Ringtone 3.mp3"
    case ringtone4 = "Ringtone 4.mp3"
    case ringtone5 = "Ringtone 5.mp3"
    case ringtone6 = "Ringtone 6.mp3"
    case ringtone7 = "Ringtone 7.mp3"

    var fileName: String {
        let components = rawValue.split(separator: ".")
        guard components.count >= 2 else {
            return rawValue
        }
        return components.dropLast().joined(separator: ".")
    }

    var fileExtension: String {
        let components = rawValue.split(separator: ".")
        guard let last = components.last else {
            return ""
        }
        return String(last)
    }

    var bundleURL: URL? {
        Bundle.main.url(
            forResource: fileName,
            withExtension: fileExtension
        )
    }

    var displayName: String {
        fileName
    }
}
