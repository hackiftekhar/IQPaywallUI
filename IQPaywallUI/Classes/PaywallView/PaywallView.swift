//
//  PaywallView.swift

import SwiftUI
import StoreKit
import IQStoreKitManager

public struct PaywallView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PaywallViewModel = .init()

    @State private var showManageSubscription: Bool = false
    @State private var showTermsAndConditions: Bool = false
    @State private var showPrivacyPolicy: Bool = false

    private let configuration: PaywallConfiguration

    public init(configuration: PaywallConfiguration) {
        self.configuration = configuration
    }

    private var callToActionTitle: String {

        if viewModel.isProductPurchasing {
            return "Please wait..."
        } else if viewModel.products.isEmpty && viewModel.isProductLoading {
            return "Loading..."
        } else if let selectedProductId = viewModel.selectedProductId,
                  let product = viewModel.products.first(where: { $0.id == selectedProductId }) {
            if product.status != .inactive {
                return product.subscription != nil ? "Manage Subscription" : "Unlocked"
            } else if let subscription = product.subscription {
                if let introOffer = subscription.introductoryOffer,
                   product.isEligibleForIntroOffer {
                    return "Start \(introOffer.formatted) Now"
                } else {
                    return configuration.actionButton.titleToSubscribe
                }
            } else {
                return configuration.actionButton.titleToUnlock
            }
        } else {
            return "Choose your plan"
        }
    }

    private var callToActionBackground: Color {

        if viewModel.isProductPurchasing {
            return .gray
        } else if viewModel.products.isEmpty && viewModel.isProductLoading {
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
                    VStack(spacing: 16) {

                        ForEach(configuration.elements) { element in
                            switch element {
                            case .logo(let logo):
                                Image(uiImage: logo.logo)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 70, height: 70)
                                    .padding(15)
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
//                                let newProductStyle: PaywallConfiguration.Product = {
//                                    var style = productStyle
//                                    style.style = .list
//                                    return style
//                                }()
//                                productView(productStyle: newProductStyle)
                            }
                        }

                        if !configuration.elements.contains(where: { $0.id == ObjectIdentifier(PaywallConfiguration.Product.self) }) {
                            let productStyle: PaywallConfiguration.Product = .init()
                            productView(productStyle: productStyle)
                        }

                        // Products
                        if !viewModel.isProductLoading {
                            if let error = viewModel.productLoadingError {
                                Text(error.localizedDescription)
                            } else if viewModel.products.isEmpty {
                                Text("No Products to show")
                            }
                        }

                        if let currentPlan = viewModel.currentPlan {
                            VStack(spacing: 0) {
                                switch currentPlan.type {
                                case .consumable, .nonConsumable:
                                    EmptyView()
                                case .autoRenewable:
                                    if let renewalInfo = currentPlan.renewalInfo {
                                        if renewalInfo.willAutoRenew,
                                           let nextRenewalDate = renewalInfo.nextRenewalDate {
                                            let renewalDataString = nextRenewalDate.formatted(.dateTime.hour().minute().month().day().year())
                                            if let autoRenewPreference = renewalInfo.autoRenewPreference,
                                               autoRenewPreference != currentPlan.id {
                                                Text("Upcoming Plan Change")
                                                    .font(configuration.actionButton.font.withSize(15).swiftUIFont.weight(.bold))
                                                Text("Starting \(renewalDataString), your plan will change from '\(currentPlan.displayName)' to '\(PurchaseStatusManager.shared.snapshot(for:autoRenewPreference)?.displayName ?? autoRenewPreference)'")
                                                    .multilineTextAlignment(.leading)
                                            } else {
                                                Text("'\(currentPlan.displayName)' Renews Automatically")
                                                    .font(configuration.actionButton.font.withSize(15).swiftUIFont.weight(.bold))
                                                Text("\(nextRenewalDate.formatted(.dateTime.hour().minute().month().day().year()))")
                                            }
                                        } else if let expirationDate = renewalInfo.expirationDate {
                                            Text("You have cancelled your '\(currentPlan.displayName)' subscription")
                                                .font(configuration.actionButton.font.withSize(15).swiftUIFont.weight(.bold))
                                            Text("Your subscription will end on \(expirationDate.formatted(.dateTime.hour().minute().month().day().year()))")
                                        }
                                    }
                                case .nonRenewable:
                                    if let renewalInfo = currentPlan.renewalInfo {
                                        if let expirationDate = renewalInfo.expirationDate {
                                            Text("Your '\(currentPlan.displayName)' subscription will end on \(expirationDate.formatted(.dateTime.hour().minute().month().day().year()))")
                                                .font(configuration.actionButton.font.withSize(15).swiftUIFont.weight(.bold))
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .font(configuration.actionButton.font.withSize(12).swiftUIFont.weight(.regular))
                            .foregroundStyle(configuration.foregroundColor.swiftUIColor)
                        }

                        Button(action: manageSubscriptionAction) {
                            Text("Manage Subscriptions")
                                .font(configuration.linkStyle.font.swiftUIFont)
                                .foregroundStyle(configuration.linkStyle.color?.swiftUIColor ?? Color.blue)
                        }
                        .disabled(viewModel.isProductPurchasing)
                        .frame(maxWidth: .infinity)
                        .padding(5)

                        HStack {
                            if let terms = configuration.terms {
                                Button(action: termsAndConditionAction) {
                                    Text(terms.title)
                                        .font(configuration.linkStyle.font.swiftUIFont)
                                        .foregroundStyle(configuration.linkStyle.color?.swiftUIColor ?? Color.blue)
                                }
                                .disabled(viewModel.isProductPurchasing)
                                .frame(maxWidth: .infinity)
                                .padding(5)
                            }
                            if let privacyPolicy = configuration.privacyPolicy {
                                Button(action: privacyPolicyAction) {
                                    Text(privacyPolicy.title)
                                        .font(configuration.linkStyle.font.swiftUIFont)
                                        .foregroundStyle(configuration.linkStyle.color?.swiftUIColor ?? Color.blue)
                                }
                                .disabled(viewModel.isProductPurchasing)
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

                VStack {
                    Spacer()
                    VStack {
                        if let selectedProductId = viewModel.selectedProductId,
                           let product = viewModel.products.first(where: { $0.id == selectedProductId }),
                           !product.isActive,
                           let subscription = product.subscription,
                           let introOffer = subscription.introductoryOffer,
                           product.isEligibleForIntroOffer {
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
                                .foregroundStyle(configuration.backgroundColor.swiftUIColor)
                                .font(configuration.actionButton.font.swiftUIFont)
                        }
                        .defaultGlassStyle()
                        .disabled(viewModel.isProductLoading)
                        .redacted(reason: (viewModel.products.isEmpty && viewModel.isProductLoading) ? .placeholder : [] )
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    //                        .colorScheme(.light)
                    .alert("Error!", isPresented: $viewModel.isProductPurchasingError, actions: {
                        Button("OK", action: {})
                    }, message: {
                        Text(viewModel.productPurchaseError?.localizedDescription ?? "")
                    })
                }
            }
            .manageSubscriptionsSheet(isPresented: $showManageSubscription)
            .alert("Error!", isPresented: $viewModel.isProductLoadingError, actions: {
                Button("OK", action: crossAction)
            }, message: {
                Text(viewModel.productLoadingError?.localizedDescription ?? "")
            })
            .onAppear {
                Task {
                    await fetchProducts()
                }
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
                        .disabled(viewModel.isProductPurchasing)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        crossAction()
                    } label: {
                        Image(systemName: "xmark").imageScale(.large)
                    }
                    .disabled(viewModel.isProductPurchasing)
                }
            }
        }
        .onChange(of: showManageSubscription, perform: { newValue in
            if newValue == false {
                //User dismissed the manage subscription screen, let's see if user has changed something or not
                Task {
                    // Refresh list
                    await fetchProducts()
                }
            }
        })
        .interactiveDismissDisabled(viewModel.isProductPurchasing)
        .tint(configuration.foregroundColor.swiftUIColor)
        .foregroundStyle(configuration.foregroundColor.swiftUIColor)
        .navigationViewStyle(.stack)
    }

    private func fetchProducts() async {
        await viewModel.fetchProducts(productIds: configuration.productIds)

        if viewModel.selectedProductId == nil {
            if let currentPlan = viewModel.products.first(where: { $0.status == .active}) {
                viewModel.selectedProductId = currentPlan.id
            } else {
                viewModel.selectedProductId = configuration.recommendedProductId
            }
        }
    }

    private func subscribeAction() {
        guard let selectedProductId = viewModel.selectedProductId else {
            HapticGenerator.shared.error()
            return
        }
        HapticGenerator.shared.softImpact()

        if let product = viewModel.products.first(where: { $0.id == selectedProductId }),
           product.status != .inactive {
            showManageSubscription = true
        } else if let product = StoreKitManager.shared.product(withID: selectedProductId) {
            Task {
                await viewModel.purchase(product: product)
                await fetchProducts()
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
            await viewModel.restorePurchases()
            await fetchProducts()
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
            let products: [ProductInfo] = viewModel.products.isEmpty ? ProductInfo.placeholders : viewModel.products
            ForEach(products, id: \.self) { product in
                CardProductView(product: product,
                                productStyle: productStyle,
                                configuration: configuration,
                                selectedProductId: $viewModel.selectedProductId,
                                isOnlyAvailableProduct: configuration.productIds.count <= 1
                )
            }
        }
        .redacted(reason: (viewModel.products.isEmpty && viewModel.isProductLoading) ? .placeholder : [] )
        .padding(.vertical)
    }

    func productTableListView(productStyle: PaywallConfiguration.Product) -> some View {
        VStack {
            let products: [ProductInfo] = viewModel.products.isEmpty ? ProductInfo.placeholders : viewModel.products
            ForEach(products, id: \.self) { product in
                ListProductView(product: product,
                                productStyle: productStyle,
                                configuration: configuration,
                                selectedProductId: $viewModel.selectedProductId,
                )
            }
        }
        .redacted(reason: (viewModel.products.isEmpty && viewModel.isProductLoading) ? .placeholder : [] )
    }
}

#Preview {

    let configuration = {
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
