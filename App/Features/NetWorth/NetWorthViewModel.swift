import Foundation
import FrugalityCore

@MainActor
final class NetWorthViewModel: ObservableObject {
    @Published var input: NetWorthInput {
        didSet {
            JSONStore.save(input, key: .netWorth)
            result = NetWorthCalculator.summarize(input)
        }
    }
    @Published private(set) var result: NetWorthResult

    init() {
        let saved = JSONStore.load(NetWorthInput.self, key: .netWorth) ?? NetWorthInput()
        input = saved
        result = NetWorthCalculator.summarize(saved)
    }

    func addAsset() { input.assets.append(AssetItem()) }
    func addDebt() { input.debts.append(DebtItem()) }
    func deleteAsset(_ id: UUID) { input.assets.removeAll { $0.id == id } }
    func deleteDebt(_ id: UUID) { input.debts.removeAll { $0.id == id } }
}
