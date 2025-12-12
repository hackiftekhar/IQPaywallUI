//
//  OfferCodeRedemptionCompatibility.swift
//  Pods
//
//  Created by Iftekhar on 12/12/25.
//

import SwiftUI
import StoreKit

private struct OfferCodeRedemptionCompatibility: ViewModifier {
    
    // The binding to control the sheet presentation
    @Binding var isPresented: Bool
    
    // The closure to execute when the redemption attempt completes
    let onCompletion: (Result<Void, Error>) -> Void

    // A flag used for imperative presentation on older OS versions
    @State private var shouldPresentLegacySheet = false
    
    // Fallback error for older OS where completion is not provided by Apple
    enum RedemptionError: Error {
        case legacySheetPresentedSuccessfully
    }

    func body(content: Content) -> some View {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            // --- iOS 16.0+ (Modern Declarative API) ---
            content
                .offerCodeRedemption(isPresented: $isPresented, onCompletion: onCompletion)
        } else {
            // --- iOS 14.0 & 15.0 (Imperative Fallback) ---
            content
                // 1. Monitor the binding change to trigger the legacy presentation
                .onChange(of: isPresented) { newValue in
                    if newValue {
                        SKPaymentQueue.default().presentCodeRedemptionSheet()
                        isPresented = false
                        onCompletion(.failure(RedemptionError.legacySheetPresentedSuccessfully))
                    }
                }
        }
    }
}

extension View {
    func offerCodeRedemptionCompatibility(isPresented: Binding<Bool>, onCompletion: @escaping ((Result<Void, Error>) -> Void)) -> some View {
        modifier(OfferCodeRedemptionCompatibility(isPresented: isPresented, onCompletion: onCompletion))
    }
}
