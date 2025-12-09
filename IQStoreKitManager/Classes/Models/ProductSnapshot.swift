//
//  ProductSnapshot.swift

import StoreKit

internal struct RenewalSnapshot: Codable, Equatable {
    let id: String
    let type: Product.ProductType
    let state: Product.SubscriptionInfo.RenewalState
    let isActive: Bool
    let willAutoRenew: Bool
    let autoRenewPreference: String?
    let nextRenewalDate: Date?
    let gracePeriodExpirationDate: Date?
    let expirationDate: Date?
    let ownershipType: Transaction.OwnershipType?

    init(state: Product.SubscriptionInfo.RenewalState,
         transaction: Transaction,
         renewalInfo: Product.SubscriptionInfo.RenewalInfo?) {
        self.id = transaction.productID
        self.type = transaction.productType
        self.state = state
        self.willAutoRenew = renewalInfo?.willAutoRenew ?? false
        self.autoRenewPreference = renewalInfo?.autoRenewPreference
        self.nextRenewalDate = renewalInfo?.renewalDate
        self.gracePeriodExpirationDate = renewalInfo?.gracePeriodExpirationDate
        self.expirationDate = transaction.expirationDate
        self.ownershipType = transaction.ownershipType

        switch state {
        case .subscribed, .inGracePeriod:
            isActive = true
        case .expired, .revoked, .inBillingRetryPeriod:
            isActive = false
        default: isActive = false
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case state
        case isActive
        case willAutoRenew
        case autoRenewPreference
        case nextRenewalDate
        case gracePeriodExpirationDate
        case expirationDate
        case ownershipType
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(state.rawValue, forKey: .state)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(willAutoRenew, forKey: .willAutoRenew)
        try container.encode(autoRenewPreference, forKey: .autoRenewPreference)
        try container.encode(nextRenewalDate, forKey: .nextRenewalDate)
        try container.encode(gracePeriodExpirationDate, forKey: .gracePeriodExpirationDate)
        try container.encode(expirationDate, forKey: .expirationDate)
        try container.encode(ownershipType?.rawValue, forKey: .ownershipType)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .autoRenewPreference)
        let type: String = try container.decode(String.self, forKey: .type)
        self.type = .init(rawValue: type)
        let state: Int = try container.decode(Int.self, forKey: .state)
        self.state = .init(rawValue: state)
        self.isActive = try container.decode(Bool.self, forKey: .isActive)
        self.willAutoRenew = try container.decode(Bool.self, forKey: .willAutoRenew)
        self.nextRenewalDate = try? container.decodeIfPresent(Date.self, forKey: .nextRenewalDate)
        self.gracePeriodExpirationDate = try? container.decodeIfPresent(Date.self, forKey: .gracePeriodExpirationDate)
        self.expirationDate = try? container.decodeIfPresent(Date.self, forKey: .expirationDate)
        self.autoRenewPreference = try? container.decode(String.self, forKey: .autoRenewPreference)

        if let ownershipType: String = try? container.decode(String.self, forKey: .ownershipType) {
            self.ownershipType = Transaction.OwnershipType(rawValue: ownershipType)
        } else {
            self.ownershipType = nil
        }

//        let environment: String = try container.decode(String.self, forKey: .environment)
//        self.environment = AppStore.Environment(rawValue: environment)
    }
}

internal struct ProductSnapshot: Codable, Equatable {

    let id: String
    let type: Product.ProductType
    let displayName: String
    let isEligibleForIntroOffer: Bool
    let isFamilyShareable: Bool

    let renewalInfo: RenewalSnapshot?
//    let environment: AppStore.Environment

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case displayName
        case isEligibleForIntroOffer
        case isFamilyShareable

        case renewalInfo
//        case environment
    }

    // For Non Subscription products
    init(product: Product, isEligibleForIntroOffer: Bool, transaction: Transaction) {
        self.id = product.id
        self.type = product.type
        self.displayName = product.displayName
        self.isEligibleForIntroOffer = isEligibleForIntroOffer
        self.isFamilyShareable = product.isFamilyShareable

        let renewalSnapshot = RenewalSnapshot(state: .subscribed,
                                              transaction: transaction,
                                              renewalInfo: nil)
        self.renewalInfo = renewalSnapshot
    }

    init(product: Product, isEligibleForIntroOffer: Bool, status: Product.SubscriptionInfo.Status?) {
        self.id = product.id
        self.type = product.type
        self.displayName = product.displayName
        self.isEligibleForIntroOffer = isEligibleForIntroOffer
        self.isFamilyShareable = product.isFamilyShareable

        if let status = status,
           let transaction: Transaction = try? Self.verify(status.transaction) {

            let renewalInfo: Product.SubscriptionInfo.RenewalInfo? = try? Self.verify(status.renewalInfo)
            if renewalInfo?.currentProductID == product.id {
                let renewalSnapshot = RenewalSnapshot(state: status.state,
                                                      transaction: transaction,
                                                      renewalInfo: renewalInfo)
                self.renewalInfo = renewalSnapshot
            } else if renewalInfo?.autoRenewPreference == product.id, renewalInfo?.willAutoRenew == true {
                let renewalSnapshot = RenewalSnapshot(state: .expired,
                                                      transaction: transaction,
                                                      renewalInfo: renewalInfo)
                self.renewalInfo = renewalSnapshot
            } else {
                self.renewalInfo = nil
            }
        } else {
            self.renewalInfo = nil
        }
//        self.environment = environment
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(isEligibleForIntroOffer, forKey: .isEligibleForIntroOffer)
        try container.encode(isFamilyShareable, forKey: .isFamilyShareable)
        try container.encode(renewalInfo, forKey: .renewalInfo)
//        try container.encode(environment.rawValue, forKey: .environment)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        let type: String = try container.decode(String.self, forKey: .type)
        self.type = .init(rawValue: type)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.isEligibleForIntroOffer = try container.decode(Bool.self, forKey: .isEligibleForIntroOffer)
        self.isFamilyShareable = try container.decode(Bool.self, forKey: .isFamilyShareable)
        self.renewalInfo = try? container.decode(RenewalSnapshot.self, forKey: .renewalInfo)

//        let environment: String = try container.decode(String.self, forKey: .environment)
//        self.environment = AppStore.Environment(rawValue: environment)
    }

    private static func verify<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }


    var status: ActiveStatus {
        switch renewalInfo?.state {
        case .subscribed, .inGracePeriod, .inBillingRetryPeriod:
            switch type {
            case .consumable, .nonConsumable:
                return .unlocked
            case .autoRenewable, .nonRenewable:
                if renewalInfo?.state == .inGracePeriod {
                    return .gracePeriod
                } else if renewalInfo?.state == .inBillingRetryPeriod {
                    return .billingRetryPeriod
                } else {
                    return .active
                }
            default:
                return .inactive
            }
        case .expired, .revoked:
            fallthrough
        default:
            if renewalInfo?.autoRenewPreference == id, renewalInfo?.willAutoRenew == true {
                return .upcoming
            } else {
                return .inactive
            }
        }
    }

    var isActive: Bool {
        renewalInfo?.isActive ?? false
    }
}
