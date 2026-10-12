import XCTest
@testable import FrugalityCore

final class RentVsBuyCalculatorTests: XCTestCase {
    func testCashPurchaseVersusRentWithNoGrowth() {
        // Buyer pays cash and has no costs, so they invest the $1,000/month rent they avoid.
        let r = RentVsBuyCalculator.compare(RentVsBuyInput(
            years: 1, homePrice: 100_000, downPaymentRate: 1, buyClosingCostRate: 0, sellingCostRate: 0,
            propertyTaxRate: 0, homeInsuranceAnnual: 0, maintenanceRate: 0, appreciationRate: 0,
            monthlyRent: 1_000, rentGrowthRate: 0, rentersInsuranceAnnual: 0, investmentReturn: 0
        ))
        XCTAssertEqual(r.years.count, 1)
        XCTAssertEqual(r.years[0].buyerNetWorth, 112_000)
        XCTAssertEqual(r.years[0].renterNetWorth, 100_000)
        XCTAssertEqual(r.breakEvenYear, 1)
        XCTAssertEqual(r.upfrontCashToBuy, 100_000)
        XCTAssertEqual(r.monthlyMortgagePayment, 0)
    }

    func testDefaults() {
        let r = RentVsBuyCalculator.compare(RentVsBuyInput())
        XCTAssertEqual(r.upfrontCashToBuy, 92_000)
        XCTAssertEqual(r.monthlyMortgagePayment, dec("2022.62"))
        XCTAssertEqual(r.years.count, 10)
        assertClose(r.years[0].buyerNetWorth, dec("70856.72"))
        assertClose(r.years[0].renterNetWorth, dec("106366.53"))
        assertClose(r.years[9].buyerNetWorth, dec("234028.95"))
        assertClose(r.years[9].renterNetWorth, dec("258915.76"))
        XCTAssertNil(r.breakEvenYear)
        XCTAssertLessThan(r.finalAdvantageOfBuying, 0)
    }

    func testYearsAreClamped() {
        XCTAssertEqual(RentVsBuyCalculator.compare(RentVsBuyInput(years: 0)).years.count, 1)
        XCTAssertEqual(RentVsBuyCalculator.compare(RentVsBuyInput(years: 500)).years.count, 50)
    }

    func testLoanBalanceFallsOverTime() {
        let r = RentVsBuyCalculator.compare(RentVsBuyInput())
        for pair in zip(r.years, r.years.dropFirst()) {
            XCTAssertLessThan(pair.1.loanBalance, pair.0.loanBalance)
        }
    }
}
