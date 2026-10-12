import Foundation

public struct SnowballInput: Codable, Equatable {
    public var years: Int
    public var startingCash: Decimal
    /// Outside money added to the cash pile every month (from your paycheck).
    public var monthlySavings: Decimal
    /// Price of each property today; later purchases cost more as prices appreciate.
    public var propertyPrice: Decimal
    public var downPaymentRate: Decimal
    public var closingCostRate: Decimal
    public var mortgageRate: Decimal
    public var mortgageYears: Int
    public var monthlyRent: Decimal
    public var vacancyRate: Decimal
    /// Share of rent set aside for repairs and capital expenses.
    public var maintenanceRate: Decimal
    /// Share of rent paid to a property manager.
    public var managementRate: Decimal
    /// Property taxes plus insurance per property per year, at today's price.
    public var annualTaxesAndInsurance: Decimal
    public var appreciationRate: Decimal
    public var rentGrowthRate: Decimal
    /// When false, positive cash flow is spent rather than saved toward the next property.
    public var reinvestCashFlow: Bool
    public var maxProperties: Int

    public init(
        years: Int = 20,
        startingCash: Decimal = 75_000,
        monthlySavings: Decimal = 1_000,
        propertyPrice: Decimal = 250_000,
        downPaymentRate: Decimal = Decimal(25) / 100,
        closingCostRate: Decimal = Decimal(3) / 100,
        mortgageRate: Decimal = Decimal(7) / 100,
        mortgageYears: Int = 30,
        monthlyRent: Decimal = 2_200,
        vacancyRate: Decimal = Decimal(5) / 100,
        maintenanceRate: Decimal = Decimal(8) / 100,
        managementRate: Decimal = Decimal(8) / 100,
        annualTaxesAndInsurance: Decimal = 4_500,
        appreciationRate: Decimal = Decimal(3) / 100,
        rentGrowthRate: Decimal = Decimal(3) / 100,
        reinvestCashFlow: Bool = true,
        maxProperties: Int = 50
    ) {
        self.years = years
        self.startingCash = startingCash
        self.monthlySavings = monthlySavings
        self.propertyPrice = propertyPrice
        self.downPaymentRate = downPaymentRate
        self.closingCostRate = closingCostRate
        self.mortgageRate = mortgageRate
        self.mortgageYears = mortgageYears
        self.monthlyRent = monthlyRent
        self.vacancyRate = vacancyRate
        self.maintenanceRate = maintenanceRate
        self.managementRate = managementRate
        self.annualTaxesAndInsurance = annualTaxesAndInsurance
        self.appreciationRate = appreciationRate
        self.rentGrowthRate = rentGrowthRate
        self.reinvestCashFlow = reinvestCashFlow
        self.maxProperties = maxProperties
    }
}

public struct SnowballPurchase: Equatable, Identifiable {
    /// 1 for the first property, 2 for the second, ...
    public let number: Int
    /// Months from the start (0 = bought immediately).
    public let month: Int
    public let price: Decimal
    public var id: Int { number }
}

public struct SnowballYear: Equatable, Identifiable {
    public let year: Int
    public let propertiesOwned: Int
    public let portfolioValue: Decimal
    public let totalDebt: Decimal
    public let equity: Decimal
    public let cash: Decimal
    /// Rental cash flow over the year, after all property expenses and mortgage payments.
    public let annualCashFlow: Decimal
    public var netWorth: Decimal { equity + cash }
    public var id: Int { year }
}

public struct SnowballResult: Equatable {
    public let purchases: [SnowballPurchase]
    public let years: [SnowballYear]
    /// Down payment plus closing costs for a property at today's price.
    public let cashNeededPerProperty: Decimal
    /// Monthly cash flow of a property bought today, in its first month.
    public let monthlyCashFlowPerProperty: Decimal
}

/// Simulates buying rentals month by month. Each month every property collects rent and pays its
/// expenses and mortgage; savings (and, if reinvesting, the cash flow) go into a cash pile; whenever
/// the pile covers a down payment plus closing costs, another property is bought at the current price.
/// Prices, rents, and taxes step up once a year. Negative cash flow always comes out of the pile.
/// Not modeled: refinancing, income tax, selling.
public enum SnowballCalculator {
    private struct Property {
        var value: Decimal
        var loanBalance: Decimal
        let payment: Decimal
        var rent: Decimal
        var taxesAndInsurance: Decimal
    }

