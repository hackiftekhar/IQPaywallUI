//
//  PaywallUI.swift

import Foundation
import SwiftUI

@objc
public class IQPaywallUI: NSObject {

    @objc public static func configure(productIds: [String]) {
        IQStoreKitManager.shared.configure(productIDs: productIds)
    }

    public static func paywallViewController(with configuration: IQPaywallConfiguration) -> UIViewController {
        return UIHostingController(rootView: PaywallView(configuration: configuration))
    }
}
