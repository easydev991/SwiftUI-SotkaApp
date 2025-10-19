import SWDesignSystem
import SwiftData
import SwiftUI

struct EditProgressScreen: View {
    @Bindable var progress: Progress
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var progressService: ProgressService
    @State private var showDeleteDialog = false
    @FocusState private var focus: FocusableField?

    init(progress: Progress, mode: ProgressDisplayMode) {
        self.progress = progress
        self._progressService = .init(
            initialValue: .init(progress: progress, mode: mode)
        )
    }

    var body: some View {
        VStack(spacing: 12) {
            displayModePicker
            contentView
        }
        .animation(.default, value: progressService.displayMode)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if progress.hasAnyData {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showDeleteDialog = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Button { focus = nil } label: {
                    Image(systemName: "keyboard.chevron.compact.down.fill")
                }
                Spacer()
                if focus != nil {
                    previousButton
                    nextButton
                }
            }
        }
        .confirmationDialog(
            .progressEditConfirmDeleteTitle,
            isPresented: $showDeleteDialog,
            titleVisibility: .visible
        ) {
            Button(.progressEditDelete, role: .destructive) {
                do {
                    try progressService.deleteProgress(context: modelContext)
                    dismiss()
                } catch {
                    print("Ошибка удаления прогресса: \(error.localizedDescription)")
                }
            }
        } message: {
            Text(.progressEditConfirmDeleteMessage)
        }
    }
}

private extension EditProgressScreen {
    enum FocusableField: Hashable {
        case pullUps, pushUps, squats, weight

        var next: FocusableField? {
            switch self {
            case .pullUps:
                .pushUps
            case .pushUps:
                .squats
            case .squats:
                .weight
            case .weight:
                nil // Последнее поле
            }
        }

        var previous: FocusableField? {
            switch self {
            case .pullUps:
                nil // Первое поле
            case .pushUps:
                .pullUps
            case .squats:
                .pushUps
            case .weight:
                .squats
            }
        }
    }

    @ViewBuilder
    var displayModePicker: some View {
        @Bindable var service = progressService
        Picker(.progressDisplayMode, selection: $service.displayMode) {
            ForEach(ProgressDisplayMode.allCases) {
                Text($0.title).tag($0)
            }
        }
        .pickerStyle(.segmented)
        .padding([.top, .horizontal])
    }

    @ViewBuilder
    var contentView: some View {
        switch progressService.displayMode {
        case .metrics:
            metricsSection
        case .photos:
            EditProgressPhotoScreen(progress: progress)
                .environment(progressService)
        }
    }

    var metricsSection: some View {
        ScrollViewReader { proxy in
            List {
                exerciseSection
                weightSection
                    .listSectionSeparator(.hidden)
                saveButton
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .background(Color.swBackground)
            .navigationTitle(.progressEditTitle)
            .task {
                guard focus == nil else { return }
                try? await Task.sleep(for: .milliseconds(500))
                focus = .pullUps
            }
            .onChange(of: focus) { _, newFocus in
                guard let newFocus else { return }
                withAnimation(.easeInOut(duration: 0.5)) {
                    proxy.scrollTo(newFocus, anchor: .center)
                }
            }
        }
    }

    var exerciseSection: some View {
        Section {
            ProgressInputRow(
                dataType: .pullUps,
                value: $progressService.pullUps,
                keyboardType: .numberPad,
                focus: $focus,
                field: .pullUps
            )
            .id(FocusableField.pullUps)
            ProgressInputRow(
                dataType: .pushUps,
                value: $progressService.pushUps,
                keyboardType: .numberPad,
                focus: $focus,
                field: .pushUps
            )
            .id(FocusableField.pushUps)
            ProgressInputRow(
                dataType: .squats,
                value: $progressService.squats,
                keyboardType: .numberPad,
                focus: $focus,
                field: .squats
            )
            .id(FocusableField.squats)
        } header: {
            Text(.progressEditHeader)
        } footer: {
            Text(.progressEditFooter)
                .foregroundStyle(.secondary)
        }
    }

    var weightSection: some View {
        Section {
            ProgressInputRow(
                dataType: .weight,
                value: $progressService.weight,
                keyboardType: .decimalPad,
                focus: $focus,
                field: .weight
            )
            .id(FocusableField.weight)
        }
    }

    var saveButton: some View {
        Button(.progressEditSave, action: performSave)
            .buttonStyle(SWButtonStyle(mode: .filled, size: .large))
            .disabled(!progressService.hasChanges || !progressService.canSave)
    }

    var previousButton: some View {
        Button {
            if let previousField = focus?.previous {
                focus = previousField
            }
        } label: {
            Image(systemName: "chevron.backward")
        }
        .disabled(focus?.previous == nil)
    }

    var nextButton: some View {
        Button {
            if let nextField = focus?.next {
                focus = nextField
            }
        } label: {
            Image(systemName: "chevron.right")
        }
        .disabled(focus?.next == nil)
    }

    func performSave() {
        do {
            try progressService.saveProgress(context: modelContext)
            dismiss()
        } catch {
            print("Ошибка сохранения прогресса: \(error.localizedDescription)")
        }
    }
}

// MARK: - ProgressInputRow

private struct ProgressInputRow: View {
    let dataType: Progress.DataType
    @Binding var value: String
    let keyboardType: UIKeyboardType
    let focus: FocusState<EditProgressScreen.FocusableField?>.Binding
    let field: EditProgressScreen.FocusableField

    var body: some View {
        HStack(spacing: 12) {
            dataType.icon
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(.blue)
            Text(dataType.localizedTitle)
                .foregroundStyle(Color.swMainText)
                .frame(maxWidth: .infinity, alignment: .leading)
            SWTextField(
                placeholder: String(localized: .progressEditEnter),
                text: $value,
                isFocused: focus.wrappedValue == field,
                inputValidation: dataType == .weight ? .decimalNumber : .integer
            )
            .keyboardType(keyboardType)
            .frame(width: 100)
            .focused(focus, equals: field)
        }
    }
}

#if DEBUG
#Preview("Пустой прогресс") {
    NavigationStack {
        EditProgressScreen(progress: .init(id: 1), mode: .metrics)
    }
}

#Preview("С данными") {
    NavigationStack {
        EditProgressScreen(
            progress: .init(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.5),
            mode: .metrics
        )
    }
}

#Preview("Синхронизированный") {
    NavigationStack {
        EditProgressScreen(progress: {
            let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.5)
            progress.isSynced = true
            return progress
        }(), mode: .metrics)
    }
}
#endif
