//
//  StoreKitManager.swift

import Foundation
import StoreKit

public protocol StoreKitManagerDelegate: AnyObject {
    func deliver(product: Product, transaction: StoreKit.Transaction, renewalInfo: Product.SubscriptionInfo.RenewalInfo?, receiptData:Data, appAccountToken: UUID?, completion: @escaping ((Swift.Result<Void, Error>) -> Void))

    func generateSignature(product: Product, offerID: String, appAccountToken: UUID?, completion: @escaping ((Swift.Result<OfferSignature, Error>) -> Void))
}

extension StoreKitManagerDelegate {

    func deliver(product: Product, transaction: StoreKit.Transaction, renewalInfo: Product.SubscriptionInfo.RenewalInfo?, receiptData:Data, appAccountToken: UUID?, completion: @escaping ((Swift.Result<Void, Error>) -> Void)) {
        completion(.success(()))
    }

    func generateSignature(product: Product, offerID: String, appAccountToken: UUID?, completion: @escaping ((Swift.Result<OfferSignature, Error>) -> Void)) {
        fatalError("You must implement \(#function) and generate an offer signature")
    }
}

// StoreKit 2 manager
@objc
public final class StoreKitManager: NSObject, ObservableObject {
    @objc static public let shared = StoreKitManager()

    private let receiptFetcher = AppReceiptFetcher()

    // For cancelled subscriptions, we don't get a realtime update, so we schedule a refresh timer
    private var refreshTimer: Timer?

    weak var delegate: StoreKitManagerDelegate?

    // MARK: - Configuration
    private var productIDs: [String] = []
    private var products: [Product] = []

    // Observe transactions
    private var updatesTask: Task<Void, Never>?

    // Optional user linking
    private(set) var appAccountToken: UUID?

    private let purchaseStatusManager = PurchaseStatusManager.shared

    private override init() {
        super.init()
    }
    deinit { updatesTask?.cancel() }

    @objc public func setAppAccountToken(_ token: UUID?) {
        self.appAccountToken = token
    }

    @objc public func configure(productIDs: [String]) {
        configure(productIDs: productIDs, delegate: nil)
    }

    public func configure(productIDs: [String], delegate: StoreKitManagerDelegate?) {
        self.productIDs = productIDs
        self.delegate = delegate
        Task {
            let products = await loadProducts(productIDs: productIDs)
            self.products = products
            self.renewRefreshTimers()
            beginObservingTransactions()
            addForegroundObserver()
        }
    }

