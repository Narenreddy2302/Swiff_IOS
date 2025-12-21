//
//  StatusBannerView.swift
//  Swiff IOS
//
//  Created by Claude Code on 12/20/25.
//  Banner showing pending count and total owed for timeline views
//

import SwiftUI

struct StatusBannerView: View {
    let config: StatusBannerConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(config.pendingCount) pending split\(config.pendingCount == 1 ? "" : "s")")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.wisePrimaryText)

            Text(subtitleText)
                .font(.system(size: 14))
                .foregroundColor(.wiseSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.wiseTertiaryBackground)
        .cornerRadius(12)
    }

    private var subtitleText: String {
        let amountStr = formatCurrency(config.totalAmount)
        let splitStr = config.pendingCount == 1 ? "split" : "splits"

        if let name = config.personName {
            if config.isUserOwing {
                return "You owe \(name) \(amountStr) total across \(config.pendingCount) \(splitStr)."
            } else {
                return "\(name) owes you \(amountStr) total across \(config.pendingCount) \(splitStr)."
            }
        } else {
            if config.isUserOwing {
                return "You owe \(amountStr) total across \(config.pendingCount) \(splitStr)."
            } else {
                return "Owed to you \(amountStr) total across \(config.pendingCount) \(splitStr)."
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(String(format: "%.2f", amount))"
    }
}

#Preview {
    VStack(spacing: 16) {
        StatusBannerView(config: StatusBannerConfig(
            pendingCount: 2,
            totalAmount: 50.50,
            isUserOwing: true,
            personName: "Jordan"
        ))

        StatusBannerView(config: StatusBannerConfig(
            pendingCount: 1,
            totalAmount: 125.00,
            isUserOwing: false,
            personName: "Sarah"
        ))

        StatusBannerView(config: StatusBannerConfig(
            pendingCount: 5,
            totalAmount: 234.75,
            isUserOwing: true
        ))
    }
    .padding()
    .background(Color.wiseBackground)
}
