//
//  FeatureView.swift

import SwiftUI
import StoreKit

struct FeatureView: View {

    // MARK: Inputs
    let feature: IQPaywallConfiguration.Feature

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(feature.titles, id: \.self) { title in
                HStack(spacing: 20) {
                    if let icon = feature.icon {
                        Image(uiImage: icon.icon.withRenderingMode(.alwaysTemplate))
                            .foregroundStyle(Color(uiColor: icon.color))
                            .imageScale(.large)
                    }
                    Text(title)
                        .font(Font(feature.style.font))
                        .foregroundStyle(Color(uiColor: feature.style.color))
                }
            }
        }
    }
}
