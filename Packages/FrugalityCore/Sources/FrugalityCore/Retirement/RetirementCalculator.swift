import Foundation

public struct RetirementInput: Codable, Equatable {
    public var currentAge: Int
    public var retirementAge: Int
    public var currentSavings: Decimal
    public var monthlyContribution: Decimal
    public var employerMonthlyContribution: Decimal
    /// Yearly increase in contributions (raises), e.g. 0.02.
    public var contributionGrowthRate: Decimal
    /// Expected yearly return, compounded monthly.
    public var annualReturn: Decimal
    public var inflationRate: Decimal
    /// Share of the balance withdrawn per year in retirement, e.g. 0.04.
    public var withdrawalRate: Decimal
    /// Optional Social Security estimate. Optional so inputs saved before it existed still load.
    public var socialSecurity: SocialSecurityInput?

    public init(
        currentAge: Int = 30,
        retirementAge: Int = 65,
        currentSavings: Decimal = 0,
        monthlyContribution: Decimal = 0,
        employerMonthlyContribution: Decimal = 0,
        contributionGrowthRate: Decimal = Decimal(2) / 100,
        annualReturn: Decimal = Decimal(7) / 100,
        inflationRate: Decimal = Decimal(3) / 100,
        withdrawalRate: Decimal = Decimal(4) / 100,
        socialSecurity: SocialSecurityInput? = nil
    ) {
        self.currentAge = currentAge
        self.retirementAge = retirementAge
        self.currentSavings = currentSavings
        self.monthlyContribution = monthlyContribution
        self.employerMonthlyContribution = employerMonthlyContribution
        self.contributionGrowthRate = contributionGrowthRate
        self.annualReturn = annualReturn
        self.inflationRate = inflationRate
        self.withdrawalRate = withdrawalRate
        self.socialSecurity = socialSecurity
    }
}

public struct RetirementYear: Equatable, Identifiable {
    public let yearIndex: Int
    public let age: Int
    public let balance: Decimal
    public let balanceInTodayDollars: Decimal
    /// Starting savings plus every contribution so far.
    public let totalContributed: Decimal
    public var id: Int { yearIndex }
}

public struct RetirementResult: Equatable {
    public let years: [RetirementYear]
    public let finalBalance: Decimal
    public let finalBalanceInTodayDollars: Decimal
    public let totalContributed: Decimal
    public let totalGrowth: Decimal
    public let annualIncome: Decimal
    public let annualIncomeInTodayDollars: Decimal

    public var monthlyIncomeInTodayDollars: Decimal {
        (annualIncomeInTodayDollars / 12).roundedToCents()
    }
}

/// Projects retirement savings month by month: growth first, then that month's contribution.
/// Contributions rise once a year by `contributionGrowthRate`. Ages are clamped to 0...120.
public enum RetirementCalculator {
    public static func project(_ input: RetirementInput) -> RetirementResult {
        let startAge = input.currentAge.clamped(0, 120)
        let endAge = input.retirementAge.clamped(startAge, 120)
        let yearCount = endAge - startAge

        let monthlyReturn = input.annualReturn.asSafeRate / 12
        let inflation = input.inflationRate.asSafeRate
        let contributionGrowth = input.contributionGrowthRate.asSafeRate

        var balance = max(input.currentSavings, 0)
        var contributed = balance
        var monthly = max(input.monthlyContribution, 0) + max(input.employerMonthlyContribution, 0)
        var rows: [RetirementYear] = []

        for year in stride(from: 1, through: yearCount, by: 1) {
            for _ in 0..<12 {
                balance = balance * (1 + monthlyReturn) + monthly
                contributed += monthly
            }
            let deflator = pow(1 + inflation, year)
            rows.append(RetirementYear(
                yearIndex: year,
                age: startAge + year,
                balance: balance.roundedToCents(),
                balanceInTodayDollars: (balance / deflator).roundedToCents(),
                totalContributed: contributed.roundedToCents()
            ))
            monthly *= 1 + contributionGrowth
        }

        let todayDollars = balance / pow(1 + inflation, yearCount)
        let withdrawal = max(input.withdrawalRate, 0)
        return RetirementResult(
            years: rows,
            finalBalance: balance.roundedToCents(),
            finalBalanceInTodayDollars: todayDollars.roundedToCents(),
            totalContributed: contributed.roundedToCents(),
            totalGrowth: (balance - contributed).roundedToCents(),
            annualIncome: (balance * withdrawal).roundedToCents(),
            annualIncomeInTodayDollars: (todayDollars * withdrawal).roundedToCents()
        )
    }
}
