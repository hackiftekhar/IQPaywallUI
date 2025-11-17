//
//  TableViewController.swift
//  PaywallViewController
//
//  Created by Iftekhar on 11/14/25.
//

import UIKit
import IQPaywallUI
import SwiftUI

class TableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let isMonthlySubscriptionActive = PurchaseStatusManager.shared.isActive(productID: "com.paywall.ui.monthly")
        let currentlyActivePlan: ProductStatus? = PurchaseStatusManager.shared.currentlyActivePlan
        let snapshot: ProductStatus? = PurchaseStatusManager.shared.snapshot(for: "com.paywall.ui.monthly")
        NotificationCenter.default.addObserver(forName: PurchaseStatusManager.purchaseStatusDidChangedNotification, object: nil, queue: nil) { _ in
        }
    }

    @IBAction func showPaywallAction(_ sender: UIButton) {
        let semibold30 = UIFont(name: "KohinoorBangla-Semibold", size: 30)!
        let semibold20 = UIFont(name: "KohinoorBangla-Semibold", size: 20)!
        let semibold15 = UIFont(name: "KohinoorBangla-Semibold", size: 15)!
        let regular15 = UIFont(name: "KohinoorBangla-Regular", size: 15)!
        let light12 = UIFont(name: "KohinoorBangla-Light", size: 12)!
        let themeColor = UIColor.systemPink

        var configuration = IQPaywallConfiguration()
        configuration.elements.append(.logo(.init(UIImage(named:"ruler_logo")!, backgroundColor: themeColor)))
        configuration.elements.append(.title(.init("Unlock Pro Features", style: .init(font: semibold30, color: themeColor))))
        configuration.elements.append(.subtitle(.init("Get access to all our pro features", style: .init(font: semibold15, color: themeColor))))
        configuration.elements.append(.feature(.init(titles: ["Remove all ads",
                                                              "Customize Color Themes",
                                                              "Unlock Pixel Ratio feature",
                                                              "Persist Your Settings"],
                                                     icon: .init(UIImage(systemName: "checkmark.circle.fill")!, color: themeColor),
                                                     style: .init(font: regular15, color: themeColor))))

        configuration.elements.append(.product(.init(style: .card,
                                                     nameStyle: .init(font: semibold20, color: themeColor),
                                                     priceStyle: .init(font: semibold20, color: themeColor),
                                                     subscriptionPeriodStyle: .init(font: light12, color: themeColor),
                                                     descriptionStyle:.init(font: regular15, color: themeColor)
                                                    ))
        )

        configuration.productIds = ["com.infoenum.ruler.monthly",
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
        self.present(hostingController, animated: true)
    }
}
