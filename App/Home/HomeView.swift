import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @State private var order: [Feature] = Feature.ordered(savedIDs: JSONStore.load([String].self, key: .homeOrder) ?? [])
    @State private var dragging: Feature?

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
                            ForEach(order) { feature in
                                NavigationLink(value: feature) {
                                    FeatureTile(feature: feature)
                                }
                                .buttonStyle(.plain)
                                .onDrag {
                                    dragging = feature
                                    return NSItemProvider(object: feature.rawValue as NSString)
                                }
                                .onDrop(of: [.text], delegate: ReorderDropDelegate(
                                    target: feature, order: $order, dragging: $dragging
                                ))
                            }
                        }
                        Text("Press and hold a calculator to move it.")
                            .font(.footnote)
                            .foregroundStyle(Theme.muted)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(16)
                }
            }
            .navigationDestination(for: Feature.self) { feature in
                feature.destination
            }
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: order) { _, newOrder in
                JSONStore.save(newOrder.map(\.rawValue), key: .homeOrder)
            }
        }
    }
}

/// Moves the dragged tile into the hovered tile's place as the finger passes over it.
private struct ReorderDropDelegate: DropDelegate {
    let target: Feature
    @Binding var order: [Feature]
    @Binding var dragging: Feature?

    func dropEntered(info: DropInfo) {
        guard let dragging, dragging != target,
              let from = order.firstIndex(of: dragging),
              let to = order.firstIndex(of: target) else { return }
        withAnimation(.snappy) {
            order.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        return true
    }
}

/// Every tile is the same size: fixed height, title on one line, subtitle on up to two.
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
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(feature.subtitle)
                .font(.footnote)
                .foregroundStyle(Theme.muted)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 130, maxHeight: 130, alignment: .topLeading)
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .card()
        .contentShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}
