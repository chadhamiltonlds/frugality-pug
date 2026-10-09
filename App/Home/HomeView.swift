import SwiftUI

struct HomeView: View {
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ZStack {
                ThemedBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Frugality Pug")
                                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                                .foregroundStyle(Theme.ink)
                            Text("Plan it. Budget it. Keep it.")
                                .foregroundStyle(Theme.muted)
                        }
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(Feature.allCases) { feature in
                                NavigationLink(value: feature) {
                                    FeatureTile(feature: feature)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationDestination(for: Feature.self) { feature in
                feature.destination
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private struct FeatureTile: View {
    let feature: Feature

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: feature.symbol)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Theme.accent, in: Circle())
            Text(feature.title)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.ink)
            Text(feature.subtitle)
                .font(.footnote)
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.leading)
            if !feature.isAvailable {
                Text("Coming soon")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.cream, in: Capsule())
            }
        }
        .card()
    }
}
