import Foundation
import FrugalityCore

@MainActor
final class RetirementViewModel: ObservableObject {
    @Published var input: RetirementInput {
        didSet {
            JSONStore.save(input, key: .retirement)
            result = RetirementCalculator.project(input)
        }
    }
    @Published private(set) var result: RetirementResult

    init() {
        let saved = JSONStore.load(RetirementInput.self, key: .retirement) ?? RetirementInput()
        input = saved
        result = RetirementCalculator.project(saved)
    }
}
