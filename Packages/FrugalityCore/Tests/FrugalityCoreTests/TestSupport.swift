import Foundation
import XCTest
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

/// For long month-by-month simulations, where last-digit differences in Decimal math can move a cent.
func assertClose(_ actual: Decimal, _ expected: Decimal, tolerance: Decimal = dec("0.05"),
                 file: StaticString = #filePath, line: UInt = #line) {
    let difference = actual > expected ? actual - expected : expected - actual
    XCTAssertLessThanOrEqual(difference, tolerance, "\(actual) is not within \(tolerance) of \(expected)", file: file, line: line)
}
