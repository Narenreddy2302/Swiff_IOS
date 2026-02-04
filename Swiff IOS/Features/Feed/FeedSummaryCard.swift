//
//  FeedSummaryCard.swift
//  Swiff IOS
//
//  Professional summary card showing balance overview at top of feed
//  Features: Total balance, you owe, they owe with animated counters
//  Created: 2026-02-04
//

import SwiftUI

// MARK: - Feed Summary Card

/// Shows a quick overview of balances at the top of the Twitter-style feed
struct FeedSummaryCard: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var dataManager: DataManager
    @State private var animateIn = false
    
    // MARK: - Computed Properties
    
    private var totalYouOwe: Double {
        dataManager.people
            .filter { $0.balance < 0 }
            .reduce(0) { $0 + abs($1.balance) }
    }
    
    private var totalTheyOwe: Double {
        dataManager.people
            .filter { $0.balance > 0 }
            .reduce(0) { $0 + $1.balance }
    }
    
    private var netBalance: Double {
        totalTheyOwe - totalYouOwe
    }
    
    private var netBalanceColor: Color {
        if netBalance > 0 {
            return Theme.Colors.amountPositive
        } else if netBalance < 0 {
            return Theme.Colors.amountNegative
        }
        return Theme.Colors.textSecondary
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            // Net Balance
            VStack(spacing: 4) {
                Text("Net Balance")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Text(formatCurrency(netBalance))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(netBalanceColor)
            }
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : -10)
            .animation(.spring(response: 0.4).delay(0.1), value: animateIn)
            
            // You Owe / They Owe
            HStack(spacing: 20) {
                // You Owe
                BalancePill(
                    icon: "arrow.up.circle.fill",
                    label: "You owe",
                    amount: totalYouOwe,
                    color: Theme.Colors.amountNegative
                )
                .opacity(animateIn ? 1 : 0)
                .offset(x: animateIn ? 0 : -20)
                .animation(.spring(response: 0.4).delay(0.2), value: animateIn)
                
                // Divider
                Rectangle()
                    .fill(Theme.Colors.border)
                    .frame(width: 1, height: 40)
                
                // They Owe
                BalancePill(
                    icon: "arrow.down.circle.fill",
                    label: "They owe",
                    amount: totalTheyOwe,
                    color: Theme.Colors.amountPositive
                )
                .opacity(animateIn ? 1 : 0)
                .offset(x: animateIn ? 0 : 20)
                .animation(.spring(response: 0.4).delay(0.3), value: animateIn)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Theme.Colors.cardBackground,
                    Theme.Colors.cardBackground.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.Colors.border.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .onAppear {
            withAnimation {
                animateIn = true
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = UserSettings.shared.selectedCurrency
        
        let prefix = amount >= 0 ? "+" : ""
        if let formatted = formatter.string(from: NSNumber(value: abs(amount))) {
            return amount >= 0 ? "+\(formatted)" : "-\(formatted)"
        }
        return "$0.00"
    }
}

// MARK: - Balance Pill

struct BalancePill: View {
    let icon: String
    let label: String
    let amount: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            Text(formatCurrency(amount))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = UserSettings.shared.selectedCurrency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Preview

#Preview {
    VStack {
        FeedSummaryCard()
            .padding()
        Spacer()
    }
    .background(Theme.Colors.background)
    .environmentObject(DataManager.shared)
}
