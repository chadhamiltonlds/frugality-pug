import SwiftUI

/// A percent input bound to a fraction: typing 7 sets the value to 0.07.
struct PercentField: View {
    let title: String
    @Binding var value: Decimal
    @State private var text = ""

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            Text(title)
                .foregroundStyle(Theme.ink)
            Spacer()
            UnderlinedInput(text: $text, suffix: "%", width: 96)
                .onChange(of: text) { _, newText in
                    value = PercentField.parse(newText)
                }
        }
        .onAppear {
            text = NSDecimalNumber(decimal: value * 100).stringValue
        }
    }

    static func parse(_ text: String) -> Decimal {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        let digits = trimmed.filter { $0.isNumber || $0 == "." }
        let signed = trimmed.hasPrefix("-") ? "-" + digits : digits
        return (Decimal(string: signed, locale: Locale(identifier: "en_US_POSIX")) ?? 0) / 100
    }
}
