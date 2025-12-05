//
//  PurchaseState.swift

import StoreKit

internal enum PurchaseState {
    case success(transaction: Transaction)
    case restored
    case pending
    case userCancelled
    case failure(error: Error)
}
