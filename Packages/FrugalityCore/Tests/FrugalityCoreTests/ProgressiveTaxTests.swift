import XCTest
@testable import FrugalityCore

final class ProgressiveTaxTests: XCTestCase {
    private let brackets = [
        TaxBracket(from: 0, rate: dec("0.10")),
        TaxBracket(from: 1000, rate: dec("0.20")),
        TaxBracket(from: 5000, rate: dec("0.30"))
    ]

    func testZeroAndNegativeIncomeOwesNothing() {
        XCTAssertEqual(progressiveTax(income: 0, brackets: brackets), 0)
        XCTAssertEqual(progressiveTax(income: -500, brackets: brackets), 0)
    }

    func testIncomeInsideFirstBracket() {
        XCTAssertEqual(progressiveTax(income: 500, brackets: brackets), 50)
    }

    func testIncomeExactlyOnBoundary() {
        XCTAssertEqual(progressiveTax(income: 1000, brackets: brackets), 100)
    }

    func testIncomeSpanningAllBrackets() {
        // 100 + 800 + 30% of 1000
        XCTAssertEqual(progressiveTax(income: 6000, brackets: brackets), 1200)
    }

    func testZeroRateBottomBracket() {
        let zeroFirst = [
            TaxBracket(from: 0, rate: 0),
            TaxBracket(from: 2000, rate: dec("0.05"))
        ]
        XCTAssertEqual(progressiveTax(income: 1500, brackets: zeroFirst), 0)
        XCTAssertEqual(progressiveTax(income: 3000, brackets: zeroFirst), 50)
    }

    func testEmptyScheduleOwesNothing() {
        XCTAssertEqual(progressiveTax(income: 10_000, brackets: []), 0)
    }
}
