import Foundation

/// Every saved item and its schema version. Add a key here for anything new that is saved.
/// Bump `version` when the saved type changes shape; old files with another version are ignored
/// (the screen starts fresh) unless a migration is added to `JSONStore.load`.
struct StoreKey {
    let name: String
    let version: Int

    static let homeOrder = StoreKey(name: "home-order", version: 1)
    static let takeHome = StoreKey(name: "take-home", version: 1)
    static let retirement = StoreKey(name: "retirement", version: 1)
    static let netWorth = StoreKey(name: "net-worth", version: 1)
    static let rentVsBuy = StoreKey(name: "rent-vs-buy", version: 1)
    static let snowball = StoreKey(name: "real-estate-snowball", version: 1)
    static let budget = StoreKey(name: "budget", version: 1)
    static let amortization = StoreKey(name: "amortization", version: 1)
    static let rentalAnalysis = StoreKey(name: "rental-analysis", version: 1)
}

/// The only place the app reads and writes saved data: one small JSON file per key in Application Support.
/// Data stays on the device.
enum JSONStore {
    private struct Envelope<Value: Codable>: Codable {
        var version: Int
        var value: Value
    }

    private static var directory: URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let folder = base.appendingPathComponent("FrugalityPug", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private static func url(for key: StoreKey) -> URL? {
        directory?.appendingPathComponent("\(key.name).json")
    }

    static func load<Value: Codable>(_ type: Value.Type, key: StoreKey) -> Value? {
        guard let url = url(for: key),
              let data = try? Data(contentsOf: url),
              let envelope = try? JSONDecoder().decode(Envelope<Value>.self, from: data),
              envelope.version == key.version else { return nil }
        return envelope.value
    }

    static func save<Value: Codable>(_ value: Value, key: StoreKey) {
        guard let url = url(for: key),
              let data = try? JSONEncoder().encode(Envelope(version: key.version, value: value)) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
