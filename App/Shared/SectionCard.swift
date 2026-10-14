import SwiftUI

/// A titled ink-outlined paper card. Use for every group of inputs or results.
struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(Theme.font(.headline, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
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
        .font(Theme.font(.body, weight: emphasized ? .semibold : .regular))
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
                .font(Theme.font(.subheadline))
                .foregroundStyle(Theme.muted)
            Text(value)
                .font(Theme.font(size: 36, weight: .bold))
                .foregroundStyle(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            if let footnote {
                Text(footnote)
                    .font(Theme.font(.footnote))
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
            HStack(spacing: 10) {
                InkTag(fill: Theme.accent, size: CGSize(width: 28, height: 28)) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(.white)
                }
                Text(title)
                    .font(Theme.font(.body, weight: .semibold))
                    .foregroundStyle(Theme.ink)
            }
        }
        .buttonStyle(.borderless)
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
