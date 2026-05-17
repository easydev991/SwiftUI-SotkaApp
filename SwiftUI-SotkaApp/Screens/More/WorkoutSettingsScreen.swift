import SwiftUI
import SWUtils

struct WorkoutSettingsScreen: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.analyticsService) private var analytics

    var body: some View {
        List {
            @Bindable var settings = appSettings
            Section {
                customExercisesButton
            }
            Section {
                notificationToggle
                if settings.workoutNotificationsEnabled {
                    makeNotificationTimePicker($settings.workoutNotificationTime)
                }
            }
            Section(.moreScreenRestGroup) {
                makeRestTimePicker($settings.restTime)
                makeTimerSoundToggle($settings.playTimerSound)
                if settings.playTimerSound {
                    makeTimerSoundPicker($settings.timerSound)
                }
                if UIDevice.current.userInterfaceIdiom == .phone {
                    makeVibrateToggle($settings.vibrate)
                }
            }
        }
        .animation(.default, value: appSettings.workoutNotificationsEnabled)
        .animation(.default, value: appSettings.playTimerSound)
        .navigationTitle(.workoutSettingsScreen)
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen(.workoutSettings)
        .onChange(of: appSettings.workoutNotificationsEnabled) { _, _ in
            analytics.log(.userAction(action: .toggleWorkoutNotifications))
        }
        .onChange(of: appSettings.restTime) { _, newValue in
            analytics.log(.userAction(action: .selectRestTime(seconds: newValue)))
        }
    }
}

private extension WorkoutSettingsScreen {
    var customExercisesButton: some View {
        NavigationLink(destination: CustomExercisesScreen()) {
            Text(.customExercises)
        }
        .accessibilityIdentifier("customExercisesButton")
    }

    var notificationToggle: some View {
        Toggle(
            .workoutNotifications,
            isOn: .init(
                get: { appSettings.workoutNotificationsEnabled },
                set: {
                    appSettings.setWorkoutNotificationsEnabled($0)
                }
            )
        )
    }

    func makeNotificationTimePicker(_ value: Binding<Date>) -> some View {
        DatePicker(
            .notificationTime,
            selection: value,
            displayedComponents: .hourAndMinute
        )
    }

    func makeTimerSoundToggle(_ value: Binding<Bool>) -> some View {
        Toggle(.timerSoundToggle, isOn: value)
    }

    func makeVibrateToggle(_ value: Binding<Bool>) -> some View {
        Toggle(.timerVibrateToggle, isOn: value)
    }

    func makeTimerSoundPicker(_ value: Binding<TimerSound>) -> some View {
        Picker(.moreScreenTimerSound, selection: value) {
            ForEach(TimerSound.allCases, id: \.self) { sound in
                Text(sound.displayName).tag(sound)
            }
        }
        .pickerStyle(.navigationLink)
    }

    func makeRestTimePicker(_ value: Binding<Int>) -> some View {
        Picker(.restTimePicker, selection: value) {
            ForEach(Constants.restPickerOptions, id: \.self) { seconds in
                Text(RestTimeComponents(totalSeconds: seconds).localizedString).tag(seconds)
            }
        }
        .pickerStyle(.navigationLink)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WorkoutSettingsScreen()
            .environment(AppSettings())
    }
}
#endif
