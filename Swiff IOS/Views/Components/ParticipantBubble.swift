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
                Text(String(format: "$%.2f", participant.amount))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(participant.hasPaid ? .wiseSecondaryText : .wiseWarning)
            }
        }
        .frame(width: 70)
    }
}

// MARK: - Preview

#Preview("Participant Bubbles") {
    let person1 = Person(
        name: "Alice",
        email: "alice@example.com",
        phone: "+1234567890",
        avatar: "👩‍💼"
    )

    let person2 = Person(
        name: "Bob",
        email: "bob@example.com",
        phone: "+1234567891",
        avatar: "👨‍💻"
    )

    let participant1 = SplitParticipant(personId: person1.id, amount: 30.0, hasPaid: true)
    let participant2 = SplitParticipant(personId: person2.id, amount: 30.0, hasPaid: false)

    HStack(spacing: 16) {
        ParticipantBubble(person: person1, participant: participant1)
        ParticipantBubble(person: person2, participant: participant2)
        ParticipantBubble(person: person1, participant: participant1, showAmount: false)
    }
    .padding()
    .background(Color.wiseBackground)
}
