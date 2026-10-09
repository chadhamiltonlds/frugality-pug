import Foundation

// MARK: - Shared shapes
//
// These types are only ever decoded from the JSON data files. Numbers are read with `decodeDecimal`
// so they stay exact (see DecimalDecoding.swift).

struct StatusBrackets: Decodable, Equatable {
    var single: [TaxBracket]
    var marriedJoint: [TaxBracket]
    var headOfHousehold: [TaxBracket]

    func brackets(for status: FilingStatus) -> [TaxBracket] {
        switch status {
        case .single: return single
        case .marriedJoint: return marriedJoint
        case .headOfHousehold: return headOfHousehold
        }
    }
}

struct StatusAmounts: Decodable, Equatable {
    var single: Decimal
    var marriedJoint: Decimal
    var headOfHousehold: Decimal

    func value(for status: FilingStatus) -> Decimal {
        switch status {
        case .single: return single
        case .marriedJoint: return marriedJoint
        case .headOfHousehold: return headOfHousehold
        }
    }
}

extension StatusAmounts {
    private enum CodingKeys: String, CodingKey {
        case single, marriedJoint, headOfHousehold
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            single: try c.decodeDecimal(forKey: .single),
            marriedJoint: try c.decodeDecimal(forKey: .marriedJoint),
            headOfHousehold: try c.decodeDecimal(forKey: .headOfHousehold)
        )
    }
}

// MARK: - Federal

struct FederalTaxData: Decodable, Equatable {
    struct SocialSecurity: Decodable, Equatable {
        var rate: Decimal
        var wageBase: Decimal
    }

    struct Medicare: Decodable, Equatable {
        var rate: Decimal
        var additionalRate: Decimal
        var additionalThreshold: StatusAmounts
    }

    struct ChildTaxCredit: Decodable, Equatable {
        var perChild: Decimal
        var perOtherDependent: Decimal
        var phaseOutStart: StatusAmounts
        var reductionPerThousand: Decimal
    }

    var year: Int
    var standardDeduction: StatusAmounts
    var brackets: StatusBrackets
    var socialSecurity: SocialSecurity
    var medicare: Medicare
    var childTaxCredit: ChildTaxCredit
}

extension FederalTaxData.SocialSecurity {
    private enum CodingKeys: String, CodingKey {
        case rate, wageBase
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            rate: try c.decodeDecimal(forKey: .rate),
            wageBase: try c.decodeDecimal(forKey: .wageBase)
        )
    }
}

extension FederalTaxData.Medicare {
    private enum CodingKeys: String, CodingKey {
        case rate, additionalRate, additionalThreshold
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            rate: try c.decodeDecimal(forKey: .rate),
            additionalRate: try c.decodeDecimal(forKey: .additionalRate),
            additionalThreshold: try c.decode(StatusAmounts.self, forKey: .additionalThreshold)
        )
    }
}

extension FederalTaxData.ChildTaxCredit {
    private enum CodingKeys: String, CodingKey {
        case perChild, perOtherDependent, phaseOutStart, reductionPerThousand
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            perChild: try c.decodeDecimal(forKey: .perChild),
            perOtherDependent: try c.decodeDecimal(forKey: .perOtherDependent),
            phaseOutStart: try c.decode(StatusAmounts.self, forKey: .phaseOutStart),
            reductionPerThousand: try c.decodeDecimal(forKey: .reductionPerThousand)
        )
    }
}

// MARK: - State

/// Whether an exemption lowers taxable income (deduction) or lowers the tax itself (credit).
enum ExemptionKind: String, Decodable, Equatable {
    case deduction
    case credit
}

struct StateBrackets: Decodable, Equatable {
    var single: [TaxBracket]
    var marriedJoint: [TaxBracket]
}

struct StateAmounts: Decodable, Equatable {
    var single: Decimal
    var marriedJoint: Decimal
}

extension StateAmounts {
    private enum CodingKeys: String, CodingKey {
        case single, marriedJoint
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            single: try c.decodeDecimal(forKey: .single),
            marriedJoint: try c.decodeDecimal(forKey: .marriedJoint)
        )
    }
}

struct PersonalExemption: Decodable, Equatable {
    var kind: ExemptionKind
    var single: Decimal
    var marriedJoint: Decimal
}

