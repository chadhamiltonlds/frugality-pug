import SwiftUI
import UIKit

/// Whole-number input with square minus/plus keys. Replaces the system Stepper.
struct LedgerStepper: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let valueText: (Int) -> String

    init(_ title: String, value: Binding<Int>, in range: ClosedRange<Int>, step: Int = 1,
         valueText: @escaping (Int) -> String = { "\($0)" }) {
        self.title = title
        self._value = value
        self.range = range
        self.step = max(1, step)
        self.valueText = valueText
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 8)
            key("minus", enabled: value > range.lowerBound) { change(by: -step) }
            Text(valueText(value))
                .font(.body.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
                .frame(minWidth: 56)
                .lineLimit(1)
                .fixedSize()
            key("plus", enabled: value < range.upperBound) { change(by: step) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(valueText(value))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: change(by: step)
            case .decrement: change(by: -step)
            @unknown default: break
            }
        }
    }

    /// "1 year", "30 years"
    static func years(_ count: Int) -> String {
        "\(count) \(count == 1 ? "year" : "years")"
    }

    private func change(by delta: Int) {
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        value = min(max(clamped + delta, range.lowerBound), range.upperBound)
    }

    private func key(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(enabled ? Theme.ink : Theme.muted.opacity(0.5))
                .frame(width: 34, height: 34)
                .background(enabled ? Theme.peach.opacity(0.6) : Theme.cream)
                .overlay(Rectangle().stroke(enabled ? Theme.ink : Theme.muted.opacity(0.5), lineWidth: Theme.lineWidth))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

/// A row of square, joined choices. Replaces the segmented picker.
struct ChoiceBar<Option: Hashable>: View {
    @Binding var selection: Option
    let options: [Option]
    let label: (Option) -> String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                let selected = option == selection
                if index > 0 {
                    Rectangle().fill(Theme.ink).frame(width: Theme.lineWidth)
                }
                Button { selection = option } label: {
                    Text(label(option))
                        .font(.subheadline.weight(selected ? .bold : .medium))
                        .foregroundStyle(selected ? Theme.paper : Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(selected ? Theme.ink : Theme.paper)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .overlay(Rectangle().stroke(Theme.ink, lineWidth: Theme.lineWidth))
        .animation(.easeOut(duration: 0.12), value: selection)
    }
}

/// Square ledger checkbox. Applied to every Toggle on calculator screens.
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: 12) {
                configuration.label
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 8)
                ZStack {
                    Rectangle()
                        .fill(configuration.isOn ? Theme.positive : Theme.paper)
                    Rectangle()
                        .stroke(Theme.ink, lineWidth: Theme.lineWidth)
                    if configuration.isOn {
                        Image(systemName: "checkmark")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(Theme.paper)
                    }
                }
                .frame(width: 28, height: 28)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(configuration.isOn ? .isSelected : [])
    }
}

/// Text input sitting on an inked underline, like a blank on a paper form.
struct UnderlinedInput: View {
    @Binding var text: String
    var prefix: String?
    var suffix: String?
    var width: CGFloat

    var body: some View {
        HStack(spacing: 2) {
            if let prefix { Text(prefix).foregroundStyle(Theme.muted) }
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .fontWeight(.semibold)
                .foregroundStyle(Theme.ink)
            if let suffix { Text(suffix).foregroundStyle(Theme.muted) }
        }
        .padding(.bottom, 3)
        .frame(maxWidth: width)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.ink).frame(height: Theme.lineWidth)
        }
    }
}

/// Keeps the edge swipe-back gesture working on screens that hide the navigation bar.
extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
