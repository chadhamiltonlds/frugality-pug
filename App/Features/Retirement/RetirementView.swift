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
            socialSecurityCard
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
            RuledLine()
            ResultRow(label: "You and your employer put in", value: result.totalContributed.asWholeCurrency)
            ResultRow(label: "Investment growth", value: result.totalGrowth.asWholeCurrency)
            ResultRow(label: "Yearly income at \(model.input.withdrawalRate.asPercent)",
                      value: result.annualIncomeInTodayDollars.asWholeCurrency)
            ResultRow(label: "Monthly income from savings", value: result.monthlyIncomeInTodayDollars.asWholeCurrency,
                      emphasized: model.socialSecurity == nil)
            if let ss = model.socialSecurity {
                ResultRow(label: "Social Security from age \(ss.claimAge)", value: ss.monthlyBenefit.asWholeCurrency)
                ResultRow(label: "Total monthly income", value: model.totalMonthlyIncome.asWholeCurrency, emphasized: true)
            }
            Text("Income is in today's dollars.")
                .font(Theme.font(.caption))
                .foregroundStyle(Theme.muted)
        }
    }

    // MARK: - Social Security (optional)

    private var socialSecurity: Binding<SocialSecurityInput> {
        Binding(
            get: { model.input.socialSecurity ?? SocialSecurityInput() },
            set: { model.input.socialSecurity = $0 }
        )
    }

    private var socialSecurityCard: some View {
        SectionCard(title: "Social Security (optional)") {
            Toggle("Include Social Security", isOn: socialSecurity.isOn)
            if socialSecurity.wrappedValue.isOn {
                MoneyField(title: "Typical yearly earnings", value: socialSecurity.annualEarnings)
                Stepper("Years you'll have worked: \(socialSecurity.wrappedValue.yearsWorked)",
                        value: socialSecurity.yearsWorked, in: 0...50)
                Stepper("Start benefits at: \(socialSecurity.wrappedValue.claimAge)",
                        value: socialSecurity.claimAge, in: 62...70)
                if let ss = model.socialSecurity {
                    RuledLine()
                    if ss.eligible {
                        ResultRow(label: "Estimated benefit", value: "\(ss.monthlyBenefit.asWholeCurrency)/mo", emphasized: true)
                        ResultRow(label: "At full retirement age (\(Self.ageText(ss.fullRetirementAgeMonths)))",
                                  value: "\(ss.benefitAtFullRetirementAge.asWholeCurrency)/mo")
                        if ss.claimAdjustment != 0 {
                            ResultRow(label: ss.claimAdjustment < 0 ? "Claiming early" : "Waiting bonus",
                                      value: ss.claimAdjustment.asPercent)
                        }
                    } else {
                        Text("Social Security needs at least 10 years of work with earnings.")
                            .foregroundStyle(Theme.accent)
                    }
                }
                Text("Rough estimate in today's dollars using SSA's 2026 formula, assuming steady earnings. For your actual record, check ssa.gov/myaccount. Spousal benefits and taxes aren't included.")
                    .font(Theme.font(.caption))
                    .foregroundStyle(Theme.muted)
            }
        }
    }

    /// 804 -> "67", 798 -> "66 and 6 mo"
    static func ageText(_ months: Int) -> String {
        months % 12 == 0 ? "\(months / 12)" : "\(months / 12) and \(months % 12) mo"
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
