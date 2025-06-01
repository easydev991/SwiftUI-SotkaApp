import SwiftUI

/// Упражнение с соответствующим `type_id` для отправки на сервер
enum ExerciseType: Int {
    /// подтягивания
    case pullups = 0

    /// австралийские подтягивания
    case austrPullups = 1

    /// приседания
    case squats = 2

    /// отжимания
    case pushups = 3

    /// отжимания на коленях
    case pushupsKnees = 4

    /// выпады
    case lunges = 5

    /// турбо-упражнение 93.1
    case turbo93_1 = 93

    /// турбо-упражнение 93.2
    case turbo93_2 = 932

    /// турбо-упражнение 93.3
    case turbo93_3 = 933

    /// турбо-упражнение 93.4
    case turbo93_4 = 934

    /// турбо-упражнение 93.5
    case turbo93_5 = 935

    /// турбо-отжимания 94 (индийские)
    case turbo94Pushups = 94

    /// турбо-приседания 94 (спартанские наклоны)
    case turbo94Squats = 942

    /// турбо-подтягивания 94 (подтягивания с согнутыми ногами)
    case turbo94Pullups = 943

    /// турбо-упражнение 95.1
    case turbo95_1 = 95

    /// турбо-упражнение 95.2
    case turbo95_2 = 952

    /// турбо-упражнение 95.3
    case turbo95_3 = 953

    /// турбо-упражнение 95.4
    case turbo95_4 = 954

    /// турбо-упражнение 95.5
    case turbo95_5 = 955

    /// турбо-отжимания 96 (медленные)
    case turbo96Pushups = 96

    /// турбо-приседания 96 (медленные)
    case turbo96Squats = 962

    /// турбо-подтягивания 96 (медленные)
    case turbo96Pullups = 963

    /// высокие отжимания 97 (с ногами на возвышенности)
    case turbo97PushupsHigh = 97

    /// высокие отжимания с упором (с руками на возвышенности)
    case turbo97PushupsHighArms = 973

    /// турбо-подтягивания 98 (лесенка)
    case turbo98Pullups = 98

    /// турбо-отжимания 98 (лесенка)
    case turbo98Pushups = 982

    /// турбо-приседания 98 (лесенка)
    case turbo98Squats = 983

    var localizedTitle: LocalizedStringKey {
        switch self {
        case .pullups: "Pull-ups"
        case .austrPullups: "Australian pull-ups"
        case .squats: "Squats"
        case .pushups: "Push-ups"
        case .pushupsKnees: "Knees push-ups"
        case .lunges: "Lunges"
        case .turbo93_1: "Turbo 93-1"
        case .turbo93_2: "Turbo 93-2"
        case .turbo93_3: "Turbo 93-3"
        case .turbo93_4: "Turbo 93-4"
        case .turbo93_5: "Turbo 93-5"
        case .turbo94Pushups: "Turbo 94 push-ups"
        case .turbo94Squats: "Turbo 94 squats"
        case .turbo94Pullups: "Turbo 94 pull-ups"
        case .turbo95_1: "Turbo 95-1"
        case .turbo95_2: "Turbo 95-2"
        case .turbo95_3: "Turbo 95-3"
        case .turbo95_4: "Turbo 95-4"
        case .turbo95_5: "Turbo 95-5"
        case .turbo96Pushups: "Turbo 96 push-ups"
        case .turbo96Squats: "Turbo 96 squats"
        case .turbo96Pullups: "Turbo 96 pull-ups"
        case .turbo97PushupsHigh: "Turbo 97 push-ups high"
        case .turbo97PushupsHighArms: "Turbo 97 push-ups high arms"
        case .turbo98Pushups: "Turbo 98 push-ups"
        case .turbo98Squats: "Turbo 98 squats"
        case .turbo98Pullups: "Turbo 98 pull-ups"
        }
    }

    var image: Image {
        switch self {
        case .pushups, .turbo94Pushups, .turbo96Pushups, .turbo97PushupsHigh, .turbo97PushupsHighArms, .turbo98Pushups:
            .init(.pushups)
        case .pullups, .turbo93_1, .turbo94Pullups, .turbo96Pullups, .turbo98Pullups:
            .init(.pullups)
        case .squats, .turbo94Squats, .turbo96Squats, .turbo98Squats:
            .init(.squats)
        case .austrPullups:
            .init(.pullupsAustralian)
        case .pushupsKnees:
            .init(.pushupsKnee)
        case .lunges:
            .init(.lunges)
        default:
            .init(systemName: "figure.play")
        }
    }
}

extension ExerciseType {
    /// Пользовательские упражнения
    enum CustomType: Int {
        case pushups = 0
        case pullups
        case lunges
        case squats
        case stretch
        case bars
        case crunches
        case muscleup
        case standing
        case absLegRaises
        case absHangingLegRaises
        case absMountainClimber
        case absBicycle
        case pushupsDecline
        case pushupsIncline
        case squatsPistol

        var image: Image {
            switch self {
            case .pushups: .init(.pushups)
            case .pullups: .init(.pullups)
            case .lunges: .init(.lunges)
            case .squats: .init(.squats)
            case .stretch: .init(.stretch)
            case .bars: .init(.bars)
            case .crunches: .init(.crunches)
            case .muscleup: .init(.muscleup)
            case .standing: .init(.standing)
            case .absLegRaises: .init(.absLegRaises)
            case .absHangingLegRaises: .init(.absHangingLegRaises)
            case .absMountainClimber: .init(.absMountainClimber)
            case .absBicycle: .init(.absBicycle)
            case .pushupsDecline: .init(.pushupsDecline)
            case .pushupsIncline: .init(.pushupsIncline)
            case .squatsPistol: .init(.squatsPistol)
            }
        }
    }
}
