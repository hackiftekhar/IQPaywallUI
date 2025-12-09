//
//  ProductDisplayInfo.swift

import StoreKit
import IQStoreKitManager

// 1. Create a wrapper struct for display data
public struct ProductInfo: Identifiable, Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public let id: String
    public let type: Product.ProductType
    public let displayName: String
    public let description: String
    public let price: Decimal
    public let priceFormatStyle: Decimal.FormatStyle.Currency
    public let displayPrice: String
    public let subscription: ProductInfo.SubscriptionInfo?

    private(set) var snapshot: ProductStatus?
    public var isActive: Bool { snapshot?.isActive ?? false }
    public var status: ActiveStatus { snapshot?.status ?? .inactive }
    public var isEligibleForIntroOffer: Bool { snapshot?.isEligibleForIntroOffer ?? false }

    init(id: String, type: Product.ProductType,
         displayName: String, description: String,
         price: Decimal, priceFormatStyle: Decimal.FormatStyle.Currency, displayPrice: String,
         subscription: ProductInfo.SubscriptionInfo?, snapshot: ProductStatus?) {
        self.id = id
        self.type = type
        self.displayName = displayName
        self.description = description
        self.price = price
        self.priceFormatStyle = priceFormatStyle
        self.displayPrice = displayPrice
        self.subscription = subscription
        self.snapshot = snapshot
    }

    init(product: Product, snapshot: ProductStatus?) {
        self.id = product.id
        self.type = product.type
        self.displayName = product.displayName
        self.price = product.price
        self.priceFormatStyle = product.priceFormatStyle
        self.displayPrice = product.displayPrice
        self.description = product.description
        if let subscription = product.subscription {
            self.subscription = .init(subscription: subscription)
        } else {
            self.subscription = nil
        }
        self.snapshot = snapshot
    }

    mutating internal func updateSnapshot(_ snapshot: ProductStatus?) {
        self.snapshot = snapshot
    }

    var discountedDisplayPrice: String? {
        guard let subscription = subscription,
              let offer = subscription.introductoryOffer else {
            return nil
        }

        switch offer.paymentMode {
        case .freeTrial:
            return"\(offer.period.localizedDescription) Free"
        case .payAsYouGo:
            return offer.displayPrice
        case .payUpFront:

            let originalDays = subscription.subscriptionPeriod.days
            let upfrontDays = offer.period.days * offer.periodCount

            let ratio: CGFloat = CGFloat(originalDays) / CGFloat(upfrontDays)

            let offerPrice = offer.price * Decimal(ratio)

            return offerPrice.formatted(priceFormatStyle)
        default:
            return displayPrice
        }
    }

    public struct SubscriptionInfo: Hashable {
        let subscriptionPeriod: ProductInfo.SubscriptionPeriod
        let introductoryOffer: ProductInfo.SubscriptionOffer?

        init(subscriptionPeriod: ProductInfo.SubscriptionPeriod, introductoryOffer: ProductInfo.SubscriptionOffer) {
            self.subscriptionPeriod = subscriptionPeriod
            self.introductoryOffer = introductoryOffer
        }

        init(subscription: Product.SubscriptionInfo) {
            self.subscriptionPeriod = .init(subscriptionPeriod: subscription.subscriptionPeriod)
            if let offer = subscription.introductoryOffer {
                self.introductoryOffer = .init(offer: offer)
            } else {
                self.introductoryOffer = nil
            }
        }
    }
}

extension ProductInfo {
    var subscriptionPeriodDescription: String? {
        switch type {
        case .nonConsumable:
            return "Lifetime"
        case .autoRenewable:
            if let period = subscription?.subscriptionPeriod {
                return "per " + period.formatted
            }
        case .nonRenewable:
            if let period = subscription?.subscriptionPeriod {
                return period.formatted
            }
        case .consumable:
            fallthrough
        default:
            break
        }
        return nil
    }
}

extension ProductInfo {

    static let placeholders: [ProductInfo] = [monthlyPlaceholder, yearlyPlaceholder, lifetimePlaceholder]

    static let monthlyPlaceholder = ProductInfo(
        id: "com.placeholder.monthly",
        type: .autoRenewable,
        displayName: "Monthly",
        description: "Unlock all pro features",
        price: .init(0.99),
        priceFormatStyle: .currency(code: "USD"),
        displayPrice: "$0.99",
        subscription: .init(subscriptionPeriod: .init(unit: .month, value: 1),
                            introductoryOffer: .init(id: nil, type: .introductory, price: .init(0.00), displayPrice: "Free", periodCount: 1, period: .init(unit: .week, value: 1), paymentMode: .freeTrial)), snapshot: nil,
    )
    static let yearlyPlaceholder = ProductInfo(
        id: "com.placeholder.yearly",
        type: .autoRenewable,
        displayName: "Yearly",
        description: "Unlock all pro features",
        price: .init(9.99),
        priceFormatStyle: .currency(code: "USD"),
        displayPrice: "$9.99",
        subscription: .init(subscriptionPeriod: .init(unit: .month, value: 1),
                            introductoryOffer: .init(id: nil, type: .introductory, price: .init(0.00), displayPrice: "Free", periodCount: 1, period: .init(unit: .week, value: 1), paymentMode: .freeTrial)), snapshot: nil,
    )
    static let lifetimePlaceholder = ProductInfo(
        id: "com.placeholder.lifetime",
        type: .nonConsumable,
        displayName: "Lifetime",
        description: "Unlock all pro features",
        price: .init(29.99),
        priceFormatStyle: .currency(code: "USD"),
        displayPrice: "$29.99",
        subscription: nil,
        snapshot: nil
    )
}
