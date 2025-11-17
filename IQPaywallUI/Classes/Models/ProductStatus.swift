//
//  ProductStatus.swift

import StoreKit

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

@objc public final class ProductStatus: NSObject {
    @objc public let productID: String
    @objc public let state: RenewalState
    @objc public let willAutoRenew: Bool
    @objc public let nextRenewalDate: Date?
    @objc public let expirationDate: Date?
    @objc public let isEligibleForIntroOffer: Bool
    @objc public let isFamilyShareable: Bool
    @objc public let ownershipType: OwnershipType

    init(from snapshot: ProductSnapshot) {
        self.productID = snapshot.productID
        self.willAutoRenew = snapshot.willAutoRenew
        self.nextRenewalDate = snapshot.nextRenewalDate
        self.expirationDate = snapshot.expirationDate
        self.isEligibleForIntroOffer = snapshot.isEligibleForIntroOffer
        self.isFamilyShareable = snapshot.isFamilyShareable

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

    public var isActive: Bool {
        switch state {
        case .subscribed, .inGracePeriod, .inBillingRetryPeriod: return true
        default: return false
        }
    }
}

