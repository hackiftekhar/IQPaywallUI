//
//  CardProductView.swift

import SwiftUI
import StoreKit

internal struct CardProductView: View {

    // MARK: Inputs
    let product: ProductInfo
    let productStyle: PaywallConfiguration.Product
    let configuration: PaywallConfiguration
    @Binding var selectedProductId: String?
    let isOnlyAvailableProduct: Bool

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
            VStack(alignment: .leading, spacing: 6) {

                Text(product.displayName)
                    .font(productStyle.nameStyle.font.swiftUIFont)
                    .foregroundColor(titleForegroundColor)

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

                Text(product.description)
                    .lineLimit(5)
                    .multilineTextAlignment(.leading)
                    .font(productStyle.descriptionStyle.font.swiftUIFont)
                    .foregroundColor(descriptionColor)
                    .truncationMode(.tail)
            }
            .padding(5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .stroke(configuration.foregroundColor.swiftUIColor, lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(configuration.foregroundColor.swiftUIColor.opacity(product.id == selectedProductId ? 1.0 : 0.05))
                )
                .backwardCompatibleGlassEffect()
        )
        .overlay(alignment: .top) {
            if product.status != .inactive {
                Text(product.status.displayName)
                    .font(productStyle.nameStyle.font.withSize(10).swiftUIFont)
                    .foregroundColor(product.id == selectedProductId ? configuration.foregroundColor.swiftUIColor : configuration.backgroundColor.swiftUIColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(configuration.foregroundColor.swiftUIColor, lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(titleForegroundColor)
                            )
                    )
                    .offset(y: -8)
            }
        }
        .scaleEffect((product.id == selectedProductId && !isOnlyAvailableProduct) ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: product.id == selectedProductId)
    }


    private func onSelectAction() {
        withAnimation {
            selectedProductId = product.id
            HapticGenerator.shared.selectionChanged()
        }
    }
}
