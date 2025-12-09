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

    var lyFormatted: String {
        switch self {
        case .day:      return "Daily"
        case .week:     return "Weekly"
        case .month:    return "Monthly"
        case .year:     return "Yearly"
        @unknown default: return ""
        }
    }
}
