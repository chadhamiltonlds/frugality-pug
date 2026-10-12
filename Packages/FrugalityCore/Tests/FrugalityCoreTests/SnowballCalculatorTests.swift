import XCTest
@testable import FrugalityCore

final class SnowballCalculatorTests: XCTestCase {
    /// Cash purchases, $1,000/month rent, no expenses or growth: the second property is bought at month 100.
    private let simple = SnowballInput(
        years: 10, startingCash: 100_000, monthlySavings: 0, propertyPrice: 100_000,
        downPaymentRate: 1, closingCostRate: 0, monthlyRent: 1_000, vacancyRate: 0,
        maintenanceRate: 0, managementRate: 0, annualTaxesAndInsurance: 0,
        appreciationRate: 0, rentGrowthRate: 0
    )

    func testSimpleSnowballTiming() {
        let r = SnowballCalculator.simulate(simple)
        XCTAssertEqual(r.purchases.map(\.month), [0, 100])
        XCTAssertEqual(r.years.count, 10)
        XCTAssertEqual(r.years[0].propertiesOwned, 1)
        XCTAssertEqual(r.years[0].cash, 12_000)
        XCTAssertEqual(r.years[9].propertiesOwned, 2)
        XCTAssertEqual(r.years[9].cash, 40_000)
        XCTAssertEqual(r.years[9].annualCashFlow, 24_000)
        XCTAssertEqual(r.years[9].netWorth, 240_000)
        XCTAssertEqual(r.cashNeededPerProperty, 100_000)
        XCTAssertEqual(r.monthlyCashFlowPerProperty, 1_000)
    }

    func testCashFlowNotReinvestedDelaysPurchases() {
        var input = simple
        input.reinvestCashFlow = false
        let r = SnowballCalculator.simulate(input)
        XCTAssertEqual(r.purchases.map(\.month), [0])
        XCTAssertEqual(r.years[9].cash, 0)
    }

    func testMaxPropertiesCap() {
        var input = simple
        input.startingCash = 1_000_000
        input.maxProperties = 3
        let r = SnowballCalculator.simulate(input)
        XCTAssertEqual(r.purchases.count, 3)
        XCTAssertEqual(r.years[0].cash, 700_000 + 36_000)
    }

    func testNotEnoughCashBuysNothing() {
        var input = simple
        input.startingCash = 50_000
        input.years = 1
        let r = SnowballCalculator.simulate(input)
        XCTAssertTrue(r.purchases.isEmpty)
        XCTAssertEqual(r.years[0].cash, 50_000)
    }

    func testDefaults() {
        let r = SnowballCalculator.simulate(SnowballInput())
        XCTAssertEqual(r.cashNeededPerProperty, 70_000)
        XCTAssertEqual(r.monthlyCashFlowPerProperty, dec("115.56"))
        XCTAssertEqual(r.purchases.map(\.month), [0, 64, 119, 162, 197, 226])
        XCTAssertEqual(r.years.count, 20)
        assertClose(r.years[0].cash, dec("18386.69"))
        XCTAssertEqual(r.years[19].propertiesOwned, 6)
        assertClose(r.years[19].portfolioValue, dec("2709166.85"))
        assertClose(r.years[19].equity, dec("1371898.44"))
        assertClose(r.years[19].cash, dec("72497.50"))
    }
}
