//
//  PurchaseStatusManager.swift

import Foundation
import StoreKit

@objc
public final class PurchaseStatusManager: NSObject {

    @objc public static let shared = PurchaseStatusManager()

    private let receiptFetcher = AppReceiptFetcher()

    @objc
    public static let purchaseStatusDidChangedNotification: Notification.Name = Notification.Name("PurchaseStatusDidChangedNotification")

    // Cache status snapshots per productID (main-actor mutation)
    private var snapshotStatus: [String: ProductSnapshot] = [:]

    private override init() {
        super.init()
        snapshotStatus = (try? self.cachedSnapshot()) ?? [:]
    }

    @objc public var currentlyActivePlan: ProductStatus? {
        guard let snapshot = self.snapshotStatus.values.first(where: { $0.isActive } ) else {
            return nil
        }
        return ProductStatus(from: snapshot)
    }

    /// Snapshot for UI (active, grace, retry, etc.)
    @objc public func snapshot(for productID: String) -> ProductStatus? {
        guard let snapshot = snapshotStatus[productID] else {
            return nil
        }
        return ProductStatus(from: snapshot)

    }

    @objc public func isActive(productID: String) -> Bool {
         return snapshotStatus[productID]?.isActive == true
    }

    @objc public var isAnyPlanActive: Bool {
        for snapshot in self.snapshotStatus.values {
            if snapshot.isActive {
                return true
            }
        }
        return false
    }
}

internal extension PurchaseStatusManager {

    func refreshStatuses(_ products: [Product]) async {
        var newSnapshots: [String: ProductSnapshot] = self.snapshotStatus
        let cachedSnapshots: [String: ProductSnapshot] = (try? self.cachedSnapshot()) ?? [:]
        for product in products {
            if let sub = product.subscription {
                do {
                    let statuses = try await sub.status
                    let snapshot = await self.bestSnapshot(for: product, statuses: statuses)
                    if let snapshot {
                        newSnapshots[product.id] = snapshot
                    } else if let cached = cachedSnapshots[product.id] {
                        newSnapshots[product.id] = cached
                    }
                } catch {

                    if let cached = cachedSnapshots[product.id] {
                        newSnapshots[product.id] = cached
                    } else {
                        // produce a minimal snapshot when status can't be fetched
                        let snap = ProductSnapshot(
                            productID: product.id,
                            state: .expired,
                            willAutoRenew: false,
                            nextRenewalDate: nil,
                            expirationDate: nil,
                            isEligibleForIntroOffer: await isEligibleForIntroOffer(for: product),
                            isFamilyShareable: product.isFamilyShareable,
                            ownershipType: nil
//                            environment: product.environment
                        )
                        newSnapshots[product.id] = snap
                    }
                }
            } else {
                // Non-subscription product — try to find a latest transaction
                if let txn = await StoreKitManager.shared.latestTransaction(for: product.id) {
                    let snap = ProductSnapshot(
                        productID: product.id,
                        state: .subscribed,
                        willAutoRenew: false,
                        nextRenewalDate: nil,
                        expirationDate: nil,
                        isEligibleForIntroOffer: await isEligibleForIntroOffer(for: product),
                        isFamilyShareable: product.isFamilyShareable,
                        ownershipType: txn.ownershipType
                    )
                    newSnapshots[product.id] = snap
                } else if let cached = cachedSnapshots[product.id] {
                    newSnapshots[product.id] = cached
                } else {
                    // produce a minimal snapshot when status can't be fetched
                    let snap = ProductSnapshot(
                        productID: product.id,
                        state: .expired,
                        willAutoRenew: false,
                        nextRenewalDate: nil,
                        expirationDate: nil,
                        isEligibleForIntroOffer: await isEligibleForIntroOffer(for: product),
                        isFamilyShareable: product.isFamilyShareable,
                        ownershipType: nil
//                            environment: product.environment
                    )
                    newSnapshots[product.id] = snap
                }
            }

        }
        self.snapshotStatus = newSnapshots
        if newSnapshots != cachedSnapshots {
            await MainActor.run {
                NotificationCenter.default.post(name: Self.purchaseStatusDidChangedNotification, object: nil)
            }
        }
        try? persistSnapshot(newSnapshots)
    }

