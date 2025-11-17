import Foundation
import StoreKit

final class AppReceiptFetcher: NSObject, SKRequestDelegate {
    enum ReceiptError: Error {
        case missingAfterRefresh
        case refreshFailed(String)
    }
    
    private var continuation: CheckedContinuation<Void, Error>?
    
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
              let data = try? Data(contentsOf: url) else { return nil }
        return data.base64EncodedString()
    }
    
    private func refreshReceipt() async throws {
        if continuation != nil { // already refreshing
            return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                self.continuation = continuation
                let request = SKReceiptRefreshRequest()
                request.delegate = self
                request.start()
            }
        }
    }
    
    // MARK: SKRequestDelegate
    
    func requestDidFinish(_ request: SKRequest) {
        continuation?.resume(returning: ())
        continuation = nil
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        continuation?.resume(throwing: ReceiptError.refreshFailed(error.localizedDescription))
        continuation = nil
    }
}
