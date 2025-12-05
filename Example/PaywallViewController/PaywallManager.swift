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
import IQStoreKitManager

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

    func paywallView() -> some View {
        PaywallView(configuration: configuration)
    }

    // MARK: - Present Paywall
    @objc
    func present(from controller: UIViewController, themeColor: UIColor) {

        let hostingController = UIHostingController(rootView: paywallView())
        //        hostingController.modalPresentationStyle = .fullScreen
        controller.present(hostingController, animated: true)
    }

    // Customized configuration
    var configuration: PaywallConfiguration {
        let semibold30 = UIFont(name: "ChalkboardSE-Bold", size: 30)!
        let semibold20 = UIFont(name: "ChalkboardSE-Bold", size: 20)!
        let semibold18 = UIFont(name: "ChalkboardSE-Bold", size: 18)!
        let semibold15 = UIFont(name: "ChalkboardSE-Bold", size: 15)!
        let regular18 = UIFont(name: "ChalkboardSE-Regular", size: 18)!
        let regular15 = UIFont(name: "ChalkboardSE-Regular", size: 15)!
        let light15 = UIFont(name: "ChalkboardSE-Light", size: 15)!
        let light12 = UIFont(name: "ChalkboardSE-Light", size: 12)!

        let foregroundColor = UIColor.systemPink
        let backgroundColor = UIColor.white

        var configuration = PaywallConfiguration()
        configuration.elements.append(.logo(.init(UIImage(named:"ruler_logo")!, backgroundColor: foregroundColor)))
        configuration.elements.append(.title(.init("Unlock Pro Features", style: .init(font: semibold30, color: foregroundColor))))
        configuration.elements.append(.subtitle(.init("Get access to all our pro features", style: .init(font: semibold15, color: foregroundColor))))
        configuration.elements.append(.feature(.init(titles: ["Remove all ads",
                                                              "Customize Color Themes",
                                                              "Unlock Pixel Ratio feature",
                                                              "Persist Your Settings"],
                                                     icon: .init(UIImage(systemName: "checkmark.circle.fill")!, color: foregroundColor),
                                                     style: .init(font: regular15, color: foregroundColor))))

        configuration.elements.append(.product(.init(style: .card,
                                                     nameStyle: .init(font: semibold20, color: foregroundColor),
                                                     priceStyle: .init(font: semibold20, color: foregroundColor),
                                                     subscriptionPeriodStyle: .init(font: light12, color: foregroundColor),
                                                     descriptionStyle:.init(font: regular15, color: foregroundColor)
                                                    ))
        )

        configuration.productIds = [
            Self.monthlyProductID,
            Self.yearlyProductID,
            Self.lifetimeProductID,
        ]
        configuration.recommendedProductId = Self.yearlyProductID

        configuration.actionButton.font = semibold20

        configuration.terms = .init("Terms & Conditions", url: URL(string: "https://www.termsAndConditions.com")!)
        configuration.privacyPolicy = .init("Privacy Policy", url: URL(string: "https://www.privacyPolicy.com")!)

        configuration.backgroundColor = backgroundColor
        configuration.foregroundColor = foregroundColor
        configuration.linkStyle = .init(font: regular15, color: foregroundColor)
        return configuration
    }

    // Minimal configuration
//    var configuration: PaywallConfiguration {
//        var configuration = PaywallConfiguration()
//        configuration.elements.append(.logo(.init(UIImage(named:"ruler_logo")!)))
//        configuration.elements.append(.title(.init("Unlock Pro Features")))
//        configuration.elements.append(.subtitle(.init("Get access to all our pro features")))
//        configuration.elements.append(.feature(.init(titles: ["Remove all ads",
//                                                              "Customize Color Themes",
//                                                              "Unlock Pixel Ratio feature",
//                                                              "Persist Your Settings"],
//                                                     icon: .init(UIImage(systemName: "checkmark.circle.fill")!))))
//
//        configuration.elements.append(.product(.init(style: .list))
//        )
//
//        configuration.productIds = [
//            Self.monthlyProductID,
//            Self.yearlyProductID,
//            Self.lifetimeProductID,
//        ]
//        configuration.recommendedProductId = Self.yearlyProductID
//        configuration.terms = .init("Terms & Conditions", url: URL(string: "https://www.termsAndConditions.com")!)
//        configuration.privacyPolicy = .init("Privacy Policy", url: URL(string: "https://www.privacyPolicy.com")!)
//
//        return configuration
//    }
}
