import Foundation
import FrugalityCore

@MainActor
final class SnowballViewModel: ObservableObject {
    @Published var input: SnowballInput {
        didSet {
            JSONStore.save(input, key: .snowball)
            result = SnowballCalculator.simulate(input)
        }
    }
    @Published private(set) var result: SnowballResult

    init() {
        let saved = JSONStore.load(SnowballInput.self, key: .snowball) ?? SnowballInput()
        input = saved
        result = SnowballCalculator.simulate(saved)
    }
}
