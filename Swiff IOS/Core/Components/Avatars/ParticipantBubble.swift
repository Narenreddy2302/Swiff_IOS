//
//  ParticipantBubble.swift
//  Swiff IOS
//
//  Individual participant display for split bills
//

import SwiftUI

struct ParticipantBubble: View {
    let person: Person
    let participant: SplitParticipant
    let showAmount: Bool

    init(person: Person, participant: SplitParticipant, showAmount: Bool = true) {
        self.person = person
        self.participant = participant
        self.showAmount = showAmount
    }

    var body: some View {
        VStack(spacing: 6) {
            // Avatar with status indicator
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    avatarType: person.avatarType,
                    size: .large,
                    style: .solid
                )

                // Payment status badge
                ZStack {
                    Circle()
                        .fill(Color.wiseCardBackground)
                        .frame(width: 20, height: 20)

                    Image(systemName: participant.hasPaid ? "checkmark.circle.fill" : "clock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(participant.hasPaid ? .wiseSuccess : .wiseWarning)
                }
                .offset(x: 2, y: 2)
            }
            .frame(width: 48, height: 48)

            // Name
            Text(person.name)
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wisePrimaryText)
                .lineLimit(1)

            // Amount (if showing)
            if showAmount {
                Text(participant.amount.asCurrency)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(participant.hasPaid ? .wiseSecondaryText : .wiseWarning)
            }
        }
        .frame(width: 70)
    }
}

