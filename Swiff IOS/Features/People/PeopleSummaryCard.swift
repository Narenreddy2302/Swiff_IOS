//
//  PeopleSummaryCard.swift
//  Swiff IOS
//
//  Summary card showing balance overview for all people
//  Features: Total owed, total owing, net position
//  Created: 2026-02-04
//

import SwiftUI

// MARK: - People Summary Card

/// Shows a quick overview of balances across all people
struct PeopleSummaryCard: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var dataManager: DataManager
    @State private var animateIn = false
    
    // MARK: - Computed Properties
    
    private var peopleWhoOweYou: [Person] {
        dataManager.people.filter { $0.balance > 0 }
    }
    
    private var peopleYouOwe: [Person] {
        dataManager.people.filter { $0.balance < 0 }
    }
    
    private var totalOwedToYou: Double {
        peopleWhoOweYou.reduce(0) { $0 + $1.balance }
    }
    
    private var totalYouOwe: Double {
        abs(peopleYouOwe.reduce(0) { $0 + $1.balance })
    }
    
    private var netBalance: Double {
        totalOwedToYou - totalYouOwe
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("BALANCE SUMMARY")
                    .font(.spotifyLabelSmall)
                    .textCase(.uppercase)
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Spacer()
                
                // People count
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 11))
                    Text("\(dataManager.people.count)")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(Theme.Colors.textTertiary)
            }
            
            // Main Stats
            HStack(spacing: 0) {
                // They Owe You
                StatColumn(
                    icon: "arrow.down.circle.fill",
                    label: "They Owe",
                    amount: totalOwedToYou,
                    count: peopleWhoOweYou.count,
                    color: Theme.Colors.amountPositive,
                    animate: animateIn
                )
                
                // Divider
                Rectangle()
                    .fill(Theme.Colors.border)
                    .frame(width: 1)
                    .padding(.vertical, 8)
                
                // You Owe
                StatColumn(
                    icon: "arrow.up.circle.fill",
                    label: "You Owe",
                    amount: totalYouOwe,
                    count: peopleYouOwe.count,
                    color: Theme.Colors.amountNegative,
                    animate: animateIn
                )
            }
            
            // Net Position
            netPositionBar
        }
        .padding(16)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) {
                animateIn = true
            }
        }
    }
    
    // MARK: - Net Position Bar
    
    private var netPositionBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Net Position")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Spacer()
                
                Text(formatCurrency(netBalance, showSign: true))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(netBalance >= 0 ? Theme.Colors.amountPositive : Theme.Colors.amountNegative)
            }
            
            // Visual indicator
            GeometryReader { geometry in
                ZStack(alignment: netBalance >= 0 ? .leading : .trailing) {
                    // Background
                    Capsule()
                        .fill(Theme.Colors.border.opacity(0.5))
                    
                    // Position indicator
                    Capsule()
                        .fill(netBalance >= 0 ? Theme.Colors.amountPositive : Theme.Colors.amountNegative)
                        .frame(width: calculateBarWidth(geometry: geometry))
                        .animation(.spring(response: 0.6), value: animateIn)
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .background(Theme.Colors.background)
        .cornerRadius(10)
    }
    
    // MARK: - Helpers
    
    private func calculateBarWidth(geometry: GeometryProxy) -> CGFloat {
        guard animateIn else { return 0 }
        let total = totalOwedToYou + totalYouOwe
        guard total > 0 else { return geometry.size.width / 2 }
        
        let ratio = abs(netBalance) / total
        return max(geometry.size.width * CGFloat(ratio) * 0.5, 20)
    }
    
    private func formatCurrency(_ amount: Double, showSign: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = UserSettings.shared.selectedCurrency
        
        if showSign && amount != 0 {
            let prefix = amount > 0 ? "+" : ""
            return prefix + (formatter.string(from: NSNumber(value: amount)) ?? "$0")
        }
        return formatter.string(from: NSNumber(value: abs(amount))) ?? "$0"
    }
}

// MARK: - Stat Column

struct StatColumn: View {
    let icon: String
    let label: String
    let amount: Double
    let count: Int
    let color: Color
    let animate: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
                .opacity(animate ? 1 : 0)
                .scaleEffect(animate ? 1 : 0.5)
            
            // Amount
            Text(formatCurrency(amount))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)
                .opacity(animate ? 1 : 0)
            
            // Label + Count
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Text("(\(count))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.textTertiary)
            }
            .opacity(animate ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.4).delay(0.1), value: animate)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = UserSettings.shared.selectedCurrency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Preview

#Preview {
    VStack {
        PeopleSummaryCard()
            .padding()
        Spacer()
    }
    .background(Theme.Colors.background)
    .environmentObject(DataManager.shared)
}
