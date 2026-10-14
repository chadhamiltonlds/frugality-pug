import SwiftUI
import FrugalityCore

struct BudgetView: View {
    @StateObject private var model = BudgetViewModel()
    @State private var newCategory = ""

    var body: some View {
        CalculatorScreen(title: "Budget") {
            summaryCard
            SectionCard(title: "Income (take-home)") {
                ForEach($model.input.incomes) { $income in
                    IncomeRow(income: $income) { model.deleteIncome(income.id) }
                    DashedRule()
                }
                AddRowButton(title: "Add income") { model.addIncome() }
            }
            SectionCard(title: "Monthly expenses") {
                ForEach($model.input.expenses) { $expense in
                    ExpenseRow(expense: $expense, categories: model.categories) { model.deleteExpense(expense.id) }
                    DashedRule()
                }
                AddRowButton(title: "Add expense") { model.addExpense() }
            }
            categoriesCard
            customCategoryCard
        }
        .tint(Theme.accent)
    }

    private var summaryCard: some View {
        let summary = model.summary
        let over = summary.remaining < 0
        return ReceiptCard(title: "This month") {
            HeadlineNumber(
                caption: over ? "Over budget by" : "Left to assign",
                value: (over ? -summary.remaining : summary.remaining).asCurrency,
                color: over ? Theme.accent : Theme.positive
            )
            DashedRule()
            ResultRow(label: "Income", value: summary.monthlyIncome.asCurrency)
            ResultRow(label: "Expenses", value: summary.monthlyExpenses.asCurrency)
            if let rate = summary.savingsRate {
                ResultRow(label: "Savings rate", value: rate.asPercent)
            }
        }
    }

    @ViewBuilder
    private var categoriesCard: some View {
        if !model.summary.categories.isEmpty {
            SectionCard(title: "Where it goes") {
                ForEach(model.summary.categories) { category in
                    CategoryBar(category: category)
                }
            }
        }
    }

    private var customCategoryCard: some View {
        SectionCard(title: "Add a category") {
            HStack {
                TextField("Category name", text: $newCategory)
                Button("Add") {
                    model.addCategory(newCategory)
                    newCategory = ""
                }
                .buttonStyle(.borderless)
                .disabled(newCategory.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
}

private struct IncomeRow: View {
    @Binding var income: IncomeSource
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Name (e.g. Paycheck)", text: $income.name)
                    .font(.body.weight(.semibold))
                DeleteRowButton(action: onDelete)
            }
            MoneyField(title: "Per paycheck", value: $income.amountPerPaycheck)
            ChoiceBar(selection: $income.schedule, options: BudgetPaySchedule.allCases) { $0.displayName }
            Text("\(income.monthlyAmount.asCurrency) per month")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
        }
    }
}

private struct ExpenseRow: View {
    @Binding var expense: BudgetExpense
    let categories: [String]
    let onDelete: () -> Void

    /// Keeps a category that is no longer in the list selectable, so the picker never shows blank.
    private var choices: [String] {
        categories.contains(expense.category) ? categories : categories + [expense.category]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Expense (e.g. Rent)", text: $expense.name)
                    .font(.body.weight(.semibold))
                    .onChange(of: expense.name) { _, newName in
                        if expense.categoryIsAutomatic {
                            expense.category = BudgetCategories.suggest(for: newName)
                        }
                    }
                DeleteRowButton(action: onDelete)
            }
            HStack {
                Text("Category").foregroundStyle(Theme.muted)
                Spacer()
                Picker("Category", selection: Binding(
                    get: { expense.category },
                    set: { newValue in
                        expense.category = newValue
                        expense.categoryIsAutomatic = false
                    }
                )) {
                    ForEach(choices, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
            }
            MoneyField(title: "Per month", value: $expense.monthlyAmount)
        }
    }
}

private struct CategoryBar: View {
    let category: BudgetCategoryTotal

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(category.name)
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(category.total.asCurrency)
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                if let share = category.shareOfIncome {
                    Text(share.asPercent)
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                        .frame(width: 52, alignment: .trailing)
                }
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Theme.cream)
                    Rectangle()
                        .fill(ChartColors.series1)
                        .frame(width: proxy.size.width * CGFloat(category.shareOfExpenses.doubleValue))
                }
            }
            .frame(height: 8)
            .overlay(Rectangle().stroke(Theme.ink, lineWidth: 1))
        }
        .accessibilityElement(children: .combine)
    }
}
