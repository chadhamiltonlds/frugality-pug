import Foundation

extension Decimal {
    /// Lowest growth/return rate accepted by projections (-99%), so (1 + rate) stays positive.
    static let minimumRate = Decimal(-99) / 100

    func clamped(to range: ClosedRange<Decimal>) -> Decimal {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }

    /// Clamps a projection rate to at least -99%.
    var asSafeRate: Decimal {
        Swift.max(self, Decimal.minimumRate)
    }
}

extension Int {
    func clamped(_ lower: Int, _ upper: Int) -> Int {
        Swift.min(Swift.max(self, lower), upper)
    }
}
