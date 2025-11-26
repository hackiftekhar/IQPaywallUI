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
