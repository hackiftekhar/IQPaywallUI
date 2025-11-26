//
//  IQPaywallUI.swift

import Foundation
import SwiftUI

import Security
import CryptoKit

@objc
public class IQPaywallUI: NSObject {

    @objc public static func setAppAccountToken(_ token: UUID?) {
        StoreKitManager.shared.setAppAccountToken(token)
    }

    @objc public static func configure(productIds: [String]) {
        StoreKitManager.shared.configure(productIDs: productIds)
    }

    public static func paywallViewController(with configuration: PaywallConfiguration) -> UIViewController {
        return UIHostingController(rootView: PaywallView(configuration: configuration))
    }

    // MARK: - AppAccount token (unchanged)
    public func appAccountToken(for userID: Int) -> UUID {
        // 1) बनाइये एक deterministic input string
        let input = "\(Bundle.main.bundleIdentifier ?? "")-\(userID)"

        // 2) SHA256 digest लें
        let digest = SHA256.hash(data: Data(input.utf8))   // SHA256Digest

        // 3) digest को बाइट्स के array में बदलें
        var bytes = Array(digest) // [UInt8], SHA256 => 32 bytes

        // 4) UUID के लिए पहले 16 bytes लें और RFC-4122 के version/variant bits सेट करें
        //    - version = 4 (pseudo-random / here derived from hash) : set high nibble of byte[6] to 0x4
        //    - variant = RFC 4122 : set high bits of byte[8] to 0b10xxxxxx
        bytes[6] = (bytes[6] & 0x0F) | 0x40   // version 4
        bytes[8] = (bytes[8] & 0x3F) | 0x80   // variant RFC4122

        // 5) UUID tuple बनाइए (uuid_t)
        let uuidTuple: uuid_t = (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        )

        return UUID(uuid: uuidTuple)
    }
}
