//
//  ListProductView.swift

import SwiftUI
import StoreKit

struct ListProductView: View {

    // MARK: Inputs
    let product: Product
    let productStyle: IQPaywallConfiguration.Product
    let tintColor: Color
    @Binding var selectedProductId: String?
    let isActive: Bool

    var body: some View {
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

                Text(descriptionText)
                    .font(Font(productStyle.descriptionStyle.font))
                    .foregroundColor(product.id == selectedProductId ? .white : Color(uiColor: productStyle.descriptionStyle.color))
                    .truncationMode(.tail)
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
                            Text("per " + billingText(for: period))
                        } else {
                            Text("")
                        }
                    case .nonRenewable:
                        if let period = product.subscription?.subscriptionPeriod {
                            Text("a " + billingText(for: period))
                        } else {
                            Text("")
                        }
                    default:
                        Text("")
                    }
                }
                .font(Font(productStyle.descriptionStyle.font))
                .foregroundColor(product.id == selectedProductId ? .white : Color(uiColor: productStyle.descriptionStyle.color))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                selectedProductId = product.id
                HapticGenerator.shared.selectionChanged()
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
        )
        .animation(.easeInOut(duration: 0.1), value: product.id == selectedProductId)
    }

    // MARK: Helpers

    private var descriptionText: String {
        product.description
    }

    private func billingText(for period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day: "Day"
        case .week: "Week"
        case .month: "Month"
        case .year:  "Year"
        default:     ""
        }
    }
}
