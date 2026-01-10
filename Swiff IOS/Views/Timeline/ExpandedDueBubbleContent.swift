//
//  ExpandedDueBubbleContent.swift
//  Swiff IOS
//
//  iMessage-style transaction bubble for displaying split bills in conversations
//  Uses iMessageBubbleShape for authentic bubble appearance
//

import SwiftUI

/// iMessage-style transaction bubble for split bill display
/// Matches the design spec with proper bubble shape and content structure
struct ExpandedDueBubbleContent: View {
    let splitBill: SplitBill
    let isTheyOweMe: Bool
    let contactName: String
    var showTail: Bool = true

    @EnvironmentObject var dataManager: DataManager

    // MARK: - Computed Properties

    /// Bubble direction based on who owes (incoming = they owe me, outgoing = I owe them)
    private var bubbleDirection: iMessageBubbleDirection {
        isTheyOweMe ? .incoming : .outgoing
    }

    /// Background color: gray for received (they owe me), blue for sent (I owe them)
    private var backgroundColor: Color {
        isTheyOweMe ? .iMessageGray : .iMessageBlue
    }

    /// Primary text color
    private var primaryTextColor: Color {
        isTheyOweMe ? .wisePrimaryText : .white
    }

    /// Secondary text color for labels
    private var secondaryTextColor: Color {
        isTheyOweMe ? .wiseSecondaryText : .white.opacity(0.8)
    }

    /// Divider color
    private var dividerColor: Color {
        isTheyOweMe ? Color.wiseBorder.opacity(0.5) : .white.opacity(0.3)
    }

    /// Amount color: orange for received, yellow for sent
    private var amountColor: Color {
        isTheyOweMe ? .transactionOrange : .transactionYellow
    }

    /// Payer name
    private var payerName: String {
        if let payer = dataManager.people.first(where: { $0.id == splitBill.paidById }) {
            let currentUserId = UserProfileManager.shared.profile.id
            return splitBill.paidById == currentUserId ? "You" : payer.name
        }
        return "Unknown"
    }

    /// All involved names as a comma-separated string
    private var involvedNames: String {
        let names = splitBill.participants.compactMap { participant -> String? in
            guard let person = dataManager.people.first(where: { $0.id == participant.personId }) else {
                return nil
            }
            let currentUserId = UserProfileManager.shared.profile.id
            return person.id == currentUserId ? "You" : person.name
        }
        return names.isEmpty ? contactName : names.joined(separator: ", ")
    }

    /// Your share amount
    private var yourShare: Double {
        let currentUserId = UserProfileManager.shared.profile.id
        if let participant = splitBill.participants.first(where: { $0.personId == currentUserId }) {
            return participant.amount
        }
        // If current user is the payer or not found, calculate equal share
        let participantCount = max(splitBill.participants.count, 1)
        return splitBill.totalAmount / Double(participantCount)
    }

    /// Amount label text
    private var amountLabel: String {
        isTheyOweMe ? "You Owe" : "Each Owes"
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Transaction Name + Amount with label
            headerSection

            // Divider
            dividerLine

            // Details section
            detailsSection
        }
        .padding(14)
        .background(backgroundColor)
        .clipShape(iMessageBubbleShape(direction: bubbleDirection, showTail: showTail))
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top) {
            // Transaction name (left side)
            Text(splitBill.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(primaryTextColor)
                .lineLimit(2)

            Spacer()

            // Amount + label (right side)
            VStack(alignment: .trailing, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formatCurrency(yourShare))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(amountColor)

                    Text("/ \(amountLabel)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(amountColor)
                }
            }
        }
    }

    // MARK: - Divider

    private var dividerLine: some View {
        Rectangle()
            .fill(dividerColor)
            .frame(height: 1)
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(spacing: 8) {
            // Total Bill
            detailRow(label: "Total Bill", value: formatCurrency(splitBill.totalAmount))

            // Paid by
            detailRow(label: "Paid by", value: payerName)

            // Split Method
            detailRow(label: "Split Method", value: "Equally")

            // Who are all involved
            detailRow(label: "Who are all involved", value: involvedNames)
        }
    }

    // MARK: - Detail Row

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(secondaryTextColor)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(primaryTextColor)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
    }

    // MARK: - Helpers

    private func formatCurrency(_ amount: Double) -> String {
        amount.asCurrency
    }
}

// MARK: - Preview

#Preview("Transaction Bubble - Received (They Owe Me)") {
    VStack(spacing: 16) {
        // Creator text (shown outside bubble in parent view)
        Text("Li Wei created this")
            .font(.system(size: 12))
            .foregroundColor(.wiseSecondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)

        ExpandedDueBubbleContent(
            splitBill: MockData.pendingSplitBill,
            isTheyOweMe: true,
            contactName: "Li Wei"
        )
        .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
        .padding(.horizontal, 12)
    }
    .background(Color.wiseBackground)
    .environmentObject(DataManager.shared)
}

#Preview("Transaction Bubble - Sent (I Owe Them)") {
    VStack(spacing: 16) {
        // Creator text (shown outside bubble in parent view)
        Text("You created this")
            .font(.system(size: 12))
            .foregroundColor(.wiseSecondaryText)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 12)

        ExpandedDueBubbleContent(
            splitBill: MockData.pendingSplitBill,
            isTheyOweMe: false,
            contactName: "Jane Doe"
        )
        .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
        .padding(.horizontal, 12)
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
    .background(Color.wiseBackground)
    .environmentObject(DataManager.shared)
}
