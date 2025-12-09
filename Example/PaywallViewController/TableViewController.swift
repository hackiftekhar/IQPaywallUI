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

    @IBOutlet var coinsCountLabel: UILabel!
    @IBOutlet var claimCountDateLabel: UILabel!
    @IBOutlet var claimButton: UIButton!
    @IBOutlet var unlockProButton: UIButton!
    @IBOutlet var unlockNatureSoundButton: UIButton!
    @IBOutlet var subscribeButton: UIButton!
    @IBOutlet var autoRenewableSubscriptionStatusLabel: UILabel!
    @IBOutlet var subscribeTutorPlusButton: UIButton!
    @IBOutlet var nonRenewableSubscriptionStatus: UILabel!

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

    private func updateProductStatuses() {

        coinsCountLabel.text = "\(PaywallManager.shared.coins)"
        claimCountDateLabel.text = Date().formatted(.dateTime.month().day().year())
        claimButton.setTitle(PaywallManager.shared.hasClaimedToday ? "Claimed" : "Claim" , for: .normal)
        claimButton.tintColor = PaywallManager.shared.hasClaimedToday ? .gray : UIColor.systemGreen
        claimCountDateLabel.textColor = PaywallManager.shared.hasClaimedToday ? .systemGreen : UIColor.systemRed

        unlockProButton.setTitle(PaywallManager.shared.isActive(.pro) ? "Unlocked" : "Unlock Pro (Lifetime)", for: .normal)
        unlockProButton.tintColor = PaywallManager.shared.isActive(.pro) ? UIColor.systemGreen : UIColor.systemBlue
        unlockNatureSoundButton.setTitle(PaywallManager.shared.isActive(.nature_sound_pack) ? "Unlocked" : "Unlock Nature Sound (Lifetime)", for: .normal)
        unlockNatureSoundButton.tintColor = PaywallManager.shared.isActive(.nature_sound_pack) ? UIColor.systemGreen : UIColor.systemBlue

        if let currentPlan = PaywallManager.shared.subscriptionStatus() {
            let message: String
            switch currentPlan.status {
            case .inactive:
                message = "Subscription Status: Inactive"
                subscribeButton.setTitle("Subscribe", for: .normal)
                subscribeButton.tintColor = UIColor.systemBlue
            case .active, .gracePeriod, .billingRetryPeriod, .unlocked:
                if let renewalInfo = currentPlan.renewalInfo {
                    if renewalInfo.willAutoRenew,
                       let nextRenewalDate = renewalInfo.nextRenewalDate,
                       let autoRenewPreference = renewalInfo.autoRenewPreference {
                        let renewalDataString = nextRenewalDate.formatted(.dateTime.hour().minute().month().day().year())
                        if autoRenewPreference != currentPlan.id {
                            message = "Upcoming Plan Change\nStarting \(renewalDataString), your plan will change from '\(currentPlan.displayName)' to '\(PurchaseStatusManager.shared.snapshot(for:autoRenewPreference)?.displayName ?? autoRenewPreference)'"
                        } else {
                            message = "'\(currentPlan.displayName)' Renews Automatically\n\(nextRenewalDate.formatted(.dateTime.hour().minute().month().day().year()))"
                        }
                    } else if let expirationDate = renewalInfo.expirationDate {
                        message = "You have cancelled your '\(currentPlan.displayName)' subscription\nYour subscription will end on \(expirationDate.formatted(.dateTime.hour().minute().month().day().year()))"
                    } else {
                        message = "Auto Renewal Subscription"
                    }
                } else {
                    message = "Auto Renewal Subscription"
                }
                subscribeButton.setTitle("Subscribed", for: .normal)
                subscribeButton.tintColor = UIColor.systemGreen
            case .upcoming:
                if let renewalInfo = currentPlan.renewalInfo, renewalInfo.willAutoRenew,
                   let nextRenewalDate = renewalInfo.nextRenewalDate {
                    let renewalDataString = nextRenewalDate.formatted(.dateTime.hour().minute().month().day().year())
                    message = "Upcoming Plan\nWill start on \(renewalDataString)"
                } else {
                    message = "Auto Renewal Subscription"
                }
                subscribeButton.setTitle("Upcoming", for: .normal)
                subscribeButton.tintColor = UIColor.systemOrange
            }

            autoRenewableSubscriptionStatusLabel.text = message
        } else {
            autoRenewableSubscriptionStatusLabel.text = "Subscription Status: Inactive"
            subscribeButton.setTitle("Subscribe", for: .normal)
            subscribeButton.tintColor = UIColor.systemBlue
        }

        if let currentPlan = PaywallManager.shared.tutorPlusSubscriptionStatus() {
            let message: String
            switch currentPlan.status {
            case .inactive:
                message = "Subscription Status: Inactive"
                subscribeTutorPlusButton.setTitle("Subscribe Tutor Plus Pack", for: .normal)
                subscribeTutorPlusButton.tintColor = UIColor.systemBlue
            case .active, .gracePeriod, .billingRetryPeriod, .unlocked:
                if let renewalInfo = currentPlan.renewalInfo {
                    if renewalInfo.willAutoRenew,
                       let nextRenewalDate = renewalInfo.nextRenewalDate,
                       let autoRenewPreference = renewalInfo.autoRenewPreference {
                        let renewalDataString = nextRenewalDate.formatted(.dateTime.hour().minute().month().day().year())
                        if autoRenewPreference != currentPlan.id {
                            message = "Upcoming Plan Change\nStarting \(renewalDataString), your plan will change from '\(currentPlan.displayName)' to '\(PurchaseStatusManager.shared.snapshot(for:autoRenewPreference)?.displayName ?? autoRenewPreference)'"
                        } else {
                            message = "'\(currentPlan.displayName)' Renews Automatically\n\(nextRenewalDate.formatted(.dateTime.hour().minute().month().day().year()))"
                        }
                    } else if let expirationDate = renewalInfo.expirationDate {
                        message = "You have cancelled your '\(currentPlan.displayName)' subscription\nYour subscription will end on \(expirationDate.formatted(.dateTime.hour().minute().month().day().year()))"
                    } else {
                        message = "Auto Renewal Subscription"
                    }
                } else {
                    message = "Auto Renewal Subscription"
                }
                subscribeTutorPlusButton.setTitle("Subscribed", for: .normal)
                subscribeTutorPlusButton.tintColor = UIColor.systemGreen
            case .upcoming:
                if let renewalInfo = currentPlan.renewalInfo, renewalInfo.willAutoRenew,
                   let nextRenewalDate = renewalInfo.nextRenewalDate {
                    let renewalDataString = nextRenewalDate.formatted(.dateTime.hour().minute().month().day().year())
                    message = "Upcoming Plan\nWill start on \(renewalDataString)"
                } else {
                    message = "Auto Renewal Subscription"
                }
                subscribeTutorPlusButton.setTitle("Upcoming", for: .normal)
                subscribeTutorPlusButton.tintColor = UIColor.systemOrange
            }

            nonRenewableSubscriptionStatus.text = message
        } else {
            nonRenewableSubscriptionStatus.text = "Subscription Status: Inactive"
            subscribeTutorPlusButton.setTitle("Subscribe Tutor Plus Pack", for: .normal)
            subscribeTutorPlusButton.tintColor = UIColor.systemBlue
        }
    }
}

