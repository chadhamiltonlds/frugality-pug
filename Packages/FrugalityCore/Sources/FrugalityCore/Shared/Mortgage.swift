import Foundation

/// Fixed-rate, fully amortizing loan math shared by RentVsBuy and RealEstateSnowball.
public enum Mortgage {
    /// Monthly principal + interest payment. 0 when there is no principal; principal / months at a 0% rate.
    /// `years` is clamped to 1...50.
    public static func monthlyPayment(principal: Decimal, annualRate: Decimal, years: Int) -> Decimal {
        guard principal > 0 else { return 0 }
        let months = years.clamped(1, 50) * 12
        let r = max(annualRate, 0) / 12
        guard r > 0 else { return principal / Decimal(months) }
        let factor = pow(1 + r, months)
        return principal * r * factor / (factor - 1)
    }

    /// One month of amortization. The last payment is capped at the remaining balance.
    static func step(balance: Decimal, annualRate: Decimal, payment: Decimal)
        -> (interest: Decimal, principal: Decimal, balance: Decimal) {
        guard balance > 0 else { return (0, 0, 0) }
        let interest = balance * max(annualRate, 0) / 12
        let principal = min(max(payment - interest, 0), balance)
        return (interest, principal, balance - principal)
    }
}
