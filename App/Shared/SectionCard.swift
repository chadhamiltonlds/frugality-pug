import SwiftUI

/// A titled paper slip. Use for every group of inputs.
struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SlipTitle(title)
            content
        }
        .card()
    }
}

/// A titled receipt with a torn bottom edge. Use for results.
struct ReceiptCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        let shape = ReceiptShape()
        VStack(alignment: .leading, spacing: 12) {
            SlipTitle(title)
            content
        }
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 16 + shape.toothHeight, trailing: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SlipBackground(shape: shape))
    }
}

/// Slip heading with a dashed tear line under it.
private struct SlipTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
            DashedRule()
        }
    }
}

/// Dashed separator, like the perforation on a receipt.
struct DashedRule: View {
    var body: some View {
        Line()
            .stroke(Theme.ink.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            .frame(height: 1)
            .accessibilityHidden(true)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return path
        }
    }
}

/// One label/value line, joined by a dotted leader like a price list.
struct ResultRow: View {
    let label: String
    let value: String
    var emphasized = false
    var valueColor: Color = Theme.ink

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 6) {
            Text(label)
                .foregroundStyle(Theme.ink)
                .layoutPriority(1)
            DottedLeader()
            Text(value)
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .fixedSize()
                .layoutPriority(2)
        }
        .font(emphasized ? .body.weight(.bold) : .body)
        .accessibilityElement(children: .combine)
    }
}

private struct DottedLeader: View {
    var body: some View {
        Dots()
            .stroke(Theme.muted.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [0, 5]))
            .frame(minWidth: 10, maxWidth: .infinity)
            .frame(height: 2)
            .alignmentGuide(.lastTextBaseline) { d in d[.bottom] }
            .accessibilityHidden(true)
    }

    private struct Dots: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX + 1, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX - 1, y: rect.midY))
            return path
        }
    }
}

/// The big figure at the top of a results receipt.
struct HeadlineNumber: View {
    let caption: String
    let value: String
    var color: Color = Theme.positive
    var footnote: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(caption)
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
            Text(value)
                .font(Theme.display(.largeTitle))
                .foregroundStyle(color)
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            if let footnote {
                Text(footnote)
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// A small table: first column left-aligned, the rest right-aligned numbers.
struct LedgerTable: View {
    struct Row: Identifiable {
        let id: Int
        let cells: [String]
        var emphasized = false
    }

    let headers: [String]
    let rows: [Row]

    var body: some View {
        Grid(alignment: .trailing, horizontalSpacing: 10, verticalSpacing: 6) {
            GridRow {
                ForEach(headers.indices, id: \.self) { index in
                    Text(headers[index])
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                        .gridColumnAlignment(index == 0 ? .leading : .trailing)
                }
            }
            DashedRule()
                .gridCellUnsizedAxes(.horizontal)
            ForEach(rows) { row in
                GridRow {
                    ForEach(row.cells.indices, id: \.self) { index in
                        Text(row.cells[index])
                            .font(row.emphasized ? .subheadline.weight(.heavy) : .subheadline)
                            .foregroundStyle(row.emphasized ? Theme.accent : Theme.ink)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
            }
        }
    }
}

/// Standard screen frame: graph-paper page, square back button, big left-aligned title,
/// then a scrolling stack of slips. The system navigation bar is hidden.
struct CalculatorScreen<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            ThemedBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.bold))
                                .foregroundStyle(Theme.ink)
                                .frame(width: 40, height: 40)
                                .background(Theme.paper)
                                .overlay(Rectangle().stroke(Theme.ink, lineWidth: Theme.lineWidth))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Back to home")
                        Text(title)
                            .font(Theme.display(.largeTitle))
                            .foregroundStyle(Theme.ink)
                            .minimumScaleFactor(0.6)
                            .lineLimit(2)
                            .accessibilityAddTraits(.isHeader)
                    }
                    content
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .toggleStyle(CheckboxToggleStyle())
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// "+ Add …" button at the bottom of an editable list.
struct AddRowButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "plus.square.fill")
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
