//
//  ProductStatus.swift

import StoreKit

@objc public enum ActiveStatus: Int {
    case inactive
    case active
    case gracePeriod
    case billingRetryPeriod
    case upcoming
    case unlocked

    public var displayName: String {
        switch self {
        case .inactive:  return "Inactive"
        case .active:    return "Active"
        case .gracePeriod:    return "Grace Period"
        case .billingRetryPeriod:    return "Billing Retry Period"
        case .upcoming:  return "Upcoming"
        case .unlocked:  return "Unlocked"
        }
    }
}

@objc public enum RenewalState: Int {
    case subscribed
    case expired
    case inBillingRetryPeriod
    case inGracePeriod
    case revoked
}

@objc public enum OwnershipType: Int {
    case none
    case purchased
    case familyShared
}

@objc public enum ProductType: Int {
    case consumable
    case nonConsumable
    case autoRenewable
    case nonRenewable
}

@objc public final class RenewalStatus: NSObject {

    private let snapshot: RenewalSnapshot

    @objc public let state: RenewalState
    @objc public let ownershipType: OwnershipType
    @objc public var willAutoRenew: Bool { snapshot.willAutoRenew }
    @objc public var autoRenewPreference: String? { snapshot.autoRenewPreference }
    @objc public var nextRenewalDate: Date? { snapshot.nextRenewalDate }
    @objc public var expirationDate: Date? { snapshot.expirationDate }
    @objc public var gracePeriodExpirationDate: Date? { snapshot.gracePeriodExpirationDate }
    @objc public var isActive: Bool { snapshot.isActive }

    init(from snapshot: RenewalSnapshot) {
        self.snapshot = snapshot

        switch snapshot.state {
        case .subscribed:   self.state = .subscribed
        case .expired:      self.state = .expired
        case .inBillingRetryPeriod: self.state = .inBillingRetryPeriod
        case .inGracePeriod:    self.state = .inGracePeriod
        case .revoked:      self.state = .revoked
        default:            self.state = .expired
        }
        switch snapshot.ownershipType {
        case .purchased:    self.ownershipType = .purchased
        case .familyShared: self.ownershipType = .familyShared
        default:            self.ownershipType = .none
        }
        super.init()
    }
}

@objc public final class ProductStatus: NSObject {

    private let snapshot: ProductSnapshot

    @objc public let type: ProductType
    @objc public let renewalInfo: RenewalStatus?
    @objc public var id: String { snapshot.id }
    @objc public var displayName: String { snapshot.displayName }
    @objc public var isEligibleForIntroOffer: Bool { snapshot.isEligibleForIntroOffer }
    @objc public var isFamilyShareable: Bool { snapshot.isFamilyShareable }
    @objc public var status: ActiveStatus { snapshot.status }

    init(from snapshot: ProductSnapshot) {
        self.snapshot = snapshot

        if let renewalInfo = snapshot.renewalInfo {
            self.renewalInfo = .init(from: renewalInfo)
        } else {
            self.renewalInfo = nil
        }

        switch snapshot.type {
        case .consumable:   self.type = .consumable
        case .nonConsumable:      self.type = .nonConsumable
        case .autoRenewable: self.type = .autoRenewable
        case .nonRenewable:    self.type = .nonRenewable
        default:            self.type = .nonConsumable
        }

        super.init()
    }

    @objc
    public var isActive: Bool {
        renewalInfo?.isActive ?? false
    }
}
