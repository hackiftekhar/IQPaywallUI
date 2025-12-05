//
//  PaywallView.swift

import SwiftUI
import StoreKit
import IQStoreKitManager

public struct PaywallView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PaywallViewModel = .init()
    @StateObject private var storeKitManager = StoreKitManager.shared

    @State private var showManageSubscription: Bool = false
    @State private var showTermsAndConditions: Bool = false
    @State private var showPrivacyPolicy: Bool = false

    private let configuration: PaywallConfiguration

    public init(configuration: PaywallConfiguration) {
        self.configuration = configuration
    }

    private var callToActionTitle: String {

        if storeKitManager.isProductPurchasing {
            return "Please wait..."
        } else if viewModel.products.isEmpty && storeKitManager.isProductLoading {
            return "Loading..."
        } else if let selectedProductId = viewModel.selectedProductId,
                  let product = viewModel.products.first(where: { $0.id == selectedProductId }) {
            if let snapshot = PurchaseStatusManager.shared.snapshot(for: product.id) {
                if snapshot.isActive {
                    return product.subscription != nil ? "Manage Subscription" : "Unlocked"
                } else if let subscription = product.subscription {
                    if let introOffer = subscription.introductoryOffer,
                       snapshot.isEligibleForIntroOffer {
                        return "Start \(introOffer.formatted) Now"
                    } else {
                        return configuration.actionButton.titleToSubscribe
                    }
                } else {
                    return configuration.actionButton.titleToUnlock
                }
            } else {
                return product.subscription != nil ? configuration.actionButton.titleToSubscribe : configuration.actionButton.titleToUnlock
            }
        } else {
            return "Choose your plan"
        }
    }

    private var callToActionBackground: Color {

        if storeKitManager.isProductPurchasing {
            return .gray
        } else if viewModel.products.isEmpty && storeKitManager.isProductLoading {
            return .gray
        } else if let selectedProductId = viewModel.selectedProductId,
                  viewModel.products.contains(where: { $0.id == selectedProductId }) {
            return configuration.foregroundColor.swiftUIColor
        } else {
            return .gray
        }
    }

    public var body: some View {
        NavigationView {
            ZStack {
                configuration.backgroundColor.swiftUIColor
                    .ignoresSafeArea()

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
                                    .background(logo.backgroundColor.swiftUIColor)
                                    .cornerRadius(30)
                            case .title(let title):
                                Text(title.title)
                                    .font(title.style.font.swiftUIFont)
                                    .foregroundStyle(title.style.color?.swiftUIColor ?? Color.primary)
                            case .subtitle(let subtitle):
                                Text(subtitle.title)
                                    .font(subtitle.style.font.swiftUIFont)
                                    .foregroundStyle(subtitle.style.color?.swiftUIColor ?? Color.secondary)
                            case .feature(let feature):
                                FeatureView(feature: feature, configuration: configuration)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            case .product(let productStyle):
                                productView(productStyle: productStyle)
                            }
                        }

                        if !configuration.elements.contains(where: { $0.id == ObjectIdentifier(PaywallConfiguration.Product.self) }) {
                            let productStyle: PaywallConfiguration.Product = .init()
                            productView(productStyle: productStyle)
                        }

                        // Products
                        if viewModel.products.isEmpty {
                            if storeKitManager.isProductLoading {
                                ProgressView("Loading...")
                            } else if let error = storeKitManager.productLoadingError {
                                Text(error.localizedDescription)
                            } else if viewModel.products.isEmpty {
                                Text("No Products to show")
                            }
                        }

                        Button(action: manageSubscriptionAction) {
                            Text("Manage Subscriptions")
                                .font(configuration.linkStyle.font.swiftUIFont)
                                .foregroundStyle(configuration.linkStyle.color?.swiftUIColor ?? Color.blue)
                        }
                        .disabled(storeKitManager.isProductPurchasing)
                        .frame(maxWidth: .infinity)
                        .padding(5)

                        HStack {
                            if let terms = configuration.terms {
                                Button(action: termsAndConditionAction) {
                                    Text(terms.title)
                                        .font(configuration.linkStyle.font.swiftUIFont)
                                        .foregroundStyle(configuration.linkStyle.color?.swiftUIColor ?? Color.blue)
                                }
                                .disabled(storeKitManager.isProductPurchasing)
                                .frame(maxWidth: .infinity)
                                .padding(5)
                            }
                            if let privacyPolicy = configuration.privacyPolicy {
                                Button(action: privacyPolicyAction) {
                                    Text(privacyPolicy.title)
                                        .font(configuration.linkStyle.font.swiftUIFont)
                                        .foregroundStyle(configuration.linkStyle.color?.swiftUIColor ?? Color.blue)
                                }
                                .disabled(storeKitManager.isProductPurchasing)
                                .frame(maxWidth: .infinity)
                                .padding(5)
                            }
                        }
                    }
                    .padding()
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 100)   // bottom content inset
                }

                if !viewModel.products.isEmpty {
                    VStack {
                        Spacer()
                        VStack {
                            if let selectedProductId = viewModel.selectedProductId,
                               let product = viewModel.products.first(where: { $0.id == selectedProductId }),
                               let snapshot = PurchaseStatusManager.shared.snapshot(for: product.id),
                               !snapshot.isActive,
                               let subscription = product.subscription,
                               let introOffer = subscription.introductoryOffer,
                               snapshot.isEligibleForIntroOffer {
                                VStack {
                                    Text(introOffer.formatted)
                                        .font(configuration.actionButton.font.withSize(15).swiftUIFont.weight(.regular))
                                    Text("No commitment. Cancel anytime.")
                                        .font(configuration.actionButton.font.withSize(12).swiftUIFont.weight(.light))
                                }
                            }

                            Button(action: subscribeAction) {
                                Text(callToActionTitle)
                                    .frame(maxWidth: .infinity)
                                    .padding()
    //                                .background(callToActionBackground)
    //                                .cornerRadius(20)
                                    .foregroundStyle(configuration.backgroundColor.swiftUIColor)
                                    .font(configuration.actionButton.font.swiftUIFont)
                            }
                            .defaultGlassStyle()
    //                        .background(callToActionBackground)
    //                        .tint(callToActionBackground)
    //                        .buttonStyle(.glass)
    //                        .backwardCompatibleGlassEffect()
                            .disabled(storeKitManager.isProductLoading)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
//                        .colorScheme(.light)
                        .alert("Error!", isPresented: $storeKitManager.isProductPurchasingError, actions: {
                            Button("OK", action: {})
                        }, message: {
                            Text(storeKitManager.productPurchaseError?.localizedDescription ?? "")
                        })
                    }
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
                        .disabled(storeKitManager.isProductPurchasing)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        crossAction()
                    } label: {
                        Image(systemName: "xmark").imageScale(.large)
                    }
                    .disabled(storeKitManager.isProductPurchasing)
                }
            }
        }
        .disabled(storeKitManager.isProductPurchasing)
        .interactiveDismissDisabled(storeKitManager.isProductPurchasing)
        .tint(configuration.foregroundColor.swiftUIColor)
        .foregroundStyle(configuration.foregroundColor.swiftUIColor)
        .navigationViewStyle(.stack)
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
              let product = viewModel.products.first(where: { $0.id == selectedProductId }) else {
            HapticGenerator.shared.error()
            return
        }
        HapticGenerator.shared.softImpact()
        let snapshot = PurchaseStatusManager.shared.snapshot(for: selectedProductId)
        if snapshot?.isActive == true {
            showManageSubscription = true
        } else {
            Task  {
                let result = await storeKitManager.purchase(product: product)

                await MainActor.run {
                    switch result {
                    case .success, .restored:
                        HapticGenerator.shared.success()
                    case .pending:
                        HapticGenerator.shared.warning()
                    case .userCancelled:
                        break
                    case .failure:
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

        Task {
            let result = await storeKitManager.restorePurchases()

            await MainActor.run {
                switch result {
                case .success, .restored:
                    HapticGenerator.shared.success()
                case .pending:
                    HapticGenerator.shared.warning()
                case .userCancelled:
                    break
                case .failure:
                    HapticGenerator.shared.error()
                }
            }
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

extension PaywallView {

    func productView(productStyle: PaywallConfiguration.Product) -> some View {
        VStack {
            switch productStyle.style {
            case .card:
                productCardListView(productStyle: productStyle)
            case .list:
                productTableListView(productStyle: productStyle)
            }
        }
    }

    func productCardListView(productStyle: PaywallConfiguration.Product) -> some View {
        HStack(spacing: 16) {
            ForEach(viewModel.products, id: \.self) { product in
                CardProductView(product: product,
                                productStyle: productStyle,
                                configuration: configuration,
                                selectedProductId: $viewModel.selectedProductId,
                                isActive: PurchaseStatusManager.shared.isActive(productID: product.id),
                                isOnlyAvailableProduct: configuration.productIds.count <= 1
                )
            }
        }
        .padding(.vertical)
    }

    func productTableListView(productStyle: PaywallConfiguration.Product) -> some View {
        VStack {
            ForEach(viewModel.products, id: \.self) { product in
                ListProductView(product: product,
                                productStyle: productStyle,
                                configuration: configuration,
                                selectedProductId: $viewModel.selectedProductId,
                                isActive: PurchaseStatusManager.shared.isActive(productID: product.id))
            }
        }
    }
}

#Preview {

    var configuration = {
        var configuration = PaywallConfiguration()
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
