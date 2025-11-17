//
//  PurchaseState.swift

import StoreKit

public enum PurchaseState {
    case success(transaction: Transaction)
    case pending
    case userCancelled
    case failed(error: Error)
}
