import Foundation

/// Optional Social Security add-on for the retirement projection. Nil on `RetirementInput` means never set up.
public struct SocialSecurityInput: Codable, Equatable {
    public var isOn: Bool
    /// Typical yearly earnings over a career, in today's dollars (capped at the Social Security wage base).
    public var annualEarnings: Decimal
    /// Total years with earnings by the time benefits start. 35 count; fewer than 10 means no benefit.
    public var yearsWorked: Int
    public var claimAge: Int

    public init(isOn: Bool = false, annualEarnings: Decimal = 0, yearsWorked: Int = 35, claimAge: Int = 67) {
        self.isOn = isOn
        self.annualEarnings = annualEarnings
        self.yearsWorked = yearsWorked
        self.claimAge = claimAge
    }
}

public struct SocialSecurityEstimate: Equatable {
    /// False with fewer than the minimum years of work (10) or no earnings.
    public let eligible: Bool
    public let claimAge: Int
    public let fullRetirementAgeMonths: Int
    /// Monthly benefit at full retirement age (primary insurance amount), today's dollars.
    public let benefitAtFullRetirementAge: Decimal
    /// Change for claiming early (negative) or late (positive), e.g. -0.30 at 62 with a full retirement age of 67.
    public let claimAdjustment: Decimal
    public let monthlyBenefit: Decimal
    public var annualBenefit: Decimal { monthlyBenefit * 12 }
}

/// Social Security rules for one year, from `Resources/tax/<year>/social-security.json`.
/// Rough estimate: assumes steady career earnings in today's dollars, so the result is in today's dollars.
/// Not modeled: spousal/survivor benefits, the earnings test, taxation of benefits, WEP/GPO.
public struct SocialSecurityData {
    let year: Int
    let bendPoints: [Decimal]
    let factors: [Decimal]
    let wageBase: Decimal
    let computationYears: Int
    let minimumYears: Int
    let earliestClaimAge: Int
    let latestClaimAge: Int
    let earlyFirstMonths: Int
    let earlyFirstRate: Decimal
    let earlyLaterRate: Decimal
    let delayedCreditPerMonth: Decimal
    /// (born in or after this year, full retirement age in months), latest birth years first.
    let fullRetirementAges: [(bornFrom: Int, months: Int)]

    public static func load(year: Int = TaxYearData.latestYear) throws -> SocialSecurityData {
        try load(year: year, bundle: .module)
    }

    static func load(year: Int, bundle: Bundle) throws -> SocialSecurityData {
        guard let url = bundle.url(forResource: "social-security", withExtension: "json", subdirectory: "tax/\(year)") else {
            throw TaxDataError.missingFile("tax/\(year)/social-security.json")
        }
        let file = try JSONDecoder().decode(File.self, from: Data(contentsOf: url))
        guard file.bendPoints.count == 2, file.factors.count == 3 else {
            throw TaxDataError.invalid("social-security.json: need 2 bend points and 3 factors")
        }
        return SocialSecurityData(
            year: file.year,
            bendPoints: file.bendPoints.map(\.value),
            factors: file.factors.map(\.value),
            wageBase: file.wageBase.value,
            computationYears: file.computationYears,
            minimumYears: file.minimumYears,
            earliestClaimAge: file.earliestClaimAge,
            latestClaimAge: file.latestClaimAge,
            earlyFirstMonths: file.earlyReduction.firstMonths,
            earlyFirstRate: file.earlyReduction.firstRate.fraction,
            earlyLaterRate: file.earlyReduction.laterRate.fraction,
            delayedCreditPerMonth: file.delayedCreditPerMonth.fraction,
            fullRetirementAges: file.fullRetirementAge
                .sorted { $0.bornFrom > $1.bornFrom }
                .map { (bornFrom: $0.bornFrom, months: $0.months) }
        )
    }

    public func fullRetirementAgeMonths(birthYear: Int) -> Int {
        fullRetirementAges.first { birthYear >= $0.bornFrom }?.months ?? 804
    }

