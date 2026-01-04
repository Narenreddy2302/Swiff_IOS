//
//  PersonConversationHeader.swift
//  Swiff IOS
//
//  Compact header for person conversation view
//  80pt height with avatar, name, balance, and quick actions
//

import SwiftUI

struct PersonConversationHeader: View {
    let person: Person
    var onBack: (() -> Void)?
    var onEdit: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            // Back button (circular with gray filled background)
            if let onBack = onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.wisePrimaryText)
                        .frame(width: 32, height: 32)
                        .background(Color.wiseBorder.opacity(0.3))
                        .clipShape(Circle())
                }
            }

            // Person info (name + balance)
            VStack(alignment: .leading, spacing: 1) {
                Text(person.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)

                // Balance summary - split into two parts
                balanceView
            }

            Spacer()

            // Edit button (if provided)
            if let onEdit = onEdit {
                Button(action: onEdit) {
                    Text("Edit")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.wiseForestGreen)
                }
            }

            // Avatar on right (matching reference design)
            AvatarView(person: person, size: .large, style: .solid)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(height: 70)
        .background(Color.wiseCardBackground)
        .overlay(
            Rectangle()
                .fill(Color.wiseBorder)
                .frame(height: 1)
            , alignment: .bottom
        )
    }

    @ViewBuilder
    private var balanceView: some View {
        if person.balance > 0 {
            // Person owes you - split into gray + green
            HStack(spacing: 4) {
                Text("Owes you")
                    .font(.system(size: 12))
                    .foregroundColor(.wiseSecondaryText)
                Text("$\(String(format: "%.2f", person.balance))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AmountColors.positive)
            }
        } else if person.balance < 0 {
            // You owe person - split into gray + red
            HStack(spacing: 4) {
                Text("You owe")
                    .font(.system(size: 12))
                    .foregroundColor(.wiseSecondaryText)
                Text("$\(String(format: "%.2f", abs(person.balance)))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.wiseError)
            }
        } else {
            // Settled up
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.wiseBrightGreen)
                Text("Settled up")
                    .font(.system(size: 12))
                    .foregroundColor(.wiseSecondaryText)
            }
        }
    }
}

// MARK: - Preview

#Preview("PersonConversationHeader - Owes You") {
    PersonConversationHeader(
        person: MockData.personOwedMoney
    )
    .background(Color.wiseBackground)
}

#Preview("PersonConversationHeader - You Owe") {
    PersonConversationHeader(
        person: MockData.personOwingMoney
    )
    .background(Color.wiseBackground)
}

#Preview("PersonConversationHeader - Settled") {
    PersonConversationHeader(
        person: MockData.personSettled
    )
    .background(Color.wiseBackground)
}

#Preview("PersonConversationHeader - Long Name") {
    PersonConversationHeader(
        person: MockData.longNamePerson
    )
    .background(Color.wiseBackground)
}
