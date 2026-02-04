//
//  UpcomingRenewalsWidget.swift
//  Swiff IOS
//
//  Compact widget showing upcoming subscription renewals
//  Features: Next 7 days, countdown, total cost
//  Created: 2026-02-04
//

import SwiftUI

// MARK: - Upcoming Renewals Widget

/// Compact card showing subscriptions renewing in the next 7 days
struct UpcomingRenewalsWidget: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var dataManager: DataManager
    @State private var animateIn = false
    
    // MARK: - Computed Properties
    
    private var upcomingRenewals: [Subscription] {
        let now = Date()
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        
        return dataManager.subscriptions
            .filter { $0.isActive && $0.nextBillingDate >= now && $0.nextBillingDate <= nextWeek }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
    }
    
    private var totalUpcomingCost: Double {
        upcomingRenewals.reduce(0) { $0 + $1.price }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.warning)
                    
                    Text("UPCOMING RENEWALS")
                        .font(.spotifyLabelSmall)
                        .textCase(.uppercase)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                Spacer()
                
                // Total cost badge
                if !upcomingRenewals.isEmpty {
                    Text(formatCurrency(totalUpcomingCost))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.Colors.warning)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.Colors.warning.opacity(0.12))
                        .cornerRadius(10)
                }
            }
            
            if upcomingRenewals.isEmpty {
                // Empty state
                emptyState
            } else {
                // Renewals list (max 3)
                VStack(spacing: 0) {
                    ForEach(Array(upcomingRenewals.prefix(3).enumerated()), id: \.element.id) { index, subscription in
                        RenewalRow(subscription: subscription, animate: animateIn, index: index)
                        
                        if index < min(upcomingRenewals.count - 1, 2) {
                            Divider()
                                .background(Theme.Colors.border.opacity(0.5))
                        }
                    }
                }
                
                // See all button if more than 3
                if upcomingRenewals.count > 3 {
                    Button(action: {
                        HapticManager.shared.light()
                        // Navigate to full calendar
                    }) {
                        HStack {
                            Text("See all \(upcomingRenewals.count) renewals")
                                .font(.system(size: 13, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(Theme.Colors.brandPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                    }
                }
            }
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
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(Theme.Colors.success)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("All clear!")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text("No renewals in the next 7 days")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Helpers
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = UserSettings.shared.selectedCurrency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Renewal Row

struct RenewalRow: View {
    let subscription: Subscription
    let animate: Bool
    let index: Int
    
    private var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: subscription.nextBillingDate).day ?? 0
    }
    
    private var daysText: String {
        if daysUntil == 0 {
            return "Today"
        } else if daysUntil == 1 {
            return "Tomorrow"
        } else {
            return "In \(daysUntil) days"
        }
    }
    
    private var urgencyColor: Color {
        if daysUntil <= 1 {
            return Theme.Colors.amountNegative
        } else if daysUntil <= 3 {
            return Theme.Colors.warning
        } else {
            return Theme.Colors.textSecondary
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(subscription.category.pastelAvatarColor)
                    .frame(width: 36, height: 36)
                
                Text(InitialsGenerator.generate(from: subscription.name))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: 26/255, green: 26/255, blue: 26/255))
            }
            .opacity(animate ? 1 : 0)
            .scaleEffect(animate ? 1 : 0.8)
            .animation(.spring(response: 0.4).delay(Double(index) * 0.1), value: animate)
            
            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)
                
                Text(daysText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(urgencyColor)
            }
            .opacity(animate ? 1 : 0)
            .animation(.spring(response: 0.4).delay(Double(index) * 0.1 + 0.05), value: animate)
            
            Spacer()
            
            // Price
            Text(subscription.price.asCurrency)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)
                .opacity(animate ? 1 : 0)
                .animation(.spring(response: 0.4).delay(Double(index) * 0.1 + 0.1), value: animate)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        UpcomingRenewalsWidget()
            .padding()
        Spacer()
    }
    .background(Theme.Colors.background)
    .environmentObject(DataManager.shared)
}
