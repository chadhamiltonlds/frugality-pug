import Charts
import SwiftUI
import FrugalityCore

struct SnowballView: View {
    @StateObject private var model = SnowballViewModel()

    var body: some View {
        CalculatorScreen(title: "Property Snowball") {
            SectionCard(title: "Plan") {
                Stepper("Run for \(model.input.years) years", value: $model.input.years, in: 1...40)
                MoneyField(title: "Cash to start", value: $model.input.startingCash)
                MoneyField(title: "Savings added per month", value: $model.input.monthlySavings)
                Toggle("Reinvest rental cash flow", isOn: $model.input.reinvestCashFlow)
                Stepper("Stop at \(model.input.maxProperties) properties", value: $model.input.maxProperties, in: 1...100)
            }
            SectionCard(title: "Each property (today's prices)") {
                MoneyField(title: "Price", value: $model.input.propertyPrice)
                PercentField(title: "Down payment", value: $model.input.downPaymentRate)
                PercentField(title: "Closing costs", value: $model.input.closingCostRate)
                PercentField(title: "Mortgage rate", value: $model.input.mortgageRate)
                Stepper("Loan term: \(model.input.mortgageYears) years", value: $model.input.mortgageYears, in: 5...40, step: 5)
                MoneyField(title: "Monthly rent", value: $model.input.monthlyRent)
                PercentField(title: "Vacancy", value: $model.input.vacancyRate)
                PercentField(title: "Repairs (share of rent)", value: $model.input.maintenanceRate)
                PercentField(title: "Management (share of rent)", value: $model.input.managementRate)
                MoneyField(title: "Taxes + insurance (yearly)", value: $model.input.annualTaxesAndInsurance)
            }
            SectionCard(title: "Growth") {
                PercentField(title: "Home value growth", value: $model.input.appreciationRate)
                PercentField(title: "Rent growth", value: $model.input.rentGrowthRate)
            }
            resultCard
            purchasesCard
            chartCard
            tableCard
        }
        .tint(Theme.accent)
    }

    private var resultCard: some View {
        let result = model.result
        let last = result.years.last
        let flow = result.monthlyCashFlowPerProperty
        return SectionCard(title: "After \(result.years.count) years") {
            HeadlineNumber(
                caption: "Properties owned",
                value: "\(last?.propertiesOwned ?? 0)",
                footnote: last.map { "Net worth from real estate: \($0.netWorth.asWholeCurrency) (equity + cash)" }
            )
            RuledLine()
            ResultRow(label: "Cash needed per property", value: result.cashNeededPerProperty.asWholeCurrency)
            ResultRow(label: "Cash flow per property (month 1)", value: flow.asCurrency,
                      valueColor: flow >= 0 ? Theme.positive : Theme.accent)
            if let last {
                ResultRow(label: "Equity", value: last.equity.asWholeCurrency)
                ResultRow(label: "Cash on hand", value: last.cash.asWholeCurrency)
                ResultRow(label: "Cash flow in the last year", value: last.annualCashFlow.asWholeCurrency)
            }
            Text("Each month, rent pays expenses and the mortgage; savings and cash flow pile up until the next down payment is covered. Taxes, refinancing and selling aren't included.")
                .font(Theme.font(.caption))
                .foregroundStyle(Theme.muted)
        }
    }

    private var purchasesCard: some View {
        SectionCard(title: "Purchases") {
            if model.result.purchases.isEmpty {
                Text("Not enough cash for a down payment yet.")
                    .foregroundStyle(Theme.muted)
            }
            ForEach(model.result.purchases) { purchase in
                ResultRow(label: "#\(purchase.number) · \(Self.timing(purchase.month))", value: purchase.price.asWholeCurrency)
            }
        }
    }

    private var chartCard: some View {
        SectionCard(title: "Real estate net worth by year") {
            Chart(model.result.years) { year in
                BarMark(x: .value("Year", year.year), y: .value("Net worth", year.netWorth.doubleValue))
                    .foregroundStyle(ChartColors.series1)
                    .cornerRadius(4)
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

    private var tableCard: some View {
        SectionCard(title: "Year by year: properties · equity · cash") {
            ForEach(model.result.years) { year in
                HStack {
                    Text("Year \(year.year)")
                    Spacer()
                    Text("\(year.propertiesOwned) · \(year.equity.asWholeCurrency) · \(year.cash.asWholeCurrency)")
                        .monospacedDigit()
                }
                .foregroundStyle(Theme.ink)
            }
        }
    }

    /// "Day one", "8 mo", "5 yr 4 mo"
    static func timing(_ month: Int) -> String {
        if month == 0 { return "Day one" }
        let years = month / 12
        let months = month % 12
        switch (years, months) {
        case (0, _): return "\(months) mo"
        case (_, 0): return "\(years) yr"
        default: return "\(years) yr \(months) mo"
        }
    }
}
