import Charts
import SwiftUI
import FrugalityCore

struct AmortizationView: View {
    @StateObject private var model = AmortizationViewModel()

    var body: some View {
        CalculatorScreen(title: "Amortization") {
            SectionCard(title: "Loan") {
                MoneyField(title: "Loan amount", value: $model.input.loanAmount)
                PercentField(title: "Interest rate", value: $model.input.annualRate)
                Stepper("Term: \(model.input.termYears) years", value: $model.input.termYears, in: 5...40, step: 5)
                MoneyField(title: "Extra principal per month", value: $model.input.extraMonthlyPayment)
            }
            checkCard
            summaryCard
            chartCard
            tableCard
        }
        .tint(Theme.accent)
    }

    private var checkCard: some View {
        let result = model.result
        let years = min(model.input.checkAfterYears, model.input.termYears)
        return SectionCard(title: "Still owed") {
            Stepper("After \(years) \(years == 1 ? "year" : "years")",
                    value: $model.input.checkAfterYears, in: 0...max(model.input.termYears, 1))
            HeadlineNumber(
                caption: "Balance remaining",
                value: result.balanceAtCheck.asCurrency,
                color: Theme.ink,
                footnote: "\(result.paidOffShareAtCheck.asPercent) of the loan paid off"
            )
        }
    }

    private var summaryCard: some View {
        let result = model.result
        return SectionCard(title: "Whole loan") {
            ResultRow(label: "Monthly payment (principal + interest)", value: result.monthlyPayment.asCurrency, emphasized: true)
            if model.input.extraMonthlyPayment > 0 {
                ResultRow(label: "With extra principal", value: (result.monthlyPayment + model.input.extraMonthlyPayment).asCurrency)
            }
            ResultRow(label: "Paid off in", value: Self.duration(result.payoffMonths))
            ResultRow(label: "Total interest", value: result.totalInterest.asCurrency)
            ResultRow(label: "Total paid", value: result.totalPaid.asCurrency)
            if result.interestSaved > 0 {
                ResultRow(label: "Interest saved by extra payments", value: result.interestSaved.asCurrency,
                          valueColor: Theme.positive)
            }
            Text("Taxes, insurance and PMI aren't included.")
                .font(Theme.font(.caption))
                .foregroundStyle(Theme.muted)
        }
    }

    @ViewBuilder
    private var chartCard: some View {
        if !model.result.years.isEmpty {
            SectionCard(title: "Balance by year") {
                Chart(model.result.years) { year in
                    LineMark(x: .value("Year", year.year), y: .value("Balance", year.balance.doubleValue))
                        .foregroundStyle(ChartColors.series1)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    if model.input.checkAfterYears == year.year {
                        PointMark(x: .value("Year", year.year), y: .value("Balance", year.balance.doubleValue))
                            .foregroundStyle(ChartColors.series1)
                            .symbolSize(80)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let amount = value.as(Double.self) { Text(compactDollars(amount)) }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
    }

    @ViewBuilder
    private var tableCard: some View {
        if !model.result.years.isEmpty {
            SectionCard(title: "Year by year: principal · interest · balance") {
                ForEach(model.result.years) { year in
                    HStack {
                        Text("Year \(year.year)")
                        Spacer()
                        Text("\(year.principalPaid.asWholeCurrency) · \(year.interestPaid.asWholeCurrency) · \(year.balance.asWholeCurrency)")
                            .monospacedDigit()
                    }
                    .font(Theme.font(.body, weight: year.year == model.input.checkAfterYears ? .semibold : .regular))
                    .foregroundStyle(Theme.ink)
                }
            }
        }
    }

    /// "30 yr", "21 yr", "20 yr 11 mo", "8 mo"
    static func duration(_ months: Int) -> String {
        let years = months / 12
        let rest = months % 12
        switch (years, rest) {
        case (0, _): return "\(rest) mo"
        case (_, 0): return "\(years) yr"
        default: return "\(years) yr \(rest) mo"
        }
    }
}
