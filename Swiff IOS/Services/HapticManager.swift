//
//  HapticManager.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Centralized haptic feedback management
//

import UIKit
import SwiftUI
import Combine

// MARK: - Haptic Manager

class HapticManager {
    static let shared = HapticManager()

    private init() {}

    // MARK: - Impact Feedback

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    func light() {
        impact(.light)
    }
    
    func lightImpact() {
        impact(.light)
    }

    func medium() {
        impact(.medium)
    }

    func heavy() {
        impact(.heavy)
    }

    func soft() {
        if #available(iOS 13.0, *) {
            impact(.soft)
        } else {
            impact(.light)
        }
    }

    func rigid() {
        if #available(iOS 13.0, *) {
            impact(.rigid)
        } else {
            impact(.medium)
        }
    }

    // MARK: - Notification Feedback

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    func success() {
        notification(.success)
    }

    func warning() {
        notification(.warning)
    }

    func error() {
        notification(.error)
    }

    // MARK: - Selection Feedback

    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    // MARK: - Context-Specific Feedback

    /// Called when user taps a button
    func buttonTap() {
        light()
    }

    /// Called when user performs a destructive action
    func destructiveAction() {
        medium()
    }

    /// Called when an operation completes successfully
    func operationSuccess() {
        success()
    }

    /// Called when an operation fails
    func operationFailed() {
        error()
    }

    /// Called when user changes a selection (picker, toggle, etc.)
    func selectionChanged() {
        selection()
    }

    /// Called when user pulls to refresh
    func pullToRefresh() {
        medium()
    }

    /// Called when user adds a new item
    func itemAdded() {
        medium()
    }

    /// Called when user deletes an item
    func itemDeleted() {
        heavy()
    }

    /// Called when user swipes to perform an action
    func swipeAction() {
        soft()
    }

    /// Called when user navigates to a new screen
    func navigation() {
        soft()
    }

    /// Called when showing an alert or important message
    func alert() {
        warning()
    }
}

// MARK: - View Extension for Haptic Feedback

extension View {
    /// Adds haptic feedback to a tap gesture
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    HapticManager.shared.impact(style)
                }
        )
    }

    /// Adds selection haptic feedback on change
    func hapticSelectionOnChange<V: Equatable>(of value: V) -> some View {
        self.onChange(of: value) { _, _ in
            HapticManager.shared.selection()
        }
    }
}

// MARK: - Button Style with Haptic Feedback

struct HapticButtonStyle: ButtonStyle {
    let feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle

    init(feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        self.feedbackStyle = feedbackStyle
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue {
                    HapticManager.shared.impact(feedbackStyle)
                }
            }
    }
}

extension ButtonStyle where Self == HapticButtonStyle {
    static var haptic: HapticButtonStyle {
        HapticButtonStyle()
    }

    static func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) -> HapticButtonStyle {
        HapticButtonStyle(feedbackStyle: style)
    }
}
