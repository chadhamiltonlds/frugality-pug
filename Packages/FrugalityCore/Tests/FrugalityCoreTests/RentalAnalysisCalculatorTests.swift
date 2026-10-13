import XCTest
@testable import FrugalityCore

/// Expected values from an independent Python (Decimal) reference of the same method.
final class RentalAnalysisCalculatorTests: XCTestCase {
    func testDefaultsAreANegativeCashFlowDeal() {
        let r = RentalAnalysisCalculator.analyze(RentalAnalysisInput())
        XCTAssertEqual(r.monthlyMortgagePayment, dec("1496.93"))
        XCTAssertEqual(r.cashInvested, 84_000)
        XCTAssertEqual(r.operatingExpenses, 929)
        XCTAssertEqual(r.netOperatingIncome, 1_351)
        XCTAssertEqual(r.cashFlow, dec("-145.93"))
        XCTAssertEqual(r.capRate?.rounded(toPlaces: 4, mode: .plain), dec("0.0540"))
        XCTAssertEqual(r.debtCoverageRatio?.rounded(toPlaces: 4, mode: .plain), dec("0.9025"))
        XCTAssertEqual(r.breakEvenOccupancy?.rounded(toPlaces: 4, mode: .plain), dec("1.0108"))
        assertClose(r.firstYearPrincipalPaydown, dec("2285.57"))
        XCTAssertEqual(r.verdict, .weak)
    }

    func testStrongDealPassesEveryCheck() {
        let r = RentalAnalysisCalculator.analyze(RentalAnalysisInput(
            purchasePrice: 150_000, monthlyRent: 1_800, propertyTaxAnnual: 1_800, insuranceAnnual: 1_000
        ))
        XCTAssertEqual(r.cashFlow, dec("350.20"))
        XCTAssertEqual(r.cashOnCash?.rounded(toPlaces: 4, mode: .plain), dec("0.1001"))
        XCTAssertEqual(r.capRate?.rounded(toPlaces: 4, mode: .plain), dec("0.0879"))
        XCTAssertEqual(r.debtCoverageRatio?.rounded(toPlaces: 4, mode: .plain), dec("1.4679"))
        XCTAssertEqual(r.grossRentMultiplier?.rounded(toPlaces: 4, mode: .plain), dec("6.9444"))
        XCTAssertEqual(r.firstYearTotalReturn?.rounded(toPlaces: 4, mode: .plain), dec("0.2344"))
        XCTAssertTrue(r.checks.allSatisfy(\.passed))
        XCTAssertEqual(r.verdict, .good)
    }

    func testCashPurchaseHasNoDebtCoverageRatio() {
        let r = RentalAnalysisCalculator.analyze(RentalAnalysisInput(
            purchasePrice: 200_000, downPaymentRate: 1, closingCostRate: 0, monthlyRent: 2_000, vacancyRate: 0,
            propertyTaxAnnual: 2_400, insuranceAnnual: 1_200, maintenanceRate: 0, capexRate: 0, managementRate: 0
        ))
        XCTAssertEqual(r.loanAmount, 0)
        XCTAssertEqual(r.monthlyMortgagePayment, 0)
        XCTAssertNil(r.debtCoverageRatio)
        XCTAssertEqual(r.cashFlow, 1_700)
        XCTAssertEqual(r.capRate, dec("0.102"))
        XCTAssertEqual(r.firstYearPrincipalPaydown, 0)
        XCTAssertTrue(r.checks.first { $0.kind == .debtCoverage }!.passed)
        XCTAssertEqual(r.verdict, .good)
    }

    func testBorderlineWhenSomeChecksFail() {
        // Positive cash flow, but cap rate and cash-on-cash miss tougher targets.
        let r = RentalAnalysisCalculator.analyze(RentalAnalysisInput(
            purchasePrice: 150_000, monthlyRent: 1_800, propertyTaxAnnual: 1_800, insuranceAnnual: 1_000,
            targetCashOnCash: dec("0.15"), targetCapRate: dec("0.10")
        ))
        XCTAssertEqual(r.checks.filter(\.passed).count, 3)
        XCTAssertEqual(r.verdict, .borderline)
    }

    func testBreakEvenCashFlowIsNeverGood() {
        // All checks pass against zero targets, but $0 cash flow can't be "good".
        let r = RentalAnalysisCalculator.analyze(RentalAnalysisInput(
            purchasePrice: 200_000, downPaymentRate: 1, closingCostRate: 0, monthlyRent: 1_000, vacancyRate: 0,
            propertyTaxAnnual: 12_000, insuranceAnnual: 0, maintenanceRate: 0, capexRate: 0, managementRate: 0,
            targetMonthlyCashFlow: 0, targetCashOnCash: 0, targetCapRate: 0, targetRentToPrice: dec("0.005")
        ))
        XCTAssertEqual(r.cashFlow, 0)
        XCTAssertTrue(r.checks.allSatisfy(\.passed))
        XCTAssertEqual(r.verdict, .borderline)
    }

    func testZeroPriceAndRentDoNotCrash() {
        let r = RentalAnalysisCalculator.analyze(RentalAnalysisInput(purchasePrice: 0, closingCostRate: 0, monthlyRent: 0))
        XCTAssertNil(r.capRate)
        XCTAssertNil(r.rentToPrice)
        XCTAssertNil(r.grossRentMultiplier)
        XCTAssertNil(r.breakEvenOccupancy)
        XCTAssertNil(r.cashOnCash)
        XCTAssertNil(r.firstYearTotalReturn)
        XCTAssertEqual(r.verdict, .weak)
    }
}
