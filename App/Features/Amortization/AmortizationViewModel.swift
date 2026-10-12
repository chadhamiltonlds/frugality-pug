import Foundation
import FrugalityCore

@MainActor
final class AmortizationViewModel: ObservableObject {
    @Published var input: AmortizationInput {
        didSet {
            // Keep the check year inside the term when the term is shortened.
            // (Assigning inside didSet does not re-run the observer.)
            if input.checkAfterYears > input.termYears {
                input.checkAfterYears = input.termYears
            }
            JSONStore.save(input, key: .amortization)
            result = AmortizationCalculator.schedule(input)
        }
    }
    @Published private(set) var result: AmortizationResult

    init() {
        let saved = JSONStore.load(AmortizationInput.self, key: .amortization) ?? AmortizationInput()
        input = saved
        result = AmortizationCalculator.schedule(saved)
    }
}
