//
//  PaywallView.swift

import SwiftUI
import StoreKit
import IQPurchaseKit

public struct PaywallView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PaywallViewModel = .init()
    @State private var selectedProductId: String?
    @State private var consumableQuantity: Int = 1
    @State private var productLoadingErrorAlert: AlertModel = .init()
    @State private var productPurchaseResultAlert: AlertModel = .init()

    @State private var showManageSubscription: Bool = false
    @State private var showOfferCode: Bool = false
    @State private var showTermsAndConditions: Bool = false
    @State private var showPrivacyPolicy: Bool = false

    private let configuration: PaywallConfiguration

    public init(configuration: PaywallConfiguration) {
        self.configuration = configuration
    }

    private var callToActionTitle: String {
        if viewModel.isProductPurchasing {
            return String(localized: "Please wait...")
        }

        if viewModel.isProductLoading && viewModel.products.isEmpty {
            return String(localized: "Loading...")
        }

        guard let product = selectedProductId,
              let product = viewModel.products.first(where: { $0.id == selectedProductId }) else {
            return String(localized: "Choose your plan")
        }

        if product.isActive {
            if product.type == .autoRenewable || product.type == .nonRenewable {
                return String(localized: "Manage Subscription")
            } else {
                return String(localized: "Unlocked")
            }
        }

        if product.shouldDisplayIntroductoryOffer {
            return product.subscribeActionTitle
        }

        return "\(String(localized: "Subscribe")) \(product.price.formatted(product.priceFormatStyle))"
    }

    private var callToActionSubtitle: String? {
        if viewModel.isProductPurchasing ||
            (viewModel.isProductLoading && viewModel.products.isEmpty) {
            return nil
        }

        guard let product = selectedProductId,
              let product = viewModel.products.first(where: { $0.id == selectedProductId }), !product.isActive else {
            return nil
        }

        if product.shouldDisplayIntroductoryOffer {
            return product.subscribeActionSubtitle
        }

        return product.subscriptionPeriodDescription
    }

    private var callToActionBackground: Color {

        if viewModel.isProductPurchasing {
            return .gray
        } else if viewModel.products.isEmpty && viewModel.isProductLoading {
            return .gray
        } else if let selectedProductId = selectedProductId,
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

                        if let selectedProductId = selectedProductId,
                            let product = viewModel.products.first(where: { $0.id == selectedProductId }),
                           product.type == .consumable {
                            Stepper("Quantity: \(consumableQuantity)", value: $consumableQuantity, in: 1...Int.max)
                                .font(configuration.actionButton.font.withSize(15).swiftUIFont.weight(.bold))
                        }

                        if let currentPlan = viewModel.products.first(where: { $0.status == .active })?.snapshot,
                           let renewalInfo = currentPlan.renewalInfo?.info {
                            let dateString = renewalInfo.date?.formatted(.dateTime.hour().minute().month().day().year()) ?? ""

                            VStack(spacing: 4) {
                                switch currentPlan.type {
                                case .consumable, .nonConsumable:
                                    EmptyView()
                                case .autoRenewable:
                                    switch currentPlan.status {
                                    case .active, .upcoming:
                                        if renewalInfo.currentProductID == renewalInfo.nextProductID {
                                            Text("'\(currentPlan.displayName)' Renews Automatically")
                                                .font(configuration.actionButton.font.withSize(15).swiftUIFont.weight(.bold))
                                            Text("Your subscription will renew on \(dateString)")
                                                .multilineTextAlignment(.leading)
                                                .foregroundStyle(.secondary)
                                        } else if let nextProductID = renewalInfo.nextProductID, renewalInfo.currentProductID != nextProductID {
                                            let nextPlanName = PurchaseStatusManager.shared.snapshot(for: nextProductID)?.displayName ?? nextProductID
                                            Text("Upcoming Plan Change")
                                                .font(configuration.actionButton.font.withSize(15).swiftUIFont.weight(.bold))
                                            Text("Starting \(dateString), your plan will change from '\(currentPlan.displayName)' to '\(nextPlanName)'")
                                                .multilineTextAlignment(.leading)
                                                .foregroundStyle(.secondary)
                                        } else {
                                            Text("'\(currentPlan.displayName)' Subscription Cancelled")
                                                .font(configuration.actionButton.font.withSize(15).swiftUIFont.weight(.bold))
                                            Text("Your subscription will remain active until \(dateString)")
                                                .multilineTextAlignment(.leading)
                                                .foregroundStyle(.secondary)
                                        }
                                    case .inactive, .unlocked:
                                        EmptyView()
                                    case .gracePeriod:
                                        Text("Payment Issue")
                                            .font(configuration.actionButton.font.withSize(15).swiftUIFont.weight(.bold))
                                        Text("We couldn't process your payment. Your '\(currentPlan.displayName)' subscription remains active until \(dateString). Please update your payment method to avoid losing access.")
                                            .multilineTextAlignment(.leading)
                                            .foregroundStyle(.secondary)
                                    case .billingRetryPeriod:
                                        Text("Payment Issue")
                                            .font(configuration.actionButton.font.withSize(15).swiftUIFont.weight(.bold))
                                        Text("We couldn't process your payment for your '\(currentPlan.displayName)' subscription. Apple is retrying the payment. Please update your payment method to restore your subscription.")
                                            .multilineTextAlignment(.leading)
                                            .foregroundStyle(.secondary)
                                    }
                                case .nonRenewable:
                                    Text("'\(currentPlan.displayName)' Active")
                                        .font(configuration.actionButton.font.withSize(15).swiftUIFont.weight(.bold))
                                    Text("Your subscription will remain active until \(dateString)")
                                        .font(configuration.actionButton.font.withSize(15).swiftUIFont.weight(.bold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .font(configuration.actionButton.font.withSize(12).swiftUIFont.weight(.regular))
                            .foregroundStyle(configuration.foregroundColor.swiftUIColor)
                        }

                        if viewModel.products.contains(where: { $0.type == .autoRenewable || $0.type == .nonRenewable }) {
                            Button(action: manageSubscriptionAction) {
                                Text("Manage Subscriptions")
                                    .font(configuration.linkStyle.font.swiftUIFont)
                                    .foregroundStyle(configuration.linkStyle.color?.swiftUIColor ?? Color.blue)
                            }
                            .disabled(viewModel.isProductPurchasing)
                            .frame(maxWidth: .infinity)
                            .padding(5)
                        }

                        if configuration.canRedeemOfferCode {
                            Button(action: { showOfferCode = true }) {
                                Text("Redeem Offer Code")
                                    .font(configuration.linkStyle.font.swiftUIFont)
                                    .foregroundStyle(configuration.linkStyle.color?.swiftUIColor ?? Color.blue)
                            }
                            .disabled(viewModel.isProductPurchasing)
                            .frame(maxWidth: .infinity)
                            .padding(5)
                        }

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
                    Color.clear.frame(height: 200)   // bottom content inset
                }

                VStack {
                    Spacer()
                    VStack {
                        Button(action: subscribeAction) {
                            VStack(spacing: 2) {
                                Text(callToActionTitle)
                                    .font(configuration.actionButton.font.swiftUIFont)
                                    .multilineTextAlignment(.center)

                                if let callToActionSubtitle {
                                    Text(callToActionSubtitle)
                                        .font(configuration.actionButton.font.withSize(12).swiftUIFont.weight(.medium))
                                        .opacity(0.85)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(configuration.backgroundColor.swiftUIColor)
                        }
                        .defaultGlassStyle()
                        .disabled(viewModel.isProductLoading || viewModel.products.isEmpty)
                        .redacted(reason: (viewModel.products.isEmpty && viewModel.isProductLoading) ? .placeholder : [] )
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    //                        .colorScheme(.light)
                    .alert(productPurchaseResultAlert.title, isPresented: $productPurchaseResultAlert.isShow, actions: {
                        Button(productPurchaseResultAlert.buttonTitle, action: {})
                    }, message: {
                        Text(productPurchaseResultAlert.message)
                    })
                }
            }
            .manageSubscriptionsSheet(isPresented: $showManageSubscription)
            .offerCodeRedemptionCompatibility(isPresented: $showOfferCode, onCompletion: { result in
                handleOfferCodeResult(result: result)
            })
            .onAppear {
                Task {
                    await fetchProducts()
                }
            }
            .onChange(of: viewModel.products, perform: { _ in
                selectDefaultProductIfNeeded()
            })
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
                    await PurchaseKit.shared.refreshStatuses()
                }
            }
        })
        .interactiveDismissDisabled(viewModel.isProductPurchasing)
        .tint(configuration.foregroundColor.swiftUIColor)
        .foregroundStyle(configuration.foregroundColor.swiftUIColor)
        .navigationViewStyle(.stack)
    }

    private func fetchProducts() async {
        productLoadingErrorAlert.hide()

        do {
            try await viewModel.fetchProducts(productIds: configuration.productIds)
            selectDefaultProductIfNeeded()
        } catch {
            selectDefaultProductIfNeeded()
            if viewModel.products.isEmpty {
                productLoadingErrorAlert.show(title: "Error", message: error.localizedDescription)
            }
        }
    }

    private func selectDefaultProductIfNeeded() {
        guard selectedProductId == nil, !viewModel.products.isEmpty else { return }
        if let currentPlan = viewModel.products.first(where: { $0.status == .active}) {
            selectedProductId = currentPlan.id
        } else {
            selectedProductId = configuration.recommendedProductId
        }
    }

    private func retryFetchProducts() {
        HapticGenerator.shared.softImpact()
        Task {
            await fetchProducts()
        }
    }

    private func subscribeAction() {
        guard let selectedProductId = selectedProductId else {
            HapticGenerator.shared.error()
            return
        }
        HapticGenerator.shared.softImpact()
        productPurchaseResultAlert.hide()

        if let product = viewModel.products.first(where: { $0.id == selectedProductId }),
           product.status != .inactive {
            showManageSubscription = true
        } else if let product = viewModel.products.first(where: { $0.id == selectedProductId }) {
            Task {
                let result = await viewModel.purchase(product: product, quantity: consumableQuantity)
                handlePurchaseResult(result, isRestore: false)
            }
        }
    }

    private func manageSubscriptionAction() {
        HapticGenerator.shared.softImpact()
        showManageSubscription = true
    }

    private func restorePurchaseAction() {
        HapticGenerator.shared.softImpact()
        productPurchaseResultAlert.hide()

        Task {
            let result = await viewModel.restorePurchases()
            handlePurchaseResult(result, isRestore: true)
        }
    }

    private func handlePurchaseResult(_ result: PurchaseState, isRestore: Bool) {
        switch result {
        case .success:
            HapticGenerator.shared.success()
            if isRestore {
                productPurchaseResultAlert.show(title: "Restored", message: "Purchase Restored completed successfully!")
            } else {
                productPurchaseResultAlert.show(title: "Success", message: "Purchase completed successfully!")
            }
        case .restored:
            HapticGenerator.shared.success()
            productPurchaseResultAlert.show(title: "Restored", message: "Purchase Restored completed successfully!")
        case .pending:
            HapticGenerator.shared.warning()
            if isRestore {
                productPurchaseResultAlert.show(title: "Purchase Restored Pending", message: "Purchase is Pending to be Completed. You may need to take additional steps to complete the purchase.")
            } else {
                productPurchaseResultAlert.show(title: "Purchase Pending", message: "Purchase is Pending to be Completed. You may need to take additional steps to complete the purchase.")
            }
        case .userCancelled:
            break
        case .failure(let error):
            HapticGenerator.shared.error()
            if isRestore {
                productPurchaseResultAlert.show(title: "Purchase Restoration Failed", message: error.localizedDescription)
            } else {
                productPurchaseResultAlert.show(title: "Purchase Failed", message: error.localizedDescription)
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

    private func handleOfferCodeResult(result: Result<Void, Error>) {
        switch result {
        case .success:
            Task {
                await PurchaseKit.shared.refreshStatuses()
            }
            HapticGenerator.shared.success()
        case .failure:
            break
//            HapticGenerator.shared.error()
        }
    }
}

extension PaywallView {

    func productView(productStyle: PaywallConfiguration.Product) -> some View {
        Group {
            if !viewModel.products.isEmpty {
                switch productStyle.style {
                case .card:
                    productCardListView(productStyle: productStyle)
                case .list:
                    productTableListView(productStyle: productStyle)
                }
            } else if viewModel.isProductLoading || !productLoadingErrorAlert.isShow {
                productLoadingView()
            } else {
                productLoadingErrorView()
            }
        }
    }

    func productLoadingView() -> some View {
        ProgressView()
            .progressViewStyle(.circular)
            .scaleEffect(1.4)
            .tint(configuration.foregroundColor.swiftUIColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
    }

    func productLoadingErrorView() -> some View {
        VStack(spacing: 12) {
            Text(productLoadingErrorAlert.title)
                .font(configuration.actionButton.font.withSize(20).swiftUIFont.weight(.bold))
                .multilineTextAlignment(.center)
            Text(productLoadingErrorAlert.message)
                .font(configuration.actionButton.font.withSize(15).swiftUIFont.weight(.regular))
                .multilineTextAlignment(.center)
            Button(action: retryFetchProducts) {
                Text("Retry")
                    .font(configuration.actionButton.font.withSize(16).swiftUIFont.weight(.semibold))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .foregroundStyle(configuration.backgroundColor.swiftUIColor)
                    .background(configuration.foregroundColor.swiftUIColor)
                    .cornerRadius(10)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    func productCardListView(productStyle: PaywallConfiguration.Product) -> some View {
        HStack(spacing: 16) {
            ForEach(viewModel.products, id: \.self) { product in
                CardProductView(product: product,
                                productStyle: productStyle,
                                configuration: configuration,
                                selectedProductId: $selectedProductId,
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
                                selectedProductId: $selectedProductId,
                )
            }
        }
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
