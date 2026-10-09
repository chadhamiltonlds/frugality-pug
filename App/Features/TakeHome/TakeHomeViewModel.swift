import Foundation
import FrugalityCore

@MainActor
final class TakeHomeViewModel: ObservableObject {
    @Published var input = TakeHomeInput(grossAnnual: 0, payFrequency: .monthly, filingStatus: .single, stateCode: "OK")
    @Published private(set) var result: TakeHomeResult?
    @Published private(set) var errorMessage: String?

    let states: [StateOption]
    let taxYear: Int
    private let data: TaxYearData?

    init() {
        do {
            let loaded = try TaxYearData.load()
            data = loaded
            states = loaded.stateOptions
            taxYear = loaded.year
        } catch {
            data = nil
            states = []
            taxYear = TaxYearData.latestYear
            errorMessage = "Tax data could not be loaded."
        }
        recalculate()
    }

    func recalculate() {
        guard let data else { return }
        guard input.grossAnnual > 0 else {
            result = nil
            errorMessage = nil
            return
        }
        do {
            result = try TakeHomeCalculator.calculate(input, data: data)
            errorMessage = nil
        } catch {
            result = nil
            errorMessage = "Could not calculate for that state."
        }
    }
}
