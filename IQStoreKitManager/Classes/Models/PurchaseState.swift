//
//  PurchaseState.swift

import StoreKit

public enum PurchaseState {
    case success(transaction: Transaction)
    case restored
    case pending
    case userCancelled
    case failure(error: Error)
}
