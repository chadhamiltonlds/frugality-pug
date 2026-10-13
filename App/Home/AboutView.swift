import SwiftUI

/// About & disclaimer sheet, opened from the home screen footer.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "Version \(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ThemedBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 96, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .accessibilityHidden(true)
                        SectionCard(title: "Disclaimer") {
                            Text("These calculators were built with the help of AI. They're estimates meant to be a fun way to dream about a possible future, not financial, tax, legal or investment advice.")
                            Text("Results are only as good as the numbers you enter and the simplified assumptions behind them; each screen notes what it leaves out. Tax figures are 2026 estimates and may be incomplete or out of date.")
                            Text("Before making a real money decision, double-check the numbers and talk with a qualified professional.")
                        }
                        SectionCard(title: "Your data") {
                            Text("Everything you enter stays on this phone. There are no accounts, no tracking and no ads.")
                        }
                        Text(version)
                            .font(.footnote)
                            .foregroundStyle(Theme.muted)
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(16)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(Theme.accent)
    }
}
