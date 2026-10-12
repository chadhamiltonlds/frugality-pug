import Foundation

public enum AssetCategory: String, Codable, CaseIterable, Identifiable {
    case cash, investments, retirement, realEstate, vehicles, business, other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .cash: return "Cash & savings"
        case .investments: return "Investments"
        case .retirement: return "Retirement accounts"
        case .realEstate: return "Real estate"
        case .vehicles: return "Vehicles"
        case .business: return "Business"
        case .other: return "Other"
        }
    }
}

public enum DebtCategory: String, Codable, CaseIterable, Identifiable {
    case mortgage, studentLoan, auto, creditCard, personal, medical, other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .mortgage: return "Mortgage"
        case .studentLoan: return "Student loans"
        case .auto: return "Auto loans"
        case .creditCard: return "Credit cards"
        case .personal: return "Personal loans"
        case .medical: return "Medical"
        case .other: return "Other"
        }
    }
}

public struct AssetItem: Codable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var category: AssetCategory
    public var value: Decimal

    public init(id: UUID = UUID(), name: String = "", category: AssetCategory = .cash, value: Decimal = 0) {
        self.id = id
        self.name = name
        self.category = category
        self.value = value
    }
}

public struct DebtItem: Codable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var category: DebtCategory
    public var balance: Decimal
    public var annualInterestRate: Decimal

    public init(id: UUID = UUID(), name: String = "", category: DebtCategory = .creditCard,
                balance: Decimal = 0, annualInterestRate: Decimal = 0) {
        self.id = id
        self.name = name
        self.category = category
        self.balance = balance
        self.annualInterestRate = annualInterestRate
    }
}

public struct NetWorthInput: Codable, Equatable {
    public var assets: [AssetItem]
    public var debts: [DebtItem]

    public init(assets: [AssetItem] = [], debts: [DebtItem] = []) {
        self.assets = assets
        self.debts = debts
    }
}

public struct CategoryTotal<Category: Equatable>: Equatable {
    public let category: Category
    public let total: Decimal
}

public struct NetWorthResult: Equatable {
    public let totalAssets: Decimal
    public let totalDebts: Decimal
    public let netWorth: Decimal
    /// Non-zero categories, largest first.
    public let assetsByCategory: [CategoryTotal<AssetCategory>]
    public let debtsByCategory: [CategoryTotal<DebtCategory>]
    /// Debts / assets; nil when there are no assets.
    public let debtToAssetRatio: Decimal?
    /// Balance-weighted average interest rate; nil when there is no debt.
    public let averageInterestRate: Decimal?
    public let monthlyInterestCost: Decimal
}

/// Sums assets and debts. Negative values and rates are treated as 0.
public enum NetWorthCalculator {
    public static func summarize(_ input: NetWorthInput) -> NetWorthResult {
        let assets = input.assets.map { ($0.category, max($0.value, 0)) }
        let debts = input.debts.map { ($0.category, max($0.balance, 0), max($0.annualInterestRate, 0)) }

        let totalAssets = assets.reduce(Decimal(0)) { $0 + $1.1 }
        let totalDebts = debts.reduce(Decimal(0)) { $0 + $1.1 }
        let yearlyInterest = debts.reduce(Decimal(0)) { $0 + $1.1 * $1.2 }

        return NetWorthResult(
            totalAssets: totalAssets.roundedToCents(),
            totalDebts: totalDebts.roundedToCents(),
            netWorth: (totalAssets - totalDebts).roundedToCents(),
            assetsByCategory: grouped(assets, order: AssetCategory.allCases),
            debtsByCategory: grouped(debts.map { ($0.0, $0.1) }, order: DebtCategory.allCases),
            debtToAssetRatio: totalAssets > 0 ? totalDebts / totalAssets : nil,
            averageInterestRate: totalDebts > 0 ? yearlyInterest / totalDebts : nil,
            monthlyInterestCost: (yearlyInterest / 12).roundedToCents()
        )
    }

    private static func grouped<C: Equatable>(_ items: [(C, Decimal)], order: [C]) -> [CategoryTotal<C>] {
        var totals: [(index: Int, value: CategoryTotal<C>)] = []
        for (index, category) in order.enumerated() {
            var sum: Decimal = 0
            for item in items where item.0 == category {
                sum += item.1
            }
            totals.append((index, CategoryTotal(category: category, total: sum.roundedToCents())))
        }
        return totals
            .filter { $0.value.total > 0 }
            .sorted { $0.value.total != $1.value.total ? $0.value.total > $1.value.total : $0.index < $1.index }
            .map { $0.value }
    }
}
