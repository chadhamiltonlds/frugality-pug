import SwiftUI

/// A percent input bound to a fraction: typing 7 sets the value to 0.07.
struct PercentField: View {
    let title: String
    @Binding var value: Decimal
    @State private var text = ""

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(Theme.ink)
            Spacer()
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 80)
                .onChange(of: text) { _, newText in
                    value = PercentField.parse(newText)
                }
            Text("%").foregroundStyle(Theme.muted)
        }
        .onAppear {
            text = NSDecimalNumber(decimal: value * 100).stringValue
        }
    }

    static func parse(_ text: String) -> Decimal {
        let cleaned = text.filter { $0.isNumber || $0 == "." || $0 == "-" }
        return (Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX")) ?? 0) / 100
    }
}
