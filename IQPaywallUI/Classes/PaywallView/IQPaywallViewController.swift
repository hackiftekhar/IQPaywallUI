//
//  PaywallViewController.swift

import SwiftUI

public func paywallViewController(with configuration: IQPaywallConfiguration) -> UIViewController {
    return UIHostingController(rootView: PaywallView(configuration: configuration))
}