    private func addForegroundObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: OperationQueue()
        ) { [weak self] _ in
            guard let self = self else { return }
            Task {
                await self.refreshStatuses()
            }
        }
    }


    public func refreshStatuses() async {
        await self.purchaseStatusManager.refreshStatuses(self.products)
        self.renewRefreshTimers()
    }

    /// Refresh products
    public func loadProducts(productIDs: [String]) async -> [Product] {
        var productIDs = productIDs
        if productIDs.isEmpty { productIDs = self.productIDs }

        let products: [Product]
        do {
            products = try await loadProducts(for: productIDs)
            await purchaseStatusManager.refreshStatuses(products)
        } catch {
            products = self.products.filter({ productIDs.contains($0.id) })
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
    public func purchase(product: Product, offer: Product.SubscriptionOffer? = nil) async -> PurchaseState {

        let finalResult: PurchaseState

        do {
            var options: Set<Product.PurchaseOption> = []
            let appAccountToken: UUID? = appAccountToken
            if let appAccountToken = appAccountToken {
                options.insert(.appAccountToken(appAccountToken))
            }

            if let offer = offer, let offerId = offer.id {
                guard let delegate = delegate else {
                    fatalError("You must set delegate and implement 'generateSignature(product:offerID:appAccountToken:completion:)' function and generate an offer signature")
                }

                let signatureResponse: OfferSignature = try await withCheckedThrowingContinuation { continuation in
                    return delegate.generateSignature(product: product, offerID: offerId, appAccountToken: appAccountToken, completion: { result in
                        continuation.resume(with: result)
                    })
                }

                guard let signatureData = Data(base64Encoded: signatureResponse.signature) else {
                    throw NSError(domain: "\(Self.self)", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid signature data"])
                }

                let nonce = UUID(uuidString:signatureResponse.nonce)!
                options.insert(.promotionalOffer(offerID: offerId, keyID: signatureResponse.keyID, nonce: nonce, signature: signatureData, timestamp: signatureResponse.timestamp))
            }

            let result = try await product.purchase(options: options)
            switch result {
            case .success(let verification):
                do {
                    let transaction = try Self.verify(verification)
                    try await self.deliver(product: product, transaction: transaction, appAccountToken: appAccountToken)
                    await transaction.finish()

                    let productsToRefresh: [Product]
                    if product.subscription != nil {
                        // Refreshing products of same group
                        productsToRefresh = self.products.filter { $0.subscription?.subscriptionGroupID == product.subscription?.subscriptionGroupID }
                    } else {
                        productsToRefresh = [product]
                    }
                    await purchaseStatusManager.refreshStatuses(productsToRefresh)
                    self.renewRefreshTimers()
                    finalResult = .success(transaction: transaction)
                } catch {
                    finalResult = .failure(error: error)
                }
                
            case .userCancelled:
                finalResult = .userCancelled
            case .pending:
                finalResult = .pending
            @unknown default:
                finalResult = .failure(error: NSError(domain: "\(Self.self)", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown purchase result"]))
            }
        } catch {
            finalResult = .failure(error: error)
        }

        return finalResult
    }
    
    /// Restore purchases
    public func restorePurchases() async -> PurchaseState {

        let finalResult: PurchaseState
        do {
            try await AppStore.sync()
            await self.refreshStatuses()
            finalResult = .restored
        } catch {
            if let storeKitError = error as? StoreKitError, case .userCancelled = storeKitError {
                finalResult = .userCancelled
            } else {
                finalResult = .failure(error: error)
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
            guard let transaction = await latestTransaction(for: productID) else {
                return .failure(NSError(domain: "\(Self.self)", code: -2, userInfo: [NSLocalizedDescriptionKey: "No transaction found for product"]))
            }
            let status = try await transaction.beginRefundRequest(in: scene)
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
                    let transaction = try Self.verify(verification)
                    let product: Product? = self.products.first(where: { $0.id == transaction.productID })
                    if let product: Product = product {
                        try await self.deliver(product: product, transaction: transaction, appAccountToken: appAccountToken)
                    }
                    await transaction.finish()

                    // Load product to pass into deliver
                    if let product: Product = product {
                        let productsToRefresh: [Product]
                        if product.subscription != nil {
                            // Refreshing products of same group
                            productsToRefresh = self.products.filter { $0.subscription?.subscriptionGroupID == product.subscription?.subscriptionGroupID }
                        } else {
                            productsToRefresh = [product]
                        }

                        await self.purchaseStatusManager.refreshStatuses(productsToRefresh)
                        self.renewRefreshTimers()
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
    
    private func deliver(product: Product, transaction: Transaction, appAccountToken: UUID?) async throws {
        let renewalInfo = await self.renewalInfo(for: product)
        let receiptData = try await receiptFetcher.fetchBase64Receipt()

        if let delegate = delegate {
            return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                delegate.deliver(product: product,
                                 transaction: transaction,
                                 renewalInfo: renewalInfo,
                                 receiptData: receiptData,
                                 appAccountToken: appAccountToken,
                                 completion: { result in
                    continuation.resume(with: result)
                })
            }
        }
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

extension StoreKitManager {
    private func renewRefreshTimers() {
        refreshTimer?.invalidate()
        refreshTimer = nil

        let allSnapshots: [ProductStatus] = self.products.compactMap { PurchaseStatusManager.shared.snapshot(for: $0.id) }
        let expiryDates: [Date] = allSnapshots.compactMap { $0.renewalInfo?.nextRenewalDate ?? $0.renewalInfo?.expirationDate }.sorted()
        guard let closestExpiryDate = expiryDates.first else {
            return
        }

        let timer = Timer(fire: closestExpiryDate, interval: 3600, repeats: false) { _ in
            Task {
                await self.refreshStatuses()
            }
        }
        RunLoop.current.add(timer, forMode: .common)
        refreshTimer = timer
    }
}
