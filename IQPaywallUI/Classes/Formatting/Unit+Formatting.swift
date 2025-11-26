//
//  Unit+Formatting.swift

import StoreKit

extension Product.SubscriptionPeriod.Unit {

    var formatted: String {
        switch self {
        case .day:      return "Day"
        case .week:     return "Week"
        case .month:    return "Month"
        case .year:     return "Year"
        @unknown default: return ""
        }
    }
}