    public static func simulate(_ input: SnowballInput) -> SnowballResult {
        let months = input.years.clamped(1, 50) * 12
        let cap = input.maxProperties.clamped(0, 500)
        let down = input.downPaymentRate.clamped(to: 0...1)
        let closing = max(input.closingCostRate, 0)
        let rate = max(input.mortgageRate, 0)
        let mortgageYears = max(input.mortgageYears, 1)
        let vacancy = input.vacancyRate.clamped(to: 0...1)
        let rentExpenseRate = max(input.maintenanceRate, 0) + max(input.managementRate, 0)
        let savings = max(input.monthlySavings, 0)
        let appreciation = input.appreciationRate.asSafeRate
        let rentGrowth = input.rentGrowthRate.asSafeRate

        var cash = max(input.startingCash, 0)
        var marketPrice = max(input.propertyPrice, 0)
        var marketRent = max(input.monthlyRent, 0)
        var marketTaxes = max(input.annualTaxesAndInsurance, 0)
        var properties: [Property] = []
        var purchases: [SnowballPurchase] = []
        var years: [SnowballYear] = []
        var yearCashFlow: Decimal = 0

        func monthlyCashFlow(rent: Decimal, taxes: Decimal, mortgagePaid: Decimal) -> Decimal {
            rent * (1 - vacancy) - rent * rentExpenseRate - taxes / 12 - mortgagePaid
        }

        func buyWhileAffordable(month: Int) {
            guard marketPrice > 0 else { return }
            let needed = marketPrice * (down + closing)
            while properties.count < cap && cash >= needed {
                cash -= needed
                let loan = marketPrice * (1 - down)
                properties.append(Property(
                    value: marketPrice,
                    loanBalance: loan,
                    payment: Mortgage.monthlyPayment(principal: loan, annualRate: rate, years: mortgageYears),
                    rent: marketRent,
                    taxesAndInsurance: marketTaxes
                ))
                purchases.append(SnowballPurchase(number: properties.count, month: month, price: marketPrice.roundedToCents()))
            }
        }

        let firstPayment = Mortgage.monthlyPayment(
            principal: marketPrice * (1 - down), annualRate: rate, years: mortgageYears
        )
        let cashNeeded = marketPrice * (down + closing)
        let firstMonthFlow = monthlyCashFlow(rent: marketRent, taxes: marketTaxes, mortgagePaid: firstPayment)

        buyWhileAffordable(month: 0)

        for month in 1...months {
            var flow: Decimal = 0
            for index in properties.indices {
                let step = Mortgage.step(
                    balance: properties[index].loanBalance, annualRate: rate, payment: properties[index].payment
                )
                properties[index].loanBalance = step.balance
                flow += monthlyCashFlow(
                    rent: properties[index].rent,
                    taxes: properties[index].taxesAndInsurance,
                    mortgagePaid: step.interest + step.principal
                )
            }
            yearCashFlow += flow
            cash += savings
            if input.reinvestCashFlow || flow < 0 {
                cash += flow
            }

            if month % 12 == 0 {
                for index in properties.indices {
                    properties[index].value *= 1 + appreciation
                    properties[index].rent *= 1 + rentGrowth
                    properties[index].taxesAndInsurance *= 1 + appreciation
                }
                marketPrice *= 1 + appreciation
                marketRent *= 1 + rentGrowth
                marketTaxes *= 1 + appreciation
            }

            buyWhileAffordable(month: month)

            if month % 12 == 0 {
                let value = properties.reduce(Decimal(0)) { $0 + $1.value }
                let debt = properties.reduce(Decimal(0)) { $0 + $1.loanBalance }
                years.append(SnowballYear(
                    year: month / 12,
                    propertiesOwned: properties.count,
                    portfolioValue: value.roundedToCents(),
                    totalDebt: debt.roundedToCents(),
                    equity: (value - debt).roundedToCents(),
                    cash: cash.roundedToCents(),
                    annualCashFlow: yearCashFlow.roundedToCents()
                ))
                yearCashFlow = 0
            }
        }

        return SnowballResult(
            purchases: purchases,
            years: years,
            cashNeededPerProperty: cashNeeded.roundedToCents(),
            monthlyCashFlowPerProperty: firstMonthFlow.roundedToCents()
        )
    }
}
