//
//  IQPaywallView.swift

import SwiftUI
import StoreKit

public struct PaywallView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PaywallViewModel = .init()
    @StateObject private var storeKitManager = IQStoreKitManager.shared

    @State private var showManageSubscription: Bool = false
    @State private var showTermsAndConditions: Bool = false
    @State private var showPrivacyPolicy: Bool = false

    private let configuration: IQPaywallConfiguration

    public init(configuration: IQPaywallConfiguration) {
        self.configuration = configuration
    }

    private var callToActionTitle: String {
        if let selectedProductId = viewModel.selectedProductId,
           let product = IQStoreKitManager.shared.product(withID: selectedProductId) {
            if let snapshot = PurchaseStatusManager.shared.snapshot(for: product.id), snapshot.isActive {
                return product.subscription != nil ? "Manage Subscription" : "Unlocked"
            } else {
                return product.subscription != nil ? configuration.actionButton.titleToSubscribe : configuration.actionButton.titleToUnlock
            }
        } else {
            return "Choose your plan"
        }
    }

    public var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: configuration.backgroundColor)
                    .ignoresSafeArea()
                VStack(spacing: 10) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {

                            ForEach(configuration.elements) { element in
                                switch element {
                                case .logo(let logo):
                                    Image(uiImage: logo.logo)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 80, height: 80)
                                        .padding(20)
                                        .background(Color(uiColor: logo.backgroundColor))
                                        .cornerRadius(30)
                                case .title(let title):
                                    Text(title.title)
                                        .font(Font(title.style.font))
                                        .foregroundStyle(Color(uiColor: title.style.color))
                                case .subtitle(let subtitle):
                                    Text(subtitle.title)
                                        .font(Font(subtitle.style.font))
                                        .foregroundStyle(Color(uiColor: subtitle.style.color))
                                case .feature(let feature):
                                    FeatureView(feature: feature)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                case .product(let productStyle):
                                    switch productStyle.style {
                                    case .card:
                                        HStack(spacing: 20) {
                                            ForEach(viewModel.products, id: \.self) { product in
                                                CardProductView(product: product,
                                                                productStyle: productStyle,
                                                                tintColor: Color(uiColor: configuration.tintColor),
                                                                selectedProductId: $viewModel.selectedProductId,
                                                                isActive: PurchaseStatusManager.shared.isActive(productID: product.id))
                                            }
                                        }
                                        .padding(.vertical)
                                    case .list:
                                        VStack {
                                            ForEach(viewModel.products, id: \.self) { product in
                                                ListProductView(product: product,
                                                                productStyle: productStyle,
                                                                tintColor: Color(uiColor: configuration.tintColor),
                                                                selectedProductId: $viewModel.selectedProductId,
                                                                isActive: PurchaseStatusManager.shared.isActive(productID: product.id))
                                            }
                                        }
                                    }
                                }
                            }

                            if !configuration.elements.contains(where: { $0.id == ObjectIdentifier(IQPaywallConfiguration.Product.self) }) {
                                VStack {
                                    ForEach(viewModel.products, id: \.self) { product in
                                        ListProductView(product: product,
                                                        productStyle: .init(),
                                                        tintColor: Color(uiColor: configuration.tintColor),
                                                        selectedProductId: $viewModel.selectedProductId,
                                                        isActive: PurchaseStatusManager.shared.isActive(productID: product.id))
                                    }
                                }
                            }

                            // Products
                            if storeKitManager.isProductLoading {
                                ProgressView("Loading...")
                            } else if let error = storeKitManager.productLoadingError {
                                Text(error.localizedDescription)
                            } else if viewModel.products.isEmpty {
                                Text("No Products to show")
                            }

                            Button(action: manageSubscriptionAction) {
                                Text("Manage Subscriptions")
                                    .font(Font(configuration.linkStyle.font))
                                    .foregroundStyle(Color(configuration.linkStyle.color))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(5)

                            HStack {
                                if let terms = configuration.terms {
                                    Button(action: termsAndConditionAction) {
                                        Text(terms.title)
                                            .font(Font(configuration.linkStyle.font))
                                            .foregroundStyle(Color(configuration.linkStyle.color))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(5)
                                }
                                if let privacyPolicy = configuration.privacyPolicy {
                                    Button(action: privacyPolicyAction) {
                                        Text(privacyPolicy.title)
                                            .font(Font(configuration.linkStyle.font))
                                            .foregroundStyle(Color(configuration.linkStyle.color))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(5)
                                }
                            }
                        }
                        .padding()
                    }

                    VStack {
                        Button(action: subscribeAction) {
                            if storeKitManager.isProductPurchasing {
                                ProgressView("Please wait...")
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(configuration.tintColor))
                                    .cornerRadius(20)
                            } else {
                                Text(callToActionTitle)
                                    .foregroundStyle(.white)
                                    .font(Font(configuration.actionButton.font))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(configuration.tintColor))
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .disabled(storeKitManager.isProductLoading)
                    .alert("Error!", isPresented: $storeKitManager.isProductPurchasing, actions: {
                        Button("OK", action: {})
                    }, message: {
                        Text(storeKitManager.productPurchaseError?.localizedDescription ?? "")
                    })
                }
            }
            .manageSubscriptionsSheet(isPresented: $showManageSubscription)
            .alert("Error!", isPresented: $storeKitManager.isProductLoadingError, actions: {
                Button("OK", action: crossAction)
            }, message: {
                Text(storeKitManager.productLoadingError?.localizedDescription ?? "")
            })
            .onAppear {
                fetchProducts()
            }
            .sheet(isPresented: $showTermsAndConditions) {
                SafariView(url: configuration.terms!.url)
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                SafariView(url: configuration.privacyPolicy!.url)
            }
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {
                    Button("Restore", action: restorePurchaseAction)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        crossAction()
                    } label: {
                        Image(systemName: "xmark").imageScale(.large)
                    }
                }
            }
        }
        .tint(Color(uiColor: configuration.tintColor))
    }

    private func fetchProducts() {
        Task {
            await viewModel.fetchProducts(productIds: configuration.productIds)

            if viewModel.selectedProductId == nil {
                let currentPlan = PurchaseStatusManager.shared.currentlyActivePlan
                if let currentPlan = currentPlan,
                   let index = viewModel.products.firstIndex(where: { $0.id == currentPlan.productID }) {
                    viewModel.selectedProductId = viewModel.products[index].id
                } else {
                    viewModel.selectedProductId = configuration.recommendedProductId
                }
            }
        }
    }

    private func subscribeAction() {
        guard let selectedProductId = viewModel.selectedProductId,
        let product = IQStoreKitManager.shared.product(withID: selectedProductId) else {
            HapticGenerator.shared.error()
            return
        }
        HapticGenerator.shared.softImpact()
        let snapshot = PurchaseStatusManager.shared.snapshot(for: selectedProductId)
        if snapshot?.isActive == true {
            showManageSubscription = true
        } else {
            Task  {
                let result = await IQStoreKitManager.shared.purchase(product: product)

                await MainActor.run {
                    switch result {
                    case .success:
                        HapticGenerator.shared.success()
                    case .pending:
                        HapticGenerator.shared.warning()
                    case .userCancelled:
                        break
                    case .failed:
                        HapticGenerator.shared.error()
                    }
                }
            }
        }
    }

    private func manageSubscriptionAction() {
        HapticGenerator.shared.softImpact()
        showManageSubscription = true
    }

    private func restorePurchaseAction() {
        HapticGenerator.shared.softImpact()

        Task  {
            await storeKitManager.restorePurchases()
        }
    }

    private func termsAndConditionAction() {
        HapticGenerator.shared.softImpact()
        showTermsAndConditions = true
    }

    private func privacyPolicyAction() {
        HapticGenerator.shared.softImpact()
        showPrivacyPolicy = true
    }

    private func crossAction() {
        HapticGenerator.shared.softImpact()
        dismiss()
    }
}

#Preview {

    var configuration = {
        var configuration = IQPaywallConfiguration()
        configuration.elements.append(.title(.init("Unlock Pro Features")))
        configuration.elements.append(.subtitle(.init("Get access to all our pro features")))
//        configuration.elements.append(.appIcon(.init(UIImage(named:"ruler_logo")!)))
        configuration.elements.append(.feature(.init(titles: ["Remove all ads",
                                                              "Customize Color Themes",
                                                              "Unlock Pixel Ratio feature",
                                                              "Persist Your Settings"])))
        configuration.elements.append(.product(.init()))
        configuration.terms = .init("Terms & Conditions", url: URL(string: "https://www.termsAndConditions.com")!)
        configuration.privacyPolicy = .init("Privacy Policy", url: URL(string: "https://www.privacyPolicy.com")!)
        return configuration
    }()

    PaywallView(configuration: configuration)
}
