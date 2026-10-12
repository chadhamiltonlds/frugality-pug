import Foundation

public struct RentVsBuyInput: Codable, Equatable {
    public var years: Int
    // Buying
    public var homePrice: Decimal
    public var downPaymentRate: Decimal
    public var mortgageRate: Decimal
    public var mortgageYears: Int
    public var buyClosingCostRate: Decimal
    public var sellingCostRate: Decimal
    /// Yearly property tax as a share of the home's current value.
    public var propertyTaxRate: Decimal
    public var homeInsuranceAnnual: Decimal
    public var hoaMonthly: Decimal
    /// Yearly maintenance as a share of the home's current value.
    public var maintenanceRate: Decimal
    public var appreciationRate: Decimal
    // Renting
    public var monthlyRent: Decimal
    public var rentGrowthRate: Decimal
    public var rentersInsuranceAnnual: Decimal
    // Both
    /// Return earned on money not tied up in the home (the down payment for renters, monthly savings for either side).
    public var investmentReturn: Decimal

    public init(
        years: Int = 10,
        homePrice: Decimal = 400_000,
        downPaymentRate: Decimal = Decimal(20) / 100,
        mortgageRate: Decimal = Decimal(65) / 1000,
        mortgageYears: Int = 30,
        buyClosingCostRate: Decimal = Decimal(3) / 100,
        sellingCostRate: Decimal = Decimal(6) / 100,
        propertyTaxRate: Decimal = Decimal(1) / 100,
        homeInsuranceAnnual: Decimal = 1_800,
        hoaMonthly: Decimal = 0,
        maintenanceRate: Decimal = Decimal(1) / 100,
        appreciationRate: Decimal = Decimal(3) / 100,
        monthlyRent: Decimal = 2_200,
        rentGrowthRate: Decimal = Decimal(3) / 100,
        rentersInsuranceAnnual: Decimal = 200,
        investmentReturn: Decimal = Decimal(7) / 100
    ) {
        self.years = years
        self.homePrice = homePrice
        self.downPaymentRate = downPaymentRate
        self.mortgageRate = mortgageRate
        self.mortgageYears = mortgageYears
        self.buyClosingCostRate = buyClosingCostRate
        self.sellingCostRate = sellingCostRate
        self.propertyTaxRate = propertyTaxRate
        self.homeInsuranceAnnual = homeInsuranceAnnual
        self.hoaMonthly = hoaMonthly
        self.maintenanceRate = maintenanceRate
        self.appreciationRate = appreciationRate
        self.monthlyRent = monthlyRent
        self.rentGrowthRate = rentGrowthRate
        self.rentersInsuranceAnnual = rentersInsuranceAnnual
        self.investmentReturn = investmentReturn
    }
}

public struct RentVsBuyYear: Equatable, Identifiable {
    public let year: Int
    /// Home value after selling costs, minus the loan, plus the buyer's invested savings.
    public let buyerNetWorth: Decimal
    /// The renter's invested down payment, closing costs, and monthly savings.
    public let renterNetWorth: Decimal
    public let homeValue: Decimal
    public let loanBalance: Decimal
    public let buyerTotalPaid: Decimal
    public let renterTotalPaid: Decimal
    public var id: Int { year }
}

public struct RentVsBuyResult: Equatable {
    public let years: [RentVsBuyYear]
    /// First year the buyer's net worth is at least the renter's; nil if never within the horizon.
    public let breakEvenYear: Int?
    public let upfrontCashToBuy: Decimal
    public let monthlyMortgagePayment: Decimal
    public let firstMonthOwnerCost: Decimal
    public let firstMonthRenterCost: Decimal

    /// Buyer minus renter net worth at the end of the horizon (positive favors buying).
    public var finalAdvantageOfBuying: Decimal {
        guard let last = years.last else { return 0 }
        return last.buyerNetWorth - last.renterNetWorth
    }
}

/// Month-by-month comparison. Whoever has the lower monthly cost invests the difference;
/// the renter also invests the cash the buyer spent up front. Home value and rent step up yearly.
/// Not modeled: tax effects (mortgage interest deduction, capital gains), PMI, refinancing.
public enum RentVsBuyCalculator {
    public static func compare(_ input: RentVsBuyInput) -> RentVsBuyResult {
        let years = input.years.clamped(1, 50)
        let price = max(input.homePrice, 0)
        let down = input.downPaymentRate.clamped(to: 0...1)
        let loan = price * (1 - down)
        let rate = max(input.mortgageRate, 0)
        let payment = Mortgage.monthlyPayment(principal: loan, annualRate: rate, years: input.mortgageYears)
        let upfront = price * down + price * max(input.buyClosingCostRate, 0)

        let monthlyInvestReturn = input.investmentReturn.asSafeRate / 12
        let taxRate = max(input.propertyTaxRate, 0)
        let maintenanceRate = max(input.maintenanceRate, 0)
        let insurance = max(input.homeInsuranceAnnual, 0) / 12
        let hoa = max(input.hoaMonthly, 0)
        let rentersInsurance = max(input.rentersInsuranceAnnual, 0) / 12
        let sellingKeep = 1 - input.sellingCostRate.clamped(to: 0...1)
        let appreciation = input.appreciationRate.asSafeRate
        let rentGrowth = input.rentGrowthRate.asSafeRate

        var homeValue = price
        var balance = loan
        var rent = max(input.monthlyRent, 0)
        var buyerInvested: Decimal = 0
        var renterInvested = upfront
        var buyerPaid = upfront
        var renterPaid: Decimal = 0
        var firstOwnerCost: Decimal?
        var firstRenterCost: Decimal?
        var rows: [RentVsBuyYear] = []

        for year in 1...years {
            for _ in 0..<12 {
                let step = Mortgage.step(balance: balance, annualRate: rate, payment: payment)
                balance = step.balance
                let ownerCost = step.interest + step.principal
                    + homeValue * (taxRate + maintenanceRate) / 12 + insurance + hoa
                let renterCost = rent + rentersInsurance
                if firstOwnerCost == nil {
                    firstOwnerCost = ownerCost
                    firstRenterCost = renterCost
                }

                buyerInvested *= 1 + monthlyInvestReturn
                renterInvested *= 1 + monthlyInvestReturn
                if ownerCost > renterCost {
                    renterInvested += ownerCost - renterCost
                } else {
                    buyerInvested += renterCost - ownerCost
                }
                buyerPaid += ownerCost
                renterPaid += renterCost
            }
            homeValue *= 1 + appreciation
            rent *= 1 + rentGrowth

            rows.append(RentVsBuyYear(
                year: year,
                buyerNetWorth: (homeValue * sellingKeep - balance + buyerInvested).roundedToCents(),
                renterNetWorth: renterInvested.roundedToCents(),
                homeValue: homeValue.roundedToCents(),
                loanBalance: balance.roundedToCents(),
                buyerTotalPaid: buyerPaid.roundedToCents(),
                renterTotalPaid: renterPaid.roundedToCents()
            ))
        }

        return RentVsBuyResult(
            years: rows,
            breakEvenYear: rows.first { $0.buyerNetWorth >= $0.renterNetWorth }?.year,
            upfrontCashToBuy: upfront.roundedToCents(),
            monthlyMortgagePayment: payment.roundedToCents(),
            firstMonthOwnerCost: (firstOwnerCost ?? 0).roundedToCents(),
            firstMonthRenterCost: (firstRenterCost ?? 0).roundedToCents()
        )
    }
}
