import SwiftUI
import FrugalityCore

struct RentalAnalysisView: View {
    @StateObject private var model = RentalAnalysisViewModel()

    var body: some View {
        CalculatorScreen(title: "Rental Property") {
            verdictCard
            checksCard
            SectionCard(title: "Purchase") {
                MoneyField(title: "Price", value: $model.input.purchasePrice)
                PercentField(title: "Down payment", value: $model.input.downPaymentRate)
                PercentField(title: "Closing costs", value: $model.input.closingCostRate)
                MoneyField(title: "Repairs up front", value: $model.input.upfrontRepairs)
                PercentField(title: "Mortgage rate", value: $model.input.mortgageRate)
                LedgerStepper("Loan term", value: $model.input.mortgageYears, in: 5...40, step: 5, valueText: LedgerStepper.years)
            }
            SectionCard(title: "Income (monthly)") {
                MoneyField(title: "Rent", value: $model.input.monthlyRent)
                MoneyField(title: "Other income", value: $model.input.otherMonthlyIncome)
                PercentField(title: "Vacancy", value: $model.input.vacancyRate)
            }
            SectionCard(title: "Expenses") {
                MoneyField(title: "Property tax (yearly)", value: $model.input.propertyTaxAnnual)
                MoneyField(title: "Insurance (yearly)", value: $model.input.insuranceAnnual)
                MoneyField(title: "HOA (monthly)", value: $model.input.hoaMonthly)
                MoneyField(title: "Utilities you pay (monthly)", value: $model.input.utilitiesMonthly)
                PercentField(title: "Repairs (share of rent)", value: $model.input.maintenanceRate)
                PercentField(title: "Big-ticket reserves (share of rent)", value: $model.input.capexRate)
                PercentField(title: "Management (share of rent)", value: $model.input.managementRate)
                PercentField(title: "Home value growth (yearly)", value: $model.input.appreciationRate)
            }
            SectionCard(title: "Your targets") {
                MoneyField(title: "Cash flow per month", value: $model.input.targetMonthlyCashFlow)
                PercentField(title: "Cash-on-cash return", value: $model.input.targetCashOnCash)
                PercentField(title: "Cap rate", value: $model.input.targetCapRate)
                PercentField(title: "Rent / price (1% rule)", value: $model.input.targetRentToPrice)
                RatioField(title: "Debt coverage (NOI / mortgage)", value: $model.input.targetDSCR)
            }
            detailsCard
        }
        .tint(Theme.accent)
    }

    // MARK: - Results

    private var verdictCard: some View {
        let result = model.result
        let style = Self.style(for: result.verdict)
        return ReceiptCard(title: "Verdict") {
            VerdictStamp(title: style.title, symbol: style.symbol, color: style.color, trigger: result.verdict)
                .padding(.vertical, 4)
            HeadlineNumber(
                caption: "Cash flow per month",
                value: result.cashFlow.asCurrency,
                color: result.cashFlow >= 0 ? Theme.positive : Theme.accent,
                footnote: "\(result.annualCashFlow.asCurrency) per year. \(result.checks.filter(\.passed).count) of \(result.checks.count) checks pass."
            )
        }
    }

