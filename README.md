# IQPaywallUI

[![CI Status](https://img.shields.io/travis/hackiftekhar/IQPaywallUI.svg?style=flat)](https://travis-ci.org/hackiftekhar/IQPaywallUI)
[![Version](https://img.shields.io/cocoapods/v/IQPaywallUI.svg?style=flat)](https://cocoapods.org/pods/IQPaywallUI)
[![License](https://img.shields.io/cocoapods/l/IQPaywallUI.svg?style=flat)](https://cocoapods.org/pods/IQPaywallUI)
[![Platform](https://img.shields.io/cocoapods/p/IQPaywallUI.svg?style=flat)](https://cocoapods.org/pods/IQPaywallUI)

[![Screenshot 1](https://raw.githubusercontent.com/hackiftekhar/IQPaywallUI/master/Screenshot/IQPaywallUIScreenshot.png)]

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

IQPaywallUI is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'IQPaywallUI'
```

## Usage

In AppDelegate, setup all your product ids
```swift
import IQPaywallUI
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        IQPaywallUI.configure(productIds: [
            "com.paywall.ui.monthly",
            "com.paywall.ui.yearly",
            "com.paywall.ui.lifetime"
        ])

        return true
    }
}
```

When you'll need to present the PaywallUI, create a configuration object and present it like below

```swift
    @IBAction func showPaywallAction(_ sender: UIButton) {
    
        let semibold30 = UIFont(name: "KohinoorBangla-Semibold", size: 30)!
        let semibold20 = UIFont(name: "KohinoorBangla-Semibold", size: 20)!
        let semibold15 = UIFont(name: "KohinoorBangla-Semibold", size: 15)!
        let regular15 = UIFont(name: "KohinoorBangla-Regular", size: 15)!
        let light12 = UIFont(name: "KohinoorBangla-Light", size: 12)!
        let themeColor = UIColor.systemPink

        var configuration = IQPaywallConfiguration()
        configuration.elements.append(.logo(.init(UIImage(named:"your_logo")!, backgroundColor: themeColor)))
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

        // Set the productID's you would like to show in the screen
        configuration.productIds = ["com.paywall.ui.monthly",
                                    "com.paywall.ui.lifetime"
        ]
        
        //Optionally select the recommended product id which will be selected by default in the PaywallUI
        configuration.recommendedProductId = "com.infoenum.ruler.yearly"

        configuration.actionButton.font = semibold20

        configuration.terms = .init("Terms & Conditions", url: URL(string: "https://www.terms.com")!)
        configuration.privacyPolicy = .init("Privacy Policy", url: URL(string: "https://www.privacy.com")!)

        configuration.backgroundColor = UIColor.white
        configuration.foregroundColor = themeColor
        configuration.linkStyle = .init(font: regular15, color: themeColor)
        
        let hostingController = UIHostingController(rootView: PaywallView(configuration: configuration))
        hostingController.modalPresentationStyle = .fullScreen
        self.present(hostingController, animated: true)
    } 
```

To dynamically get notified when product status has changed. You can always observe it's notification
```swift
        NotificationCenter.default.addObserver(forName: PurchaseStatusManager.purchaseStatusDidChangedNotification, object: nil, queue: nil) { _ in
        ...
        }
```

To get status of the purchase by the product id, you can always get it's snapshot which contains most of the information.
```swift
        let isMonthlySubscriptionActive = PurchaseStatusManager.shared.isActive(productID: "com.paywall.ui.monthly")
        
        // Currently active plan from the subscription
        let currentlyActivePlan: ProductStatus? = PurchaseStatusManager.shared.currentlyActivePlan

        // Detailed snapshot of a product id
        let snapshot: ProductStatus? = PurchaseStatusManager.shared.snapshot(for: "com.paywall.ui.monthly")
        
        // Check if any plan is currently active
        let isSubscribed = PurchaseStatusManager.shared.isAnyPlanActive
```

## Author

hackiftekhar, ideviftekhar@gmail.com

## License

IQPaywallUI is available under the MIT license. See the LICENSE file for more info.
