import Foundation

/// How often the user is paid.
/// The Budget feature offers only `.monthly` and `.semiMonthly`; take-home pay also offers `.biweekly`.
public enum PayFrequency: String, Codable, CaseIterable, Identifiable {
    case monthly
    case semiMonthly
    case biweekly

    public var id: String { rawValue }

    public var periodsPerYear: Int {
        switch self {
        case .monthly: return 12
        case .semiMonthly: return 24
        case .biweekly: return 26
        }
    }

    public var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .semiMonthly: return "Semi-monthly"
        case .biweekly: return "Biweekly"
        }
    }
}
