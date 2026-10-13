import Foundation

public struct RentalAnalysisInput: Codable, Equatable {
    // Purchase
    public var purchasePrice: Decimal
    public var downPaymentRate: Decimal
    public var closingCostRate: Decimal
    /// Repairs or rehab paid up front, in cash.
    public var upfrontRepairs: Decimal
    public var mortgageRate: Decimal
    public var mortgageYears: Int
    // Income
    public var monthlyRent: Decimal
    public var otherMonthlyIncome: Decimal
    public var vacancyRate: Decimal
    // Expenses
    public var propertyTaxAnnual: Decimal
    public var insuranceAnnual: Decimal
    public var hoaMonthly: Decimal
    /// Utilities the owner pays.
    public var utilitiesMonthly: Decimal
    /// Repairs, capital expenses (roof, HVAC...), and management, each a share of gross rent.
    public var maintenanceRate: Decimal
    public var capexRate: Decimal
    public var managementRate: Decimal
    public var appreciationRate: Decimal
    // Targets for the verdict
    public var targetMonthlyCashFlow: Decimal
    public var targetCashOnCash: Decimal
    public var targetCapRate: Decimal
    public var targetDSCR: Decimal
    /// Monthly rent as a share of price ("1% rule" = 0.01).
    public var targetRentToPrice: Decimal

    public init(
        purchasePrice: Decimal = 300_000,
        downPaymentRate: Decimal = Decimal(25) / 100,
        closingCostRate: Decimal = Decimal(3) / 100,
        upfrontRepairs: Decimal = 0,
        mortgageRate: Decimal = Decimal(7) / 100,
        mortgageYears: Int = 30,
        monthlyRent: Decimal = 2_400,
        otherMonthlyIncome: Decimal = 0,
        vacancyRate: Decimal = Decimal(5) / 100,
        propertyTaxAnnual: Decimal = 3_600,
        insuranceAnnual: Decimal = 1_500,
        hoaMonthly: Decimal = 0,
        utilitiesMonthly: Decimal = 0,
        maintenanceRate: Decimal = Decimal(8) / 100,
        capexRate: Decimal = Decimal(5) / 100,
        managementRate: Decimal = Decimal(8) / 100,
        appreciationRate: Decimal = Decimal(3) / 100,
        targetMonthlyCashFlow: Decimal = 200,
        targetCashOnCash: Decimal = Decimal(8) / 100,
        targetCapRate: Decimal = Decimal(6) / 100,
        targetDSCR: Decimal = Decimal(125) / 100,
        targetRentToPrice: Decimal = Decimal(1) / 100
    ) {
        self.purchasePrice = purchasePrice
        self.downPaymentRate = downPaymentRate
        self.closingCostRate = closingCostRate
        self.upfrontRepairs = upfrontRepairs
        self.mortgageRate = mortgageRate
        self.mortgageYears = mortgageYears
        self.monthlyRent = monthlyRent
        self.otherMonthlyIncome = otherMonthlyIncome
        self.vacancyRate = vacancyRate
        self.propertyTaxAnnual = propertyTaxAnnual
        self.insuranceAnnual = insuranceAnnual
        self.hoaMonthly = hoaMonthly
        self.utilitiesMonthly = utilitiesMonthly
        self.maintenanceRate = maintenanceRate
        self.capexRate = capexRate
        self.managementRate = managementRate
        self.appreciationRate = appreciationRate
        self.targetMonthlyCashFlow = targetMonthlyCashFlow
        self.targetCashOnCash = targetCashOnCash
        self.targetCapRate = targetCapRate
        self.targetDSCR = targetDSCR
        self.targetRentToPrice = targetRentToPrice
    }
}

public enum RentalCheckKind: String, CaseIterable, Identifiable {
    case cashFlow, cashOnCash, capRate, debtCoverage, rentToPrice
    public var id: String { rawValue }
}

/// One pass/fail test. `actual` is nil when the measure is undefined (e.g. no loan, no cash invested).
public struct RentalCheck: Equatable, Identifiable {
    public let kind: RentalCheckKind
    public let actual: Decimal?
    public let target: Decimal
    public let passed: Bool
    public var id: String { kind.rawValue }
}

public enum RentalVerdict: String, Equatable {
    case good, borderline, weak
}

public struct RentalAnalysisResult: Equatable {
    public let loanAmount: Decimal
    public let monthlyMortgagePayment: Decimal
    public let cashInvested: Decimal
    // Monthly figures
    public let grossIncome: Decimal
    public let vacancyLoss: Decimal
    public let operatingExpenses: Decimal
    public let netOperatingIncome: Decimal
    public let cashFlow: Decimal
    // Yearly figures and ratios
    public let annualCashFlow: Decimal
    public let annualNetOperatingIncome: Decimal
    public let capRate: Decimal?
    public let cashOnCash: Decimal?
    public let debtCoverageRatio: Decimal?
    public let rentToPrice: Decimal?
    public let grossRentMultiplier: Decimal?
    /// Share of gross income needed to cover expenses and the mortgage; nil with no income.
    public let breakEvenOccupancy: Decimal?
    public let firstYearPrincipalPaydown: Decimal
    public let firstYearAppreciation: Decimal
    /// (Cash flow + principal paydown + appreciation) / cash invested, first year; nil with no cash invested.
    public let firstYearTotalReturn: Decimal?
    public let checks: [RentalCheck]
    public let verdict: RentalVerdict
}

