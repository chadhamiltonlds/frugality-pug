import XCTest
@testable import FrugalityCore

final class BudgetCalculatorTests: XCTestCase {
    func testSummary() {
        let r = BudgetCalculator.summarize(BudgetInput(
            incomes: [
                IncomeSource(name: "Salary", amountPerPaycheck: 5_000, schedule: .semiMonthly),
                IncomeSource(name: "Side gig", amountPerPaycheck: 3_000, schedule: .monthly)
            ],
            expenses: [
                BudgetExpense(name: "Rent", monthlyAmount: 2_000, category: BudgetCategories.housing),
                BudgetExpense(name: "Groceries", monthlyAmount: 800, category: BudgetCategories.food),
                BudgetExpense(name: "401k", monthlyAmount: 1_000, category: BudgetCategories.savings)
            ]
        ))
        XCTAssertEqual(r.monthlyIncome, 13_000)
        XCTAssertEqual(r.monthlyExpenses, 3_800)
        XCTAssertEqual(r.remaining, 9_200)
        XCTAssertEqual(r.monthlySavings, 1_000)
        XCTAssertEqual(r.savingsRate?.rounded(toPlaces: 4, mode: .plain), dec("0.0769"))
        XCTAssertEqual(r.categories.map(\.name), [BudgetCategories.housing, BudgetCategories.savings, BudgetCategories.food])
        XCTAssertEqual(r.categories[0].shareOfExpenses.rounded(toPlaces: 4, mode: .plain), dec("0.5263"))
    }

    func testSameCategoryIsCombined() {
        let r = BudgetCalculator.summarize(BudgetInput(expenses: [
            BudgetExpense(name: "Electric", monthlyAmount: 120, category: BudgetCategories.utilities),
            BudgetExpense(name: "Water", monthlyAmount: 60, category: BudgetCategories.utilities)
        ]))
        XCTAssertEqual(r.categories.count, 1)
        XCTAssertEqual(r.categories[0].total, 180)
        XCTAssertNil(r.categories[0].shareOfIncome)
        XCTAssertNil(r.savingsRate)
        XCTAssertEqual(r.remaining, -180)
    }

    func testBlankCategoryAndNegativeAmounts() {
        let r = BudgetCalculator.summarize(BudgetInput(
            incomes: [IncomeSource(amountPerPaycheck: -100, schedule: .monthly)],
            expenses: [BudgetExpense(monthlyAmount: 50, category: "  "), BudgetExpense(monthlyAmount: -20)]
        ))
        XCTAssertEqual(r.monthlyIncome, 0)
        XCTAssertEqual(r.monthlyExpenses, 50)
        XCTAssertEqual(r.categories.map(\.name), [BudgetCategories.other])
    }

    func testEmptyBudget() {
        let r = BudgetCalculator.summarize(BudgetInput())
        XCTAssertEqual(r.monthlyIncome, 0)
        XCTAssertEqual(r.remaining, 0)
        XCTAssertTrue(r.categories.isEmpty)
    }

    func testCategorySuggestions() {
        let cases: [(String, String)] = [
            ("Rent", BudgetCategories.housing),
            ("Car insurance", BudgetCategories.insurance),
            ("Gas bill", BudgetCategories.utilities),
            ("Gas", BudgetCategories.transportation),
            ("Student loan", BudgetCategories.debt),
            ("Netflix", BudgetCategories.entertainment),
            ("Dog food", BudgetCategories.pets),
            ("Groceries", BudgetCategories.food),
            ("Roth IRA", BudgetCategories.savings),
            ("Daycare", BudgetCategories.kids),
            ("Something odd", BudgetCategories.other),
            ("", BudgetCategories.other)
        ]
        for (name, expected) in cases {
            XCTAssertEqual(BudgetCategories.suggest(for: name), expected, name)
        }
    }

    func testCustomCategoriesAreMergedWithoutDuplicates() {
        let all = BudgetCategories.all(custom: ["Golf", " golf ", "", "Housing", "Boat"])
        XCTAssertEqual(Array(all.suffix(2)), ["Golf", "Boat"])
        XCTAssertEqual(all.count, BudgetCategories.defaults.count + 2)
    }
}
