# Budget
Files: `App/Features/Budget/`, `FrugalityCore/Budget/` (BudgetCalculator.swift, BudgetCategories.swift), tests `BudgetCalculatorTests`. Save key: `.budget`.

- Input `BudgetInput`: `IncomeSource` list (name, take-home per paycheck, `BudgetPaySchedule` monthly or semi-monthly only, never biweekly), `BudgetExpense` list (name, monthly amount, category, `categoryIsAutomatic`), custom category names.
- Categories: `BudgetCategories.defaults` plus custom ones. `suggest(for:)` picks a category from keywords in the expense name (ordered rules; first match wins). The row follows suggestions until the user picks a category by hand.
- Method: income = per paycheck x paychecks per month. Expenses grouped by category (blank = Other), largest first. Savings lines count as assigned money.
- Output `BudgetSummary`: income, expenses, remaining (negative = over budget), category totals with shares of expenses and of income, savings and savings rate.
