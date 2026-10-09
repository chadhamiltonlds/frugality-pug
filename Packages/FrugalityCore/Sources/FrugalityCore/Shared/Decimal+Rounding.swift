import Foundation

extension Decimal {
    /// Rounds to `scale` decimal places using `mode`.
    public func rounded(toPlaces scale: Int, mode: NSDecimalNumber.RoundingMode) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, mode)
        return result
    }

    /// Rounds to cents, with halves rounding away from zero.
    public func roundedToCents() -> Decimal {
        rounded(toPlaces: 2, mode: .plain)
    }

    /// Rounds up to the next whole number (ceiling for positive values).
    var roundedUp: Decimal {
        rounded(toPlaces: 0, mode: .up)
    }
}
