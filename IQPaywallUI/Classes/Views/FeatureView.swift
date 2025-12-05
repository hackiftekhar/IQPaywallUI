//
//  FeatureView.swift

import SwiftUI
import StoreKit

internal struct FeatureView: View {

    // MARK: Inputs
    let feature: PaywallConfiguration.Feature

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(feature.titles, id: \.self) { title in
                HStack(spacing: 20) {
                    if let icon = feature.icon {
                        Image(uiImage: icon.icon.withRenderingMode(.alwaysTemplate))
                            .foregroundStyle(icon.color.swiftUIColor)
                            .imageScale(.large)
                    }
                    Text(title)
                        .font(feature.style.font.swiftUIFont)
                        .foregroundStyle(feature.style.color.swiftUIColor)
                }
            }
        }
    }
}
