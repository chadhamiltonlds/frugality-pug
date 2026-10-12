import Foundation

/// Budget pay schedules. Biweekly is intentionally not offered for budgeting.
public enum BudgetPaySchedule: String, Codable, CaseIterable, Identifiable {
    case monthly
    case semiMonthly

    public var id: String { rawValue }

    public var paychecksPerMonth: Int {
        switch self {
        case .monthly: return 1
        case .semiMonthly: return 2
        }
    }

    public var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .semiMonthly: return "Semi-monthly"
        }
    }
}

public struct IncomeSource: Codable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    /// Take-home amount of one paycheck.
    public var amountPerPaycheck: Decimal
    public var schedule: BudgetPaySchedule

    public init(id: UUID = UUID(), name: String = "", amountPerPaycheck: Decimal = 0, schedule: BudgetPaySchedule = .semiMonthly) {
        self.id = id
        self.name = name
        self.amountPerPaycheck = amountPerPaycheck
        self.schedule = schedule
    }

    public var monthlyAmount: Decimal {
        max(amountPerPaycheck, 0) * Decimal(schedule.paychecksPerMonth)
    }
}

public struct BudgetExpense: Codable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var monthlyAmount: Decimal
    public var category: String
    /// True until the user picks a category by hand; while true, the category follows the name's suggestion.
    public var categoryIsAutomatic: Bool

    public init(id: UUID = UUID(), name: String = "", monthlyAmount: Decimal = 0,
                category: String = BudgetCategories.other, categoryIsAutomatic: Bool = true) {
        self.id = id
        self.name = name
        self.monthlyAmount = monthlyAmount
        self.category = category
        self.categoryIsAutomatic = categoryIsAutomatic
    }
}

public struct BudgetInput: Codable, Equatable {
    public var incomes: [IncomeSource]
    public var expenses: [BudgetExpense]
    public var customCategories: [String]

    public init(incomes: [IncomeSource] = [], expenses: [BudgetExpense] = [], customCategories: [String] = []) {
        self.incomes = incomes
        self.expenses = expenses
        self.customCategories = customCategories
    }
}

public struct BudgetCategoryTotal: Equatable, Identifiable {
    public let name: String
    public let total: Decimal
    /// Share of all expenses (0 when there are none).
    public let shareOfExpenses: Decimal
    /// Share of income; nil when income is 0.
    public let shareOfIncome: Decimal?
    public var id: String { name }
}

public struct BudgetSummary: Equatable {
    public let monthlyIncome: Decimal
    public let monthlyExpenses: Decimal
    /// Income minus expenses; negative means overspending.
    public let remaining: Decimal
    /// Non-zero categories, largest first.
    public let categories: [BudgetCategoryTotal]
    public let monthlySavings: Decimal
    /// Savings category / income; nil when income is 0.
    public let savingsRate: Decimal?
}

/// Totals a monthly budget. Savings lines count as spending (money assigned), so `remaining` is unassigned money.
public enum BudgetCalculator {
    public static func summarize(_ input: BudgetInput) -> BudgetSummary {
        let income = input.incomes.reduce(Decimal(0)) { $0 + $1.monthlyAmount }

        var totals: [String: Decimal] = [:]
        var firstSeen: [String: Int] = [:]
        for (index, expense) in input.expenses.enumerated() {
            let trimmed = expense.category.trimmingCharacters(in: .whitespacesAndNewlines)
            let category = trimmed.isEmpty ? BudgetCategories.other : trimmed
            totals[category, default: 0] += max(expense.monthlyAmount, 0)
            if firstSeen[category] == nil { firstSeen[category] = index }
        }
        let expenses = totals.values.reduce(Decimal(0), +)

        let categories = totals
            .filter { $0.value > 0 }
            .sorted { lhs, rhs in
                lhs.value != rhs.value ? lhs.value > rhs.value : (firstSeen[lhs.key] ?? 0) < (firstSeen[rhs.key] ?? 0)
            }
            .map { entry in
                BudgetCategoryTotal(
                    name: entry.key,
                    total: entry.value.roundedToCents(),
                    shareOfExpenses: expenses > 0 ? entry.value / expenses : 0,
                    shareOfIncome: income > 0 ? entry.value / income : nil
                )
            }

        let savings = totals[BudgetCategories.savings] ?? 0
        return BudgetSummary(
            monthlyIncome: income.roundedToCents(),
            monthlyExpenses: expenses.roundedToCents(),
            remaining: (income - expenses).roundedToCents(),
            categories: categories,
            monthlySavings: savings.roundedToCents(),
            savingsRate: income > 0 ? savings / income : nil
        )
    }
}
