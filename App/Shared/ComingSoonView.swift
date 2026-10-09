import SwiftUI

struct ComingSoonView: View {
    let title: String

    var body: some View {
        ZStack {
            ThemedBackground()
            VStack(spacing: 12) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.accent)
                Text("Coming soon")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.ink)
                Text("\(title) is being built.")
                    .foregroundStyle(Theme.muted)
            }
            .card()
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
