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
    private let socialSecurityData = try? SocialSecurityData.load()

    init() {
        let saved = JSONStore.load(RetirementInput.self, key: .retirement) ?? RetirementInput()
        input = saved
        result = RetirementCalculator.project(saved)
    }

    /// Nil when the Social Security add-on is off (or its data couldn't load).
    var socialSecurity: SocialSecurityEstimate? {
        guard let settings = input.socialSecurity, settings.isOn, let data = socialSecurityData else { return nil }
        return data.estimate(settings, birthYear: TaxYearData.latestYear - input.currentAge)
    }

    var totalMonthlyIncome: Decimal {
        RetirementCalculator.totalMonthlyIncome(result, socialSecurity: socialSecurity)
    }
}
