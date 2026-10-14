import SwiftUI
import FrugalityCore

struct TakeHomeView: View {
    @StateObject private var model = TakeHomeViewModel()

    var body: some View {
        CalculatorScreen(title: "Take-Home Pay") {
            incomeCard
            detailsCard
            deductionsCard
            resultCard
            footnote
        }
        .onChange(of: model.input) { _, _ in model.recalculate() }
    }

    // MARK: - Inputs

    private var incomeCard: some View {
        SectionCard(title: "Pay") {
            MoneyField(title: "Gross salary (per year)", value: $model.input.grossAnnual)
            ChoiceBar(selection: $model.input.payFrequency, options: PayFrequency.allCases) { $0.displayName }
        }
    }

    private var detailsCard: some View {
        SectionCard(title: "You") {
            HStack {
                Text("Filing status").foregroundStyle(Theme.ink)
                Spacer()
                Picker("Filing status", selection: $model.input.filingStatus) {
                    ForEach(FilingStatus.allCases) { Text($0.displayName).tag($0) }
                }
                .labelsHidden()
            }
            HStack {
                Text("State").foregroundStyle(Theme.ink)
                Spacer()
                Picker("State", selection: $model.input.stateCode) {
                    ForEach(model.states) { Text($0.name).tag($0.code) }
                }
                .labelsHidden()
            }
            LedgerStepper("Children under 17", value: $model.input.childrenUnder17, in: 0...20)
            LedgerStepper("Other dependents", value: $model.input.otherDependents, in: 0...20)
        }
        .tint(Theme.accent)
    }

    private var deductionsCard: some View {
        SectionCard(title: "Deductions (per year)") {
            MoneyField(title: "401(k) / 403(b)", value: $model.input.preTax401kAnnual)
            MoneyField(title: "Health, HSA, FSA (pre-tax)", value: $model.input.preTaxSection125Annual)
            MoneyField(title: "Other after-tax", value: $model.input.postTaxDeductionsAnnual)
        }
    }

    // MARK: - Results

    @ViewBuilder
    private var resultCard: some View {
        if let message = model.errorMessage {
            SectionCard(title: "Take-home") {
                Text(message)
                    .foregroundStyle(Theme.accent)
            }
        } else if let result = model.result {
            ReceiptCard(title: "Take-home") {
                HeadlineNumber(
                    caption: model.input.payFrequency == .monthly ? "Per month" : "Per paycheck",
                    value: result.netPerPeriod.asCurrency,
                    footnote: "\(result.netAnnual.asCurrency) per year. \(result.effectiveTaxRate.asPercent) goes to taxes."
                )

                DashedRule()

                row("Gross", result.grossAnnual)
                if result.preTax401k > 0 { row("401(k)", -result.preTax401k) }
                if result.preTaxSection125 > 0 { row("Health, HSA, FSA", -result.preTaxSection125) }
                row("Federal income tax", -result.federalIncomeTax)
                row("Social Security", -result.socialSecurity)
                row("Medicare", -result.medicare)
                if result.additionalMedicare > 0 { row("Additional Medicare", -result.additionalMedicare) }
                row("\(result.stateName) income tax", -result.stateIncomeTax)
                if result.postTaxDeductions > 0 { row("Other after-tax", -result.postTaxDeductions) }
                DashedRule()
                row("Net per year", result.netAnnual, emphasized: true)

                if let note = result.stateNote {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }
            }
        } else {
            SectionCard(title: "Take-home") {
                Text("Enter a salary to see your take-home pay.")
                    .foregroundStyle(Theme.muted)
            }
        }
    }

    private func row(_ label: String, _ amount: Decimal, emphasized: Bool = false) -> some View {
        ResultRow(label: label, value: amount.asCurrency, emphasized: emphasized)
    }

    private var footnote: some View {
        Text("\(String(model.taxYear)) estimate. Excludes local taxes, state payroll taxes such as SDI, and itemized deductions. Head of household uses single-filer state figures.")
            .font(.caption)
            .foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
