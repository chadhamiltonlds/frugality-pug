import SwiftUI

extension Color {
    /// 0xRRGGBB
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

/// Single source of look and feel: "the pug's pocket ledger".
/// Priority Pusher's cream, ink and red, laid out as paper slips and receipts on graph paper.
/// Corners stay nearly square, edges are inked, and shadows are hard offsets rather than soft blurs.
enum Theme {
    // Palette
    static let cream = Color(hex: 0xFFF4E4)      // page
    static let peach = Color(hex: 0xF9D3A0)      // graph lines, quiet fills
    static let paper = Color(hex: 0xFFFCF6)      // slips and receipts
    static let shadow = Color(hex: 0xEDB57C)     // hard offset under slips
    static let accent = Color(hex: 0xE5484D)     // red: actions, losses
    static let muted = Color(hex: 0x8A6F66)      // secondary text
    static let ink = Color(hex: 0x2B1E1A)        // text and outlines
    static let positive = Color(hex: 0x3E9B5F)   // money green: gains
    static let coin = Color(hex: 0xE0A526)       // coin mustard: highlights

    // Shape
    static let cornerRadius: CGFloat = 3
    static let lineWidth: CGFloat = 1.5
    static let shadowOffset: CGFloat = 4

    // Type: SF Pro. Titles and big figures are black weight, expanded width.
    static func display(_ style: Font.TextStyle) -> Font {
        .system(style, weight: .black).width(.expanded)
    }
    static let sectionTitle = Font.system(.subheadline, weight: .heavy).width(.expanded)
}

/// Flat cream page with faint graph-paper lines.
struct ThemedBackground: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 22
            var grid = Path()
            var x: CGFloat = 0
            while x <= size.width {
                grid.move(to: CGPoint(x: x, y: 0))
                grid.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }
            var y: CGFloat = 0
            while y <= size.height {
                grid.move(to: CGPoint(x: 0, y: y))
                grid.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }
            context.stroke(grid, with: .color(Theme.peach.opacity(0.55)), lineWidth: 0.5)
        }
        .background(Theme.cream)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// A paper slip: inked outline, nearly square corners, hard offset shadow.
/// `shape` lets receipts use a torn edge with the same outline and shadow.
struct SlipBackground<S: Shape>: View {
    let shape: S
    var pressed = false

    var body: some View {
        ZStack {
            shape
                .fill(Theme.shadow)
                .offset(x: pressed ? 1 : Theme.shadowOffset, y: pressed ? 1 : Theme.shadowOffset)
            shape
                .fill(Theme.paper)
                .offset(x: pressed ? Theme.shadowOffset - 1 : 0, y: pressed ? Theme.shadowOffset - 1 : 0)
            shape
                .stroke(Theme.ink, lineWidth: Theme.lineWidth)
                .offset(x: pressed ? Theme.shadowOffset - 1 : 0, y: pressed ? Theme.shadowOffset - 1 : 0)
        }
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SlipBackground(shape: RoundedRectangle(cornerRadius: Theme.cornerRadius)))
    }
}

extension View {
    /// Paper slip used for every grouped block of content.
    func card() -> some View {
        modifier(CardStyle())
    }
}

/// Rectangle whose bottom edge is a torn zig-zag, like a register receipt.
struct ReceiptShape: Shape {
    var toothWidth: CGFloat = 12
    var toothHeight: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        let teeth = max(1, Int((rect.width / toothWidth).rounded()))
        let width = rect.width / CGFloat(teeth)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - toothHeight))
        for index in stride(from: teeth, to: 0, by: -1) {
            let right = rect.minX + CGFloat(index) * width
            path.addLine(to: CGPoint(x: right - width / 2, y: rect.maxY))
            path.addLine(to: CGPoint(x: right - width, y: rect.maxY - toothHeight))
        }
        path.closeSubpath()
        return path
    }
}

/// Pressing a slip pushes it down onto its shadow.
struct SlipPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .offset(x: configuration.isPressed ? Theme.shadowOffset - 1 : 0,
                    y: configuration.isPressed ? Theme.shadowOffset - 1 : 0)
            .background(SlipBackground(shape: RoundedRectangle(cornerRadius: Theme.cornerRadius),
                                       pressed: configuration.isPressed))
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}
