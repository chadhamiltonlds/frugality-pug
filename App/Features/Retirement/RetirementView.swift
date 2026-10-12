import Charts
import SwiftUI
import FrugalityCore

struct RetirementView: View {
    @StateObject private var model = RetirementViewModel()

    private static let futureSeries = "Future dollars"
    private static let todaySeries = "Today's dollars"

    var body: some View {
        CalculatorScreen(title: "Retirement") {
            SectionCard(title: "You") {
                Stepper("Current age: \(model.input.currentAge)", value: $model.input.currentAge, in: 0...100)
                Stepper("Retire at: \(model.input.retirementAge)", value: $model.input.retirementAge, in: 1...100)
            }
            SectionCard(title: "Saving") {
                MoneyField(title: "Saved so far", value: $model.input.currentSavings)
                MoneyField(title: "You add per month", value: $model.input.monthlyContribution)
                MoneyField(title: "Employer adds per month", value: $model.input.employerMonthlyContribution)
                PercentField(title: "Yearly raise in contributions", value: $model.input.contributionGrowthRate)
            }
            SectionCard(title: "Assumptions") {
                PercentField(title: "Yearly return", value: $model.input.annualReturn)
                PercentField(title: "Inflation", value: $model.input.inflationRate)
                PercentField(title: "Withdrawal rate", value: $model.input.withdrawalRate)
            }
            resultCard
            chartCard
            tableCard
        }
        .tint(Theme.accent)
    }

    private var resultCard: some View {
        let result = model.result
        let retireAge = max(model.input.retirementAge, model.input.currentAge)
        return SectionCard(title: "At age \(retireAge)") {
            HeadlineNumber(
                caption: "Saved, in today's dollars",
                value: result.finalBalanceInTodayDollars.asWholeCurrency,
                footnote: "\(result.finalBalance.asWholeCurrency) in future dollars"
            )
            Divider()
            ResultRow(label: "You and your employer put in", value: result.totalContributed.asWholeCurrency)
            ResultRow(label: "Investment growth", value: result.totalGrowth.asWholeCurrency)
            ResultRow(label: "Yearly income at \(model.input.withdrawalRate.asPercent)",
                      value: result.annualIncomeInTodayDollars.asWholeCurrency)
            ResultRow(label: "Monthly income", value: result.monthlyIncomeInTodayDollars.asWholeCurrency, emphasized: true)
            Text("Income is in today's dollars.")
                .font(.caption)
                .foregroundStyle(Theme.muted)
        }
    }

    @ViewBuilder
    private var chartCard: some View {
        if !model.result.years.isEmpty {
            SectionCard(title: "Balance by age") {
                Chart(chartPoints) { point in
                    LineMark(x: .value("Age", point.x), y: .value("Balance", point.y))
                        .foregroundStyle(by: .value("Series", point.series))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .chartForegroundStyleScale([
                    Self.futureSeries: ChartColors.series1,
                    Self.todaySeries: ChartColors.series2
                ])
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let amount = value.as(Double.self) { Text(compactDollars(amount)) }
                        }
                    }
                }
                .chartLegend(position: .top, alignment: .leading)
                .frame(height: 220)
            }
        }
    }

    private var chartPoints: [ChartPoint] {
        model.result.years.flatMap { year in
            [
                ChartPoint(x: year.age, y: year.balance.doubleValue, series: Self.futureSeries),
                ChartPoint(x: year.age, y: year.balanceInTodayDollars.doubleValue, series: Self.todaySeries)
            ]
        }
    }

    @ViewBuilder
    private var tableCard: some View {
        if !model.result.years.isEmpty {
            SectionCard(title: "Year by year (today's dollars)") {
                ForEach(model.result.years) { year in
                    ResultRow(label: "Age \(year.age)", value: year.balanceInTodayDollars.asWholeCurrency)
                }
            }
        }
    }
}
