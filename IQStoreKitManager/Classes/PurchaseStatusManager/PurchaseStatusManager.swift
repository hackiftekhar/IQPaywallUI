//
//  PurchaseStatusManager.swift

import Foundation
import StoreKit

@objc
public final class PurchaseStatusManager: NSObject {

    @objc public static let shared = PurchaseStatusManager()

    @objc
    public static let purchaseStatusDidChangedNotification: Notification.Name = Notification.Name("PurchaseStatusDidChangedNotification")

    // Cache status snapshots per productID
    private var snapshotStatus: [String: ProductSnapshot] = [:]

    private override init() {
        super.init()
        snapshotStatus = (try? self.cachedSnapshot()) ?? [:]
    }

    @objc public var activePlans: [ProductStatus] {
        let snapshots = self.snapshotStatus.values.filter { $0.isActive }
        return snapshots.map { .init(from: $0) }
    }

    /// Snapshot for UI (active, grace, retry, etc.)
    @objc public func snapshot(for productID: String) -> ProductStatus? {
        guard let snapshot = snapshotStatus[productID] else {
            return nil
        }
        return ProductStatus(from: snapshot)

    }

    @objc public func status(productID: String) -> ActiveStatus {
         return snapshotStatus[productID]?.status ?? .inactive
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
                            product: product,
                            isEligibleForIntroOffer: await isEligibleForIntroOffer(for: product),
                            status: nil
                        )
                        newSnapshots[product.id] = snap
                    }
                }
            } else {

                let introEligible = await isEligibleForIntroOffer(for: product)
                // Non-subscription product — try to find a latest transaction
                if let transaction = await StoreKitManager.shared.latestTransaction(for: product.id) {
                    let snap = ProductSnapshot(product: product,
                                               isEligibleForIntroOffer: introEligible,
                                               transaction: transaction)
                    newSnapshots[product.id] = snap
                } else if let cached = cachedSnapshots[product.id] {
                    newSnapshots[product.id] = cached
                } else {
                    // produce a minimal snapshot when status can't be fetched
                    let snap = ProductSnapshot(
                        product: product,
                        isEligibleForIntroOffer: introEligible,
                        status: nil
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

        let filtered = statuses.filter {
            (try? $0.renewalInfo.payloadValue.currentProductID) == product.id ||
            (try? $0.renewalInfo.payloadValue.autoRenewPreference) == product.id
        }

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

        let introEligible = await isEligibleForIntroOffer(for: product)

        return ProductSnapshot(
            product: product,
            isEligibleForIntroOffer: introEligible,
            status: sorted.first)
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
