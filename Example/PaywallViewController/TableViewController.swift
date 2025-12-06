//
//  TableViewController.swift
//  PaywallViewController
//
//  Created by Iftekhar on 11/14/25.
//

import UIKit
import IQPaywallUI
import IQStoreKitManager
import SwiftUI

class TableViewController: UITableViewController {

    var products: [ProductStatus] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        updateProductStatuses()
        NotificationCenter.default.addObserver(forName: PaywallManager.purchaseStatusDidChangedNotification, object: nil, queue: nil) { _ in
            self.updateProductStatuses()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    @IBAction func showPaywallAction(_ sender: UIButton) {
        PaywallManager.shared.present(from: self, themeColor: UIColor.systemPink)
    }
}

extension TableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return products.count
        case 1: return 1
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath)

            let currentPlan = products[indexPath.row]
            let title: String = currentPlan.displayName
            let subtitle: String
            if currentPlan.status != .inactive {
                switch currentPlan.type {
                case .consumable:
                    subtitle = "Purchased"
                case .nonConsumable:
                    subtitle = "Lifetime Purchased"
                case .autoRenewable:

                    switch currentPlan.status {
                    case .inactive, .unlocked:
                        subtitle = "Auto Renewal Subscription"
                    case .active:
                        if let renewalInfo = currentPlan.renewalInfo {
                            if renewalInfo.willAutoRenew,
                               let nextRenewalDate = renewalInfo.nextRenewalDate,
                               let autoRenewPreference = renewalInfo.autoRenewPreference {
                                let renewalDataString = nextRenewalDate.formatted(.dateTime.hour().minute().month().day().year())
                                if autoRenewPreference != currentPlan.id {
                                    subtitle = "Upcoming Plan Change\nStarting \(renewalDataString), your plan will change from '\(currentPlan.displayName)' to '\(PurchaseStatusManager.shared.snapshot(for:autoRenewPreference)?.displayName ?? autoRenewPreference)'"
                                } else {
                                    subtitle = "'\(currentPlan.displayName)' Renews Automatically\n\(nextRenewalDate.formatted(.dateTime.hour().minute().month().day().year()))"
                                }
                            } else if let expirationDate = renewalInfo.expirationDate {
                                subtitle = "You have cancelled your '\(currentPlan.displayName)' subscription\nYour subscription will end on \(expirationDate.formatted(.dateTime.hour().minute().month().day().year()))"
                            } else {
                                subtitle = "Auto Renewal Subscription"
                            }
                        } else {
                            subtitle = "Auto Renewal Subscription"
                        }
                    case .upcoming:
                        if let renewalInfo = currentPlan.renewalInfo, renewalInfo.willAutoRenew,
                           let nextRenewalDate = renewalInfo.nextRenewalDate {
                            let renewalDataString = nextRenewalDate.formatted(.dateTime.hour().minute().month().day().year())
                            subtitle = "Upcoming Plan\nWill start on \(renewalDataString)"
                        } else {
                            subtitle = "Auto Renewal Subscription"
                        }
                    }
                case .nonRenewable:
                    if let renewalInfo = currentPlan.renewalInfo, let expirationDate = renewalInfo.expirationDate {
                        subtitle = "Your '\(currentPlan.displayName)' subscription will end on \(expirationDate.formatted(.dateTime.hour().minute().month().day().year()))"
                    } else {
                        subtitle = "Non Renewal Subscription"
                    }
                }
            } else {
                subtitle = "Inactive"
            }

            cell.textLabel?.text = title
            cell.detailTextLabel?.text = subtitle
            return cell
        case 1: return tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath)
        default: fatalError("No Section Rows")
        }
    }

    private func updateProductStatuses() {

        self.products = PaywallManager.ProductIdentifier.allCases.compactMap({ PurchaseStatusManager.shared.snapshot(for: $0.rawValue) })
        self.tableView.reloadData()
    }
}

