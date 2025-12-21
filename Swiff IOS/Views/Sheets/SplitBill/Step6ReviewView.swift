//
//  Step6ReviewView.swift
//  Swiff IOS
//
//  Step 6: Final review before creating split bill (matches reference image)
//

import SwiftUI

struct Step6ReviewView: View {
    let title: String
    let totalAmount: Double
    let payer: Person
    let participants: [SplitParticipant]
    let category: TransactionCategory
    let date: Date
    let notes: String

    @EnvironmentObject var dataManager: DataManager

    var participantPeople: [Person] {
        participants.compactMap { participant in
            dataManager.people.first { $0.id == participant.personId }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Review Split Bill")
                        .font(.spotifyHeadingLarge)
                        .foregroundColor(.wisePrimaryText)

                    Text("Check the details before creating")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
                .padding(.top, 20)

                // Main card (matching reference image)
                VStack(alignment: .leading, spacing: 20) {
                    // Title and date with icon
                    HStack(spacing: 12) {
                        Circle()
                            .fill(category.color.opacity(0.15))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: category.icon)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(category.color)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.spotifyBodyLarge)
                                .fontWeight(.semibold)
                                .foregroundColor(.wisePrimaryText)

                            Text(formatDate(date))
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }

                        Spacer()
                    }

                    Divider()
                        .background(Color.wiseBorder.opacity(0.3))

                    // Total and Payment ID
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Total")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)
                            Spacer()
                            Text(String(format: "IDR %.0f", totalAmount))
                                .font(.spotifyNumberLarge)
                                .foregroundColor(.wisePrimaryText)
                        }

                        HStack {
                            Text("Paid by")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)
                            Spacer()
                            HStack(spacing: 8) {
                                AvatarView(
                                    avatarType: payer.avatarType,
                                    size: .small,
                                    style: .solid
                                )
                                .frame(width: 24, height: 24)
                                Text(payer.name)
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wisePrimaryText)
                            }
                        }
                    }

                    Divider()
                        .background(Color.wiseBorder.opacity(0.3))

                    // Items section (if notes exist)
                    if !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.spotifyLabelLarge)
                                .foregroundColor(.wisePrimaryText)

                            Text(notes)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }

                        Divider()
                            .background(Color.wiseBorder.opacity(0.3))
                    }

                    // Participants section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Participants")
                                .font(.spotifyLabelLarge)
                                .foregroundColor(.wisePrimaryText)

                            Spacer()

                            Text("\(participants.count) people")
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }

                        // Participant avatars
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(zip(participants, participants.indices)), id: \.0.id) { participant, index in
                                    if index < participantPeople.count {
                                        VStack(spacing: 6) {
                                            AvatarView(
                                                avatarType: participantPeople[index].avatarType,
                                                size: .large,
                                                style: .solid
                                            )
                                            .frame(width: 48, height: 48)

                                            Text(participantPeople[index].name)
                                                .font(.spotifyCaptionMedium)
                                                .foregroundColor(.wisePrimaryText)
                                                .lineLimit(1)
                                        }
                                        .frame(width: 70)
                                    }
                                }
                            }
                        }
                    }

                    Divider()
                        .background(Color.wiseBorder.opacity(0.3))

                    // Per-participant cost
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nominal per participants")
                            .font(.spotifyLabelLarge)
                            .foregroundColor(.wisePrimaryText)

                        ForEach(Array(zip(participants, participants.indices)), id: \.0.id) { participant, index in
                            if index < participantPeople.count {
                                HStack {
                                    AvatarView(
                                        avatarType: participantPeople[index].avatarType,
                                        size: .small,
                                        style: .solid
                                    )
                                    .frame(width: 24, height: 24)

                                    Text(participantPeople[index].name)
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wisePrimaryText)

                                    Spacer()

                                    Text(String(format: "$%.2f", participant.amount))
                                        .font(.spotifyBodyMedium)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.wisePrimaryText)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .padding(20)
                .background(Color.wiseCardBackground)
                .cornerRadius(16)
                .cardShadow()
                .padding(.horizontal, 20)

                Spacer(minLength: 20)
            }
        }
        .background(Color.wiseBackground)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy • hh:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview("Step 6 Review") {
    let participant1 = SplitParticipant(personId: MockData.personOwedMoney.id, amount: 30.0)
    let participant2 = SplitParticipant(personId: MockData.personOwingMoney.id, amount: 30.0)

    return Step6ReviewView(
        title: MockData.pendingSplitBill.title,
        totalAmount: MockData.pendingSplitBill.totalAmount,
        payer: MockData.personOwedMoney,
        participants: [participant1, participant2],
        category: .dining,
        date: Date(),
        notes: "Great meal with friends!"
    )
    .environmentObject(DataManager.shared)
}
