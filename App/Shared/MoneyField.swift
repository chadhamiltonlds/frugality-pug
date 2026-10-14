import SwiftUI

/// A dollar amount input. Clearing the field sets the value to 0.
struct MoneyField: View {
    let title: String
    @Binding var value: Decimal
    @State private var text = ""

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(Theme.ink)
            Spacer()
            Text("$").foregroundStyle(Theme.muted)
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 130)
                .onChange(of: text) { _, newText in
                    value = MoneyField.parse(newText)
                }
        }
        .onAppear {
            if value != 0 { text = NSDecimalNumber(decimal: value).stringValue }
        }
    }

    static func parse(_ text: String) -> Decimal {
        let cleaned = text.filter { $0.isNumber || $0 == "." }
        return Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }
}

extension Decimal {
    /// "$1,234.50"
    var asCurrency: String {
        formatted(.currency(code: "USD"))
    }

    /// "23.4%" from a fraction such as 0.234
    var asPercent: String {
        formatted(.percent.precision(.fractionLength(1)))
    }
}
