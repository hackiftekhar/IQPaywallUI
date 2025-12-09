//
//  PaywallViewModel.swift

import SwiftUI
import StoreKit
import IQStoreKitManager

public struct AlertModel {
    public var isShow: Bool = false
    private(set) var title: String = ""
    private(set) var message: String = ""
    private(set) var buttonTitle: String = ""
    init() {
    }

    mutating public func show(title: String, message: String, buttonTitle: String = "OK") {
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        isShow = true
    }
    mutating public func hide() {
        isShow = false
        title = ""
        message = ""
        buttonTitle = ""
    }
}

@MainActor
public final class PaywallViewModel: ObservableObject {

    private let storeKitManager = StoreKitManager.shared
    private let purchaseStatusManager = PurchaseStatusManager.shared
    @Published var consumableQuantity: Int = 1

    @MainActor
    @Published @objc public var selectedProductId: String?

    @MainActor
    @Published public var products: [ProductInfo] = []

    @MainActor
    @Published @objc var isProductLoading: Bool = false
    @MainActor
    @Published public var productLoadingErrorAlert: AlertModel = .init()

    @MainActor
    @Published public var isProductPurchasing: Bool = false
    @MainActor
    @Published public var productPurchaseResultAlert: AlertModel = .init()

    let formatter: DateFormatter

    init() {
        formatter = DateFormatter()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "ddMMyyyyHHmma",
                                                        options: 0,
                                                        locale: Locale.current)

        NotificationCenter.default.addObserver(forName: PurchaseStatusManager.purchaseStatusDidChangedNotification, object: nil, queue: nil) { _ in

            DispatchQueue.main.async {
                self.updateProductStatuses()
            }
        }
    }


    private func updateProductStatuses() {
        // Update product statuses
        let products = self.products.map { productInfo in
            var updatedProductInfo = productInfo
            updatedProductInfo.updateSnapshot(purchaseStatusManager.snapshot(for: productInfo.id))
            return updatedProductInfo
        }
        self.products = products
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
        productLoadingErrorAlert.hide()

        let products = await storeKitManager.loadProducts(productIDs: productIds)
        if !products.isEmpty {
            self.products = products.map({ .init(product: $0, snapshot: purchaseStatusManager.snapshot(for: $0.id)) })
        }

        if self.products.isEmpty {
            productLoadingErrorAlert.show(title: "Error", message: "No products to show")
        }

        isProductLoading = false
    }

    func purchase(product: Product) async {

        isProductPurchasing = true
        productPurchaseResultAlert.hide()

        let finalQuantity: Int? = product.type == .consumable ? consumableQuantity : nil
        let result = await storeKitManager.purchase(product: product, quantity: finalQuantity)

        switch result {
        case .success, .restored:
            HapticGenerator.shared.success()
            productPurchaseResultAlert.show(title: "Success", message: "Purchase completed successfully!")
        case .pending:
            HapticGenerator.shared.warning()
            productPurchaseResultAlert.show(title: "Purchase Pending", message: "Purchase is Pending to be Completed. You may need to take additional steps to complete the purchase.")
        case .userCancelled:
            break
        case .failure(let error):
            HapticGenerator.shared.error()
            productPurchaseResultAlert.show(title: "Purchase Failed", message: error.localizedDescription)
        }

        isProductPurchasing = false
    }

    func restorePurchases() async {

        isProductPurchasing = true
        productPurchaseResultAlert.hide()

        let result = await storeKitManager.restorePurchases()

        switch result {
        case .success, .restored:
            HapticGenerator.shared.success()
            productPurchaseResultAlert.show(title: "Restored", message: "Purchase Restored completed successfully!")
        case .pending:
            HapticGenerator.shared.warning()
            productPurchaseResultAlert.show(title: "Purchase Restored Pending", message: "Purchase is Pending to be Completed. You may need to take additional steps to complete the purchase.")
        case .userCancelled:
            break
        case .failure(let error):
            HapticGenerator.shared.error()
            productPurchaseResultAlert.show(title: "Purchase Restoration Failed", message: error.localizedDescription)
        }

        isProductPurchasing = false
    }
}


