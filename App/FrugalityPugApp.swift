import SwiftUI

@main
struct FrugalityPugApp: App {
    init() {
        Theme.applyNavigationBarAppearance()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .font(Theme.font(.body))
                .tint(Theme.accent)
                .preferredColorScheme(.light)
        }
    }
}
