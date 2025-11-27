//
//  ListProductView.swift

import SwiftUI
import StoreKit

internal struct ListProductView: View {

    // MARK: Inputs
    let product: Product
    let productStyle: PaywallConfiguration.Product
    let tintColor: Color
    @Binding var selectedProductId: String?
    let isActive: Bool

    var body: some View {
        Button {
            onSelectAction()
        } label: {
            HStack(alignment: .center) {

                Image(systemName: product.id == selectedProductId ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
                    .foregroundStyle(product.id == selectedProductId ? .white : tintColor)

                VStack(alignment: .leading) {
                    HStack {
                        Text(product.displayName)
                            .font(Font(productStyle.nameStyle.font))
                            .foregroundColor(product.id == selectedProductId ? .white : Color(uiColor: productStyle.nameStyle.color))
                        if isActive {
                            Text("(Current)")
                                .font(Font(productStyle.descriptionStyle.font))
                                .foregroundColor(product.id == selectedProductId ? .white : Color(uiColor: productStyle.descriptionStyle.color))
                        }
                        Spacer()
                    }

                     Text(product.description)
                        .multilineTextAlignment(.leading)
                        .font(Font(productStyle.descriptionStyle.font))
                        .foregroundColor(product.id == selectedProductId ? .white : Color(uiColor: productStyle.descriptionStyle.color))
                        .truncationMode(.tail)

                    if let snapshot = PurchaseStatusManager.shared.snapshot(for: product.id),
                       !snapshot.isActive,
                       let subscription = product.subscription,
                        let introOffer = subscription.introductoryOffer,
                           snapshot.isEligibleForIntroOffer {
                        VStack(alignment: .leading) {
                            Text(introOffer.formatted)
                                .font(Font(productStyle.subscriptionPeriodStyle.font))
                                .foregroundStyle(product.id == selectedProductId ? .white : Color(uiColor: productStyle.subscriptionPeriodStyle.color))
    //                        Text("No commitment. Cancel anytime.")
    //                            .font(Font(productStyle.subscriptionPeriodStyle.font))
    //                            .foregroundStyle(Color(productStyle.subscriptionPeriodStyle.color))
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(product.displayPrice)
                        .font(Font(productStyle.priceStyle.font))
                        .foregroundColor(product.id == selectedProductId ? .white : Color(uiColor: productStyle.priceStyle.color))
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
                    .font(Font(productStyle.subscriptionPeriodStyle.font))
                    .foregroundColor(product.id == selectedProductId ? .white : Color(uiColor: productStyle.subscriptionPeriodStyle.color))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 25)
                .stroke(tintColor, lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(tintColor.opacity(product.id == selectedProductId ? 1.0 : 0.05))
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
