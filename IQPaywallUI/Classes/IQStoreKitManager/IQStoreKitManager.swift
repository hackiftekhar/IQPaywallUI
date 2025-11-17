//
//  IQStoreKitManager.swift

import Foundation
import StoreKit
import Security
import CryptoKit

// StoreKit 2 manager
public final class IQStoreKitManager: NSObject, ObservableObject {
    @objc public static let shared = IQStoreKitManager()

    // MARK: - Configuration
    private var productIDs: [String] = []
    private var products: [Product] = []

    @MainActor
    @Published public var isProductLoading: Bool = false
    @MainActor
    @Published public var isProductLoadingError: Bool = false
    @MainActor
    @Published public var productLoadingError: Error? = nil


    @MainActor
    @Published public var isProductPurchasing: Bool = false
    @MainActor
    @Published public var isProductPurchasingError: Bool = false
    @MainActor
    @Published public var productPurchaseError: Error? = nil

    // Observe transactions
    private var updatesTask: Task<Void, Never>?

    // Optional user linking
    private(set) var userID: Int?

    private let inAppServer = PurchaseStatusManager.shared

    private override init() {
        super.init()
    }
    deinit { updatesTask?.cancel() }

    public func setUser(id: Int?) {
        self.userID = id
    }

    public func configure(productIDs: [String]) {
        self.productIDs = productIDs
        Task {
            let products = await loadProducts(productIDs: productIDs)
            self.products = products
            beginObservingTransactions()
        }
    }

    /// Refresh products
    public func loadProducts(productIDs: [String]) async -> [Product] {
        var productIDs = productIDs
        if productIDs.isEmpty { productIDs = self.productIDs }

        await MainActor.run {
            isProductLoading = true
            productLoadingError = nil
            isProductLoadingError = false
        }
        let products: [Product]
        do {
            products = try await loadProducts(for: productIDs)
            await inAppServer.refreshStatuses(products)
            self.products = products
            await MainActor.run {
                if products.isEmpty {
                    productLoadingError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No products to show"])
                    isProductLoadingError = true
                } else {
                    productLoadingError = nil
                    isProductLoadingError = false
                }
            }
        } catch {
            products = self.products.filter({ productIDs.contains($0.id) })
            await MainActor.run {
                productLoadingError = error
                isProductLoadingError = true
            }
        }

        await MainActor.run {
            isProductLoading = false
        }

        return products
    }

    /// Convenience: lookup loaded product
    public func product(withID id: String) -> Product? {
        products.first(where: { $0.id == id })
    }
}

extension IQStoreKitManager {

