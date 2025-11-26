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

    @IBOutlet var proTitleLabel: UILabel!
    @IBOutlet var proSubtitleLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateProLabels()
    }

    @IBAction func showPaywallAction(_ sender: UIButton) {
        PaywallManager.shared.present(from: self, themeColor: UIColor.systemPink)
    }
}

extension TableViewController {
    private func updateProLabels() {

        let currentPlan = PaywallManager.shared.currentlyActivePlan
        var title = ""
        var subtitle = ""

        let formatter = DateFormatter()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "ddMMyyyyHHmma",
                                                        options: 0,
                                                        locale: Locale.current)

        switch currentPlan?.productID {
        case PaywallManager.lifetimeProductID:
            title = "Pro Feature Unlocked"
            subtitle = "Lifetime"
        case PaywallManager.yearlyProductID:
            title = "Yearly Subscription Active"
            if let nextRenewalDate = currentPlan?.nextRenewalDate {
                subtitle = "Auto-renew \(formatter.string(from: nextRenewalDate))"
            } else if let expirationDate = currentPlan?.expirationDate {
                subtitle = "Expires \(formatter.string(from: expirationDate))"
            }
        case PaywallManager.monthlyProductID:
            title = "Monthly Subscription Active"
            if let nextRenewalDate = currentPlan?.nextRenewalDate {
                subtitle = "Auto-renew \(formatter.string(from: nextRenewalDate))"
            } else if let expirationDate = currentPlan?.expirationDate {
                subtitle = "Expires \(formatter.string(from: expirationDate))"
            }
        default:
            title = "Unlock Pro Features"
            subtitle = "Select a plan to unlock Pro features"

        }

        proTitleLabel.text = title
        proSubtitleLabel.text = subtitle
    }
}

