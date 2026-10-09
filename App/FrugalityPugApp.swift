import SwiftUI

@main
struct FrugalityPugApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .tint(Theme.accent)
                .preferredColorScheme(.light)
        }
    }
}
