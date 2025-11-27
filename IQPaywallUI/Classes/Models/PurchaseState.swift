//
//  PurchaseState.swift

import StoreKit

internal enum PurchaseState {
    case success(transaction: Transaction)
    case pending
    case userCancelled
    case failure(error: Error)
}
