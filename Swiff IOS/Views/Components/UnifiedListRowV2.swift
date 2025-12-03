//
//  UnifiedListRowV2.swift
//  Swiff IOS
//
//  Created for Unified List View Design System - Phase 1
//  Clean flat design inspired by Wise/Revolut transaction lists
//

import SwiftUI

// MARK: - Unified List Row V2

/// Second generation unified list row with flat design.
/// Key differences from V1:
/// - NO card background or shadow (flat design)
/// - Horizontal padding: 16pt, Vertical padding: 12pt
/// - Cleaner, more minimalist appearance
/// - Used for transaction-like displays
struct UnifiedListRowV2: View {
    // Required parameters
    let iconName: String              // SF Symbol name
    let iconColor: Color              // Icon and background color
    let title: String                 // Main text
    let subtitle: String              // Subtitle (e.g., "← Received – Visa • 3366")
    let value: String                 // Amount or value text
    let valueColor: Color             // Color for value text

    // Optional parameters
    var showChevron: Bool = false     // Show navigation chevron
    var onTap: (() -> Void)? = nil    // Tap handler

    // Animation state
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            // Haptic feedback on tap
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onTap?()
        }) {
            HStack(spacing: 12) {
                // Icon Circle (48x48)
                UnifiedIconCircle(
                    icon: iconName,
                    color: iconColor,
                    size: 48,
                    iconSize: 20
                )

                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                // Value
                Text(value)
                    .font(.spotifyNumberMedium)
                    .foregroundColor(valueColor)
                    .lineLimit(1)

                // Optional Chevron
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - Preview

#Preview("UnifiedListRowV2 Examples") {
    ScrollView {
        VStack(spacing: 0) {
            Text("Transaction List (V2 - Flat Design)")
                .font(.spotifyHeadingLarge)
                .padding()

            // Income transaction - GREEN
            UnifiedListRowV2(
                iconName: "arrow.down.circle.fill",
                iconColor: .wiseBrightGreen,
                title: "Payroll Deposit",
                subtitle: "← Received – Bank Transfer",
                value: "+ $1,246.00",
                valueColor: .wiseBrightGreen,
                showChevron: true,
                onTap: { print("Tapped payroll") }
            )

            Divider()
                .padding(.leading, 76)

            // Expense transaction - DEFAULT
            UnifiedListRowV2(
                iconName: "cart.fill",
                iconColor: .orange,
                title: "Amazon",
                subtitle: "→ Sent – Visa • 3366",
                value: "– $125.20",
                valueColor: .wisePrimaryText,
                showChevron: true,
                onTap: { print("Tapped Amazon") }
            )

            Divider()
                .padding(.leading, 76)

            // Coffee purchase
            UnifiedListRowV2(
                iconName: "cup.and.saucer.fill",
                iconColor: Color(red: 0.894, green: 0.506, blue: 0.251),
                title: "Starbucks",
                subtitle: "→ Sent – Apple Pay",
                value: "– $6.45",
                valueColor: .wisePrimaryText,
                showChevron: true,
                onTap: { print("Tapped Starbucks") }
            )

            Divider()
                .padding(.leading, 76)

            // Transfer
            UnifiedListRowV2(
                iconName: "arrow.left.arrow.right",
                iconColor: .wiseBlue,
                title: "Transfer to Savings",
                subtitle: "→ Transfer – Internal",
                value: "– $200.00",
                valueColor: .wisePrimaryText,
                showChevron: true
            )

            Divider()
                .padding(.leading, 76)

            // Income from friend
            UnifiedListRowV2(
                iconName: "person.fill",
                iconColor: .wisePurple,
                title: "John Doe",
                subtitle: "← Received – Venmo",
                value: "+ $50.00",
                valueColor: .wiseBrightGreen,
                showChevron: true
            )

            Divider()
                .padding(.leading, 76)

            // Gas station
            UnifiedListRowV2(
                iconName: "fuelpump.fill",
                iconColor: Color(red: 0.647, green: 0.165, blue: 0.165),
                title: "Shell Gas Station",
                subtitle: "→ Sent – Mastercard • 4421",
                value: "– $45.80",
                valueColor: .wisePrimaryText,
                showChevron: true
            )

            Divider()
                .padding(.leading, 76)

            // Subscription payment
            UnifiedListRowV2(
                iconName: "tv.fill",
                iconColor: Color.red,
                title: "Netflix",
                subtitle: "→ Sent – Visa • 3366 – Recurring",
                value: "– $15.99",
                valueColor: .wisePrimaryText,
                showChevron: true
            )

            Divider()
                .padding(.leading, 76)

            // Grocery store
            UnifiedListRowV2(
                iconName: "cart.fill",
                iconColor: .wiseBrightGreen,
                title: "Whole Foods Market",
                subtitle: "→ Sent – Debit • 1234",
                value: "– $89.34",
                valueColor: .wisePrimaryText,
                showChevron: true
            )

            Spacer()
        }
    }
    .background(Color.wiseBackground)
}

#Preview("UnifiedListRowV2 Compact") {
    VStack(spacing: 0) {
        UnifiedListRowV2(
            iconName: "dollarsign.circle.fill",
            iconColor: .wiseBrightGreen,
            title: "Salary Payment",
            subtitle: "← Received – Direct Deposit",
            value: "+ $3,500.00",
            valueColor: .wiseBrightGreen,
            showChevron: true
        )

        Divider()
            .padding(.leading, 76)

        UnifiedListRowV2(
            iconName: "cup.and.saucer.fill",
            iconColor: .orange,
            title: "Coffee Shop",
            subtitle: "→ Sent – Apple Pay",
            value: "– $4.50",
            valueColor: .wisePrimaryText,
            showChevron: true
        )
    }
    .background(Color.wiseBackground)
}
