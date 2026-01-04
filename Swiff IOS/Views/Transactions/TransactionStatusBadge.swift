//
//  TransactionStatusBadge.swift
//  Swiff IOS
//
//  Created for Page 2 Task 2.1.3
//  Visual badge component for transaction payment status
//

import SwiftUI

struct TransactionStatusBadge: View {
    let status: PaymentStatus
    var size: BadgeSize = .medium

    enum BadgeSize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 14
            }
        }

        var font: Font {
            switch self {
            case .small: return .system(size: 10, weight: .semibold)
            case .medium: return .system(size: 11, weight: .semibold)
            case .large: return .system(size: 12, weight: .semibold)
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 3, leading: 6, bottom: 3, trailing: 6)
            case .medium: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .large: return EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.system(size: size.iconSize))

            Text(status.rawValue)
                .font(size.font)
        }
        .foregroundColor(status.color)
        .padding(size.padding)
        .background(
            Capsule()
                .fill(status.badgeBackgroundColor)
        )
    }
}

// MARK: - Preview
#Preview("All Status Badges") {
    VStack(spacing: 16) {
        Text("Transaction Status Badges")
            .font(.title2)
            .fontWeight(.bold)

        VStack(alignment: .leading, spacing: 12) {
            Text("Small Size")
                .font(.caption)
                .foregroundColor(.wiseSecondaryText)

            HStack(spacing: 8) {
                ForEach(PaymentStatus.allCases, id: \.self) { status in
                    TransactionStatusBadge(status: status, size: .small)
                }
            }
        }

        VStack(alignment: .leading, spacing: 12) {
            Text("Medium Size (Default)")
                .font(.caption)
                .foregroundColor(.wiseSecondaryText)

            HStack(spacing: 8) {
                ForEach(PaymentStatus.allCases, id: \.self) { status in
                    TransactionStatusBadge(status: status, size: .medium)
                }
            }
        }

        VStack(alignment: .leading, spacing: 12) {
            Text("Large Size")
                .font(.caption)
                .foregroundColor(.wiseSecondaryText)

            HStack(spacing: 8) {
                ForEach(PaymentStatus.allCases, id: \.self) { status in
                    TransactionStatusBadge(status: status, size: .large)
                }
            }
        }

        Spacer()
    }
    .padding()
}

#Preview("On Transaction Card") {
    ZStack(alignment: .topTrailing) {
        // Mock transaction card
        HStack(spacing: 12) {
            Circle()
                .fill(Color.wiseBlue.opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "fork.knife.circle.fill")
                        .foregroundColor(.wiseBlue)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Coffee at Starbucks")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)
                Text("Morning coffee • 2h ago")
                    .font(.system(size: 14))
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            Text("-$5.50")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.wiseError)
        }
        .padding()
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()

        // Status badge positioned in top-right
        TransactionStatusBadge(status: .pending)
            .padding(8)
    }
    .padding()
    .frame(maxWidth: .infinity)
    .background(Color.wiseBackground)
}
