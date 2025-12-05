//
//  HapticGenerator.swift

import UIKit

internal final class HapticGenerator: NSObject {

    static let shared = HapticGenerator()

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
    func lightImpact() {
        impactLight.impactOccurred()
    }

    /// Medium feedback (default UI tap feel)
    func mediumImpact() {
        impactMedium.impactOccurred()
    }

    /// Strong feedback (confirm actions)
    func heavyImpact() {
        impactHeavy.impactOccurred()
    }

    /// Softer version of light feedback
    func softImpact() {
        impactSoft.impactOccurred()
    }

    /// Harder version of heavy feedback
    func rigidmpact() {
        impactRigid.impactOccurred()
    }
}

extension HapticGenerator {

    /// Success-type notification haptic
    func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    /// Warning-type notification haptic
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    /// Error-type notification haptic
    func error() {
        notificationGenerator.notificationOccurred(.error)
    }
}

extension HapticGenerator {

    /// Selection change feedback (used in pickers, segmented controls)
    @objc func selectionChanged() {
        selectionGenerator.selectionChanged()
    }
}
