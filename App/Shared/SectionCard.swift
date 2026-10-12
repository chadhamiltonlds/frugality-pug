import SwiftUI

/// A titled white card. Use for every group of inputs or results.
struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.muted)
            content
        }
        .card()
    }
}

/// One label/value line in a results card.
struct ResultRow: View {
    let label: String
    let value: String
    var emphasized = false
    var valueColor: Color = Theme.ink

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(Theme.ink)
            Spacer()
            Text(value)
                .foregroundStyle(valueColor)
                .monospacedDigit()
        }
        .font(emphasized ? .body.weight(.bold) : .body)
    }
}

/// The big headline figure at the top of a results card.
struct HeadlineNumber: View {
    let caption: String
    let value: String
    var color: Color = Theme.positive
    var footnote: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(caption)
                .font(.footnote)
                .foregroundStyle(Theme.muted)
            Text(value)
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            if let footnote {
                Text(footnote)
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
            }
        }
    }
}

/// Standard screen frame: themed background, scrolling stack of cards, inline title.
struct CalculatorScreen<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            ThemedBackground()
            ScrollView {
                VStack(spacing: 16) {
                    content
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// "+ Add …" button at the bottom of an editable list.
struct AddRowButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "plus.circle.fill")
                .font(.body.weight(.semibold))
        }
        .buttonStyle(.borderless)
        .tint(Theme.accent)
    }
}

/// Trash button for a row in an editable list.
struct DeleteRowButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "trash")
        }
        .buttonStyle(.borderless)
        .foregroundStyle(Theme.accent)
        .accessibilityLabel("Delete")
    }
}
