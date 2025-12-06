//
//  SubscriptionOffer+Formatting

import Foundation
import StoreKit

extension Product.SubscriptionOffer {

    var formatted: String {
        let formattedPeriod = period.formatted
        switch type {
        case .introductory:
            switch paymentMode {
            case .freeTrial: return "\(formattedPeriod) Free Trial"
            case .payUpFront: return "\(displayPrice) for \(formattedPeriod)"
            case .payAsYouGo: return "\(displayPrice)/\(formattedPeriod)"
            default: return "Intro offer"
            }
        case .promotional:
            switch paymentMode {
            case .freeTrial: return "Free for \(formattedPeriod)"
            case .payUpFront: return "\(displayPrice) for \(formattedPeriod)"
            case .payAsYouGo: return "\(displayPrice)/\(formattedPeriod)"
            default: return "Promotional offer"
            }
        default:
            return "Special offer"
        }
    }
}

extension ProductInfo {

    struct SubscriptionOffer {
        public let id: String?
        public let type: Product.SubscriptionOffer.OfferType
        public let displayPrice: String
        public let period: ProductInfo.SubscriptionPeriod
        public let paymentMode: Product.SubscriptionOffer.PaymentMode

        init(id: String?, type: Product.SubscriptionOffer.OfferType, displayPrice: String, period: ProductInfo.SubscriptionPeriod, paymentMode: Product.SubscriptionOffer.PaymentMode) {
            self.id = id
            self.type = type
            self.displayPrice = displayPrice
            self.period = period
            self.paymentMode = paymentMode
        }

        init(offer: Product.SubscriptionOffer) {
            self.id = offer.id
            self.type = offer.type
            self.displayPrice = offer.displayPrice
            self.period = ProductInfo.SubscriptionPeriod(subscriptionPeriod: offer.period)
            self.paymentMode = offer.paymentMode
        }

        var formatted: String {
            let formattedPeriod = period.formatted
            switch type {
            case .introductory:
                switch paymentMode {
                case .freeTrial: return "\(formattedPeriod) Free Trial"
                case .payUpFront: return "\(displayPrice) for \(formattedPeriod)"
                case .payAsYouGo: return "\(displayPrice)/\(formattedPeriod)"
                default: return "Intro offer"
                }
            case .promotional:
                switch paymentMode {
                case .freeTrial: return "Free for \(formattedPeriod)"
                case .payUpFront: return "\(displayPrice) for \(formattedPeriod)"
                case .payAsYouGo: return "\(displayPrice)/\(formattedPeriod)"
                default: return "Promotional offer"
                }
            default:
                return "Special offer"
            }
        }
    }
}
