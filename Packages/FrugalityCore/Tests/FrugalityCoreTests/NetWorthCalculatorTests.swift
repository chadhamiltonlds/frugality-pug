import XCTest
@testable import FrugalityCore

final class NetWorthCalculatorTests: XCTestCase {
    private let sample = NetWorthInput(
        assets: [
            AssetItem(name: "Checking", category: .cash, value: 10_000),
            AssetItem(name: "401(k)", category: .retirement, value: 50_000),
            AssetItem(name: "House", category: .realEstate, value: 300_000)
        ],
        debts: [
            DebtItem(name: "Mortgage", category: .mortgage, balance: 250_000, annualInterestRate: dec("0.06")),
            DebtItem(name: "Car", category: .auto, balance: 20_000, annualInterestRate: dec("0.05"))
        ]
    )

    func testTotals() {
        let r = NetWorthCalculator.summarize(sample)
        XCTAssertEqual(r.totalAssets, 360_000)
        XCTAssertEqual(r.totalDebts, 270_000)
        XCTAssertEqual(r.netWorth, 90_000)
        XCTAssertEqual(r.debtToAssetRatio, dec("0.75"))
        XCTAssertEqual(r.monthlyInterestCost, dec("1333.33"))
        XCTAssertEqual(r.averageInterestRate?.rounded(toPlaces: 6, mode: .plain), dec("0.059259"))
    }

    func testCategoriesLargestFirstAndZeroesDropped() {
        let r = NetWorthCalculator.summarize(sample)
        XCTAssertEqual(r.assetsByCategory.map(\.category), [.realEstate, .retirement, .cash])
        XCTAssertEqual(r.debtsByCategory.map(\.category), [.mortgage, .auto])
    }

    func testEmptyInput() {
        let r = NetWorthCalculator.summarize(NetWorthInput())
        XCTAssertEqual(r.netWorth, 0)
        XCTAssertNil(r.debtToAssetRatio)
        XCTAssertNil(r.averageInterestRate)
        XCTAssertTrue(r.assetsByCategory.isEmpty)
    }

    func testNegativeNetWorthAndNegativeEntries() {
        let r = NetWorthCalculator.summarize(NetWorthInput(
            assets: [AssetItem(value: 5_000), AssetItem(value: -2_000)],
            debts: [DebtItem(balance: 30_000, annualInterestRate: -1)]
        ))
        XCTAssertEqual(r.totalAssets, 5_000)
        XCTAssertEqual(r.netWorth, -25_000)
        XCTAssertEqual(r.monthlyInterestCost, 0)
    }
}