    private var checksCard: some View {
        SectionCard(title: "Checks") {
            ForEach(model.result.checks) { check in
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: check.passed ? "checkmark.square.fill" : "xmark.square.fill")
                        .foregroundStyle(check.passed ? Theme.positive : Theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Self.name(check.kind))
                            .foregroundStyle(Theme.ink)
                        Text("Target \(Self.format(check.target, kind: check.kind))")
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    Text(check.actual.map { Self.format($0, kind: check.kind) } ?? "n/a")
                        .foregroundStyle(Theme.ink)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(Self.name(check.kind)), \(check.passed ? "passes" : "fails")")
            }
        }
    }

    private var detailsCard: some View {
        let r = model.result
        return ReceiptCard(title: "The numbers (monthly unless noted)") {
            ResultRow(label: "Gross income", value: r.grossIncome.asCurrency)
            ResultRow(label: "Vacancy", value: (-r.vacancyLoss).asCurrency)
            ResultRow(label: "Operating expenses", value: (-r.operatingExpenses).asCurrency)
            ResultRow(label: "Net operating income", value: r.netOperatingIncome.asCurrency, emphasized: true)
            ResultRow(label: "Mortgage payment", value: (-r.monthlyMortgagePayment).asCurrency)
            ResultRow(label: "Cash flow", value: r.cashFlow.asCurrency, emphasized: true)
            DashedRule()
            ResultRow(label: "Cash you put in", value: r.cashInvested.asWholeCurrency)
            ResultRow(label: "Loan", value: r.loanAmount.asWholeCurrency)
            if let grm = r.grossRentMultiplier {
                ResultRow(label: "Gross rent multiplier", value: grm.formatted(.number.precision(.fractionLength(1))))
            }
            if let occupancy = r.breakEvenOccupancy {
                ResultRow(label: "Break-even occupancy", value: occupancy.asPercent)
            }
            DashedRule()
            ResultRow(label: "Year 1 loan paydown", value: r.firstYearPrincipalPaydown.asWholeCurrency)
            ResultRow(label: "Year 1 appreciation", value: r.firstYearAppreciation.asWholeCurrency)
            if let total = r.firstYearTotalReturn {
                ResultRow(label: "Year 1 total return", value: total.asPercent, emphasized: true)
            }
            Text("Total return counts cash flow, loan paydown and appreciation against the cash you put in. Income taxes and depreciation aren't included.")
                .font(.caption)
                .foregroundStyle(Theme.muted)
        }
    }

    // MARK: - Labels

    static func name(_ kind: RentalCheckKind) -> String {
        switch kind {
        case .cashFlow: return "Monthly cash flow"
        case .cashOnCash: return "Cash-on-cash return"
        case .capRate: return "Cap rate"
        case .debtCoverage: return "Debt coverage"
        case .rentToPrice: return "Rent / price"
        }
    }

    static func format(_ value: Decimal, kind: RentalCheckKind) -> String {
        switch kind {
        case .cashFlow: return value.asCurrency
        case .cashOnCash, .capRate: return value.asPercent
        case .debtCoverage: return value.formatted(.number.precision(.fractionLength(2))) + "×"
        case .rentToPrice: return value.formatted(.percent.precision(.fractionLength(2)))
        }
    }

    static func style(for verdict: RentalVerdict) -> (title: String, symbol: String, color: Color) {
        switch verdict {
        case .good: return ("Good rental", "checkmark.seal.fill", Theme.positive)
        case .borderline: return ("Borderline", "exclamationmark.triangle.fill", Color(hex: 0xC27A12))
        case .weak: return ("Weak deal", "xmark.octagon.fill", Theme.accent)
        }
    }
}

/// A plain decimal input (e.g. 1.25) for ratios.
private struct RatioField: View {
    let title: String
    @Binding var value: Decimal
    @State private var text = ""

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            Text(title).foregroundStyle(Theme.ink)
            Spacer()
            UnderlinedInput(text: $text, suffix: "×", width: 96)
                .onChange(of: text) { _, newText in
                    value = Decimal(string: newText.filter { $0.isNumber || $0 == "." },
                                    locale: Locale(identifier: "en_US_POSIX")) ?? 0
                }
        }
        .onAppear { text = NSDecimalNumber(decimal: value).stringValue }
    }
}

/// The verdict as a tilted rubber stamp. It thumps down again whenever the verdict changes.
private struct VerdictStamp: View {
    let title: String
    let symbol: String
    let color: Color
    let trigger: RentalVerdict
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
            Text(title)
        }
        .font(Theme.display(.title2))
        .foregroundStyle(color)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .overlay(Rectangle().stroke(color, lineWidth: 3))
        .overlay(Rectangle().stroke(color, lineWidth: 1).padding(5))
        .rotationEffect(.degrees(-4))
        .phaseAnimator([false, true], trigger: trigger) { content, lifted in
            content.scaleEffect(lifted && !reduceMotion ? 1.18 : 1)
        } animation: { _ in
            .spring(response: 0.18, dampingFraction: 0.55)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Verdict: \(title)")
    }
}
