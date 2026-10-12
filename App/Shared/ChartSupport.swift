import SwiftUI

/// Chart series colors, validated for color-blind separation against white cards:
/// series 1 is the theme accent, series 2 a blue. Single-series charts use series 1.
enum ChartColors {
    static let series1 = Color(hex: 0xE5484D)
    static let series2 = Color(hex: 0x2A78D6)
}

/// One plotted value. `series` names the line; charts with one series can leave it as is.
struct ChartPoint: Identifiable {
    let x: Int
    let y: Double
    var series = ""
    var id: String { "\(series)-\(x)" }
}

extension Decimal {
    /// For charts only. Money math stays in Decimal.
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }

    /// "$1,234" (no cents) for large projected figures.
    var asWholeCurrency: String {
        formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

/// Short axis labels: $950, $12K, $1.4M.
func compactDollars(_ value: Double) -> String {
    let sign = value < 0 ? "-" : ""
    let magnitude = abs(value)
    switch magnitude {
    case 1_000_000...:
        return "\(sign)$\((magnitude / 1_000_000).formatted(.number.precision(.fractionLength(0...1))))M"
    case 1_000...:
        return "\(sign)$\((magnitude / 1_000).formatted(.number.precision(.fractionLength(0))))K"
    default:
        return "\(sign)$\(magnitude.formatted(.number.precision(.fractionLength(0))))"
    }
}
