//
//  QuickActionsBar.swift
//  Swiff IOS
//
//  Quick action buttons for common tasks on Home screen
//  Features: Add expense, request money, split bill, settle up
//  Created: 2026-02-04
//

import SwiftUI

// MARK: - Quick Actions Bar

/// Horizontal scrolling bar with quick action buttons
struct QuickActionsBar: View {
    
    // MARK: - Properties
    
    @State private var showingAddExpense = false
    @State private var showingRequestMoney = false
    @State private var showingSplitBill = false
    @State private var showingSettleUp = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            Text("Quick Actions")
                .font(Theme.Fonts.labelMedium)
                .foregroundColor(Theme.Colors.textSecondary)
                .textCase(.uppercase)
            
            // Action Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickActionButton(
                        icon: "plus.circle.fill",
                        label: "Add Expense",
                        color: Theme.Colors.brandPrimary
                    ) {
                        HapticManager.shared.impact(.medium)
                        showingAddExpense = true
                    }
                    
                    QuickActionButton(
                        icon: "arrow.down.circle.fill",
                        label: "Request",
                        color: Theme.Colors.info
                    ) {
                        HapticManager.shared.impact(.medium)
                        showingRequestMoney = true
                    }
                    
                    QuickActionButton(
                        icon: "rectangle.split.3x1.fill",
                        label: "Split Bill",
                        color: Theme.Colors.success
                    ) {
                        HapticManager.shared.impact(.medium)
                        showingSplitBill = true
                    }
                    
                    QuickActionButton(
                        icon: "checkmark.circle.fill",
                        label: "Settle Up",
                        color: Theme.Colors.warning
                    ) {
                        HapticManager.shared.impact(.medium)
                        showingSettleUp = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            QuickActionSheet()
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(color)
                }
                
                // Label
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)
            }
            .frame(width: 80)
        }
        .buttonStyle(QuickActionButtonStyle())
    }
}

// MARK: - Quick Action Button Style

struct QuickActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        QuickActionsBar()
            .padding()
        Spacer()
    }
    .background(Theme.Colors.background)
}
