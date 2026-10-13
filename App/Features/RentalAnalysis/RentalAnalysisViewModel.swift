import Foundation
import FrugalityCore

@MainActor
final class RentalAnalysisViewModel: ObservableObject {
    @Published var input: RentalAnalysisInput {
        didSet {
            JSONStore.save(input, key: .rentalAnalysis)
            result = RentalAnalysisCalculator.analyze(input)
        }
    }
    @Published private(set) var result: RentalAnalysisResult

    init() {
        let saved = JSONStore.load(RentalAnalysisInput.self, key: .rentalAnalysis) ?? RentalAnalysisInput()
        input = saved
        result = RentalAnalysisCalculator.analyze(saved)
    }
}
