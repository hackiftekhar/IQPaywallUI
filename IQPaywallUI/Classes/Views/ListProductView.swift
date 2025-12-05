//
//  ListProductView.swift

import SwiftUI
import StoreKit
import IQStoreKitManager

internal struct ListProductView: View {

    // MARK: Inputs
    let product: Product
    let productStyle: PaywallConfiguration.Product
    let configuration: PaywallConfiguration
    @Binding var selectedProductId: String?
    let isActive: Bool

    var titleForegroundColor: Color {
        product.id == selectedProductId ? configuration.backgroundColor.swiftUIColor : (productStyle.nameStyle.color?.swiftUIColor ?? configuration.foregroundColor.swiftUIColor)
    }

    var priceForegroundColor: Color {
        product.id == selectedProductId ? configuration.backgroundColor.swiftUIColor : (productStyle.priceStyle.color?.swiftUIColor ?? configuration.foregroundColor.swiftUIColor)
    }

    var subscriptionPeriodColor: Color {
        product.id == selectedProductId ? configuration.backgroundColor.swiftUIColor : (productStyle.subscriptionPeriodStyle.color?.swiftUIColor ?? configuration.foregroundColor.swiftUIColor)
    }

    var descriptionColor: Color {
        product.id == selectedProductId ? configuration.backgroundColor.swiftUIColor : (productStyle.descriptionStyle.color?.swiftUIColor ?? configuration.foregroundColor.swiftUIColor)
    }

    var body: some View {
        Button {
            onSelectAction()
        } label: {
            HStack(alignment: .center) {

                Image(systemName: product.id == selectedProductId ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
                    .foregroundColor(product.id == selectedProductId ? configuration.backgroundColor.swiftUIColor : configuration.foregroundColor.swiftUIColor)

                VStack(alignment: .leading) {
                    HStack {
                        Text(product.displayName)
                            .font(productStyle.nameStyle.font.swiftUIFont)
                            .foregroundColor(titleForegroundColor)
                        if isActive {
                            Text("(Current)")
                                .font(productStyle.descriptionStyle.font.swiftUIFont)
                                .foregroundColor(descriptionColor)
                        }
                        Spacer()
                    }

                     Text(product.description)
                        .multilineTextAlignment(.leading)
                        .font(productStyle.descriptionStyle.font.swiftUIFont)
                        .foregroundColor(descriptionColor)
                        .truncationMode(.tail)

                    if let snapshot = PurchaseStatusManager.shared.snapshot(for: product.id),
                       !snapshot.isActive,
                       let subscription = product.subscription,
                        let introOffer = subscription.introductoryOffer,
                           snapshot.isEligibleForIntroOffer {
                        VStack(alignment: .leading) {
                            Text(introOffer.formatted)
                                .font(productStyle.subscriptionPeriodStyle.font.swiftUIFont)
                                .foregroundColor(subscriptionPeriodColor)
    //                        Text("No commitment. Cancel anytime.")
    //                            .font(Font(productStyle.subscriptionPeriodStyle.font))
    //                            .foregroundStyle(Color(productStyle.subscriptionPeriodStyle.color))
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(product.displayPrice)
                        .font(productStyle.priceStyle.font.swiftUIFont)
                        .foregroundColor(priceForegroundColor)
                    Group {
                        switch product.type {
                        case .consumable:
                            Text("One Time")
                        case .nonConsumable:
                            Text("Lifetime")
                        case .autoRenewable:
                            if let period = product.subscription?.subscriptionPeriod {
                                Text("per " + period.formatted)
                            } else {
                                Text("")
                            }
                        case .nonRenewable:
                            if let period = product.subscription?.subscriptionPeriod {
                                Text("a " + period.formatted)
                            } else {
                                Text("")
                            }
                        default:
                            Text("")
                        }
                    }
                    .font(productStyle.subscriptionPeriodStyle.font.swiftUIFont)
                    .foregroundColor(subscriptionPeriodColor)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 25)
                .stroke(configuration.foregroundColor.swiftUIColor, lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(configuration.foregroundColor.swiftUIColor.opacity(product.id == selectedProductId ? 1.0 : 0.05))
                )
                .backwardCompatibleGlassEffect()
        )
        .animation(.easeInOut(duration: 0.1), value: product.id == selectedProductId)
    }

    private func onSelectAction() {
        withAnimation {
            selectedProductId = product.id
            HapticGenerator.shared.selectionChanged()
        }
    }
}
