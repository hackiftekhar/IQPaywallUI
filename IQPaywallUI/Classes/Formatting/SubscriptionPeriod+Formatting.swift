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


extension ProductInfo {

    struct SubscriptionPeriod {
        public let unit: Product.SubscriptionPeriod.Unit
        public let value: Int

        init(unit: Product.SubscriptionPeriod.Unit, value: Int) {
            self.unit = unit
            self.value = value
        }
        init(subscriptionPeriod: Product.SubscriptionPeriod) {
            self.unit = subscriptionPeriod.unit
            self.value = subscriptionPeriod.value
        }

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
}
