import SwiftUI
import UIKit

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

/// Single source of look and feel. Copied from Priority Pusher's theme: cream paper outlined in thick ink,
/// small deliberate corners, Fredoka type, the icon's cream → apricot glow behind everything.
enum Theme {
    static let cream = Color(hex: 0xFFF4E4)
    static let peach = Color(hex: 0xF9D3A0)
    static let accent = Color(hex: 0xE5484D)       // Priority Pusher's cube red
    static let muted = Color(hex: 0x8A6F66)
    static let ink = Color(hex: 0x2B1E1A)
    static let positive = Color(hex: 0x3E9B5F)
    static let card = Color(hex: 0xFFFAF2)         // warm white paper
    static let outline = Color(hex: 0x1E1614)      // the icon's outline ink
    static let outlineWidth: CGFloat = 2.5
    static let cornerRadius: CGFloat = 10          // cards
    static let tagRadius: CGFloat = 7              // small ink tags
    static let ruled = Color(hex: 0x1E1614).opacity(0.16)

    /// Priority Pusher's tier ramp: cube red cooling toward fawn-brown. Used for tag fills.
    private static let ramp: [UInt32] = [0xE5484D, 0xEA5F57, 0xEE7B63, 0xF08E68, 0xF2A072,
                                         0xE9A974, 0xD9A877, 0xC9A27E, 0xB89884, 0xA89088]
    static func rampColor(_ index: Int) -> Color {
        Color(hex: ramp[min(max(index, 0), ramp.count - 1)])
    }

    /// Fredoka (bundled in App/Resources/Fonts, listed in project.yml). Scales with Dynamic Type;
    /// falls back to the system font if it ever fails to load.
    static func font(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .custom(fontName(weight), size: pointSize(style), relativeTo: style)
    }

    /// Fixed-size Fredoka for big headline figures (they shrink to fit instead of growing).
    static func font(size: CGFloat, weight: Font.Weight) -> Font {
        .custom(fontName(weight), fixedSize: size)
    }

    static func fontName(_ weight: Font.Weight) -> String {
        switch weight {
        case .bold, .heavy, .black: return "Fredoka-Bold"
        case .semibold: return "Fredoka-SemiBold"
        case .medium: return "Fredoka-Medium"
        case .light, .thin, .ultraLight: return "Fredoka-Light"
        default: return "Fredoka-Regular"
        }
    }

    static func pointSize(_ style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline, .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        default: return 17
        }
    }

    /// Navigation bar titles in Fredoka + ink (UIKit-level, so it covers every screen).
    static func applyNavigationBarAppearance() {
        let ink = UIColor(Theme.ink)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        if let large = UIFont(name: "Fredoka-Bold", size: 34) {
            appearance.largeTitleTextAttributes = [.font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: large),
                                                   .foregroundColor: ink]
        }
        if let small = UIFont(name: "Fredoka-SemiBold", size: 17) {
            appearance.titleTextAttributes = [.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: small),
                                              .foregroundColor: ink]
        }
        let bar = UINavigationBar.appearance()
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactAppearance = appearance
    }
}

/// The icon's cream → apricot glow.
struct ThemedBackground: View {
    var body: some View {
        LinearGradient(colors: [Color(hex: 0xFFF4E4), Color(hex: 0xFCE3BF), Color(hex: 0xF9D3A0)],
                       startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

extension View {
    /// Cream paper with the icon's thick ink outline.
    func inkPaper(_ fill: Color = Theme.card, radius: CGFloat = Theme.cornerRadius) -> some View {
        background(fill, in: RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(Theme.outline, lineWidth: Theme.outlineWidth))
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .inkPaper()
    }
}

extension View {
    /// Ink-outlined paper card used for every grouped block of content.
    func card() -> some View {
        modifier(CardStyle())
    }
}

/// Small square-cornered tag outlined in ink, like the 1/2/3 chips on Priority Pusher's icon.
struct InkTag<Label: View>: View {
    var fill: Color
    var size = CGSize(width: 36, height: 32)
    @ViewBuilder var label: () -> Label

    var body: some View {
        label()
            .frame(minWidth: size.width, minHeight: size.height)
            .background(fill, in: RoundedRectangle(cornerRadius: Theme.tagRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.tagRadius).strokeBorder(Theme.outline, lineWidth: 2))
    }
}

/// Dashed rule between rows, as on Priority Pusher's pad.
struct RuledLine: View {
    var body: some View {
        Line()
            .stroke(Theme.ruled, style: StrokeStyle(lineWidth: 1.2, dash: [5, 5]))
            .frame(height: 1)
            .accessibilityHidden(true)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: CGPoint(x: rect.minX, y: rect.midY))
                p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            }
        }
    }
}
