import Foundation
@testable import FrugalityCore

/// Exact Decimal from text. Avoids float literals, which pass through Double.
func dec(_ text: String) -> Decimal {
    Decimal(string: text, locale: Locale(identifier: "en_US_POSIX"))!
}

enum Fixtures {
    static let data: TaxYearData = {
        do { return try TaxYearData.load(year: 2026) } catch { fatalError("Tax data failed to load: \(error)") }
    }()
}
