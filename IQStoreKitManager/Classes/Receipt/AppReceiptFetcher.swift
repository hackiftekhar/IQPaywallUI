//
//  AppReceiptFetcher.swift

import Foundation
import StoreKit

internal final class AppReceiptFetcher: NSObject, SKRequestDelegate {
    enum ReceiptError: Error {
        case missingAfterRefresh
        case refreshFailed(String)
    }

    private var continuations: [NSObject:CheckedContinuation<Void, Error>] = [:]

    func fetchBase64Receipt(forceRefresh: Bool = false) async throws -> String {
        if let base64 = readBase64Receipt(), !forceRefresh {
            return base64
        }
        try await refreshReceipt()
        guard let base64 = readBase64Receipt() else {
            throw ReceiptError.missingAfterRefresh
        }
        return base64
    }

    private func readBase64Receipt() -> String? {
        guard let url = Bundle.main.appStoreReceiptURL,
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return data.base64EncodedString()
    }

    private func refreshReceipt() async throws {
        let request = SKReceiptRefreshRequest()
        request.delegate = self
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.continuations[request] = continuation
            request.start()
        }
    }

    // MARK: SKRequestDelegate

    func requestDidFinish(_ request: SKRequest) {
        self.continuations[request]?.resume(returning: ())
        self.continuations[request] = nil
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        self.continuations[request]?.resume(throwing: ReceiptError.refreshFailed(error.localizedDescription))
        self.continuations[request] = nil
    }
}
