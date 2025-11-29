//
//  UnifiedListRow.swift
//  Swiff IOS
//
//  Created for Unified List Design System
//  Base row component for all list views (Feed, People, Groups, Subscriptions)
//

import SwiftUI

// MARK: - Unified List Row

/// Base unified list row component used across all list views.
/// Provides consistent layout with:
/// - Icon area (48x48)
/// - Title + Subtitle (left-aligned)
/// - Value + Label (right-aligned)
/// - Optional chevron for navigation
struct UnifiedListRow<IconContent: View>: View {
    // Required parameters
    let title: String
    let subtitle: String
    let value: String
    let valueColor: Color

    // Optional parameters
    var valueLabel: String? = nil
    var showChevron: Bool = false

    // Icon content builder
    @ViewBuilder let iconContent: () -> IconContent

    // Animation state
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 16) {
            // Icon Area (48x48)
            iconContent()

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

            Spacer()

            // Value Area
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.spotifyNumberMedium)
                    .foregroundColor(valueColor)

                if let label = valueLabel {
                    Text(label)
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText)
                }
            }

            // Optional Chevron
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.wiseSecondaryText)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseCardBackground)
        )
        .subtleShadow()
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
}

// MARK: - Currency Formatting Helper

/// Helper function for formatting currency values consistently
func formatCurrency(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "USD"
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
}

/// Helper function for formatting currency with sign
func formatCurrencyWithSign(_ amount: Double, isExpense: Bool) -> String {
    let sign = isExpense ? "- " : "+ "
    return sign + formatCurrency(abs(amount))
}

// MARK: - Preview

#Preview("Unified List Row") {
    ScrollView {
        VStack(spacing: 12) {
            Text("UnifiedListRow Examples")
                .font(.headline)
                .padding()

            // Income example - GREEN
            UnifiedListRow(
                title: "Employer Inc. Payroll",
                subtitle: "Salary / Income",
                value: "+ $3,500.00",
                valueColor: .wiseBrightGreen,
                valueLabel: "9:00 AM"
            ) {
                UnifiedIconCircle(icon: "dollarsign.circle.fill", color: .wiseBrightGreen)
            }
            .padding(.horizontal, 16)

            // Expense example - RED
            UnifiedListRow(
                title: "Starbucks Coffee Company",
                subtitle: "Food & Drink",
                value: "- $6.45",
                valueColor: .wiseError,
                valueLabel: "2:30 PM"
            ) {
                UnifiedIconCircle(icon: "cup.and.saucer.fill", color: .orange)
            }
            .padding(.horizontal, 16)

            // Shopping expense - RED
            UnifiedListRow(
                title: "Target Store #1234",
                subtitle: "Shopping",
                value: "- $89.20",
                valueColor: .wiseError,
                valueLabel: "Yesterday"
            ) {
                UnifiedIconCircle(icon: "cart.fill", color: .pink)
            }
            .padding(.horizontal, 16)

            // Transfer - Neutral
            UnifiedListRow(
                title: "Transfer from Savings",
                subtitle: "Transfers",
                value: "+ $200.00",
                valueColor: .wiseBrightGreen
            ) {
                UnifiedIconCircle(icon: "arrow.left.arrow.right", color: .gray)
            }
            .padding(.horizontal, 16)

            // Subscription example
            UnifiedListRow(
                title: "Netflix Premium",
                subtitle: "Entertainment",
                value: "$15.99",
                valueColor: .wisePrimaryText,
                valueLabel: "/month"
            ) {
                UnifiedIconCircle(icon: "tv.fill", color: .red)
            }
            .padding(.horizontal, 16)

            // Person example
            UnifiedListRow(
                title: "John Doe",
                subtitle: "john@email.com",
                value: "+ $50.00",
                valueColor: .wiseBrightGreen,
                valueLabel: "owes you"
            ) {
                UnifiedIconCircle(icon: "person.fill", color: .wiseBlue)
            }
            .padding(.horizontal, 16)

            // With chevron
            UnifiedListRow(
                title: "View All Transactions",
                subtitle: "See complete history",
                value: "",
                valueColor: .wisePrimaryText,
                showChevron: true
            ) {
                UnifiedIconCircle(icon: "list.bullet", color: .wiseBrightGreen)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical)
    }
    .background(Color.wiseBackground)
}
