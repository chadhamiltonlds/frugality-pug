import XCTest
@testable import FrugalityCore

/// Expected values from an independent Python (Decimal) reference of the same method.
final class RetirementCalculatorTests: XCTestCase {
    func testOneYearOfMonthlyCompounding() {
        let r = RetirementCalculator.project(RetirementInput(
            currentAge: 30, retirementAge: 31, currentSavings: 10_000,
            contributionGrowthRate: 0, annualReturn: dec("0.07"), inflationRate: dec("0.03")
        ))
        XCTAssertEqual(r.finalBalance, dec("10722.90"))
        XCTAssertEqual(r.finalBalanceInTodayDollars, dec("10410.58"))
        XCTAssertEqual(r.years.count, 1)
        XCTAssertEqual(r.years[0].age, 31)
    }

    func testZeroReturnIsJustContributions() {
        let r = RetirementCalculator.project(RetirementInput(
            currentAge: 30, retirementAge: 40, monthlyContribution: 500,
            contributionGrowthRate: 0, annualReturn: 0, inflationRate: 0
        ))
        XCTAssertEqual(r.finalBalance, 60_000)
        XCTAssertEqual(r.totalContributed, 60_000)
        XCTAssertEqual(r.totalGrowth, 0)
    }

    func testTypicalProjection() {
        let r = RetirementCalculator.project(RetirementInput(
            currentAge: 35, retirementAge: 65, currentSavings: 50_000,
            monthlyContribution: 1_000, employerMonthlyContribution: 300
        ))
        assertClose(r.finalBalance, dec("2348411.55"))
        assertClose(r.finalBalanceInTodayDollars, dec("967514.47"))
        assertClose(r.totalContributed, dec("682862.04"))
        assertClose(r.annualIncomeInTodayDollars, dec("38700.58"))
        XCTAssertEqual(r.years.count, 30)
        XCTAssertEqual(r.years[9].age, 45)
        assertClose(r.years[9].balance, dec("344084.34"))
    }

    func testAlreadyAtRetirementAge() {
        let r = RetirementCalculator.project(RetirementInput(currentAge: 70, retirementAge: 65, currentSavings: 500_000))
        XCTAssertTrue(r.years.isEmpty)
        XCTAssertEqual(r.finalBalance, 500_000)
        XCTAssertEqual(r.finalBalanceInTodayDollars, 500_000)
        XCTAssertEqual(r.annualIncome, 20_000)
    }

    func testNegativeInputsAreTreatedAsZero() {
        let r = RetirementCalculator.project(RetirementInput(
            currentAge: 30, retirementAge: 31, currentSavings: -1_000, monthlyContribution: -100, annualReturn: 0
        ))
        XCTAssertEqual(r.finalBalance, 0)
    }
}
