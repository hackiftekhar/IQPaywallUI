//
//  ProductPriceColumn.swift

import SwiftUI
import StoreKit
import IQPurchaseKit

internal struct ProductPriceColumn: View {

    let product: ProductInfo
    let productStyle: PaywallConfiguration.Product
    let textFormatting: any PaywallTextFormatting
    let alignment: HorizontalAlignment
    let priceColor: Color
    let periodColor: Color

    private var hasEligibleIntroductoryOffer: Bool {
        product.shouldDisplayIntroductoryOffer && !product.isActive
    }

    private var mutedPriceColor: Color {
        priceColor.opacity(0.55)
    }

    var body: some View {
        Group {
            if hasEligibleIntroductoryOffer,
               let offer = product.subscription?.introductoryOffer {
                introPriceColumn(texts: textFormatting.introductoryOfferPriceColumn(for: product, offer: offer))
            } else {
                regularPriceColumn(texts: textFormatting.regularPriceColumn(for: product))
            }
        }
    }

    private func regularPriceColumn(texts: PaywallPriceColumnTexts) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(texts.primaryPrice)
                .font(productStyle.priceStyle.font.swiftUIFont)
                .foregroundColor(priceColor)

            if let cadence = texts.cadence {
                Text(cadence)
                    .font(productStyle.subscriptionPeriodStyle.font.swiftUIFont)
                    .foregroundColor(periodColor)
            }
        }
    }

    @ViewBuilder
    private func introPriceColumn(texts: PaywallPriceColumnTexts) -> some View {
        VStack(alignment: alignment, spacing: 3) {
            if let strikethroughPrice = texts.strikethroughPrice {
                Text(strikethroughPrice)
                    .font(productStyle.priceStyle.font.swiftUIFont)
                    .strikethrough()
                    .foregroundColor(mutedPriceColor)
            }

            Text(texts.primaryPrice)
                .font(productStyle.priceStyle.font.swiftUIFont.weight(.bold))
                .foregroundColor(priceColor)

            if let cadence = texts.cadence {
                Text(cadence)
                    .font(productStyle.subscriptionPeriodStyle.font.swiftUIFont)
                    .foregroundColor(periodColor)
            }

            if let footnote = texts.footnote {
                Text(footnote)
                    .font(productStyle.subscriptionPeriodStyle.font.swiftUIFont.weight(.medium))
                    .multilineTextAlignment(textAlignment)
                    .foregroundColor(periodColor)
            }
        }
    }

    private var textAlignment: TextAlignment {
        alignment == .trailing ? .trailing : .leading
    }
}
