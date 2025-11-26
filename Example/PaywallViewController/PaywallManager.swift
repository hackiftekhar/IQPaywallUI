//
//  PaywallManager.swift
//  Storeshots
//
//  Created by IE11 on 17/11/25.
//  Copyright © 2025 InfoEnum. All rights reserved.
//

import UIKit
import SwiftUI
import IQPaywallUI

@objc
final class PaywallManager: NSObject {

    @objc static let shared = PaywallManager()
    @objc static let monthlyProductID    = "com.infoenum.ruler.monthly"
    @objc static let yearlyProductID     = "com.infoenum.ruler.yearly"
    @objc static let lifetimeProductID   = "com.infoenum.ruler.one_time_purchase"

    @objc static var purchaseStatusDidChangedNotification: Notification.Name {
        return PurchaseStatusManager.purchaseStatusDidChangedNotification
    }

    private override init() {
        super.init()
    }
    
    // MARK: - App purchase activation check
    @objc
    var isSubscribed: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return PurchaseStatusManager.shared.isAnyPlanActive
        #endif
    }
    
    @objc
    var currentlyActivePlan: ProductStatus? {
        return PurchaseStatusManager.shared.currentlyActivePlan
    }
    
    @objc
    func configure() {
        IQPaywallUI.configure(productIds: [
            Self.monthlyProductID,
            Self.yearlyProductID,
            Self.lifetimeProductID,
        ])
    }

    // MARK: - Present Paywall
    @objc
    func present(from controller: UIViewController, themeColor: UIColor) {
        let semibold30 = UIFont(name: "KohinoorBangla-Semibold", size: 30)!
        let semibold20 = UIFont(name: "KohinoorBangla-Semibold", size: 20)!
        let semibold15 = UIFont(name: "KohinoorBangla-Semibold", size: 15)!
        let regular15 = UIFont(name: "KohinoorBangla-Regular", size: 15)!
        let light12 = UIFont(name: "KohinoorBangla-Light", size: 12)!
        let themeColor = UIColor.systemPink

        var configuration = PaywallConfiguration()
        configuration.elements.append(.logo(.init(UIImage(named:"ruler_logo")!, backgroundColor: themeColor)))
        configuration.elements.append(.title(.init("Unlock Pro Features", style: .init(font: semibold30, color: themeColor))))
        configuration.elements.append(.subtitle(.init("Get access to all our pro features", style: .init(font: semibold15, color: themeColor))))
        configuration.elements.append(.feature(.init(titles: ["Remove all ads",
                                                              "Customize Color Themes",
                                                              "Unlock Pixel Ratio feature",
                                                              "Persist Your Settings"],
                                                     icon: .init(UIImage(systemName: "checkmark.circle.fill")!, color: themeColor),
                                                     style: .init(font: regular15, color: themeColor))))

        configuration.elements.append(.product(.init(style: .list,
                                                     nameStyle: .init(font: semibold20, color: themeColor),
                                                     priceStyle: .init(font: semibold20, color: themeColor),
                                                     subscriptionPeriodStyle: .init(font: light12, color: themeColor),
                                                     descriptionStyle:.init(font: regular15, color: themeColor)
                                                    ))
        )

        configuration.productIds = [
            "com.infoenum.ruler.monthly",
            "com.infoenum.ruler.yearly",
            "com.infoenum.ruler.one_time_purchase"
        ]
        configuration.recommendedProductId = "com.infoenum.ruler.yearly"

        configuration.actionButton.font = semibold20

        configuration.terms = .init("Terms & Conditions", url: URL(string: "https://www.termsAndConditions.com")!)
        configuration.privacyPolicy = .init("Privacy Policy", url: URL(string: "https://www.privacyPolicy.com")!)

        configuration.backgroundColor = UIColor.white
        configuration.tintColor = themeColor
        configuration.linkStyle = .init(font: regular15, color: themeColor)

        let hostingController = UIHostingController(rootView: PaywallView(configuration: configuration))
        hostingController.modalPresentationStyle = .fullScreen
        controller.present(hostingController, animated: true)
    }
}
