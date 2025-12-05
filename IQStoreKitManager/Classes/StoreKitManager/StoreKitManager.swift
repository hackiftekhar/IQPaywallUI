//
//  StoreKitManager.swift

import Foundation
import StoreKit

// StoreKit 2 manager
@objc
public final class StoreKitManager: NSObject, ObservableObject {
    @objc static public let shared = StoreKitManager()

    // MARK: - Configuration
    private var productIDs: [String] = []
    private var products: [Product] = []

    @MainActor
    @Published @objc public var isProductLoading: Bool = false

    @MainActor
    @Published @objc public var isProductLoadingError: Bool = false

    @MainActor
    @Published @objc public var productLoadingError: Error? = nil


    @MainActor
    @Published @objc public var isProductPurchasing: Bool = false

    @MainActor
    @Published @objc public var isProductPurchasingError: Bool = false

    @MainActor
    @Published @objc public var productPurchaseError: Error? = nil

    // Observe transactions
    private var updatesTask: Task<Void, Never>?

    // Optional user linking
    private(set) var appAccountToken: UUID?

    private let inAppServer = PurchaseStatusManager.shared

    private override init() {
        super.init()
    }
    deinit { updatesTask?.cancel() }

    @objc public func setAppAccountToken(_ token: UUID?) {
        self.appAccountToken = token
    }

    @objc public func configure(productIDs: [String]) {
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

extension StoreKitManager {

    /// Purchase a product
    public func purchase(product: Product) async -> PurchaseState {

        await MainActor.run {
            isProductPurchasing = true
            isProductPurchasingError = false
            productPurchaseError = nil
        }

        let finalResult: PurchaseState

        do {
            var options: Set<Product.PurchaseOption> = []
            let appAccountToken: UUID? = appAccountToken
            if let appAccountToken = appAccountToken {
                options.insert(.appAccountToken(appAccountToken))
            }

            let result = try await product.purchase(options: options)
            switch result {
            case .success(let verification):
                do {
                    let txn = try Self.verify(verification)
                    let _ = try await deliverAndValidate(transaction: txn, for: product, appAccountToken: appAccountToken)
                    await txn.finish()
                    await inAppServer.refreshStatuses([product])
                    finalResult = .success(transaction: txn)
                } catch {
                    finalResult = .failure(error: error)
                }
                
            case .userCancelled:
                finalResult = .userCancelled
            case .pending:
                finalResult = .pending
            @unknown default:
                finalResult = .failure(error: NSError(domain: "IAP", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown purchase result"]))
            }
        } catch {
            finalResult = .failure(error: error)
        }

        await MainActor.run {
            isProductPurchasing = false
            switch finalResult {
            case .success, .restored:
                break
            case .pending:
                isProductPurchasingError = true
                productPurchaseError = NSError(domain: "IAP", code: -1, userInfo: [NSLocalizedDescriptionKey: "Purchase is Pending to be Completed!"])
            case .userCancelled:
                break
            case .failure(let error):
                isProductPurchasingError = true
                productPurchaseError = error
            }
        }

        return finalResult
    }
    
    /// Restore purchases
    public func restorePurchases() async -> PurchaseState {
        await MainActor.run {
            isProductPurchasing = true
            isProductPurchasingError = false
            productPurchaseError = nil
        }

        let finalResult: PurchaseState
        do {
            try await AppStore.sync()
            await inAppServer.refreshStatuses(self.products)
            finalResult = .restored
        } catch {
            if let storeKitError = error as? StoreKitError, case .userCancelled = storeKitError {
                finalResult = .userCancelled
            } else {
                finalResult = .failure(error: error)
            }
        }

        await MainActor.run {
            isProductPurchasing = false
            switch finalResult {
            case .success, .restored:
                break
            case .pending:
                isProductPurchasingError = true
                productPurchaseError = NSError(domain: "IAP", code: -1, userInfo: [NSLocalizedDescriptionKey: "Purchase is Pending to be Completed!"])
            case .userCancelled:
                break
            case .failure(let error):
                isProductPurchasingError = true
                productPurchaseError = error
            }
        }

        return finalResult
    }
}

extension StoreKitManager {

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
    @objc public func presentCodeRedemptionSheet() {
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

extension StoreKitManager {

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
                        let appAccountToken = appAccountToken
                        let _ = try await self.deliverAndValidate(transaction: txn, for: product, appAccountToken: appAccountToken)
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
    
    private func deliverAndValidate(transaction: Transaction, for product: Product, appAccountToken: UUID?) async throws {
        let renewalInfo = await self.renewalInfo(for: product)
        try await self.inAppServer.validate(
            transaction: transaction,
            renewalInfo: renewalInfo,
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
}
