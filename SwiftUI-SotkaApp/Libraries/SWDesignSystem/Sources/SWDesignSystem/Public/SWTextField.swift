import SwiftUI

/// Однострочное для ввода текста
public struct SWTextField: View {
    private let placeholder: String
    @Binding private var text: String
    private let lineLimit: Int
    private let isSecure: Bool
    private let isFocused: Bool
    private let errorState: ErrorState?
    private let inputValidation: InputValidation?

    /// Инициализирует `SWTextField`
    /// - Parameters:
    ///   - placeholder: Плейсхолдер
    ///   - text: Текст
    ///   - lineLimit: Максимальное количество строк в текстфилде, по умолчанию 1
    ///   - isSecure: `true` - нужно прятать текст, `false` - не нужно, по умолчанию `false`
    ///   - isFocused: `true` - текстфилд сфокусирован, `false` - нет. Влияет на цвет рамки
    ///   - errorState: Состояние ошибки, по умолчанию отсутствует
    ///   - inputValidation: Валидация ввода, по умолчанию отсутствует
    public init(
        placeholder: String,
        text: Binding<String>,
        lineLimit: Int = 1,
        isSecure: Bool = false,
        isFocused: Bool,
        errorState: ErrorState? = nil,
        inputValidation: InputValidation? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.lineLimit = lineLimit
        self.isSecure = isSecure
        self.isFocused = isFocused
        self.errorState = errorState
        self.inputValidation = inputValidation
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            textField
                .lineLimit(lineLimit)
                .tint(.swAccent)
                .foregroundStyle(Color.swMainText)
                .padding(12)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(borderColor, lineWidth: 1)
                        .animation(.default, value: isFocused)
                }
            errorMessageViewIfNeeded
                .transition(.slide.combined(with: .opacity))
        }
        .animation(.default, value: errorState)
    }
}

public extension SWTextField {
    enum ErrorState: Equatable {
        case noMessage
        case message(String)

        var message: String? {
            if case let .message(text) = self, !text.isEmpty {
                text
            } else {
                nil
            }
        }
    }

    enum InputValidation {
        /// Для веса: только цифры + максимум одна запятая/точка
        case decimalNumber
        /// Для целых чисел: только цифры
        case integer
    }
}

private extension SWTextField {
    @ViewBuilder
    var textField: some View {
        if isSecure {
            SecureField(.init(placeholder), text: $text)
        } else {
            TextField(placeholder, text: $text, axis: .vertical)
                .onChange(of: text) { _, newValue in
                    if let validation = inputValidation {
                        text = validateInput(newValue, validation: validation)
                    }
                }
        }
    }

    @ViewBuilder
    var errorMessageViewIfNeeded: some View {
        if let message = errorState?.message {
            Text(.init(message))
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .foregroundStyle(Color.swError)
        }
    }

    var borderColor: Color {
        guard errorState == nil else { return .swError }
        return isFocused ? .swAccent : .swSeparators
    }

    /// Валидирует ввод в зависимости от типа валидации
    /// - Parameters:
    ///   - input: Введенный текст
    ///   - validation: Тип валидации
    /// - Returns: Отфильтрованный текст
    func validateInput(_ input: String, validation: InputValidation) -> String {
        switch validation {
        case .decimalNumber:
            validateDecimalInput(input)
        case .integer:
            validateIntegerInput(input)
        }
    }

    /// Валидирует ввод десятичного числа (только цифры + максимум одна запятая/точка)
    /// - Parameter input: Введенный текст
    /// - Returns: Отфильтрованный текст
    func validateDecimalInput(_ input: String) -> String {
        var result = ""
        var hasDecimalSeparator = false

        for character in input {
            if character.isNumber {
                result.append(character)
            } else if character == "," || character == ".", !hasDecimalSeparator {
                // Используем запятую как стандартный разделитель
                result.append(",")
                hasDecimalSeparator = true
            }
        }

        return result
    }

    /// Валидирует ввод целого числа (только цифры)
    /// - Parameter input: Введенный текст
    /// - Returns: Отфильтрованный текст
    func validateIntegerInput(_ input: String) -> String {
        input.filter(\.isNumber)
    }
}

#if DEBUG
#Preview("Мало текста") {
    VStack(spacing: 20) {
        SWTextField(
            placeholder: "Placeholder",
            text: .constant(""),
            isFocused: false
        )
        SWTextField(
            placeholder: "Placeholder",
            text: .constant(""),
            isSecure: true,
            isFocused: false
        )
        SWTextField(
            placeholder: "Placeholder",
            text: .constant("Text"),
            isFocused: true
        )
        SWTextField(
            placeholder: "Placeholder",
            text: .constant("Text"),
            isFocused: false,
            errorState: .noMessage
        )
        SWTextField(
            placeholder: "Placeholder",
            text: .constant("Text"),
            isFocused: false,
            errorState: .message("Error message")
        )
    }
    .padding(.horizontal)
}

#Preview("Валидация ввода") {
    @Previewable @State var decimalText = ""
    @Previewable @State var integerText = ""

    return VStack(spacing: 20) {
        SWTextField(
            placeholder: "Введите вес (десятичное число)",
            text: $decimalText,
            isFocused: true,
            inputValidation: .decimalNumber
        )
        SWTextField(
            placeholder: "Введите количество (целое число)",
            text: $integerText,
            isFocused: false,
            inputValidation: .integer
        )
    }
    .padding(.horizontal)
}

#Preview("Много текста") {
    @Previewable @State var text =
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum"
    return VStack(spacing: 20) {
        SWTextField(
            placeholder: "Placeholder",
            text: $text,
            lineLimit: 2,
            isFocused: false
        )
        SWTextField(
            placeholder: "Placeholder",
            text: $text,
            lineLimit: 3,
            isSecure: true,
            isFocused: false
        )
        SWTextField(
            placeholder: "Placeholder",
            text: $text,
            lineLimit: 4,
            isFocused: true
        )
        SWTextField(
            placeholder: "Placeholder",
            text: $text,
            lineLimit: 5,
            isFocused: false,
            errorState: .noMessage
        )
        SWTextField(
            placeholder: "Placeholder",
            text: $text,
            lineLimit: 6,
            isFocused: false,
            errorState: .message("Error message")
        )
    }
    .padding(.horizontal)
}
#endif
