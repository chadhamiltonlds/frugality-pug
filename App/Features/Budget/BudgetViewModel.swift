import Foundation
import FrugalityCore

@MainActor
final class BudgetViewModel: ObservableObject {
    @Published var input: BudgetInput {
        didSet {
            JSONStore.save(input, key: .budget)
            summary = BudgetCalculator.summarize(input)
        }
    }
    @Published private(set) var summary: BudgetSummary

    init() {
        let saved = JSONStore.load(BudgetInput.self, key: .budget) ?? BudgetInput()
        input = saved
        summary = BudgetCalculator.summarize(saved)
    }

    var categories: [String] {
        BudgetCategories.all(custom: input.customCategories)
    }

    func addIncome() { input.incomes.append(IncomeSource()) }
    func addExpense() { input.expenses.append(BudgetExpense()) }
    func deleteIncome(_ id: UUID) { input.incomes.removeAll { $0.id == id } }
    func deleteExpense(_ id: UUID) { input.expenses.removeAll { $0.id == id } }

    func addCategory(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        input.customCategories.append(trimmed)
    }
}
