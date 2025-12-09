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
import StoreKit

@objc
final class PaywallManager: NSObject {

    @objc static let shared = PaywallManager()

    enum ProductIdentifier: String, CaseIterable {

        case coins              = "com.infoenum.inAppPurchaseDemo.coins"

        case pro                = "com.infoenum.inAppPurchaseDemo.unlock_pro"
        case nature_sound_pack  = "com.infoenum.inAppPurchaseDemo.nature_sound_pack"

        case weekly             = "com.infoenum.inAppPurchaseDemo.weekly"
        case monthly            = "com.infoenum.inAppPurchaseDemo.monthly"
        case yearly             = "com.infoenum.inAppPurchaseDemo.yearly"

        case meditation_tutor   = "com.infoenum.inAppPurchaseDemo.meditation_tutor"
    }

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
            for plan in ProductIdentifier.allCases {
                if let status = PurchaseStatusManager.shared.snapshot(for: plan.rawValue),
                   status.isActive {
                    return true
                }
            }
            return false
    #endif
        }
    
        @objc
        var currentlyActivePlan: ProductStatus? {
            return PurchaseStatusManager.shared.activePlans.first
        }


    func isActive(_ identifier: ProductIdentifier) -> Bool {
        return PurchaseStatusManager.shared.isActive(productID: identifier.rawValue)
    }

    func subscriptionStatus() -> ProductStatus? {
        let plans: [ProductIdentifier] = [.weekly, .monthly, .yearly]
        for plan in plans {
            if let status = PurchaseStatusManager.shared.snapshot(for: plan.rawValue),
               status.isActive {
                return status
            }
        }
        return nil
    }

    func tutorPlusSubscriptionStatus() -> ProductStatus? {
        return PurchaseStatusManager.shared.snapshot(for: ProductIdentifier.meditation_tutor.rawValue)
    }
}

extension PaywallManager {

    private(set) var coins: Int {
        get {
            return UserDefaults.standard.integer(forKey: "coins")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "coins")
            UserDefaults.standard.synchronize()
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    private(set) var claimedDates: [String: Bool] {
        get {
            return (UserDefaults.standard.dictionary(forKey: "claimedDates") as? [String : Bool]) ?? [:]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "claimedDates")
            UserDefaults.standard.synchronize()
        }
    }

    func purchaseCoins(from controller: UIViewController) {
        self.present(from: controller, productIdentifiers: [.coins])
    }

    var hasClaimedToday: Bool {
        var claimedDates = self.claimedDates
        let claimDateString: String = Self.dateFormatter.string(from: Date())
        return claimedDates[claimDateString] ?? false
    }

    func claimTodayCoins() -> Bool {
        var claimedDates = self.claimedDates
        let claimDateString: String = Self.dateFormatter.string(from: Date())
        let hasClaimed: Bool = claimedDates[claimDateString] ?? false
        if hasClaimed {
            return false
        } else {
            // Add coins
            self.coins += 5
            // Mark claimed today
            claimedDates[claimDateString] = true
            self.claimedDates = claimedDates
            return true
        }
    }

    func deductMeditationSession() -> Bool {
        return deductCoins(coins: 25)
    }

    func deductBreathingSession() -> Bool {
        return deductCoins(coins: 15)
    }

    private func deductCoins(coins: Int) -> Bool {
        let currentCoins = self.coins
        guard coins <= currentCoins else {
            return false
        }

        self.coins = currentCoins - coins
        return true
    }
}

extension PaywallManager {

    func unlockPro(from controller: UIViewController) {
        self.present(from: controller, productIdentifiers: [.pro])
    }

    func unlockNatureSound(from controller: UIViewController) {
        self.present(from: controller, productIdentifiers: [.nature_sound_pack])
    }

    func subscription(from controller: UIViewController) {
        self.present(from: controller, productIdentifiers: [.weekly, .monthly, .yearly])
    }

    func subscribeTutorialPlus(from controller: UIViewController) {
        self.present(from: controller, productIdentifiers: [.meditation_tutor])
    }

}

extension PaywallManager {

    @objc
    func configure() {
        IQPaywallUI.configure(productIds: ProductIdentifier.allCases.map({ $0.rawValue }), delegate: self)
    }

    func paywallView() -> some View {
        PaywallView(configuration: configuration)
    }

    // MARK: - Present Paywall
    func present(from controller: UIViewController, productIdentifiers: [ProductIdentifier]) {

        var configuration = self.configuration
        configuration.productIds = productIdentifiers.map({ $0.rawValue })
        configuration.recommendedProductId = productIdentifiers.first?.rawValue

        let hostingController = UIHostingController(rootView: PaywallView(configuration: configuration))
        hostingController.modalPresentationStyle = .fullScreen
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

        configuration.elements.append(.product(.init(style: .list,
                                                     nameStyle: .init(font: semibold20, color: foregroundColor),
                                                     priceStyle: .init(font: semibold20, color: foregroundColor),
                                                     subscriptionPeriodStyle: .init(font: light12, color: foregroundColor),
                                                     descriptionStyle:.init(font: regular15, color: foregroundColor)
                                                    ))
        )

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

extension PaywallManager: StoreKitManagerDelegate {
    func generateSignature(product: Product, offerID: String, appAccountToken: UUID?, completion: @escaping (Result<IQStoreKitManager.OfferSignature, any Error>) -> Void) {
    }

    func deliver(product: Product,
                 transaction: StoreKit.Transaction,
                 renewalInfo: Product.SubscriptionInfo.RenewalInfo?,
                 receiptData: Data,
                 appAccountToken: UUID?,
                 completion: @escaping (Result<Void, any Error>) -> Void) {

        if product.id == ProductIdentifier.coins.rawValue {
            // Deliver coins
            let currentCoins = self.coins
            let coinPerQuantity: Int = 50
            let purchasedCoins = coinPerQuantity * transaction.purchasedQuantity
            self.coins = purchasedCoins
            completion(.success(()))
            return
        } else {
            completion(.success(()))
        }

//        var params: [String:String] = [:]
//        params["receipt_token"] = receiptData.base64EncodedString()
//        params["product_id"] = transaction.productID
//        params["environment"] = transaction.environment.rawValue
//        YourAPIClient.purchasePlan(param: params) { result in
//            switch result {
//            case .success(let success):
                //Server-less apps can immediately run this
//                completion(.success(()))
//            case .failure(let failure):
//                completion(.failure(failure))
//            }
//        }
    }
}
