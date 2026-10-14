import SwiftUI
import FrugalityCore

struct NetWorthView: View {
    @StateObject private var model = NetWorthViewModel()

    var body: some View {
        CalculatorScreen(title: "Net Worth") {
            resultCard
            SectionCard(title: "Assets") {
                ForEach($model.input.assets) { $asset in
                    AssetRow(asset: $asset) { model.deleteAsset(asset.id) }
                    Divider()
                }
                AddRowButton(title: "Add asset") { model.addAsset() }
            }
            SectionCard(title: "Debts") {
                ForEach($model.input.debts) { $debt in
                    DebtRow(debt: $debt) { model.deleteDebt(debt.id) }
                    Divider()
                }
                AddRowButton(title: "Add debt") { model.addDebt() }
            }
            breakdownCard
        }
    }

    private var resultCard: some View {
        let result = model.result
        return SectionCard(title: "Summary") {
            HeadlineNumber(
                caption: "Net worth",
                value: result.netWorth.asCurrency,
                color: result.netWorth >= 0 ? Theme.positive : Theme.accent
            )
            Divider()
            ResultRow(label: "Total assets", value: result.totalAssets.asCurrency)
            ResultRow(label: "Total debts", value: result.totalDebts.asCurrency)
            if let ratio = result.debtToAssetRatio {
                ResultRow(label: "Debt to assets", value: ratio.asPercent)
            }
            if let rate = result.averageInterestRate {
                ResultRow(label: "Average interest rate", value: rate.asPercent)
            }
            if result.monthlyInterestCost > 0 {
                ResultRow(label: "Interest per month", value: result.monthlyInterestCost.asCurrency)
            }
        }
    }

    @ViewBuilder
    private var breakdownCard: some View {
        let result = model.result
        if !result.assetsByCategory.isEmpty || !result.debtsByCategory.isEmpty {
            SectionCard(title: "By category") {
                ForEach(result.assetsByCategory, id: \.category) { item in
                    ResultRow(label: item.category.displayName, value: item.total.asCurrency)
                }
                if !result.assetsByCategory.isEmpty && !result.debtsByCategory.isEmpty {
                    Divider()
                }
                ForEach(result.debtsByCategory, id: \.category) { item in
                    ResultRow(label: item.category.displayName, value: (-item.total).asCurrency, valueColor: Theme.accent)
                }
            }
        }
    }
}

private struct AssetRow: View {
    @Binding var asset: AssetItem
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Name (e.g. Checking)", text: $asset.name)
                    .font(.body.weight(.semibold))
                DeleteRowButton(action: onDelete)
            }
            HStack {
                Text("Type").foregroundStyle(Theme.muted)
                Spacer()
                Picker("Type", selection: $asset.category) {
                    ForEach(AssetCategory.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.menu)
                .tint(Theme.accent)
            }
            MoneyField(title: "Value", value: $asset.value)
        }
    }
}

private struct DebtRow: View {
    @Binding var debt: DebtItem
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Name (e.g. Car loan)", text: $debt.name)
                    .font(.body.weight(.semibold))
                DeleteRowButton(action: onDelete)
            }
            HStack {
                Text("Type").foregroundStyle(Theme.muted)
                Spacer()
                Picker("Type", selection: $debt.category) {
                    ForEach(DebtCategory.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.menu)
                .tint(Theme.accent)
            }
            MoneyField(title: "Balance", value: $debt.balance)
            PercentField(title: "Interest rate", value: $debt.annualInterestRate)
        }
    }
}