/// First-year rental analysis. Repairs, capex, and management are shares of gross rent (rent + other income).
/// Verdict: good = at least 4 of 5 checks pass and cash flow is positive; weak = cash flow is negative or at
/// most 1 check passes; otherwise borderline.
public enum RentalAnalysisCalculator {
    public static func analyze(_ input: RentalAnalysisInput) -> RentalAnalysisResult {
        let price = max(input.purchasePrice, 0)
        let down = input.downPaymentRate.clamped(to: 0...1)
        let rate = max(input.mortgageRate, 0)
        let loan = price * (1 - down)
        let payment = Mortgage.monthlyPayment(principal: loan, annualRate: rate, years: input.mortgageYears)
        let cashInvested = price * down + price * max(input.closingCostRate, 0) + max(input.upfrontRepairs, 0)

        let rent = max(input.monthlyRent, 0)
        let gross = rent + max(input.otherMonthlyIncome, 0)
        let vacancyLoss = gross * input.vacancyRate.clamped(to: 0...1)
        let rentShare = max(input.maintenanceRate, 0) + max(input.capexRate, 0) + max(input.managementRate, 0)
        let expenses = max(input.propertyTaxAnnual, 0) / 12 + max(input.insuranceAnnual, 0) / 12
            + max(input.hoaMonthly, 0) + max(input.utilitiesMonthly, 0) + gross * rentShare
        let noi = gross - vacancyLoss - expenses
        // Rounded once, so checks and verdict agree with the cents shown on screen.
        let cashFlow = (noi - payment).roundedToCents()
        let annualCashFlow = cashFlow * 12
        let annualNOI = noi * 12

        var balance = loan
        var principalPaid: Decimal = 0
        for _ in 0..<12 {
            let step = Mortgage.step(balance: balance, annualRate: rate, payment: payment)
            principalPaid += step.principal
            balance = step.balance
        }
        let appreciation = price * input.appreciationRate.asSafeRate

        let capRate: Decimal? = price > 0 ? annualNOI / price : nil
        let cashOnCash: Decimal? = cashInvested > 0 ? annualCashFlow / cashInvested : nil
        let dscr: Decimal? = payment > 0 ? noi / payment : nil
        let rentToPrice: Decimal? = price > 0 ? rent / price : nil

        let checks = [
            RentalCheck(kind: .cashFlow, actual: cashFlow, target: input.targetMonthlyCashFlow,
                        passed: cashFlow >= input.targetMonthlyCashFlow),
            RentalCheck(kind: .cashOnCash, actual: cashOnCash, target: input.targetCashOnCash,
                        passed: cashOnCash.map { $0 >= input.targetCashOnCash } ?? (annualCashFlow > 0)),
            RentalCheck(kind: .capRate, actual: capRate, target: input.targetCapRate,
                        passed: capRate.map { $0 >= input.targetCapRate } ?? false),
            RentalCheck(kind: .debtCoverage, actual: dscr, target: input.targetDSCR,
                        passed: dscr.map { $0 >= input.targetDSCR } ?? true),
            RentalCheck(kind: .rentToPrice, actual: rentToPrice, target: input.targetRentToPrice,
                        passed: rentToPrice.map { $0 >= input.targetRentToPrice } ?? false)
        ]
        let passedCount = checks.filter(\.passed).count
        let verdict: RentalVerdict
        if cashFlow < 0 || passedCount <= 1 {
            verdict = .weak
        } else if passedCount >= 4 && cashFlow > 0 {
            verdict = .good
        } else {
            verdict = .borderline
        }

        return RentalAnalysisResult(
            loanAmount: loan.roundedToCents(),
            monthlyMortgagePayment: payment.roundedToCents(),
            cashInvested: cashInvested.roundedToCents(),
            grossIncome: gross.roundedToCents(),
            vacancyLoss: vacancyLoss.roundedToCents(),
            operatingExpenses: expenses.roundedToCents(),
            netOperatingIncome: noi.roundedToCents(),
            cashFlow: cashFlow,
            annualCashFlow: annualCashFlow.roundedToCents(),
            annualNetOperatingIncome: annualNOI.roundedToCents(),
            capRate: capRate,
            cashOnCash: cashOnCash,
            debtCoverageRatio: dscr,
            rentToPrice: rentToPrice,
            grossRentMultiplier: gross > 0 ? price / (gross * 12) : nil,
            breakEvenOccupancy: gross > 0 ? (expenses + payment) / gross : nil,
            firstYearPrincipalPaydown: principalPaid.roundedToCents(),
            firstYearAppreciation: appreciation.roundedToCents(),
            firstYearTotalReturn: cashInvested > 0 ? (annualCashFlow + principalPaid + appreciation) / cashInvested : nil,
            checks: checks,
            verdict: verdict
        )
    }
}
