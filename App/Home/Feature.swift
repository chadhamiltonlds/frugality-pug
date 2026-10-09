import SwiftUI

/// The six calculators. To add one: add a case here, a folder in App/Features, and a folder in FrugalityCore.
enum Feature: String, CaseIterable, Identifiable {
    case retirement
    case rentVsBuy
    case netWorth
    case realEstateSnowball
    case takeHome
    case budget

    var id: String { rawValue }

    var title: String {
        switch self {
        case .retirement: return "Retirement"
        case .rentVsBuy: return "Rent vs Buy"
        case .netWorth: return "Net Worth"
        case .realEstateSnowball: return "Property Snowball"
        case .takeHome: return "Take-Home Pay"
        case .budget: return "Budget"
        }
    }

    var subtitle: String {
        switch self {
        case .retirement: return "What you'll have saved"
        case .rentVsBuy: return "Is buying worth it?"
        case .netWorth: return "Assets minus debts"
        case .realEstateSnowball: return "Rentals that fund rentals"
        case .takeHome: return "Gross to net"
        case .budget: return "Monthly income and spending"
        }
    }

    var symbol: String {
        switch self {
        case .retirement: return "chart.line.uptrend.xyaxis"
        case .rentVsBuy: return "house.fill"
        case .netWorth: return "scalemass.fill"
        case .realEstateSnowball: return "building.2.fill"
        case .takeHome: return "dollarsign.circle.fill"
        case .budget: return "list.bullet.rectangle.fill"
        }
    }

    var isAvailable: Bool {
        switch self {
        case .takeHome: return true
        default: return false
        }
    }

    @MainActor @ViewBuilder
    var destination: some View {
        switch self {
        case .takeHome: TakeHomeView()
        default: ComingSoonView(title: title)
        }
    }
}
