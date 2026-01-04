//
//  SplitBillDetailView.swift
//  Swiff IOS
//
//  Detail view for viewing and managing split bills
//

import SwiftUI

struct SplitBillDetailView: View {
    let splitBillId: UUID
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss

    @State private var showDeleteConfirmation = false
    @State private var showShareSheet = false

    // Computed property for reactive updates - looks up fresh data from DataManager
    private var splitBill: SplitBill? {
        dataManager.splitBills.first { $0.id == splitBillId }
    }

    private var payer: Person? {
        guard let splitBill = splitBill else { return nil }
        return dataManager.people.first { $0.id == splitBill.paidById }
    }

    private var participants: [Person] {
        guard let splitBill = splitBill else { return [] }
        return splitBill.participants.compactMap { participant in
            dataManager.people.first { $0.id == participant.personId }
        }
    }

    var body: some View {
        ScrollView {
            if let splitBill = splitBill {
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

                        VStack(spacing: 0) {
                            ForEach(Array(zip(splitBill.participants, splitBill.participants.indices)), id: \.0.id) { participant, index in
                                if index < participants.count {
                                    participantRow(participant: participant, person: participants[index])

                                    if index < splitBill.participants.count - 1 {
                                        AlignedDivider()
                                    }
                                }
                            }
                        }
                        .background(Color.wiseCardBackground)
                        .cornerRadius(12)
                    }

                    Spacer(minLength: 20)
                }
                .padding(20)
            } else {
                // Split bill not found view
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.wiseWarning)
                    Text("Split Bill Not Found")
                        .font(.spotifyHeadingMedium)
                        .foregroundColor(.wisePrimaryText)
                    Text("This split bill may have been deleted.")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                    Button("Go Back") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .background(Color.wiseBackground)
        .navigationTitle("Split Bill Details")
        .navigationBarTitleDisplayMode(.inline)
        .hidesTabBar()
        .observeEntity(splitBillId, type: .splitBill, dataManager: dataManager)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if splitBill != nil {
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
        HStack(spacing: 14) {
            // Initials-based avatar (44x44)
            ZStack {
                Circle()
                    .fill(InitialsAvatarColors.color(for: person.name))
                    .frame(width: 44, height: 44)

                Text(InitialsGenerator.generate(from: person.name))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 26/255, green: 26/255, blue: 26/255))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(person.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)

                // Show split method details and status
                HStack(spacing: 6) {
                    if let percentage = participant.percentage {
                        Text("\(String(format: "%.1f", percentage))%")
                    } else if let shares = participant.shares {
                        Text("\(shares) \(shares == 1 ? "share" : "shares")")
                    } else {
                        Text(participant.hasPaid ? "Settled" : "Pending")
                    }
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(String(format: "$%.2f", participant.amount))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)

                if !participant.hasPaid {
                    Button(action: {
                        HapticManager.shared.light()
                        markAsPaid(participantId: participant.id)
                    }) {
                        Text("Mark Paid")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.wiseForestGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.wiseBrightGreen)
                            .cornerRadius(6)
                    }
                } else if let paymentDate = participant.paymentDate {
                    Text(formatRelativeDate(paymentDate))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Actions

    private func markAsPaid(participantId: UUID) {
        do {
            try dataManager.markParticipantAsPaid(splitBillId: splitBillId, participantId: participantId)
            HapticManager.shared.success()
        } catch {
            print("Error marking participant as paid: \(error)")
        }
    }

    private func deleteSplitBill() {
        do {
            try dataManager.deleteSplitBill(id: splitBillId)
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

#Preview("Split Bill Detail - Settled") {
    NavigationView {
        SplitBillDetailView(splitBillId: MockData.settledSplitBill.id)
            .environmentObject(DataManager.shared)
    }
}

#Preview("Split Bill Detail - Pending") {
    NavigationView {
        SplitBillDetailView(splitBillId: MockData.pendingSplitBill.id)
            .environmentObject(DataManager.shared)
    }
}

#Preview("Split Bill Detail - Partially Paid") {
    NavigationView {
        SplitBillDetailView(splitBillId: MockData.partiallySplitBill.id)
            .environmentObject(DataManager.shared)
    }
}
