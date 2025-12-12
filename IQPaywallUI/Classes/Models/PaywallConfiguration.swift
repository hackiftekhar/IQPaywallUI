//
//  PaywallConfiguration.swift

public struct PaywallConfiguration {

    public var elements: [Element]

    public var productIds: [String]
    public var recommendedProductId: String?

    public var actionButton: ActionButton

    public var backgroundColor: UIColor
    public var foregroundColor: UIColor
    public var linkStyle: LabelStyle
    public var terms: Link?
    public var privacyPolicy: Link?
    public var canRedeemOfferCode: Bool

    public init(productIds: [String] = [],
                recommendedProductId: String? = nil,
                elements: [Element] = [],
                actionButton: ActionButton = .init(),
                backgroundColor: UIColor = UIColor.systemBackground,
                foregroundColor: UIColor = UIColor.systemBlue,
                linkStyle: LabelStyle = .init(font: UIFont.preferredFont(forTextStyle: .footnote)),
                canRedeemOfferCode: Bool = false) {
        self.productIds = productIds
        self.recommendedProductId = recommendedProductId
        self.elements = elements
        self.actionButton = actionButton
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.linkStyle = linkStyle
        self.canRedeemOfferCode = canRedeemOfferCode
    }
}

extension PaywallConfiguration {

    public struct LabelStyle: Equatable, Hashable {
        public var font: UIFont
        public var color: UIColor?

        public init(font: UIFont, color: UIColor? = nil) {
            self.font = font
            self.color = color
        }
    }

    public enum Element: Identifiable {
        public var id: ObjectIdentifier {
            switch self {
            case .logo: return ObjectIdentifier(Logo.self)
            case .title: return ObjectIdentifier(Title.self)
            case .subtitle: return ObjectIdentifier(Subtitle.self)
            case .feature: return ObjectIdentifier(Feature.self)
            case .product: return ObjectIdentifier(Product.self)
            }
        }

        case logo(_ logo: Logo)
        case title(_ title: Title)
        case subtitle(_ subtitle: Subtitle)
        case feature(_ feature: Feature)
        case product(_ product: Product)
    }

    public struct Link {
        public var title: String
        public var url: URL

        public init(_ title: String, url: URL) {
            self.title = title
            self.url = url
        }
    }

    public struct Logo {
        public var logo: UIImage
        public var backgroundColor: UIColor

        public init(_ logo: UIImage, backgroundColor: UIColor = UIColor.clear) {
            self.logo = logo
            self.backgroundColor = backgroundColor
        }
    }

    public struct Title {
        public var title: String
        public var style: LabelStyle

        public init(_ title: String,
                    style: LabelStyle = .init(font: UIFont.preferredFont(forTextStyle: .largeTitle))) {
            self.title = title
            self.style = style
        }
    }

    public struct Subtitle {
        public var title: String
        public var style: LabelStyle

        public init(_ title: String,
                    style: LabelStyle = .init(font: UIFont.preferredFont(forTextStyle: .headline))) {
            self.title = title
            self.style = style
        }
    }

    public struct Feature: Hashable {

        public struct Icon: Hashable {
            public var icon: UIImage
            public var color: UIColor?

            public init(_ icon: UIImage, color: UIColor? = nil) {
                self.icon = icon
                self.color = color
            }
        }

        public var titles: [String]
        public var icon: Icon?
        public var style: LabelStyle

        public init(titles: [String],
                    icon: Icon? = nil,
                    style: LabelStyle = .init(font: UIFont.preferredFont(forTextStyle: .callout))) {
            self.titles = titles
            self.icon = icon
            self.style = style
        }
    }

    public struct ActionButton {
        public var nonRenewTitle: String
        public var autoRenewTitle: String
        public var consumableTitle: String
        public var nonConsumableTitle: String
        public var font: UIFont

        public init(nonRenewTitle: String = "Subscribe",
                    autoRenewTitle: String = "Subscribe",
                    consumableTitle: String = "Buy Now",
                    nonConsumableTitle: String = "Unlock Now",
                    font: UIFont = .preferredFont(forTextStyle: .body)) {
            self.nonRenewTitle = nonRenewTitle
            self.autoRenewTitle = autoRenewTitle
            self.consumableTitle = consumableTitle
            self.nonConsumableTitle = nonConsumableTitle
            self.font = font
        }
    }

    public struct Product {

        public enum Style {
            case card
            case list
        }

        public var style: Style
        public var nameStyle: LabelStyle
        public var priceStyle: LabelStyle
        public var subscriptionPeriodStyle: LabelStyle
        public var descriptionStyle: LabelStyle

        public init(style: Style = .card,
                    nameStyle: LabelStyle = .init(font: UIFont.preferredFont(forTextStyle: .title2)),
                    priceStyle: LabelStyle = .init(font: UIFont.preferredFont(forTextStyle: .title1)),
                    subscriptionPeriodStyle: LabelStyle = .init(font: UIFont.preferredFont(forTextStyle: .footnote)),
                    descriptionStyle: LabelStyle = .init(font: UIFont.preferredFont(forTextStyle: .caption1))
        ) {
            self.style = style
            self.nameStyle = nameStyle
            self.priceStyle = priceStyle
            self.subscriptionPeriodStyle = subscriptionPeriodStyle
            self.descriptionStyle = descriptionStyle
        }
    }
}

import SwiftUI
extension UIColor {
    var swiftUIColor: Color {
        Color(uiColor: self)
    }
}

extension UIFont {
    var swiftUIFont: Font {
        Font(self)
    }
}
