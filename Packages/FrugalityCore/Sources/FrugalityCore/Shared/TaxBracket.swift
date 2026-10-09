import Foundation

/// One step of a progressive tax schedule: `rate` applies to income above `from`
/// up to the next bracket's `from`.
struct TaxBracket: Decodable, Equatable {
    var from: Decimal
    var rate: Decimal
}

extension TaxBracket {
    private enum CodingKeys: String, CodingKey {
        case from, rate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            from: try container.decodeDecimal(forKey: .from),
            rate: try container.decodeDecimal(forKey: .rate)
        )
    }
}

/// Tax on `income` under a progressive schedule. `brackets` must be sorted ascending by `from`.
/// Returns 0 for zero or negative income and for an empty schedule.
func progressiveTax(income: Decimal, brackets: [TaxBracket]) -> Decimal {
    guard income > 0 else { return 0 }
    var tax: Decimal = 0
    for (index, bracket) in brackets.enumerated() {
        if income <= bracket.from { break }
        let top: Decimal
        if index + 1 < brackets.count {
            top = min(income, brackets[index + 1].from)
        } else {
            top = income
        }
        tax += (top - bracket.from) * bracket.rate
    }
    return tax
}
