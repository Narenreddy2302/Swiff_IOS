//
//  SplitBillDetailView.swift
//  Swiff IOS
//
//  Detail view for viewing and managing split bills
//

import SwiftUI

struct SplitBillDetailView: View {
    let splitBill: SplitBill
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss

    @State private var showDeleteConfirmation = false
    @State private var showShareSheet = false

    private var payer: Person? {
        dataManager.people.first { $0.id == splitBill.paidById }
    }

    private var participants: [Person] {
        splitBill.participants.compactMap { participant in
            dataManager.people.first { $0.id == participant.personId }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header card
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(splitBill.category.color.opacity(0.15))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: splitBill.category.icon)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(splitBill.category.color)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(splitBill.title)
                                .font(.spotifyHeadingLarge)
                                .foregroundColor(.wisePrimaryText)

                            HStack(spacing: 8) {
                                Text(formatDate(splitBill.date))
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wiseSecondaryText)

                                // Split type badge
                                SplitTypeBadge(splitType: splitBill.splitType)
                            }
                        }
                    }

                    Divider()
                        .background(Color.wiseBorder.opacity(0.3))

                    // Total amount
                    HStack {
                        Text("Total Amount")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseSecondaryText)
                        Spacer()
                        Text(String(format: "$%.2f", splitBill.totalAmount))
                            .font(.spotifyNumberLarge)
                            .foregroundColor(.wisePrimaryText)
                    }

                    // Split method info
                    HStack {
                        Text("Split Method")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseSecondaryText)
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: splitBill.splitType.icon)
                                .font(.system(size: 14, weight: .medium))
                            Text(splitBill.splitType.rawValue)
                                .font(.spotifyBodyMedium)
                        }
                        .foregroundColor(.wisePrimaryText)
                    }

                    // Paid by
                    if let payer = payer {
                        HStack {
                            Text("Paid by")
                                .font(.spotifyBodyMedium)
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

                    // Settlement progress
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Settlement Progress")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wiseSecondaryText)
                            Spacer()

                            HStack(spacing: 6) {
                                if splitBill.isFullySettled {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.wiseSuccess)
                                }
                                Text("\(splitBill.settledCount)/\(splitBill.participants.count)")
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(splitBill.isFullySettled ? .wiseSuccess : .wisePrimaryText)
                            }
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.wiseBorder.opacity(0.3))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(splitBill.isFullySettled ? Color.wiseSuccess : Color.wiseBrightGreen)
                                    .frame(
                                        width: geometry.size.width * splitBill.settlementProgress,
                                        height: 8
                                    )
                                    .animation(.smooth, value: splitBill.settlementProgress)
                            }
                        }
                        .frame(height: 8)

                        if splitBill.totalPending > 0 {
                            Text(String(format: "$%.2f remaining", splitBill.totalPending))
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseWarning)
                        }
                    }
                }
                .padding(20)
                .background(Color.wiseCardBackground)
                .cornerRadius(16)
                .cardShadow()

                // Notes (if exists)
                if !splitBill.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        Text(splitBill.notes)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseSecondaryText)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.wiseCardBackground)
                            .cornerRadius(12)
                    }
                }

                // Participants section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Participants")
                        .font(.spotifyHeadingMedium)
                        .foregroundColor(.wisePrimaryText)

                    VStack(spacing: 12) {
                        ForEach(Array(zip(splitBill.participants, splitBill.participants.indices)), id: \.0.id) { participant, index in
                            if index < participants.count {
                                participantRow(participant: participant, person: participants[index])
                            }
                        }
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(20)
        }
        .background(Color.wiseBackground)
        .navigationTitle("Split Bill Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showShareSheet = true }) {
                        Label("Share Details", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.wisePrimaryText)
                }
            }
        }
        .alert("Delete Split Bill?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteSplitBill()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Participant Row

    @ViewBuilder
    private func participantRow(participant: SplitParticipant, person: Person) -> some View {
        HStack(spacing: 12) {
            // Avatar with status badge
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    avatarType: person.avatarType,
                    size: .large,
                    style: .solid
                )
                .frame(width: 48, height: 48)

                // Status badge
                Circle()
                    .fill(participant.hasPaid ? Color.wiseSuccess : Color.wiseWarning)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Image(systemName: participant.hasPaid ? "checkmark" : "clock")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(x: 2, y: 2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)

                // Show split method details
                HStack(spacing: 6) {
                    if let percentage = participant.percentage {
                        Text("\(String(format: "%.1f", percentage))%")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.wiseBorder.opacity(0.2))
                            .cornerRadius(4)
                    } else if let shares = participant.shares {
                        Text("\(shares) \(shares == 1 ? "share" : "shares")")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.wiseBorder.opacity(0.2))
                            .cornerRadius(4)
                    }

                    Text(participant.hasPaid ? "Settled" : "Pending")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(participant.hasPaid ? .wiseSuccess : .wiseWarning)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(String(format: "$%.2f", participant.amount))
                    .font(.spotifyNumberMedium)
                    .foregroundColor(.wisePrimaryText)

                if !participant.hasPaid {
                    Button(action: {
                        HapticManager.shared.light()
                        markAsPaid(participantId: participant.id)
                    }) {
                        Text("Mark Paid")
                            .font(.spotifyCaptionMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(.wiseForestGreen)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.wiseBrightGreen)
                            .cornerRadius(8)
                    }
                } else if let paymentDate = participant.paymentDate {
                    Text(formatRelativeDate(paymentDate))
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Actions

    private func markAsPaid(participantId: UUID) {
        do {
            try dataManager.markParticipantAsPaid(splitBillId: splitBill.id, participantId: participantId)
            HapticManager.shared.success()
        } catch {
            print("Error marking participant as paid: \(error)")
        }
    }

    private func deleteSplitBill() {
        do {
            try dataManager.deleteSplitBill(id: splitBill.id)
            HapticManager.shared.success()
            dismiss()
        } catch {
            print("Error deleting split bill: \(error)")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview("Split Bill Detail") {
    let dataManager = DataManager.shared
    let person1 = Person(name: "Alice", email: "alice@example.com", phone: "+1234567890", avatar: "👩‍💼")
    let person2 = Person(name: "Bob", email: "bob@example.com", phone: "+1234567891", avatar: "👨‍💻")
    let person3 = Person(name: "Charlie", email: "charlie@example.com", phone: "+1234567892", avatar: "🧑‍🔧")
    dataManager.people = [person1, person2, person3]

    let participant1 = SplitParticipant(personId: person1.id, amount: 30.0, hasPaid: true)
    let participant2 = SplitParticipant(personId: person2.id, amount: 30.0, hasPaid: false)
    let participant3 = SplitParticipant(personId: person3.id, amount: 30.0, hasPaid: true)

    let splitBill = SplitBill(
        title: "Dinner at Italian Restaurant",
        totalAmount: 90.0,
        paidById: person1.id,
        splitType: .equally,
        participants: [participant1, participant2, participant3],
        notes: "Great meal with friends!",
        category: .dining,
        date: Date()
    )

    return NavigationView {
        SplitBillDetailView(splitBill: splitBill)
            .environmentObject(dataManager)
    }
}
