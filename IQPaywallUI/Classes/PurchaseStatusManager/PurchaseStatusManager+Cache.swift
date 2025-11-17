//
//  PurchaseStatusManager+Cache.swift

import Foundation

extension PurchaseStatusManager {

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private static let snapshotsAccount = "cached_snapshots"

    func persistSnapshot(_ snapshots: [String: ProductSnapshot]) throws {

        let data = try Self.encoder.encode(snapshots)
        try StoreKitInAppServerKeychain.set(data: data, for: Self.snapshotsAccount)
    }

    func cachedSnapshot() throws -> [String: ProductSnapshot] {

        guard let data = try? StoreKitInAppServerKeychain.data(for: Self.snapshotsAccount) else { return [:] }
        let map = try Self.decoder.decode([String: ProductSnapshot].self, from: data)
        return map
    }

    func clearSnapshots() throws {
        try StoreKitInAppServerKeychain.remove(for: Self.snapshotsAccount)
    }
}
