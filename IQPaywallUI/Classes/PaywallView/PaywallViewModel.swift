//
//  PaywallViewModel.swift

import SwiftUI
import StoreKit
import IQStoreKitManager

@MainActor
internal final class PaywallViewModel: ObservableObject {

    @Published var selectedProductId: String?
    @Published var products: [Product] = []

    func fetchProducts(productIds: [String]) async {

        var cachedProducts = [Product]()

        for productId in productIds {
            if let cachedProduct = StoreKitManager.shared.product(withID: productId) {
                cachedProducts.append(cachedProduct)
            }
        }
        if !cachedProducts.isEmpty {
            self.products = cachedProducts
        }

        products = await StoreKitManager.shared.loadProducts(productIDs: productIds)
    }
}

