//
//  PaywallViewModel.swift

import SwiftUI
import StoreKit
import IQStoreKitManager

@MainActor
public final class PaywallViewModel: ObservableObject {

    private let storeKitManager = StoreKitManager.shared
    private let purchaseStatusManager = PurchaseStatusManager.shared

    @MainActor
    @Published @objc public var selectedProductId: String?

    @MainActor
    @Published public var products: [ProductInfo] = []

    @MainActor
    @Published @objc public var isProductLoading: Bool = false

    @MainActor
    @Published @objc public var isProductLoadingError: Bool = false

    @MainActor
    @Published @objc public var productLoadingError: Error? = nil

    @MainActor
    @Published @objc public var isProductPurchasing: Bool = false

    @MainActor
    @Published @objc public var isProductPurchasingError: Bool = false

    @MainActor
    @Published @objc public var productPurchaseError: Error? = nil


    let formatter: DateFormatter

    init() {
        formatter = DateFormatter()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "ddMMyyyyHHmma",
                                                        options: 0,
                                                        locale: Locale.current)
    }

    var currentPlan: ProductStatus? {
        // First select the selected product if active
        if let selectedProductId = selectedProductId,
           let snapshot = purchaseStatusManager.snapshot(for: selectedProductId),
           snapshot.isActive {
            return snapshot
        }

        // Then select the first from the first active product in the list
        for product in products {
            if let snapshot = purchaseStatusManager.snapshot(for: product.id),
               snapshot.isActive {
                return snapshot
            }
        }

        // Finally return the currently active plan saved in the manager
        return purchaseStatusManager.activePlans.first
    }

    func fetchProducts(productIds: [String]) async {

        var cachedProducts = [Product]()

        for productId in productIds {
            if let cachedProduct = storeKitManager.product(withID: productId) {
                cachedProducts.append(cachedProduct)
            }
        }
        if !cachedProducts.isEmpty {
            self.products = cachedProducts.map({ .init(product: $0, snapshot: purchaseStatusManager.snapshot(for: $0.id)) })
        }

        isProductLoading = true
        productLoadingError = nil
        isProductLoadingError = false

        let products = await storeKitManager.loadProducts(productIDs: productIds)

        if products.isEmpty {
            productLoadingError = NSError(domain: "\(Self.self)", code: 0, userInfo: [NSLocalizedDescriptionKey: "No products to show"])
            isProductLoadingError = true
        }

        self.products = products.map({ .init(product: $0, snapshot: purchaseStatusManager.snapshot(for: $0.id)) })
        isProductLoading = false
    }

    func purchase(product: Product) async {

        isProductPurchasing = true
        isProductPurchasingError = false
        productPurchaseError = nil

        let result = await storeKitManager.purchase(product: product)

        switch result {
        case .success, .restored:
            HapticGenerator.shared.success()
        case .pending:
            HapticGenerator.shared.warning()
            productPurchaseError = NSError(domain: "\(Self.self)", code: -1, userInfo: [NSLocalizedDescriptionKey: "Purchase is Pending to be Completed!"])
            isProductPurchasingError = true
        case .userCancelled:
            break
        case .failure(let error):
            HapticGenerator.shared.error()
            productPurchaseError = error
            isProductPurchasingError = true
        }

        isProductPurchasing = false
    }

    func restorePurchases() async {

        isProductPurchasing = true
        isProductPurchasingError = false
        productPurchaseError = nil

        let result = await storeKitManager.restorePurchases()

        switch result {
        case .success, .restored:
            HapticGenerator.shared.success()
        case .pending:
            HapticGenerator.shared.warning()
            productPurchaseError = NSError(domain: "\(Self.self)", code: -1, userInfo: [NSLocalizedDescriptionKey: "Purchase is Pending to be Completed!"])
            isProductPurchasingError = true
        case .userCancelled:
            break
        case .failure(let error):
            HapticGenerator.shared.error()
            productPurchaseError = error
            isProductPurchasingError = true
        }

        isProductPurchasing = false
    }
}


