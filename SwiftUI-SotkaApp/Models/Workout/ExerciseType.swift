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

    var localizedTitle: String {
        switch self {
        case .pullups: String(localized: .pullUps)
        case .austrPullups: String(localized: .australianPullUps)
        case .squats: String(localized: .squats)
        case .pushups: String(localized: .pushUps)
        case .pushupsKnees: String(localized: .kneesPushUps)
        case .lunges: String(localized: .lunges)
        case .turbo93_1: String(localized: .turbo931)
        case .turbo93_2: String(localized: .turbo932)
        case .turbo93_3: String(localized: .turbo933)
        case .turbo93_4: String(localized: .turbo934)
        case .turbo93_5: String(localized: .turbo935)
        case .turbo94Pushups: String(localized: .turbo94PushUps)
        case .turbo94Squats: String(localized: .turbo94Squats)
        case .turbo94Pullups: String(localized: .turbo94PullUps)
        case .turbo95_1: String(localized: .turbo951)
        case .turbo95_2: String(localized: .turbo952)
        case .turbo95_3: String(localized: .turbo953)
        case .turbo95_4: String(localized: .turbo954)
        case .turbo95_5: String(localized: .turbo955)
        case .turbo96Pushups: String(localized: .turbo96PushUps)
        case .turbo96Squats: String(localized: .turbo96Squats)
        case .turbo96Pullups: String(localized: .turbo96PullUps)
        case .turbo97PushupsHigh: String(localized: .turbo97PushUpsHigh)
        case .turbo97PushupsHighArms: String(localized: .turbo97PushUpsHighArms)
        case .turbo98Pushups: String(localized: .turbo98PushUps)
        case .turbo98Squats: String(localized: .turbo98Squats)
        case .turbo98Pullups: String(localized: .turbo98PullUps)
        }
    }

    var image: Image {
        switch self {
        case .pushups, .turbo94Pushups, .turbo96Pushups, .turbo98Pushups:
            .init(.pushups)
        case .pullups, .turbo93_1, .turbo93_2, .turbo93_3, .turbo93_4, .turbo93_5, .turbo94Pullups, .turbo96Pullups, .turbo98Pullups:
            .init(.pullups)
        case .squats, .turbo94Squats, .turbo95_1, .turbo95_2, .turbo95_3, .turbo95_4, .turbo95_5, .turbo96Squats, .turbo98Squats:
            .init(.squats)
        case .austrPullups:
            .init(.pullupsAustralian)
        case .pushupsKnees:
            .init(.pushupsKnee)
        case .lunges:
            .init(.lunges)
        case .turbo97PushupsHigh:
            .init(.pushupsDecline)
        case .turbo97PushupsHighArms:
            .init(.pushupsIncline)
        }
    }

    /// Получить локализованное название упражнения с учетом дня и типа выполнения
    /// - Parameters:
    ///   - dayNumber: Номер дня
    ///   - executionType: Тип выполнения упражнений
    ///   - sortOrder: Порядок следования упражнения в списке (для дня 97 в турбо-режиме)
    /// - Returns: Локализованное название упражнения
    func makeLocalizedTitle(_ dayNumber: Int, executionType: ExerciseExecutionType, sortOrder: Int? = nil) -> String {
        if executionType == .turbo, dayNumber == 92, self == .lunges {
            return String(localized: .lunges92)
        }

        // Для дня 97 в турбо-режиме используем разные названия в зависимости от sortOrder
        if executionType == .turbo, dayNumber == 97, self == .pushups, let sortOrder {
            switch sortOrder {
            case 0, 4:
                return String(localized: "pushUps970")
            case 1, 3:
                return String(localized: "pushUps971")
            case 2:
                return String(localized: "pushUps972")
            default:
                return localizedTitle
            }
        }

        // Для дня 97 в турбо-режиме для других типов упражнений используем стандартные названия
        if executionType == .turbo, dayNumber == 97, self == .turbo97PushupsHigh {
            if let sortOrder {
                switch sortOrder {
                case 0, 4:
                    return String(localized: "pushUps970")
                default:
                    return localizedTitle
                }
            }
        }

        if executionType == .turbo, dayNumber == 97, self == .turbo97PushupsHighArms {
            if let sortOrder, sortOrder == 2 {
                return String(localized: "pushUps972")
            }
        }

        return localizedTitle
    }
}

extension ExerciseType {
    /// Стандартные упражнения, доступные для редактирования тренировки
    static var standardExercises: [ExerciseType] {
        [
            .pullups,
            .austrPullups,
            .squats,
            .pushups,
            .pushupsKnees,
            .lunges
        ]
    }

    /// Пользовательские упражнения
    enum CustomType: Int, CaseIterable {
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
