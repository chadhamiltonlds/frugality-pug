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

/// Single source of look and feel. Matches Priority Pusher: warm cream and peach, white rounded cards, red accent.
enum Theme {
    static let cream = Color(hex: 0xFFF4E4)
    static let peach = Color(hex: 0xF9D3A0)
    static let accent = Color(hex: 0xE5484D)
    static let muted = Color(hex: 0x8A6F66)
    static let ink = Color(hex: 0x2B1E1A)
    static let positive = Color(hex: 0x3E9B5F)
    static let card = Color.white
    static let cornerRadius: CGFloat = 20
}

struct ThemedBackground: View {
    var body: some View {
        LinearGradient(colors: [Theme.peach, Theme.cream], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .shadow(color: Theme.ink.opacity(0.08), radius: 8, y: 3)
    }
}

extension View {
    /// White rounded card used for every grouped block of content.
    func card() -> some View {
        modifier(CardStyle())
    }
}