    /// Estimated monthly benefit. `birthYear` sets the full retirement age.
    public func estimate(_ input: SocialSecurityInput, birthYear: Int) -> SocialSecurityEstimate {
        let claimAge = input.claimAge.clamped(earliestClaimAge, latestClaimAge)
        let fraMonths = fullRetirementAgeMonths(birthYear: birthYear)
        let years = input.yearsWorked.clamped(0, 80)
        let earnings = min(max(input.annualEarnings, 0), wageBase)

        // No benefit without enough years of work (or with no earnings, which earn no credits).
        guard years >= minimumYears, earnings > 0 else {
            return SocialSecurityEstimate(eligible: false, claimAge: claimAge, fullRetirementAgeMonths: fraMonths,
                                          benefitAtFullRetirementAge: 0, claimAdjustment: 0, monthlyBenefit: 0)
        }

        // Average indexed monthly earnings: the best `computationYears` years, zeros for missing years,
        // rounded down to the dollar as SSA does.
        let counted = Decimal(min(years, computationYears))
        let aime = (earnings * counted / Decimal(computationYears) / 12).rounded(toPlaces: 0, mode: .down)

        let first = min(aime, bendPoints[0])
        let second = min(max(aime - bendPoints[0], 0), bendPoints[1] - bendPoints[0])
        let third = max(aime - bendPoints[1], 0)
        let raw = first * factors[0] + second * factors[1] + third * factors[2]
        let pia = (raw * 10).rounded(toPlaces: 0, mode: .down) / 10        // SSA rounds down to the dime

        let offset = claimAge * 12 - fraMonths
        let adjustment: Decimal
        if offset < 0 {
            let early = -offset
            let firstPart = Decimal(min(early, earlyFirstMonths)) * earlyFirstRate
            let laterPart = Decimal(max(early - earlyFirstMonths, 0)) * earlyLaterRate
            adjustment = -(firstPart + laterPart)
        } else {
            adjustment = Decimal(offset) * delayedCreditPerMonth
        }
        let monthly = (pia * (1 + adjustment)).rounded(toPlaces: 0, mode: .down)  // benefits round down to the dollar

        return SocialSecurityEstimate(eligible: true, claimAge: claimAge, fullRetirementAgeMonths: fraMonths,
                                      benefitAtFullRetirementAge: pia, claimAdjustment: adjustment, monthlyBenefit: monthly)
    }

    // MARK: - File format

    private struct Fraction: Decodable {
        let numerator: Int
        let denominator: Int
        var fraction: Decimal { denominator == 0 ? 0 : Decimal(numerator) / Decimal(denominator) }

        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            numerator = try container.decode(Int.self)
            denominator = try container.decode(Int.self)
        }
    }

    private struct Number: Decodable {
        let value: Decimal
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let number = try container.decode(Double.self)
            value = Decimal(string: String(number), locale: Locale(identifier: "en_US_POSIX")) ?? 0
        }
    }

    private struct File: Decodable {
        struct EarlyReduction: Decodable {
            let firstMonths: Int
            let firstRate: Fraction
            let laterRate: Fraction
        }

        struct FullRetirementAge: Decodable {
            let bornFrom: Int
            let months: Int
        }

        let year: Int
        let bendPoints: [Number]
        let factors: [Number]
        let wageBase: Number
        let computationYears: Int
        let minimumYears: Int
        let earliestClaimAge: Int
        let latestClaimAge: Int
        let earlyReduction: EarlyReduction
        let delayedCreditPerMonth: Fraction
        let fullRetirementAge: [FullRetirementAge]
    }
}

extension RetirementCalculator {
    /// Monthly retirement income in today's dollars once Social Security has started:
    /// portfolio withdrawals plus the benefit (nil or off counts as 0).
    public static func totalMonthlyIncome(_ result: RetirementResult, socialSecurity: SocialSecurityEstimate?) -> Decimal {
        result.monthlyIncomeInTodayDollars + (socialSecurity?.monthlyBenefit ?? 0)
    }
}