extension TableViewController {

    @IBAction private func purchaseCoinAction(_ sender: UIButton) {
        PaywallManager.shared.purchaseCoins(from: self)
    }

    @IBAction private func claimAction(_ sender: UIButton) {
        let result = PaywallManager.shared.claimTodayCoins()
        let alert = UIAlertController(title: result ? "Success" : "Already Claimed", message: result ? "You have claimed today's coins." : "You have already claimed today's coins.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
        updateProductStatuses()
    }

    @IBAction private func startMeditationAction(_ sender: UIButton) {
        if (PaywallManager.shared.deductMeditationSession()) {
            let alert = UIAlertController(title: "Success", message: "You have started a meditation session.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "End Session", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            updateProductStatuses()
        } else {
            let alert = UIAlertController(title: "Insufficient Coins", message: "You do not have enough coins to start a meditation session. Please purchase more coins.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Buy", style: .default, handler: {_ in 
                PaywallManager.shared.purchaseCoins(from: self)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }

    @IBAction private func startBreathingAction(_ sender: UIButton) {
        if (PaywallManager.shared.deductBreathingSession()) {
            let alert = UIAlertController(title: "Success", message: "You have started a Breathing session.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "End Session", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            updateProductStatuses()
        } else {
            let alert = UIAlertController(title: "Insufficient Coins", message: "You do not have enough coins to start a breathing session. Please purchase more coins.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Buy", style: .default, handler: {_ in
                PaywallManager.shared.purchaseCoins(from: self)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension TableViewController {

    @IBAction private func unlockProAction(_ sender: UIButton) {
        PaywallManager.shared.unlockPro(from: self)
    }

    @IBAction private func unlockNatureSoundAction(_ sender: UIButton) {
        PaywallManager.shared.unlockNatureSound(from: self)
    }
}

extension TableViewController {

    @IBAction private func subscribeAction(_ sender: UIButton) {
        PaywallManager.shared.subscription(from: self)
    }
}

extension TableViewController {

    @IBAction private func subscribeTutorAction(_ sender: UIButton) {
        PaywallManager.shared.subscribeTutorialPlus(from: self)
    }
}

extension TableViewController {
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        return 2
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        switch section {
//        case 0: return products.count
//        case 1: return 1
//        default: return 0
//        }
//    }
//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        switch indexPath.section {
//        case 0:
//            let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath)
//
//            let currentPlan = products[indexPath.row]
//            let title: String = currentPlan.displayName
//            let subtitle: String
//            if currentPlan.status != .inactive {
//                switch currentPlan.type {
//                case .consumable:
//                    subtitle = "Purchased"
//                case .nonConsumable:
//                    subtitle = "Lifetime Purchased"
//                case .autoRenewable:
//
//                    switch currentPlan.status {
//                    case .inactive, .unlocked:
//                        subtitle = "Auto Renewal Subscription"
//                    case .active:
//                        if let renewalInfo = currentPlan.renewalInfo {
//                            if renewalInfo.willAutoRenew,
//                               let nextRenewalDate = renewalInfo.nextRenewalDate,
//                               let autoRenewPreference = renewalInfo.autoRenewPreference {
//                                let renewalDataString = nextRenewalDate.formatted(.dateTime.hour().minute().month().day().year())
//                                if autoRenewPreference != currentPlan.id {
//                                    subtitle = "Upcoming Plan Change\nStarting \(renewalDataString), your plan will change from '\(currentPlan.displayName)' to '\(PurchaseStatusManager.shared.snapshot(for:autoRenewPreference)?.displayName ?? autoRenewPreference)'"
//                                } else {
//                                    subtitle = "'\(currentPlan.displayName)' Renews Automatically\n\(nextRenewalDate.formatted(.dateTime.hour().minute().month().day().year()))"
//                                }
//                            } else if let expirationDate = renewalInfo.expirationDate {
//                                subtitle = "You have cancelled your '\(currentPlan.displayName)' subscription\nYour subscription will end on \(expirationDate.formatted(.dateTime.hour().minute().month().day().year()))"
//                            } else {
//                                subtitle = "Auto Renewal Subscription"
//                            }
//                        } else {
//                            subtitle = "Auto Renewal Subscription"
//                        }
//                    case .upcoming:
//                        if let renewalInfo = currentPlan.renewalInfo, renewalInfo.willAutoRenew,
//                           let nextRenewalDate = renewalInfo.nextRenewalDate {
//                            let renewalDataString = nextRenewalDate.formatted(.dateTime.hour().minute().month().day().year())
//                            subtitle = "Upcoming Plan\nWill start on \(renewalDataString)"
//                        } else {
//                            subtitle = "Auto Renewal Subscription"
//                        }
//                    }
//                case .nonRenewable:
//                    if let renewalInfo = currentPlan.renewalInfo, let expirationDate = renewalInfo.expirationDate {
//                        subtitle = "Your '\(currentPlan.displayName)' subscription will end on \(expirationDate.formatted(.dateTime.hour().minute().month().day().year()))"
//                    } else {
//                        subtitle = "Non Renewal Subscription"
//                    }
//                }
//            } else {
//                subtitle = "Inactive"
//            }
//
//            cell.textLabel?.text = title
//            cell.detailTextLabel?.text = subtitle
//            return cell
//        case 1: return tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath)
//        default: fatalError("No Section Rows")
//        }
//    }
}

