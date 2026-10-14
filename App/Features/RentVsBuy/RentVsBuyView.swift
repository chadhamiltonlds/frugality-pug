import Charts
import SwiftUI
import FrugalityCore

struct RentVsBuyView: View {
    @StateObject private var model = RentVsBuyViewModel()

    private static let buySeries = "Buy"
    private static let rentSeries = "Rent"

    var body: some View {
        CalculatorScreen(title: "Rent vs Buy") {
            SectionCard(title: "Time frame") {
                LedgerStepper("Compare over", value: $model.input.years, in: 1...40, valueText: LedgerStepper.years)
            }
            SectionCard(title: "Buying") {
                MoneyField(title: "Home price", value: $model.input.homePrice)
                PercentField(title: "Down payment", value: $model.input.downPaymentRate)
                PercentField(title: "Mortgage rate", value: $model.input.mortgageRate)
                LedgerStepper("Loan term", value: $model.input.mortgageYears, in: 5...40, step: 5, valueText: LedgerStepper.years)
                PercentField(title: "Closing costs", value: $model.input.buyClosingCostRate)
                PercentField(title: "Selling costs", value: $model.input.sellingCostRate)
                PercentField(title: "Property tax (yearly)", value: $model.input.propertyTaxRate)
                MoneyField(title: "Home insurance (yearly)", value: $model.input.homeInsuranceAnnual)
                MoneyField(title: "HOA (monthly)", value: $model.input.hoaMonthly)
                PercentField(title: "Maintenance (yearly)", value: $model.input.maintenanceRate)
                PercentField(title: "Home value growth", value: $model.input.appreciationRate)
            }
            SectionCard(title: "Renting") {
                MoneyField(title: "Monthly rent", value: $model.input.monthlyRent)
                PercentField(title: "Rent increase (yearly)", value: $model.input.rentGrowthRate)
                MoneyField(title: "Renter's insurance (yearly)", value: $model.input.rentersInsuranceAnnual)
            }
            SectionCard(title: "Investing") {
                PercentField(title: "Return on invested savings", value: $model.input.investmentReturn)
            }
            resultCard
            chartCard
            tableCard
        }
        .tint(Theme.accent)
    }

    private var resultCard: some View {
        let result = model.result
        let advantage = result.finalAdvantageOfBuying
        let years = result.years.count
        return ReceiptCard(title: "After \(LedgerStepper.years(years))") {
            HeadlineNumber(
                caption: advantage >= 0 ? "Buying comes out ahead by" : "Renting comes out ahead by",
                value: (advantage >= 0 ? advantage : -advantage).asWholeCurrency,
                color: advantage >= 0 ? ChartColors.series1 : ChartColors.series2,
                footnote: result.breakEvenYear.map { "Buying pulls ahead in year \($0)" }
                    ?? "Buying doesn't pull ahead within \(years) years"
            )
            DashedRule()
            ResultRow(label: "Cash to buy (down + closing)", value: result.upfrontCashToBuy.asWholeCurrency)
            ResultRow(label: "Mortgage payment", value: result.monthlyMortgagePayment.asCurrency)
            ResultRow(label: "First month owning, all in", value: result.firstMonthOwnerCost.asCurrency)
            ResultRow(label: "First month renting", value: result.firstMonthRenterCost.asCurrency)
            Text("Whoever spends less each month invests the difference. Taxes, PMI and refinancing aren't included.")
                .font(.caption)
                .foregroundStyle(Theme.muted)
        }
    }

    private var chartCard: some View {
        SectionCard(title: "Net worth by year") {
            Chart(chartPoints) { point in
                LineMark(x: .value("Year", point.x), y: .value("Net worth", point.y))
                    .foregroundStyle(by: .value("Choice", point.series))
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
            .chartForegroundStyleScale([
                Self.buySeries: ChartColors.series1,
                Self.rentSeries: ChartColors.series2
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

    private var chartPoints: [ChartPoint] {
        model.result.years.flatMap { year in
            [
                ChartPoint(x: year.year, y: year.buyerNetWorth.doubleValue, series: Self.buySeries),
                ChartPoint(x: year.year, y: year.renterNetWorth.doubleValue, series: Self.rentSeries)
            ]
        }
    }

    private var tableCard: some View {
        SectionCard(title: "Net worth, year by year") {
            LedgerTable(
                headers: ["Year", "Buy", "Rent"],
                rows: model.result.years.map { year in
                    LedgerTable.Row(id: year.year,
                                    cells: ["\(year.year)", year.buyerNetWorth.asWholeCurrency,
                                            year.renterNetWorth.asWholeCurrency])
                }
            )
        }
    }
}
