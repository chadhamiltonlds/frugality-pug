# Net Worth
Files: `App/Features/NetWorth/`, `FrugalityCore/NetWorth/NetWorthCalculator.swift`, tests `NetWorthCalculatorTests`. Save key: `.netWorth`.

- Input `NetWorthInput`: lists of `AssetItem` (name, `AssetCategory`, value) and `DebtItem` (name, `DebtCategory`, balance, interest rate).
- Method: sums; negative values and rates count as 0. Categories with zero totals are dropped and the rest are sorted largest first.
- Output `NetWorthResult`: totals, net worth, by-category totals, debt-to-asset ratio, balance-weighted average interest rate, monthly interest cost.
- Screen: summary, editable asset and debt lists, by-category card.
