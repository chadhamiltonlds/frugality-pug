import SwiftUI
import FrugalityCore

struct TakeHomeView: View {
    @StateObject private var model = TakeHomeViewModel()

    var body: some View {
        ZStack {
            ThemedBackground()
            ScrollView {
                VStack(spacing: 16) {
                    incomeCard
                    detailsCard
                    deductionsCard
                    resultCard
                    footnote
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Take-Home Pay")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: model.input) { _, _ in model.recalculate() }
    }

    // MARK: - Inputs

    private var incomeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoneyField(title: "Gross salary (per year)", value: $model.input.grossAnnual)
            Picker("Paid", selection: $model.input.payFrequency) {
                ForEach(PayFrequency.allCases) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)
        }
        .card()
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Filing status", selection: $model.input.filingStatus) {
                ForEach(FilingStatus.allCases) { Text($0.displayName).tag($0) }
            }
            Picker("State", selection: $model.input.stateCode) {
                ForEach(model.states) { Text($0.name).tag($0.code) }
            }
            Stepper("Children under 17: \(model.input.childrenUnder17)", value: $model.input.childrenUnder17, in: 0...20)
            Stepper("Other dependents: \(model.input.otherDependents)", value: $model.input.otherDependents, in: 0...20)
        }
        .tint(Theme.accent)
        .card()
    }

    private var deductionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Deductions (per year)")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.muted)
            MoneyField(title: "401(k) / 403(b)", value: $model.input.preTax401kAnnual)
            MoneyField(title: "Health, HSA, FSA (pre-tax)", value: $model.input.preTaxSection125Annual)
            MoneyField(title: "Other after-tax", value: $model.input.postTaxDeductionsAnnual)
        }
        .card()
    }

    // MARK: - Results

    @ViewBuilder
    private var resultCard: some View {
        if let message = model.errorMessage {
            Text(message)
                .foregroundStyle(Theme.accent)
                .card()
        } else if let result = model.result {
            VStack(alignment: .leading, spacing: 10) {
                Text(model.input.payFrequency == .monthly ? "Take-home per month" : "Take-home per paycheck")
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
                Text(result.netPerPeriod.asCurrency)
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.positive)
                Text("\(result.netAnnual.asCurrency) per year · \(result.effectiveTaxRate.asPercent) taxes")
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)

                Divider()

                row("Gross", result.grossAnnual)
                if result.preTax401k > 0 { row("401(k)", -result.preTax401k) }
                if result.preTaxSection125 > 0 { row("Health, HSA, FSA", -result.preTaxSection125) }
                row("Federal income tax", -result.federalIncomeTax)
                row("Social Security", -result.socialSecurity)
                row("Medicare", -result.medicare)
                if result.additionalMedicare > 0 { row("Additional Medicare", -result.additionalMedicare) }
                row("\(result.stateName) income tax", -result.stateIncomeTax)
                if result.postTaxDeductions > 0 { row("Other after-tax", -result.postTaxDeductions) }
                Divider()
                row("Net per year", result.netAnnual, emphasized: true)

                if let note = result.stateNote {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }
            }
            .card()
        } else {
            Text("Enter a salary to see your take-home pay.")
                .foregroundStyle(Theme.muted)
                .card()
        }
    }

    private func row(_ label: String, _ amount: Decimal, emphasized: Bool = false) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(amount.asCurrency)
        }
        .font(emphasized ? .body.weight(.bold) : .body)
        .foregroundStyle(Theme.ink)
    }

    private var footnote: some View {
        Text("\(String(model.taxYear)) estimate. Excludes local taxes, state payroll taxes such as SDI, and itemized deductions. Head of household uses single-filer state figures.")
            .font(.caption)
            .foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
