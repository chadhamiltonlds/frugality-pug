import XCTest
@testable import FrugalityCore

final class MortgageTests: XCTestCase {
    func testStandardThirtyYearPayment() {
        XCTAssertEqual(Mortgage.monthlyPayment(principal: 200_000, annualRate: dec("0.06"), years: 30).roundedToCents(), dec("1199.10"))
    }

    func testZeroRateSplitsPrincipalEvenly() {
        XCTAssertEqual(Mortgage.monthlyPayment(principal: 200_000, annualRate: 0, years: 30).roundedToCents(), dec("555.56"))
    }

    func testNoPrincipalMeansNoPayment() {
        XCTAssertEqual(Mortgage.monthlyPayment(principal: 0, annualRate: dec("0.06"), years: 30), 0)
        XCTAssertEqual(Mortgage.monthlyPayment(principal: -5, annualRate: dec("0.06"), years: 30), 0)
    }

    func testLoanPaysOffExactlyOverItsTerm() {
        let payment = Mortgage.monthlyPayment(principal: 100_000, annualRate: dec("0.05"), years: 15)
        var balance: Decimal = 100_000
        for _ in 0..<180 {
            balance = Mortgage.step(balance: balance, annualRate: dec("0.05"), payment: payment).balance
        }
        assertClose(balance, 0, tolerance: dec("0.01"))
    }

    func testStepOnPaidOffLoanDoesNothing() {
        let step = Mortgage.step(balance: 0, annualRate: dec("0.05"), payment: 500)
        XCTAssertEqual(step.interest, 0)
        XCTAssertEqual(step.principal, 0)
        XCTAssertEqual(step.balance, 0)
    }
}
