import Foundation

public enum TakeHomeError: Error, Equatable {
    case unknownState(String)
}

public struct TakeHomeInput: Equatable {
    public var grossAnnual: Decimal
    public var payFrequency: PayFrequency
    public var filingStatus: FilingStatus
    public var stateCode: String
    public var childrenUnder17: Int
    public var otherDependents: Int
    /// Traditional 401(k)/403(b) deferrals: lower income tax, not FICA.
    public var preTax401kAnnual: Decimal
    /// Section 125 items (health premiums, HSA/FSA via payroll): lower income tax and FICA.
    public var preTaxSection125Annual: Decimal
    public var postTaxDeductionsAnnual: Decimal

    public init(
        grossAnnual: Decimal = 0,
        payFrequency: PayFrequency = .monthly,
        filingStatus: FilingStatus = .single,
        stateCode: String = "TX",
        childrenUnder17: Int = 0,
        otherDependents: Int = 0,
        preTax401kAnnual: Decimal = 0,
        preTaxSection125Annual: Decimal = 0,
        postTaxDeductionsAnnual: Decimal = 0
    ) {
        self.grossAnnual = grossAnnual
        self.payFrequency = payFrequency
        self.filingStatus = filingStatus
        self.stateCode = stateCode
        self.childrenUnder17 = childrenUnder17
        self.otherDependents = otherDependents
        self.preTax401kAnnual = preTax401kAnnual
        self.preTaxSection125Annual = preTaxSection125Annual
        self.postTaxDeductionsAnnual = postTaxDeductionsAnnual
    }
}

public struct TakeHomeResult: Equatable {
    public let grossAnnual: Decimal
    public let preTax401k: Decimal
    public let preTaxSection125: Decimal
    public let postTaxDeductions: Decimal
    public let federalIncomeTax: Decimal
    public let socialSecurity: Decimal
    public let medicare: Decimal
    public let additionalMedicare: Decimal
    public let stateIncomeTax: Decimal
    public let netAnnual: Decimal
    public let periodsPerYear: Int
    public let stateName: String
    public let stateIsApproximate: Bool
    public let stateNote: String?

    public var totalTaxes: Decimal {
        federalIncomeTax + socialSecurity + medicare + additionalMedicare + stateIncomeTax
    }

    public var netPerPeriod: Decimal {
        (netAnnual / Decimal(periodsPerYear)).roundedToCents()
    }

    public var grossPerPeriod: Decimal {
        (grossAnnual / Decimal(periodsPerYear)).roundedToCents()
    }

    /// Total taxes as a fraction of gross pay (0 when gross is 0).
    public var effectiveTaxRate: Decimal {
        guard grossAnnual > 0 else { return 0 }
        return totalTaxes / grossAnnual
    }
}

/// Estimates take-home pay. Inputs are annual; results are annual with per-period helpers.
/// Not modeled: local taxes, state payroll taxes (SDI/PFML), AMT, itemized deductions, refundable credits.
public enum TakeHomeCalculator {
    public static func calculate(_ input: TakeHomeInput, data: TaxYearData) throws -> TakeHomeResult {
        let code = input.stateCode.uppercased()
        guard let rule = data.states.first(where: { $0.code == code }) else {
            throw TakeHomeError.unknownState(input.stateCode)
        }

        let federal = data.federal
        let status = input.filingStatus

        let gross = max(input.grossAnnual, 0)
        let preTax401k = min(max(input.preTax401kAnnual, 0), gross)
        let section125 = min(max(input.preTaxSection125Annual, 0), gross - preTax401k)
        let postTax = max(input.postTaxDeductionsAnnual, 0)
        let children = max(input.childrenUnder17, 0)
        let otherDependents = max(input.otherDependents, 0)

        // Federal income tax
        let adjustedIncome = gross - preTax401k - section125
        let federalTaxable = max(adjustedIncome - federal.standardDeduction.value(for: status), 0)
        let bracketTax = progressiveTax(income: federalTaxable, brackets: federal.brackets.brackets(for: status))
        let credit = childCredit(
            data: federal.childTaxCredit, status: status, adjustedIncome: adjustedIncome,
            children: children, otherDependents: otherDependents
        )
        let federalIncomeTax = max(bracketTax - credit, 0).roundedToCents()

        // FICA
        let ficaWages = gross - section125
        let socialSecurity = (min(ficaWages, federal.socialSecurity.wageBase) * federal.socialSecurity.rate).roundedToCents()
        let medicare = (ficaWages * federal.medicare.rate).roundedToCents()
        let additionalWages = max(ficaWages - federal.medicare.additionalThreshold.value(for: status), 0)
        let additionalMedicare = (additionalWages * federal.medicare.additionalRate).roundedToCents()

        // State income tax
        let stateIncomeTax = stateTax(
            rule: rule, status: status, gross: gross, preTax401k: preTax401k, section125: section125,
            dependents: children + otherDependents
        ).roundedToCents()

        let taxesTotal: Decimal = federalIncomeTax + socialSecurity + medicare + additionalMedicare + stateIncomeTax
        let deductionsTotal: Decimal = preTax401k + section125 + postTax
        let net = max(gross - deductionsTotal - taxesTotal, 0)

        return TakeHomeResult(
            grossAnnual: gross,
            preTax401k: preTax401k,
            preTaxSection125: section125,
            postTaxDeductions: postTax,
            federalIncomeTax: federalIncomeTax,
            socialSecurity: socialSecurity,
            medicare: medicare,
            additionalMedicare: additionalMedicare,
            stateIncomeTax: stateIncomeTax,
            netAnnual: net,
            periodsPerYear: input.payFrequency.periodsPerYear,
            stateName: rule.name,
            stateIsApproximate: rule.approximate ?? false,
            stateNote: rule.note
        )
    }

    // MARK: - Pieces

    /// Child tax credit plus credit for other dependents, reduced $50 per $1,000 (or part) over the phase-out start.
    private static func childCredit(
        data: FederalTaxData.ChildTaxCredit, status: FilingStatus, adjustedIncome: Decimal,
        children: Int, otherDependents: Int
    ) -> Decimal {
        let base = Decimal(children) * data.perChild + Decimal(otherDependents) * data.perOtherDependent
        let over = max(adjustedIncome - data.phaseOutStart.value(for: status), 0)
        let steps = (over / 1000).roundedUp
        return max(base - steps * data.reductionPerThousand, 0)
    }

    /// State income tax. Head of household uses the single-filer figures.
    private static func stateTax(
        rule: StateTaxRule, status: FilingStatus, gross: Decimal, preTax401k: Decimal,
        section125: Decimal, dependents: Int
    ) -> Decimal {
        guard rule.hasIncomeTax, let brackets = rule.brackets else { return 0 }

        let joint = status == .marriedJoint
        let income = gross - (rule.taxes401kContributions == true ? 0 : preTax401k) - section125

        var deductions: Decimal = 0
        var credits: Decimal = 0

        if let standard = rule.standardDeduction {
            deductions += joint ? standard.marriedJoint : standard.single
        }
        if let personal = rule.personalExemption {
            let amount = joint ? personal.marriedJoint : personal.single
            switch personal.kind {
            case .deduction: deductions += amount
            case .credit: credits += amount
            }
        }
        if let dependent = rule.dependentExemption {
            let amount = Decimal(dependents) * dependent.amount
            switch dependent.kind {
            case .deduction: deductions += amount
            case .credit: credits += amount
            }
        }

        let taxable = max(income - deductions, 0)
        let tax = progressiveTax(income: taxable, brackets: joint ? brackets.marriedJoint : brackets.single)
        return max(tax - credits, 0)
    }
}
