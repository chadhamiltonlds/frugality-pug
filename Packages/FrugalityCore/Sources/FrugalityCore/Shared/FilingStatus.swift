import Foundation

public enum FilingStatus: String, Codable, CaseIterable, Identifiable {
    case single
    case marriedJoint
    case headOfHousehold

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .single: return "Single"
        case .marriedJoint: return "Married filing jointly"
        case .headOfHousehold: return "Head of household"
        }
    }
}
