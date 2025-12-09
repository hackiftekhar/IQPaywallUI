//
//  SubscriptionOffer+Formatting

import Foundation
import StoreKit

extension ProductInfo {

    struct SubscriptionOffer: Hashable {
        public let id: String?
        public let type: Product.SubscriptionOffer.OfferType
        public let price: Decimal
        public let displayPrice: String
        public let periodCount: Int
        public let period: ProductInfo.SubscriptionPeriod
        public let paymentMode: Product.SubscriptionOffer.PaymentMode

        init(id: String?, type: Product.SubscriptionOffer.OfferType, price: Decimal, displayPrice: String, periodCount: Int, period: ProductInfo.SubscriptionPeriod, paymentMode: Product.SubscriptionOffer.PaymentMode) {
            self.id = id
            self.type = type
            self.periodCount = periodCount
            self.price = price
            self.displayPrice = displayPrice
            self.period = period
            self.paymentMode = paymentMode
        }

        init(offer: Product.SubscriptionOffer) {
            self.id = offer.id
            self.type = offer.type
            self.price = offer.price
            self.displayPrice = offer.displayPrice
            self.periodCount = offer.periodCount

            if offer.period.unit == .day && offer.period.value == 7 {
                period = .init(unit: .week, value: 1)
            } else if offer.period.unit == .day && offer.period.value == 30 {
                period = .init(unit: .month, value: 1)
            } else if offer.period.unit == .day && offer.period.value == 365 {
                period = .init(unit: .year, value: 1)
            } else if offer.period.unit == .month && offer.period.value == 12 {
                period = .init(unit: .year, value: 1)
            } else {
                period = ProductInfo.SubscriptionPeriod(subscriptionPeriod: offer.period)
            }

            self.paymentMode = offer.paymentMode
        }

        /// Generates a localized, contextual title for the subscription action button.
        var actionTitle: String {

            let duration = self.period.localizedDescription
            switch type {
            case .introductory:
                switch paymentMode {
                case .freeTrial:    // "Start 7-Day Free Trial"
                    return "Start \(duration) Free Trial"
                case .payUpFront:   // "Pay $0.99 for 3 Months"
                    return "Pay \(displayPrice) for \(duration)"
                case .payAsYouGo:   // "Pay $1.99 Monthly for 6 Months"
                    return "Pay \(displayPrice) \(self.period.unit.lyFormatted) for \(periodCount) \(self.period.unit.formatted)"
                default: break
                }
            case .promotional:
                switch paymentMode {
                case .freeTrial:    // "Subscribe Free for 1 Month"
                    return "Subscribe Free for \(duration)"
                case .payUpFront:   // "Pay $0.99 for 3 Months"
                    return "Pay \(displayPrice) for \(duration)"
                case .payAsYouGo:   // "Pay $1.99 Monthly for 6 Months"
                    return "Pay \(displayPrice) \(self.period.unit.lyFormatted) for \(periodCount) \(self.period.unit.formatted)"
                default: break
                }
//            case .winBack:
//            return "WinBack Offer"
            default: break
            }

            return "Pay \(displayPrice) / \(self.period.unit.lyFormatted) for \(periodCount) \(self.period.unit.formatted)"
        }

        var localizedDescription: String {

            let duration = self.period.localizedDescription
            switch type {
            case .introductory:
                switch paymentMode {
                case .freeTrial:    // "Start 7-Day Free Trial"
                    return "\(duration) Free Trial"
                case .payUpFront:   // "Pay $0.99 for 3 Months"
                    return "\(displayPrice) for \(duration)"
                case .payAsYouGo:   // "Pay $1.99 Monthly for 6 Months"
                    return "\(displayPrice) \(self.period.unit.lyFormatted) for \(periodCount) \(self.period.unit.formatted)"
                default: break
                }
            case .promotional:
                switch paymentMode {
                case .freeTrial:    // "Subscribe Free for 1 Month"
                    return "Free for \(duration)"
                case .payUpFront:   // "Pay $0.99 for 3 Months"
                    return "\(displayPrice) for \(duration)"
                case .payAsYouGo:   // "Pay $1.99 Monthly for 6 Months"
                    return "\(displayPrice) / \(self.period.unit.lyFormatted) for \(periodCount) \(self.period.unit.formatted)"
                default: break
                }
//            case .winBack:
//            return "WinBack Offer"
            default: break
            }

            return "Pay \(displayPrice) / \(self.period.unit.lyFormatted) for \(periodCount) \(self.period.unit.formatted)"
        }
    }
}
