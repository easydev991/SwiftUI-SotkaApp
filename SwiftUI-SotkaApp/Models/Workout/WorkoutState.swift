enum WorkoutState {
    case active
    case completed
    case inactive

    var isActive: Bool {
        self == .active
    }
}
