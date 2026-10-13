import SwiftUI

/// The calculators on the home screen. To add one: add a case here, a folder in App/Features, a folder in FrugalityCore,
/// a StoreKey in App/Persistence/JSONStore.swift, and a doc in docs/features/.
enum Feature: String, CaseIterable, Identifiable {
    case retirement
    case rentVsBuy
    case netWorth
    case realEstateSnowball
    case amortization
    case rentalAnalysis
    case takeHome
    case budget

    var id: String { rawValue }

    var title: String {
        switch self {
        case .retirement: return "Retirement"
        case .rentVsBuy: return "Rent vs Buy"
        case .netWorth: return "Net Worth"
        case .realEstateSnowball: return "Property Snowball"
        case .amortization: return "Amortization"
        case .rentalAnalysis: return "Rental Property"
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
        case .amortization: return "What's still owed, and when"
        case .rentalAnalysis: return "Is this rental a good deal?"
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
        case .amortization: return "chart.line.downtrend.xyaxis"
        case .rentalAnalysis: return "key.fill"
        case .takeHome: return "dollarsign.circle.fill"
        case .budget: return "list.bullet.rectangle.fill"
        }
    }

    @MainActor @ViewBuilder
    var destination: some View {
        switch self {
        case .retirement: RetirementView()
        case .rentVsBuy: RentVsBuyView()
        case .netWorth: NetWorthView()
        case .realEstateSnowball: SnowballView()
        case .amortization: AmortizationView()
        case .rentalAnalysis: RentalAnalysisView()
        case .takeHome: TakeHomeView()
        case .budget: BudgetView()
        }
    }

    /// Applies a saved order: known features in saved order, then any new ones in default order.
    static func ordered(savedIDs: [String]) -> [Feature] {
        var result: [Feature] = []
        for id in savedIDs {
            if let feature = Feature(rawValue: id), !result.contains(feature) {
                result.append(feature)
            }
        }
        for feature in allCases where !result.contains(feature) {
            result.append(feature)
        }
        return result
    }
}
