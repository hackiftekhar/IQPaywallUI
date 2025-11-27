//
//  CombinedGlassBackground.swift

import SwiftUI

struct BackwardCompatibleGlassEffect: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 25))
        } else {
            content
        }
    }
}

extension View {
    func backwardCompatibleGlassEffect() -> some View {
        self.modifier(BackwardCompatibleGlassEffect())
    }
}

extension Button {
    @ViewBuilder
    func defaultGlassStyle() -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent)
        } else {
            self.buttonStyle(.borderedProminent)
        }
    }
}
