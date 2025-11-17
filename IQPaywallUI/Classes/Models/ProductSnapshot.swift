//
//  ProductSnapshot.swift

import StoreKit

struct ProductSnapshot: Codable, Equatable {

    public let productID: String
    public let state: Product.SubscriptionInfo.RenewalState
    public let willAutoRenew: Bool
    public let nextRenewalDate: Date?
    public let expirationDate: Date?
    public let isEligibleForIntroOffer: Bool
    public let isFamilyShareable: Bool
    public let ownershipType: Transaction.OwnershipType?
//    public let environment: AppStore.Environment

    enum CodingKeys: String, CodingKey {
        case productID
        case state
        case willAutoRenew
        case nextRenewalDate
        case expirationDate
        case isEligibleForIntroOffer
        case isFamilyShareable
        case ownershipType
        case environment
    }

    public var isActive: Bool {
        switch state {
        case .subscribed, .inGracePeriod, .inBillingRetryPeriod: return true
        default: return false
        }
    }

    init(productID: String, state: Product.SubscriptionInfo.RenewalState, willAutoRenew: Bool, nextRenewalDate: Date?, expirationDate: Date?, isEligibleForIntroOffer: Bool, isFamilyShareable: Bool, ownershipType: Transaction.OwnershipType?/*, environment: AppStore.Environment*/) {
        self.productID = productID
        self.state = state
        self.willAutoRenew = willAutoRenew
        self.nextRenewalDate = nextRenewalDate
        self.expirationDate = expirationDate
        self.isEligibleForIntroOffer = isEligibleForIntroOffer
        self.isFamilyShareable = isFamilyShareable
        self.ownershipType = ownershipType
//        self.environment = environment
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(productID, forKey: .productID)
        try container.encode(state.rawValue, forKey: .state)
        try container.encode(willAutoRenew, forKey: .willAutoRenew)
        try container.encode(nextRenewalDate, forKey: .nextRenewalDate)
        try container.encode(expirationDate, forKey: .expirationDate)
        try container.encode(isEligibleForIntroOffer, forKey: .isEligibleForIntroOffer)
        try container.encode(isFamilyShareable, forKey: .isFamilyShareable)
        try container.encode(ownershipType?.rawValue, forKey: .ownershipType)
//        try container.encode(environment.rawValue, forKey: .environment)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.productID = try container.decode(String.self, forKey: .productID)
        let state: Int = try container.decode(Int.self, forKey: .state)
        self.state = Product.SubscriptionInfo.RenewalState(rawValue: state)
        self.willAutoRenew = try container.decode(Bool.self, forKey: .willAutoRenew)
        self.nextRenewalDate = try? container.decodeIfPresent(Date.self, forKey: .nextRenewalDate)
        self.expirationDate = try? container.decodeIfPresent(Date.self, forKey: .expirationDate)
        self.isEligibleForIntroOffer = try container.decode(Bool.self, forKey: .isEligibleForIntroOffer)
        self.isFamilyShareable = try container.decode(Bool.self, forKey: .isFamilyShareable)
        if let ownershipType: String = try? container.decode(String.self, forKey: .ownershipType) {
            self.ownershipType = Transaction.OwnershipType(rawValue: ownershipType)
        } else {
            self.ownershipType = nil
        }

//        let environment: String = try container.decode(String.self, forKey: .environment)
//        self.environment = AppStore.Environment(rawValue: environment)
    }
}