    /// Purchase a produc
    public func purchase(product: Product) async -> PurchaseState {

        await MainActor.run {
            isProductPurchasing = true
            isProductPurchasingError = false
            productPurchaseError = nil
        }

        let finalResult: PurchaseState

        do {
            let userId = self.userID
            var options: Set<Product.PurchaseOption> = []
            var appAccountToken: UUID? = nil
            if let userId = userId {
                let token = self.appAccountToken(for: userId)
                appAccountToken = token
                options.insert(.appAccountToken(token))
            } else {
                appAccountToken = nil
            }

            let result = try await product.purchase(options: options)
            switch result {
            case .success(let verification):
                do {
                    let txn = try Self.verify(verification)
                    let _ = try await deliverAndValidate(transaction: txn, for: product, userId: userId, appAccountToken: appAccountToken)
                    await txn.finish()
                    await inAppServer.refreshStatuses([product])
                    finalResult = .success(transaction: txn)
                } catch {
                    return .failed(error: error)
                }
                
            case .userCancelled:
                finalResult = .userCancelled
            case .pending:
                finalResult = .pending
            @unknown default:
                finalResult = .failed(error: NSError(domain: "IAP", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown purchase result"]))
            }
        } catch {
            finalResult = .failed(error: error)
        }

        await MainActor.run {
            isProductPurchasing = false
            switch finalResult {
            case .success/*(let transaction)*/:
                break
            case .pending:
                isProductPurchasingError = true
                productPurchaseError = NSError(domain: "IAP", code: -1, userInfo: [NSLocalizedDescriptionKey: "Purchase is Pending to be Completed!"])
            case .userCancelled:
                break
            case .failed(let error):
                isProductPurchasingError = true
                productPurchaseError = error
            }
        }

        return finalResult
    }
    
    /// Restore purchases
    public func restorePurchases() async -> Result<Void, Error> {
        do {
            try await AppStore.sync()
            await inAppServer.refreshStatuses(self.products)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}

extension IQStoreKitManager {

    /// Show Apple’s Manage Subscriptions
    public func showManageSubscriptions(in scene: UIWindowScene) async -> Result<Void, Error> {
        do {
            try await AppStore.showManageSubscriptions(in: scene)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    /// Present offer code redemption sheet
    public func presentCodeRedemptionSheet() {
        if SKPaymentQueue.canMakePayments() {
            SKPaymentQueue.default().presentCodeRedemptionSheet()
        }
    }
    
    /// Start refund request for the latest transaction of a product
    public func beginRefundRequest(for productID: String, in scene: UIWindowScene) async -> Result<StoreKit.Transaction.RefundRequestStatus, Error> {
        do {
            guard let txn = await latestTransaction(for: productID) else {
                return .failure(NSError(domain: "IAP", code: -2, userInfo: [NSLocalizedDescriptionKey: "No transaction found for product"]))
            }
            let status = try await txn.beginRefundRequest(in: scene)
            return .success(status)
        } catch {
            return .failure(error)
        }
    }
}

extension IQStoreKitManager {

    /// Get all available subscription offers (intro + promos)
    public func availableSubscriptionOffers(for product: Product) -> [Product.SubscriptionOffer] {
        guard let info = product.subscription else { return [] }
        var offers: [Product.SubscriptionOffer] = []
        if let intro = info.introductoryOffer {
            offers.append(intro)
        }
        offers.append(contentsOf: info.promotionalOffers)
        return offers
    }
    
    // MARK: - Internals
    
    private func beginObservingTransactions() {
        updatesTask?.cancel()
        updatesTask = Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            for await verification in Transaction.updates {
                do {
                    let txn = try Self.verify(verification)
                    // Load product to pass into deliver
                    let product: Product? = await MainActor.run {
                        self.products.first(where: { $0.id == txn.productID })
                    }
                    if let product {
                        let appAccountToken = (self.userID != nil) ? self.appAccountToken(for: self.userID!) : nil
                        let _ = try await self.deliverAndValidate(transaction: txn, for: product, userId: self.userID, appAccountToken: appAccountToken)
                    }
                    await txn.finish()
                    if let product {
                        await self.inAppServer.refreshStatuses([product])
                    }
                } catch {
                    // Ignore unverified
                }
            }
        }
    }
    
    private func loadProducts(for ids: [String]) async throws -> [Product] {
        guard !ids.isEmpty else { return [] }
        let products = try await Product.products(for: ids)

        return products.sorted(by: { p1, p2 in
            let p1Index = ids.firstIndex(of: p1.id) ?? 0
            let p2Index = ids.firstIndex(of: p2.id) ?? 0
            return p1Index < p2Index
        })
    }
    
    static func verify<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    /// Rebuild statusSnapshots for all products

    /// Choose the most relevant status for a product and convert to snapshot

    func latestTransaction(for productID: String) async -> Transaction? {
        // Prefer current entitlements
        for await result in Transaction.currentEntitlements {
            if let tx = try? Self.verify(result), tx.productID == productID {
                return tx
            }
        }
        // Otherwise iterate all transactions
        for await result in Transaction.all {
            if let tx = try? Self.verify(result), tx.productID == productID {
                return tx
            }
        }
        return nil
    }
    
    private func deliverAndValidate(transaction: Transaction, for product: Product, userId: Int?, appAccountToken: UUID?) async throws {
        let renewalInfo = await self.renewalInfo(for: product)
        try await self.inAppServer.validate(
            transaction: transaction,
            renewalInfo: renewalInfo,
            userID: userId,
            appAccountToken: appAccountToken
        )
    }
    
    private func renewalInfo(for product: Product) async -> Product.SubscriptionInfo.RenewalInfo? {
        guard let info = product.subscription else { return nil }
        do {
            let statuses = try await info.status
//            statuses.first?.transaction.payloadValue.productID
            // Use current-most status
            let status = statuses.first(where: { (try? $0.transaction.payloadValue.productID) == product.id }) ?? statuses.first
            if let status {
                return try? Self.verify(status.renewalInfo)
            }
        } catch {}
        return nil
    }

    // MARK: - AppAccount token (unchanged)
    private func appAccountToken(for userID: Int) -> UUID {
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
