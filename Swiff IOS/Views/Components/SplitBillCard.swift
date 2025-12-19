//
//  SplitBillCard.swift
//  Swiff IOS
//
//  Card component for displaying split bills in lists
//

import SwiftUI

struct SplitBillCard: View {
    let splitBill: SplitBill
    @EnvironmentObject var dataManager: DataManager
    let onTap: (() -> Void)?

    init(splitBill: SplitBill, onTap: (() -> Void)? = nil) {
        self.splitBill = splitBill
        self.onTap = onTap
    }

    private var participants: [Person] {
        splitBill.participants.compactMap { participant in
            dataManager.people.first { $0.id == participant.personId }
        }
    }

    private var payer: Person? {
        dataManager.people.first { $0.id == splitBill.paidById }
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.light()
            onTap?()
        }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header: Icon, Title, Amount
                HStack(spacing: 12) {
                    // Category icon circle
                    Circle()
                        .fill(splitBill.category.color.opacity(0.15))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: splitBill.category.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(splitBill.category.color)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(splitBill.title)
                            .font(.spotifyBodyLarge)
                            .foregroundColor(.wisePrimaryText)
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            Text(formatDate(splitBill.date))
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseSecondaryText)

                            // Split type badge
                            SplitTypeBadge(splitType: splitBill.splitType)
                        }
                    }

                    Spacer()

                    Text(String(format: "$%.2f", splitBill.totalAmount))
                        .font(.spotifyNumberMedium)
                        .foregroundColor(.wisePrimaryText)
                }

                Divider()
                    .background(Color.wiseBorder.opacity(0.3))

                // Paid by section
                HStack(spacing: 8) {
                    Text("Paid by")
                        .font(.spotifyLabelMedium)
                        .foregroundColor(.wiseSecondaryText)

                    if let payer = payer {
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

                    Spacer()
                }

                // Participants section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Split between \(splitBill.participants.count)")
                        .font(.spotifyLabelMedium)
                        .foregroundColor(.wiseSecondaryText)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(zip(splitBill.participants, splitBill.participants.indices)), id: \.0.id) { participant, index in
                                if index < participants.count {
                                    ParticipantBubble(
                                        person: participants[index],
                                        participant: participant,
                                        showAmount: true
                                    )
                                }
                            }
                        }
                    }
                }

                // Settlement status
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(splitBill.settledCount)/\(splitBill.participants.count) settled")
                            .font(.spotifyLabelMedium)
                            .foregroundColor(.wiseSecondaryText)

                        Spacer()

                        if splitBill.totalPending > 0 {
                            Text(String(format: "$%.2f pending", splitBill.totalPending))
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseWarning)
                        }
                    }

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.wiseBorder.opacity(0.3))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.wiseBrightGreen)
                                .frame(
                                    width: geometry.size.width * splitBill.settlementProgress,
                                    height: 8
                                )
                        }
                    }
                    .frame(height: 8)
                }

                // Settle Now button (if not fully settled)
                if !splitBill.isFullySettled {
                    Button(action: {
                        HapticManager.shared.light()
                        onTap?()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Settle Now")
                                .font(.spotifyBodyMedium)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.wiseBrightGreen)
                        .cornerRadius(12)
                    }
                    .buttonStyle(ScaleButtonStyle(scaleAmount: 0.98))
                }
            }
            .padding(16)
            .background(Color.wiseCardBackground)
            .cornerRadius(16)
            .cardShadow()
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Split Type Badge

struct SplitTypeBadge: View {
    let splitType: SplitType

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: splitType.icon)
                .font(.system(size: 8, weight: .semibold))

            Text(splitType.shortName)
                .font(.system(size: 9, weight: .medium))
        }
        .foregroundColor(.wiseSecondaryText)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.wiseBorder.opacity(0.2))
        )
    }
}

// MARK: - Preview

#Preview("Split Bill Cards") {
    let person1 = Person(name: "Alice", email: "alice@example.com", phone: "+1234567890", avatar: "👩‍💼")
    let person2 = Person(name: "Bob", email: "bob@example.com", phone: "+1234567891", avatar: "👨‍💻")
    let person3 = Person(name: "Charlie", email: "charlie@example.com", phone: "+1234567892", avatar: "🧑‍🔧")

    let participant1 = SplitParticipant(personId: person1.id, amount: 30.0, hasPaid: true)
    let participant2 = SplitParticipant(personId: person2.id, amount: 30.0, hasPaid: false)
    let participant3 = SplitParticipant(personId: person3.id, amount: 30.0, hasPaid: true)

    let splitBill = SplitBill(
        title: "Dinner at Italian Restaurant",
        totalAmount: 90.0,
        paidById: person1.id,
        splitType: .equally,
        participants: [participant1, participant2, participant3],
        notes: "Great meal!",
        category: .dining,
        date: Date()
    )

    let dataManager = DataManager.shared
    dataManager.people = [person1, person2, person3]

    return ScrollView {
        VStack(spacing: 16) {
            SplitBillCard(splitBill: splitBill) {
                print("Card tapped")
            }
        }
        .padding()
        .background(Color.wiseBackground)
    }
    .environmentObject(dataManager)
}
