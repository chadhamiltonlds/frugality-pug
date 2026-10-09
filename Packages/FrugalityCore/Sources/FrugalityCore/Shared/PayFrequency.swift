import Foundation

/// How often the user is paid. Biweekly is intentionally not supported.
public enum PayFrequency: String, Codable, CaseIterable, Identifiable {
    case monthly
    case semiMonthly

    public var id: String { rawValue }

    public var periodsPerYear: Int {
        switch self {
        case .monthly: return 12
        case .semiMonthly: return 24
        }
    }

    public var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .semiMonthly: return "Twice a month"
        }
    }
}
