//
//  ChatHeaderView.swift
//  iMessageTransactionUI
//
//  Description:
//  Top navigation header for the chat interface.
//  Displays back button, contact information, and balance summary.
//
//  Layout:
//  - HStack with three sections:
//    1. Left: Back button with "Messages" text
//    2. Center: Contact avatar and name
//    3. Right: Balance summary (BalanceSummaryView)
//
//  Styling:
//  - Frosted glass background effect (blur)
//  - Bottom border separator
//  - Fixed height of 64 points
//
//  Properties:
//  - balance: BalanceType - The net balance to display
//
//  Note:
//  Back button is decorative in this implementation.
//  In production, it would trigger navigation.
//

import SwiftUI

// MARK: - ChatHeaderView
/// Top navigation header displaying contact info and balance
struct ChatHeaderView: View {
    
    // MARK: - Properties
    
    /// The net balance to display in the header
    let balance: BalanceType
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            // MARK: Left Section - Back Button
            leftSection
            
            Spacer()
            
            // MARK: Center Section - Contact Info
            centerSection
            
            Spacer()
            
            // MARK: Right Section - Balance
            rightSection
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 64)
        .background(headerBackground)
    }
    
    // MARK: - Left Section
    /// Back button with chevron and "Messages" text
    private var leftSection: some View {
        HStack(spacing: 4) {
            // Chevron icon
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
            
            // "Messages" text
            Text("Messages")
                .font(.system(size: 17))
        }
        .foregroundColor(.iMessageBlue)
        .frame(minWidth: 100, alignment: .leading)
        // In production, add tap gesture for navigation:
        // .onTapGesture { /* navigate back */ }
    }
    
    // MARK: - Center Section
    /// Contact avatar and name
    private var centerSection: some View {
        VStack(spacing: 4) {
            // Avatar circle with initials
            contactAvatar
            
            // Contact name
            Text("Group Chat")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textPrimary)
        }
    }
    
    /// Contact avatar with gradient background and initials
    private var contactAvatar: some View {
        ZStack {
            // Gradient background
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 168/255, green: 230/255, blue: 207/255),
                            Color(red: 136/255, green: 216/255, blue: 176/255)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
            
            // Initials
            Text("GC")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Right Section
    /// Balance summary display
    private var rightSection: some View {
        BalanceSummaryView(balance: balance)
            .frame(minWidth: 100, alignment: .trailing)
    }
    
    // MARK: - Header Background
    /// Frosted glass effect background with bottom border
    private var headerBackground: some View {
        ZStack(alignment: .bottom) {
            // Blur effect background
            Color.headerBackground
                .background(.ultraThinMaterial)
            
            // Bottom border
            Rectangle()
                .fill(Color.black.opacity(0.1))
                .frame(height: 0.5)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        ChatHeaderView(balance: .theyOwe(3.76))
        ChatHeaderView(balance: .youOwe(15.50))
        ChatHeaderView(balance: .settled)
        Spacer()
    }
}
