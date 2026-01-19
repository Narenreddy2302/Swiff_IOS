//
//  BalanceText.swift
//  Swiff IOS
//
//  Standardized balance display with consistent color coding
//

import SwiftUI

// MARK: - Balance Text

/// Standardized balance text display with proper color coding.
/// Shows "Owes you $X", "You owe $X", or "Settled up" based on balance value.
///
/// Example usage:
/// ```swift
/// BalanceText(balance: person.balance)
/// BalanceText(balance: -50.0, showSettledState: false)
/// ```
struct BalanceText: View {
    let balance: Double?
    var showSettledState: Bool = true
    var font: Font = Theme.Fonts.headerSubtitle

    var body: some View {
        balanceContent
            .font(font)
    }

    @ViewBuilder
    private var balanceContent: some View {
        if let balance = balance {
            if balance > 0 {
                // They owe you money (positive for you)
                Text("Owes you \(formatCurrency(balance))")
                    .foregroundColor(.wiseSecondaryText)
            } else if balance < 0 {
                // You owe them money (negative for you)
                Text("You owe \(formatCurrency(abs(balance)))")
                    .foregroundColor(.wiseError)
            } else if showSettledState {
                // Balance is zero
                Text("Settled up")
                    .foregroundColor(.wiseSecondaryText)
            } else {
                EmptyView()
            }
        } else if showSettledState {
            Text("No pending dues")
                .foregroundColor(.wiseSecondaryText)
        } else {
            EmptyView()
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        amount.asCurrency
    }
}

// MARK: - Balance Status Icon

/// Optional icon to accompany balance text
struct BalanceStatusIcon: View {
    let balance: Double?

    var body: some View {
        if let balance = balance, balance == 0 {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.wiseBrightGreen)
                .font(.caption)
        }
    }
}

// MARK: - Balance Display Row

/// Combines balance text with optional status icon
struct BalanceDisplayRow: View {
    let balance: Double?
    var showIcon: Bool = true
    var font: Font = Theme.Fonts.headerSubtitle

    var body: some View {
        HStack(spacing: 4) {
            BalanceText(balance: balance, font: font)

            if showIcon {
                BalanceStatusIcon(balance: balance)
            }
        }
    }
}

// MARK: - Preview

#Preview("Balance Text Variants") {
    VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 4) {
            Text("Positive Balance (They owe you):")
                .font(.caption)
                .foregroundColor(.gray)
            BalanceText(balance: 125.50)
        }

        VStack(alignment: .leading, spacing: 4) {
            Text("Negative Balance (You owe):")
                .font(.caption)
                .foregroundColor(.gray)
            BalanceText(balance: -50.00)
        }

        VStack(alignment: .leading, spacing: 4) {
            Text("Zero Balance (Settled):")
                .font(.caption)
                .foregroundColor(.gray)
            BalanceText(balance: 0)
        }

        VStack(alignment: .leading, spacing: 4) {
            Text("Nil Balance (No dues):")
                .font(.caption)
                .foregroundColor(.gray)
            BalanceText(balance: nil)
        }

        Divider()

        VStack(alignment: .leading, spacing: 4) {
            Text("With Icon (Zero balance):")
                .font(.caption)
                .foregroundColor(.gray)
            BalanceDisplayRow(balance: 0)
        }

        VStack(alignment: .leading, spacing: 4) {
            Text("With Icon (Has balance):")
                .font(.caption)
                .foregroundColor(.gray)
            BalanceDisplayRow(balance: 75.00)
        }
    }
    .padding()
    .background(Color.wiseBackground)
}
