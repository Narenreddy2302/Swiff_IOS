//
//  AddTransactionButton.swift
//  Swiff IOS
//
//  Green "+" button for adding transactions in conversation input area
//  Features: Scale animation, haptic feedback, responsive sizing
//

import SwiftUI

// MARK: - Add Transaction Button

/// A green circular/pill button for adding transactions
/// Adapts to compact vs regular horizontal size class
struct AddTransactionButton: View {
    let action: () -> Void
    var isCompact: Bool = true
    var showLabel: Bool = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Body

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.medium)
            action()
        }) {
            if showLabel || horizontalSizeClass == .regular {
                // Full button with label
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))

                    Text("Add")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.wiseBrightGreen)
                .clipShape(Capsule())
            } else {
                // Icon-only button
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: isCompact ? 28 : 32))
                    .foregroundColor(.wiseBrightGreen)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Transaction Type Button

/// Button for selecting transaction type (They Owe Me / I Owe)
struct TransactionTypeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))

                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .wisePrimaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.wiseBrightGreen : Color(UIColor.systemGray6))
            .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Quick Action Pill

/// A pill-shaped quick action button for the input area
struct QuickActionPill: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))

                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(color)
            .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Preview

#Preview("Add Transaction Buttons") {
    VStack(spacing: 20) {
        // Icon-only (compact)
        AddTransactionButton(action: {}, isCompact: true)

        // Icon-only (larger)
        AddTransactionButton(action: {}, isCompact: false)

        // With label
        AddTransactionButton(action: {}, showLabel: true)

        Divider()

        // Transaction type buttons
        HStack(spacing: 12) {
            TransactionTypeButton(
                title: "They Owe Me",
                icon: "arrow.down.circle.fill",
                isSelected: true,
                action: {}
            )

            TransactionTypeButton(
                title: "I Owe",
                icon: "arrow.up.circle.fill",
                isSelected: false,
                action: {}
            )
        }

        Divider()

        // Quick action pills
        HStack(spacing: 12) {
            QuickActionPill(
                title: "Split Bill",
                icon: "rectangle.split.2x1",
                color: .wiseBlue,
                action: {}
            )

            QuickActionPill(
                title: "Request",
                icon: "dollarsign.circle",
                color: .wiseBrightGreen,
                action: {}
            )

            QuickActionPill(
                title: "Settle",
                icon: "checkmark.circle",
                color: .wiseWarning,
                action: {}
            )
        }
    }
    .padding()
    .background(Color.wiseBackground)
}
