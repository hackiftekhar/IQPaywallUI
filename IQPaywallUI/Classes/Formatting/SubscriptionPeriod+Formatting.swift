//
//  SubscriptionPeriod+Formatting.swift

import StoreKit

extension ProductInfo {

    struct SubscriptionPeriod: Hashable {
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

        var localizedDescription: String {
            switch unit {
            case .day:
                if value == 7 {
                    return "1 Week"
                } else {
                    return "\(value) Day\(value == 1 ? "" : "s")"
                }
            case .week: return  "\(value) Week\(value == 1 ? "" : "s")"
            case .month: return "\(value) Month\(value == 1 ? "" : "s")"
            case .year: return  "\(value) Year\(value == 1 ? "" : "s")"
            @unknown default: return ""
            }
        }

        var formatted: String {
            switch unit {
            case .day:
                if value == 7 {
                    return "Week"
                } else {
                    return value == 1 ? "Day" : "\(value) Days"
                }

            case .week: return value == 1 ? "Week" : "\(value) Weeks"
            case .month: return value == 1 ? "Month" : "\(value) Months"
            case .year: return value == 1 ? "Year" : "\(value) Years"
            @unknown default: return ""
            }
        }

        var days: Int {
            switch unit {
            case .day:
                return value
            case .week:
                return value * 7
            case .month:
                return value * 30
            case .year:
                return value * 365
            @unknown default:
                return 0
            }
        }
    }
}