extension PersonalExemption {
    private enum CodingKeys: String, CodingKey {
        case kind, single, marriedJoint
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            kind: try c.decode(ExemptionKind.self, forKey: .kind),
            single: try c.decodeDecimal(forKey: .single),
            marriedJoint: try c.decodeDecimal(forKey: .marriedJoint)
        )
    }
}

struct DependentExemption: Decodable, Equatable {
    var kind: ExemptionKind
    var amount: Decimal
}

extension DependentExemption {
    private enum CodingKeys: String, CodingKey {
        case kind, amount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            kind: try c.decode(ExemptionKind.self, forKey: .kind),
            amount: try c.decodeDecimal(forKey: .amount)
        )
    }
}

/// One jurisdiction's income tax rules. Head of household uses the single-filer figures.
struct StateTaxRule: Decodable, Equatable {
    var code: String
    var name: String
    var hasIncomeTax: Bool
    var brackets: StateBrackets?
    var standardDeduction: StateAmounts?
    var personalExemption: PersonalExemption?
    var dependentExemption: DependentExemption?
    /// True where 401(k) deferrals are still taxed by the state (PA, NJ).
    var taxes401kContributions: Bool?
    /// True where the model leaves out a known state-specific rule; see `note`.
    var approximate: Bool?
    var note: String?
}

// MARK: - Loading

public enum TaxDataError: Error, Equatable {
    case missingFile(String)
    case invalid(String)
}

/// A selectable state/jurisdiction for the UI.
public struct StateOption: Identifiable, Equatable {
    public let code: String
    public let name: String
    public let hasIncomeTax: Bool
    public let isApproximate: Bool
    public let note: String?
    public var id: String { code }
}

/// All tax rules for one tax year, loaded from the JSON files in `Resources/tax/<year>/`.
public struct TaxYearData: Equatable {
    /// The most recent tax year with data files.
    public static let latestYear = 2026

    let federal: FederalTaxData
    let states: [StateTaxRule]

    public var year: Int { federal.year }

    public var stateOptions: [StateOption] {
        states.map {
            StateOption(code: $0.code, name: $0.name, hasIncomeTax: $0.hasIncomeTax,
                        isApproximate: $0.approximate ?? false, note: $0.note)
        }
    }

    public static func load(year: Int = TaxYearData.latestYear) throws -> TaxYearData {
        try load(year: year, bundle: .module)
    }

    static func load(year: Int, bundle: Bundle) throws -> TaxYearData {
        let decoder = JSONDecoder()

        func read<T: Decodable>(_ name: String, as type: T.Type) throws -> T {
            guard let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "tax/\(year)") else {
                throw TaxDataError.missingFile("tax/\(year)/\(name).json")
            }
            return try decoder.decode(T.self, from: Data(contentsOf: url))
        }

        let federal = try read("federal", as: FederalTaxData.self)
        let states = try read("states", as: [StateTaxRule].self)
        let data = TaxYearData(federal: federal, states: states)
        try data.validate()
        return data
    }

    /// Catches data-entry mistakes in the JSON files.
    func validate() throws {
        func check(_ brackets: [TaxBracket], _ label: String) throws {
            guard let first = brackets.first, first.from == 0 else {
                throw TaxDataError.invalid("\(label): brackets must start at 0")
            }
            for pair in zip(brackets, brackets.dropFirst()) where pair.0.from >= pair.1.from {
                throw TaxDataError.invalid("\(label): brackets must ascend")
            }
        }

        try check(federal.brackets.single, "federal single")
        try check(federal.brackets.marriedJoint, "federal marriedJoint")
        try check(federal.brackets.headOfHousehold, "federal headOfHousehold")

        var seen = Set<String>()
        for state in states {
            guard seen.insert(state.code).inserted else {
                throw TaxDataError.invalid("duplicate state \(state.code)")
            }
            if state.hasIncomeTax {
                guard let brackets = state.brackets else {
                    throw TaxDataError.invalid("\(state.code): missing brackets")
                }
                try check(brackets.single, "\(state.code) single")
                try check(brackets.marriedJoint, "\(state.code) marriedJoint")
            }
        }
    }
}
