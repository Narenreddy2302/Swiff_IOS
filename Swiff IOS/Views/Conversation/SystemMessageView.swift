//
//  SystemMessageView.swift
//  Swiff IOS
//
//  Professional system message component for conversation timelines
//  Used for status updates, transaction confirmations, etc.
//

import SwiftUI

// MARK: - System Message View

/// Clean system message view for conversation timelines
/// Displays non-interactive status messages with optional icons
struct SystemMessageView: View {
    let message: String
    let icon: String?
    let iconColor: Color?
    
    init(message: String, icon: String? = nil, iconColor: Color? = nil) {
        self.message = message
        self.icon = icon
        self.iconColor = iconColor
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(iconColor ?? .wiseSecondaryText)
            }
            
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.wiseSecondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.wiseSecondaryText.opacity(0.06))
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
    }
}

// MARK: - System Message Types

extension SystemMessageView {
    
    /// Transaction created message
    static func transactionCreated() -> SystemMessageView {
        SystemMessageView(
            message: "You created the transaction",
            icon: "checkmark.circle.fill",
            iconColor: .wiseBrightGreen
        )
    }
    
    /// Payment sent message
    static func paymentSent() -> SystemMessageView {
        SystemMessageView(
            message: "Payment sent successfully",
            icon: "checkmark.circle.fill",
            iconColor: .wiseBrightGreen
        )
    }
    
    /// Request sent message
    static func requestSent() -> SystemMessageView {
        SystemMessageView(
            message: "Request sent",
            icon: "arrow.up.circle.fill",
            iconColor: .wiseBlue
        )
    }
    
    /// Split created message
    static func splitCreated() -> SystemMessageView {
        SystemMessageView(
            message: "Bill split created",
            icon: "square.split.2x2.fill",
            iconColor: .wiseAccentBlue
        )
    }
    
    /// Generic info message
    static func info(_ message: String) -> SystemMessageView {
        SystemMessageView(
            message: message,
            icon: "info.circle.fill",
            iconColor: .wiseBlue
        )
    }
}

// MARK: - Preview

#Preview("System Messages") {
    VStack(spacing: 16) {
        SystemMessageView.transactionCreated()
        SystemMessageView.paymentSent()
        SystemMessageView.requestSent()
        SystemMessageView.splitCreated()
        SystemMessageView.info("Custom system message")
        
        // Without icon
        SystemMessageView(message: "Simple status message")
    }
    .padding(.vertical, 20)
    .background(Color.wiseBackground)
}
