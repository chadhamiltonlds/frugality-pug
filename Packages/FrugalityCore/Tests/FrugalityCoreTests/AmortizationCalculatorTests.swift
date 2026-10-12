import XCTest
@testable import FrugalityCore

/// Expected values from an independent Python (Decimal) reference; the 200k/6%/30y figures
/// match standard published amortization tables.
final class AmortizationCalculatorTests: XCTestCase {
    func testStandardThirtyYearLoan() {
        let r = AmortizationCalculator.schedule(AmortizationInput(
            loanAmount: 200_000, annualRate: dec("0.06"), termYears: 30, checkAfterYears: 5
        ))
        XCTAssertEqual(r.monthlyPayment, dec("1199.10"))
        XCTAssertEqual(r.payoffMonths, 360)
        XCTAssertEqual(r.years.count, 30)
        assertClose(r.totalInterest, dec("231676.38"))
        assertClose(r.balanceAtCheck, dec("186108.71"))
        XCTAssertEqual(r.paidOffShareAtCheck.rounded(toPlaces: 4, mode: .plain), dec("0.0695"))
        assertClose(r.years[0].interestPaid, dec("11933.19"))
        assertClose(r.years[0].principalPaid, dec("2456.02"))
        assertClose(r.years[4].balance, dec("186108.71"))
        XCTAssertEqual(r.years[29].balance, 0)
        XCTAssertEqual(r.interestSaved, 0)
    }

    func testCheckAtEndOfTermIsFullyPaid() {
        let r = AmortizationCalculator.schedule(AmortizationInput(
            loanAmount: 320_000, annualRate: dec("0.065"), termYears: 30, checkAfterYears: 30
        ))
        XCTAssertEqual(r.balanceAtCheck, 0)
        XCTAssertEqual(r.paidOffShareAtCheck, 1)
    }

    func testExtraPaymentShortensLoanAndSavesInterest() {
        let r = AmortizationCalculator.schedule(AmortizationInput(
            loanAmount: 200_000, annualRate: dec("0.06"), termYears: 30, extraMonthlyPayment: 200, checkAfterYears: 10
        ))
        XCTAssertEqual(r.payoffMonths, 252)
        XCTAssertEqual(r.years.count, 21)
        assertClose(r.totalInterest, dec("151875.87"))
        assertClose(r.interestSaved, dec("79800.51"))
        assertClose(r.balanceAtCheck, dec("134595.58"))
        XCTAssertEqual(r.years.last?.balance, 0)
    }

    func testZeroRate() {
        let r = AmortizationCalculator.schedule(AmortizationInput(
            loanAmount: 12_000, annualRate: 0, termYears: 1, checkAfterYears: 1
        ))
        XCTAssertEqual(r.monthlyPayment, 1_000)
        XCTAssertEqual(r.totalInterest, 0)
        XCTAssertEqual(r.balanceAtCheck, 0)
        XCTAssertEqual(r.paidOffShareAtCheck, 1)
    }

    func testCheckAtYearZeroIsTheFullLoan() {
        let r = AmortizationCalculator.schedule(AmortizationInput(loanAmount: 100_000, checkAfterYears: 0))
        XCTAssertEqual(r.balanceAtCheck, 100_000)
        XCTAssertEqual(r.paidOffShareAtCheck, 0)
    }

    func testCheckAfterPayoffIsZero() {
        let r = AmortizationCalculator.schedule(AmortizationInput(
            loanAmount: 200_000, annualRate: dec("0.06"), termYears: 30, extraMonthlyPayment: 200, checkAfterYears: 25
        ))
        XCTAssertEqual(r.balanceAtCheck, 0)
        XCTAssertEqual(r.paidOffShareAtCheck, 1)
    }

    func testNoLoan() {
        let r = AmortizationCalculator.schedule(AmortizationInput(loanAmount: 0))
        XCTAssertEqual(r.monthlyPayment, 0)
        XCTAssertEqual(r.payoffMonths, 0)
        XCTAssertTrue(r.years.isEmpty)
        XCTAssertEqual(r.paidOffShareAtCheck, 0)
    }

    func testOutOfRangeInputsAreClamped() {
        let r = AmortizationCalculator.schedule(AmortizationInput(
            loanAmount: 100_000, annualRate: dec("-0.05"), termYears: 500, extraMonthlyPayment: -50, checkAfterYears: 900
        ))
        XCTAssertEqual(r.payoffMonths, 600)
        XCTAssertEqual(r.totalInterest, 0)
        XCTAssertEqual(r.balanceAtCheck, 0)
    }
}
