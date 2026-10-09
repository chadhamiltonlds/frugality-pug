import Foundation

extension KeyedDecodingContainer {
    /// Decodes a JSON number into an exact `Decimal`.
    /// Decoding `Decimal` directly can pick up binary floating-point noise (0.0399 becoming 0.03990000000000000...),
    /// so data files use plain JSON numbers and this converts them through their shortest text form.
    func decodeDecimal(forKey key: Key) throws -> Decimal {
        let number = try decode(Double.self, forKey: key)
        guard let value = Decimal(string: String(number), locale: Locale(identifier: "en_US_POSIX")) else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Invalid number: \(number)")
        }
        return value
    }
}
