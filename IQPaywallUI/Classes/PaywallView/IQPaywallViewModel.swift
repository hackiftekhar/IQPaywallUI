//
//  PaywallViewModel.swift

import SwiftUI
import StoreKit

@MainActor
final class PaywallViewModel: ObservableObject {

    @Published var selectedProductId: String?
    @Published var products: [Product] = []

    func fetchProducts(productIds: [String]) async {
        products = await IQStoreKitManager.shared.loadProducts(productIDs: productIds)
    }
}

