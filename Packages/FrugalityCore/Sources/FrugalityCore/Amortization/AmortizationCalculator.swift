import Foundation

public struct AmortizationInput: Codable, Equatable {
    public var loanAmount: Decimal
    public var annualRate: Decimal
    public var termYears: Int
    /// Extra principal paid every month on top of the scheduled payment.
    public var extraMonthlyPayment: Decimal
    /// Years after the first payment at which to report the remaining balance.
    public var checkAfterYears: Int

    public init(
        loanAmount: Decimal = 320_000,
        annualRate: Decimal = Decimal(65) / 1000,
        termYears: Int = 30,
        extraMonthlyPayment: Decimal = 0,
        checkAfterYears: Int = 5
    ) {
        self.loanAmount = loanAmount
        self.annualRate = annualRate
        self.termYears = termYears
        self.extraMonthlyPayment = extraMonthlyPayment
        self.checkAfterYears = checkAfterYears
    }
}

public struct AmortizationYear: Equatable, Identifiable {
    public let year: Int
    public let principalPaid: Decimal
    public let interestPaid: Decimal
    /// Balance still owed at the end of this year.
    public let balance: Decimal
    public let totalInterestSoFar: Decimal
    public var id: Int { year }
}

public struct AmortizationResult: Equatable {
    /// Scheduled principal + interest payment (without the extra).
    public let monthlyPayment: Decimal
    public let years: [AmortizationYear]
    /// Months until the balance reaches 0, including extra payments.
    public let payoffMonths: Int
    public let totalInterest: Decimal
    public let totalPaid: Decimal
    /// Interest avoided by the extra payments, versus the scheduled payment alone.
    public let interestSaved: Decimal
    /// Balance after `checkAfterYears` (0 once paid off).
    public let balanceAtCheck: Decimal
    /// Share of the original loan paid off by `checkAfterYears`.
    public let paidOffShareAtCheck: Decimal
}

/// Standard fixed-rate amortization, month by month, with optional extra principal each month.
/// Inputs are clamped: term 1...50 years, check year 0...term, negatives treated as 0.
public enum AmortizationCalculator {
    public static func schedule(_ input: AmortizationInput) -> AmortizationResult {
        let loan = max(input.loanAmount, 0)
        let rate = max(input.annualRate, 0)
        let term = input.termYears.clamped(1, 50)
        let extra = max(input.extraMonthlyPayment, 0)
        let checkMonths = input.checkAfterYears.clamped(0, term) * 12
        let payment = Mortgage.monthlyPayment(principal: loan, annualRate: rate, years: term)

        let withExtra = run(loan: loan, rate: rate, payment: payment, extra: extra, months: term * 12, checkMonths: checkMonths)
        let scheduledInterest = extra > 0
            ? run(loan: loan, rate: rate, payment: payment, extra: 0, months: term * 12, checkMonths: 0).totalInterest
            : withExtra.totalInterest

        return AmortizationResult(
            monthlyPayment: payment.roundedToCents(),
            years: withExtra.years,
            payoffMonths: withExtra.payoffMonths,
            totalInterest: withExtra.totalInterest.roundedToCents(),
            totalPaid: (loan + withExtra.totalInterest).roundedToCents(),
            interestSaved: max(scheduledInterest - withExtra.totalInterest, 0).roundedToCents(),
            balanceAtCheck: withExtra.balanceAtCheck.roundedToCents(),
            paidOffShareAtCheck: loan > 0 ? (loan - withExtra.balanceAtCheck.roundedToCents()) / loan : 0
        )
    }

    private struct Run {
        var years: [AmortizationYear] = []
        var payoffMonths = 0
        var totalInterest: Decimal = 0
        var balanceAtCheck: Decimal = 0
    }

    private static func run(loan: Decimal, rate: Decimal, payment: Decimal, extra: Decimal,
                            months: Int, checkMonths: Int) -> Run {
        var result = Run()
        var balance = loan
        var yearPrincipal: Decimal = 0
        var yearInterest: Decimal = 0
        if checkMonths == 0 { result.balanceAtCheck = loan }

        for month in 1...months {
            guard balance > 0 else { break }
            let step = Mortgage.step(balance: balance, annualRate: rate, payment: payment + extra)
            balance = step.balance
            yearPrincipal += step.principal
            yearInterest += step.interest
            result.totalInterest += step.interest
            result.payoffMonths = month
            if month == checkMonths { result.balanceAtCheck = balance }

            if month % 12 == 0 || balance <= 0 {
                result.years.append(AmortizationYear(
                    year: (month + 11) / 12,
                    principalPaid: yearPrincipal.roundedToCents(),
                    interestPaid: yearInterest.roundedToCents(),
                    balance: balance.roundedToCents(),
                    totalInterestSoFar: result.totalInterest.roundedToCents()
                ))
                yearPrincipal = 0
                yearInterest = 0
            }
        }
        return result
    }
}
