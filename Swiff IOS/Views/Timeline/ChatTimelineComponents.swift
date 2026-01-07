//
//  ChatTimelineComponents.swift
//  Swiff IOS
//
//  Created for SWIFF iOS "iMessage Style" Redesign
//  Specific bubble contents for transactions, payments, etc.
//

import SwiftUI

// MARK: - Transaction Bubble Content
struct TransactionBubbleContent: View {
    let title: String
    let subtitle: String?
    let amount: Double
    let isExpense: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .fixedSize(horizontal: false, vertical: true)
            
            if let sub = subtitle, !sub.isEmpty {
                Text(sub)
                    .font(.system(size: 13))
                    .opacity(0.8)
            }
            
            HStack(spacing: 4) {
                if isExpense {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))
                } else {
                    Image(systemName: "arrow.down.left")
                        .font(.system(size: 10, weight: .bold))
                }
                
                Text(formatCurrency(abs(amount)))
                    .font(.system(size: 15, weight: .semibold))
            }
            .padding(.top, 2)
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "$%.2f", value)
    }
}

// MARK: - Payment Bubble Content (Specific for "Payment" type items)
struct PaymentBubbleContent: View {
    let amount: Double
    let note: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "banknote.fill")
                    .font(.system(size: 14))
                Text("Payment")
                    .font(.system(size: 14, weight: .semibold))
            }
            .opacity(0.9)
            
            if let note = note, !note.isEmpty {
                Text(note)
                    .font(.system(size: 16))
            }
            
            Text(formatCurrency(amount))
                .font(.system(size: 20, weight: .bold))
                .padding(.top, 2)
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "$%.2f", value)
    }
}

// MARK: - System Message Bubble
struct SystemMessageBubble: View {
    let text: String
    let icon: String?
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12))
            }
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.wiseSecondaryText)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.wiseSecondaryText.opacity(0.1))
        .cornerRadius(12)
    }
}
