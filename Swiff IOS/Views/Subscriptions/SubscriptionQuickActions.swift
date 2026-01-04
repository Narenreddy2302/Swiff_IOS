//
//  SubscriptionQuickActions.swift
//  Swiff IOS
//
//  Quick action buttons for subscription detail view
//  Follows PersonQuickActionButton pattern
//

import SwiftUI

// MARK: - Subscription Quick Action Button

struct SubscriptionQuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            guard !isDisabled else { return }
            HapticManager.shared.impact(.medium)
            action()
        }) {
            VStack(spacing: 8) {
                Circle()
                    .fill(isDisabled ? Color.wiseBorder.opacity(0.3) : color.opacity(0.15))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundColor(isDisabled ? .wiseSecondaryText : color)
                    )
                    .shadow(color: isDisabled ? Color.clear : color.opacity(0.2), radius: 8, x: 0, y: 4)

                Text(title)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(isDisabled ? .wiseSecondaryText : .wisePrimaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

// MARK: - Subscription Quick Actions Section

struct SubscriptionQuickActionsSection: View {
    let subscription: Subscription

    // Callbacks for actions
    let onPauseResume: () -> Void
    let onRemind: () -> Void
    let onUsage: () -> Void
    let onWebsite: () -> Void
    var onShare: (() -> Void)? = nil

    // Computed properties
    private var isPaused: Bool {
        !subscription.isActive && subscription.cancellationDate == nil
    }

    private var isCancelled: Bool {
        subscription.cancellationDate != nil
    }

    private var hasWebsite: Bool {
        guard let website = subscription.website else { return false }
        return !website.isEmpty
    }

    private var isAlreadyShared: Bool {
        subscription.isShared
    }

    var body: some View {
        VStack(spacing: 16) {
            // Row 1: 4 quick action buttons
            HStack(spacing: 0) {
                // 1. Pause/Resume Button
                pauseResumeButton

                // 2. Remind Button
                SubscriptionQuickActionButton(
                    icon: "bell.fill",
                    title: "Remind",
                    color: .wiseBlue,
                    isDisabled: isCancelled,
                    action: onRemind
                )

                // 3. Share Button
                SubscriptionQuickActionButton(
                    icon: isAlreadyShared ? "person.2.fill" : "person.badge.plus",
                    title: isAlreadyShared ? "Shared" : "Share",
                    color: Theme.Colors.brandPrimary,
                    isDisabled: isCancelled || isAlreadyShared,
                    action: { onShare?() }
                )

                // 4. Website Button
                SubscriptionQuickActionButton(
                    icon: "globe",
                    title: "Website",
                    color: .wiseOrange,
                    isDisabled: !hasWebsite,
                    action: onWebsite
                )
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var pauseResumeButton: some View {
        if isCancelled {
            // Cancelled state - disabled pause button
            SubscriptionQuickActionButton(
                icon: "pause.circle.fill",
                title: "Paused",
                color: .wiseWarning,
                isDisabled: true,
                action: {}
            )
        } else if isPaused {
            // Paused state - show resume button
            SubscriptionQuickActionButton(
                icon: "play.circle.fill",
                title: "Resume",
                color: .wiseBrightGreen,
                action: onPauseResume
            )
        } else {
            // Active state - show pause button
            SubscriptionQuickActionButton(
                icon: "pause.circle.fill",
                title: "Pause",
                color: .wiseWarning,
                action: onPauseResume
            )
        }
    }
}

// MARK: - Preview

#Preview("Quick Actions - Active") {
    VStack {
        SubscriptionQuickActionsSection(
            subscription: MockData.activeSubscription,
            onPauseResume: { print("Pause/Resume") },
            onRemind: { print("Remind") },
            onUsage: { print("Usage") },
            onWebsite: { print("Website") }
        )
    }
    .padding()
    .background(Color.wiseBackground)
}
