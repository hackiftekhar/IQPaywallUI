//
//  CardProductView.swift

import SwiftUI
import StoreKit

struct CardProductView: View {

    // MARK: Inputs
    let product: Product
    let productStyle: IQPaywallConfiguration.Product
    let tintColor: Color
    @Binding var selectedProductId: String?
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            Text(product.displayName)
                .font(Font(productStyle.nameStyle.font))
                .foregroundColor(product.id == selectedProductId ? .white : Color(uiColor: productStyle.nameStyle.color))

            Text(product.displayPrice)
                .font(Font(productStyle.priceStyle.font))
                .foregroundColor(product.id == selectedProductId ? .white : Color(uiColor: productStyle.priceStyle.color))

            Group {
                if let period = product.subscription?.subscriptionPeriod {
                    Text(billingText(for: period))
                } else {
                    Text("")
                        .opacity(0.0)
                }
            }
            .font(Font(productStyle.subscriptionPeriodStyle.font))
            .foregroundColor(product.id == selectedProductId ? .white : Color(uiColor: productStyle.subscriptionPeriodStyle.color))

            Text(product.description)
                .lineLimit(5)
                .font(Font(productStyle.descriptionStyle.font))
                .foregroundColor(product.id == selectedProductId ? .white : Color(uiColor: productStyle.descriptionStyle.color))
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .onTapGesture {
            withAnimation {
                selectedProductId = product.id
                HapticGenerator.shared.selectionChanged()
            }
        }
        .contentShape(Rectangle())
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(product.id == selectedProductId ? tintColor : tintColor.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(product.id == selectedProductId ? tintColor : Color.clear, lineWidth: 2)
        )
        .overlay(alignment: .top) {
            if isActive {
                Text("Current")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(tintColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(tintColor, lineWidth: 2)
                            )
                    )
                    .offset(y: -8)
            }
        }
        .scaleEffect(product.id == selectedProductId ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: product.id == selectedProductId)
    }

    // MARK: Helpers

    private var descriptionText: String {
        product.description
    }

    private func billingText(for period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .month: "Per Month"
        case .year:  "Per Year"
        default:     ""
        }
    }
}
