//
//  ChatTimelineComponents.swift
//  Swiff IOS
//
//  Simple rectangular message components
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
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .fixedSize(horizontal: false, vertical: true)
            
            if let sub = subtitle, !sub.isEmpty {
                Text(sub)
                    .font(.system(size: 14))
                    .opacity(0.7)
            }
            
            HStack(spacing: 4) {
                if isExpense {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .semibold))
                } else {
                    Image(systemName: "arrow.down.left")
                        .font(.system(size: 11, weight: .semibold))
                }
                
                Text(formatCurrency(abs(amount)))
                    .font(.system(size: 16, weight: .semibold))
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
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
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "banknote.fill")
                    .font(.system(size: 14))
                Text("Payment")
                    .font(.system(size: 14, weight: .semibold))
            }
            .opacity(0.85)
            
            if let note = note, !note.isEmpty {
                Text(note)
                    .font(.system(size: 16))
                    .padding(.top, 2)
            }
            
            Text(formatCurrency(amount))
                .font(.system(size: 20, weight: .bold))
                .padding(.top, 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
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
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(.wiseSecondaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.wiseSecondaryText.opacity(0.1))
        .cornerRadius(14)
    }
}
