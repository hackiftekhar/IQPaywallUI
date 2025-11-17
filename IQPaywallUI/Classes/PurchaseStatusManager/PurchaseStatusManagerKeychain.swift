//
//  StoreKitInAppServerKeychain.swift

import Foundation
import Security

final class StoreKitInAppServerKeychain: NSObject {
    private static let access: CFString = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    private static let service: String = Bundle.main.bundleIdentifier ?? "com.paywallUI.paywallUI"

    // MARK: - Keychain primitives
    static func set(data: Data, for key: String) throws {

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: access
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)

        if status == errSecSuccess {
            let statusUpdate = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            guard statusUpdate == errSecSuccess else {
                throw NSError(domain: "StoreKitInAppServerKeychain", code: Int(statusUpdate), userInfo: nil)
            }
        } else if status == errSecItemNotFound {
            var addQuery = query
            addQuery.merge(attributes) { (_, new) in new }
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw NSError(domain: "StoreKitInAppServerKeychain", code: Int(addStatus), userInfo: nil)
            }
        } else {
            throw NSError(domain: "StoreKitInAppServerKeychain", code: Int(status), userInfo: nil)
        }
    }

    static func data(for key: String) throws -> Data {

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess {
            guard let data = result as? Data else { throw NSError(domain: "StoreKitInAppServerKeychain", code: -1, userInfo: nil) }
            return data
        } else {
            throw NSError(domain: "StoreKitInAppServerKeychain", code: Int(status), userInfo: nil)
        }
    }

    static func remove(for key: String) throws {

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw NSError(domain: "StoreKitInAppServerKeychain", code: Int(status), userInfo: nil)
        }
    }
}