    private func bestSnapshot(for product: Product, statuses: [Product.SubscriptionInfo.Status]) async -> ProductSnapshot? {
        // Prefer currently active-ish states first

        let filtered = statuses.filter { (try? $0.transaction.payloadValue.productID) == product.id }

        let preferredOrder: [Product.SubscriptionInfo.RenewalState] = [.subscribed, .inGracePeriod, .inBillingRetryPeriod, .expired, .revoked]

        let sorted = filtered.sorted { (lhs: Product.SubscriptionInfo.Status, rhs: Product.SubscriptionInfo.Status) in
            let li = preferredOrder.firstIndex(of: lhs.state) ?? preferredOrder.count
            let ri = preferredOrder.firstIndex(of: rhs.state) ?? preferredOrder.count
            if li != ri { return li < ri }
            // tie-breaker: later expiration date or transaction purchase date

            let lhsVerify = try? StoreKitManager.verify(lhs.transaction)
            let rhsVerify = try? StoreKitManager.verify(rhs.transaction)

            let lDate = lhsVerify?.expirationDate ?? (try? lhs.transaction.payloadValue.expirationDate)
            let rDate = rhsVerify?.expirationDate ?? (try? rhs.transaction.payloadValue.expirationDate)
            return (lDate ?? .distantPast) > (rDate ?? .distantPast)
        }

        guard let top = sorted.first else {
            // No status — construct minimal
            return ProductSnapshot(
                productID: product.id,
                state: .expired,
                willAutoRenew: false,
                nextRenewalDate: nil,
                expirationDate: nil,
                isEligibleForIntroOffer: await isEligibleForIntroOffer(for: product),
                isFamilyShareable: product.isFamilyShareable,
                ownershipType: nil
//                environment: nil
            )
        }

        // Verify objects
        let txn: Transaction? = (try? StoreKitManager.verify(top.transaction))
        let renewalInfo: Product.SubscriptionInfo.RenewalInfo? = try? StoreKitManager.verify(top.renewalInfo)

        // Derive details
        let willAutoRenew = renewalInfo?.willAutoRenew ?? false
        let nextRenewalDate = renewalInfo?.renewalDate
        let expirationDate = txn?.expirationDate

        let introEligible = await isEligibleForIntroOffer(for: product)
        let ownership = txn?.ownershipType
//        let env = txn?.environment

        return ProductSnapshot(
            productID: product.id,
            state: top.state,
            willAutoRenew: willAutoRenew,
            nextRenewalDate: nextRenewalDate,
            expirationDate: expirationDate,
            isEligibleForIntroOffer: introEligible,
            isFamilyShareable: product.isFamilyShareable,
            ownershipType: ownership
//            environment: env
        )
    }

    /// Intro offer eligibility (best available)
    func isEligibleForIntroOffer(for product: Product) async -> Bool {
        if #available(iOS 16.4, *) {
            return await product.subscription?.isEligibleForIntroOffer ?? false
        }
        // Fallback heuristic: if no status for the group, assume eligible
        guard let info = product.subscription else { return false }
        do {
            let statuses = try await info.status
            return statuses.isEmpty
        } catch {
            return false
        }
    }
}

internal extension PurchaseStatusManager {
    /// Send a transaction and optional renewal info JWS to your server to validate and grant entitlements.
    func validate(transaction: Transaction, renewalInfo: Product.SubscriptionInfo.RenewalInfo?, appAccountToken: UUID?) async throws {

        let receiptToken = try await receiptFetcher.fetchBase64Receipt()

        var params: [String:String] = [:]
        params["receipt_token"] = receiptToken
        params["product_id"] = transaction.productID
//        params["environment"] = transaction.environment.rawValue
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
//            APIClient.purchasePlan(param: params) { result in
                continuation.resume(returning: ())
//            }
        }
    }
}
