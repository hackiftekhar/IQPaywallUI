//
//  ListProductView.swift

import SwiftUI
import StoreKit

internal struct ListProductView: View {

    // MARK: Inputs
    let product: ProductInfo
    let productStyle: PaywallConfiguration.Product
    let configuration: PaywallConfiguration
    @Binding var selectedProductId: String?

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
                        if product.status != .inactive {
                            Text("(\(product.status.displayName))")
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

                    if !product.isActive,
                       let subscription = product.subscription,
                        let introOffer = subscription.introductoryOffer,
                       product.isEligibleForIntroOffer {
                        VStack(alignment: .leading) {
                            Text(introOffer.localizedDescription)
                                .font(productStyle.subscriptionPeriodStyle.font.swiftUIFont)
                                .foregroundColor(subscriptionPeriodColor)

                VStack(alignment: .trailing) {
                    Text(product.displayPrice)
                        .font(productStyle.priceStyle.font.swiftUIFont)
                        .foregroundColor(priceForegroundColor)
                        .strikethrough(product.isEligibleForIntroOffer && product.discountedDisplayPrice != nil)

                    if product.isEligibleForIntroOffer, let discountedDisplayPrice = product.discountedDisplayPrice {
                        Text(discountedDisplayPrice)
                            .font(productStyle.priceStyle.font.swiftUIFont)
                            .foregroundColor(priceForegroundColor)
                    }

                    if let periodDescription = product.subscriptionPeriodDescription {
                        Text(periodDescription)
                            .font(productStyle.subscriptionPeriodStyle.font.swiftUIFont)
                            .foregroundColor(subscriptionPeriodColor)
                    }
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
