//
//  SubscriptionPeriod+Formatting.swift

import StoreKit

extension Product.SubscriptionPeriod {

    var formatted: String {
        switch unit {
        case .day: return value == 1 ? "Day" : "\(value) Days"
        case .week: return value == 1 ? "Week" : "\(value) Weeks"
        case .month: return value == 1 ? "Month" : "\(value) Months"
        case .year: return value == 1 ? "Year" : "\(value) Years"
        @unknown default: return ""
        }
    }
}
