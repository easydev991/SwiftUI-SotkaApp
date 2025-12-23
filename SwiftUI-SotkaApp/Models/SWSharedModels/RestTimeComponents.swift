import Foundation

struct RestTimeComponents {
    let minutes: Int
    let seconds: Int

    init(totalSeconds: Int) {
        self.minutes = totalSeconds / 60
        self.seconds = totalSeconds % 60
    }
}

extension RestTimeComponents {
    var localizedString: String {
        switch (minutes, seconds) {
        case let (0, sec) where sec > 0:
            String(localized: .sec(seconds))
        case let (min, sec) where min > 0 && sec > 0:
            String(localized: .minSec(minutes, seconds))
        case let (min, 0) where min > 0:
            String(localized: .min(minutes))
        default:
            String(localized: .sec(seconds))
        }
    }
}
