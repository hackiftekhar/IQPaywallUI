//
//  ProductPriceColumn.swift

import SwiftUI
import StoreKit
import IQPurchaseKit

internal struct ProductPriceColumn: View {

    let product: ProductInfo
    let productStyle: PaywallConfiguration.Product
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
                introPriceColumn(offer: offer)
            } else {
                regularPriceColumn
            }
        }
    }

    private var regularPriceColumn: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(compactPrice(product.displayPrice))
                .font(productStyle.priceStyle.font.swiftUIFont)
                .foregroundColor(priceColor)

            if let period = product.subscriptionPeriodDescription {
                Text(period)
                    .font(productStyle.subscriptionPeriodStyle.font.swiftUIFont)
                    .foregroundColor(periodColor)
            }
        }
    }

    @ViewBuilder
    private func introPriceColumn(offer: ProductInfo.SubscriptionOffer) -> some View {
        let cadence = product.subscriptionPeriodDescription
        let duration = offer.durationDescription

        VStack(alignment: alignment, spacing: 3) {
            switch offer.paymentMode {
            case .payUpFront:
                Text(compactPrice(product.displayPrice))
                    .font(productStyle.priceStyle.font.swiftUIFont)
                    .strikethrough()
                    .foregroundColor(mutedPriceColor)

                if let equivalentPrice = product.comparableIntroDisplayPrice {
                    Text(compactPrice(equivalentPrice))
                        .font(productStyle.priceStyle.font.swiftUIFont.weight(.bold))
                        .foregroundColor(priceColor)
                }

                if let cadence {
                    Text(cadence)
                        .font(productStyle.subscriptionPeriodStyle.font.swiftUIFont)
                        .foregroundColor(periodColor)
                }

                Text("\(compactPrice(offer.displayPrice)) \(String(localized: "for first")) \(duration)")
                    .font(productStyle.subscriptionPeriodStyle.font.swiftUIFont.weight(.medium))
                    .multilineTextAlignment(textAlignment)
                    .foregroundColor(periodColor)

            case .payAsYouGo:
                Text(compactPrice(product.displayPrice))
                    .font(productStyle.priceStyle.font.swiftUIFont)
                    .strikethrough()
                    .foregroundColor(mutedPriceColor)

                Text(compactPrice(product.comparableIntroDisplayPrice ?? offer.displayPrice))
                    .font(productStyle.priceStyle.font.swiftUIFont.weight(.bold))
                    .foregroundColor(priceColor)

                if let cadence {
                    Text(cadence)
                        .font(productStyle.subscriptionPeriodStyle.font.swiftUIFont)
                        .foregroundColor(periodColor)
                }

                Text("\(String(localized: "for first")) \(duration)")
                    .font(productStyle.subscriptionPeriodStyle.font.swiftUIFont.weight(.medium))
                    .foregroundColor(periodColor)

            case .freeTrial:
                Text(compactPrice(product.displayPrice))
                    .font(productStyle.priceStyle.font.swiftUIFont.weight(.bold))
                    .foregroundColor(priceColor)

                if let cadence {
                    Text(cadence)
                        .font(productStyle.subscriptionPeriodStyle.font.swiftUIFont)
                        .foregroundColor(periodColor)
                }

                Text("\(String(localized: "Free for first")) \(duration)")
                    .font(productStyle.subscriptionPeriodStyle.font.swiftUIFont.weight(.medium))
                    .foregroundColor(periodColor)

            default:
                regularPriceColumn
            }
        }
    }

    private var textAlignment: TextAlignment {
        alignment == .trailing ? .trailing : .leading
    }

    private func compactPrice(_ price: String) -> String {
        price.replacingOccurrences(of: ".00", with: "")
    }
}
