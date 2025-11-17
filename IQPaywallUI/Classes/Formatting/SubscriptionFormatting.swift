//
//  SubscriptionFormatting.swift
//

import Foundation
import StoreKit

struct SubscriptionFormatting {
    static func localized(period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day: return period.value == 1 ? "day" : "\(period.value) days"
        case .week: return period.value == 1 ? "week" : "\(period.value) weeks"
        case .month: return period.value == 1 ? "month" : "\(period.value) months"
        case .year: return period.value == 1 ? "year" : "\(period.value) years"
        @unknown default: return "period"
        }
    }
    static func offerLabel(offer: Product.SubscriptionOffer, product: Product) -> String {
        let periodText = localized(period: offer.period)
        switch offer.type {
        case .introductory:
            switch offer.paymentMode {
            case .freeTrial: return "\(periodText) Free Trial"
            case .payUpFront: return "\(offer.displayPrice) for \(periodText)"
            case .payAsYouGo: return "\(offer.displayPrice)/\(periodText)"
            default: return "Intro offer"
            }
        case .promotional:
            switch offer.paymentMode {
            case .freeTrial: return "Free for \(periodText)"
            case .payUpFront: return "\(offer.displayPrice) for \(periodText)"
            case .payAsYouGo: return "\(offer.displayPrice)/\(periodText)"
            default: return "Promotional offer"
            }
        default:
            return "Special offer"
        }
    }
}
