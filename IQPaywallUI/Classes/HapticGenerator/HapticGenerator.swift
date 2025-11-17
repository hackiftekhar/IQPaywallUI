//
//  HapticGenerator.swift

import UIKit

/// Simple, centralized haptic feedback manager
@objc final class HapticGenerator: NSObject {

    @objc static let shared = HapticGenerator()

    private override init() {
        super.init()
        prepare()
    }

    private let impactLight  = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy  = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft   = UIImpactFeedbackGenerator(style: .soft)
    private let impactRigid  = UIImpactFeedbackGenerator(style: .rigid)

    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator    = UISelectionFeedbackGenerator()

    // MARK: - Public Methods

    /// Prepare haptics early (e.g. viewDidAppear) for smoother feel
    private func prepare() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactSoft.prepare()
        impactRigid.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }

    /// Subtle tap feedback
    @objc func lightImpact() {
        impactLight.impactOccurred()
    }

    /// Medium feedback (default UI tap feel)
    @objc func mediumImpact() {
        impactMedium.impactOccurred()
    }

    /// Strong feedback (confirm actions)
    @objc func heavyImpact() {
        impactHeavy.impactOccurred()
    }

    /// Softer version of light feedback
    @objc func softImpact() {
        impactSoft.impactOccurred()
    }

    /// Harder version of heavy feedback
    @objc func rigidmpact() {
        impactRigid.impactOccurred()
    }
}

extension HapticGenerator {

    /// Success-type notification haptic
    @objc func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    /// Warning-type notification haptic
    @objc func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    /// Error-type notification haptic
    @objc func error() {
        notificationGenerator.notificationOccurred(.error)
    }
}

extension HapticGenerator {

    /// Selection change feedback (used in pickers, segmented controls)
    @objc func selectionChanged() {
        selectionGenerator.selectionChanged()
    }
}
