//
//  PersonDetailView.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Detailed view for person with balance and quick actions
//  Clean, focused design matching the app's visual style
//

import SwiftUI

struct PersonDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    let personId: UUID

    // Sheet presentation states
    @State private var showingEditPerson = false
    @State private var showingDeleteAlert = false
    @State private var showingSettleUpSheet = false
    @State private var showingRecordPaymentSheet = false
    @State private var showingSendReminderSheet = false

    // MARK: - Computed Properties

    var person: Person? {
        dataManager.people.first { $0.id == personId }
    }

    var personGroups: [Group] {
        guard let person = person else { return [] }
        return dataManager.groups.filter { group in
            group.members.contains(person.id)
        }
    }

    var personSplitBills: [SplitBill] {
        guard let person = person else { return [] }
        return dataManager.getSplitBillsForPerson(personId: person.id)
    }

    var personTransactions: [Transaction] {
        guard let person = person else { return [] }
        return dataManager.transactions
            .filter { transaction in
                transaction.title.contains(person.name) || transaction.subtitle.contains(person.name)
            }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            if let person = person {
                VStack(spacing: 24) {
                    // 1. Header Section
                    headerSection(for: person)

                    // 2. Balance Card
                    balanceCard(for: person)

                    // 3. Quick Actions (Two Rows)
                    quickActionsSection(for: person)

                    // 4. Shared Groups Section
                    if !personGroups.isEmpty {
                        sharedGroupsSection
                    }

                    // 5. Split Bills Section
                    if !personSplitBills.isEmpty {
                        splitBillsSection
                    }

                    // 6. Recent Activity Section
                    if !personTransactions.isEmpty {
                        recentActivitySection
                    }

                    // 7. Delete Person Button
                    deletePersonButton
                }
                .padding(.bottom, 40)
            } else {
                personNotFoundView
            }
        }
        .background(Color.wiseBackground)
        .navigationTitle(person?.name ?? "Person")
        .navigationBarTitleDisplayMode(.inline)
        .observeEntityWithRelated(personId, type: .person, relatedTypes: [.splitBill, .transaction], dataManager: dataManager)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditPerson = true
                }
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseForestGreen)
            }
        }
        .sheet(isPresented: $showingEditPerson) {
            if let person = person {
                EditPersonSheet(
                    showingEditPersonSheet: $showingEditPerson,
                    editingPerson: person,
                    onPersonUpdated: { updatedPerson in
                        do {
                            try dataManager.updatePerson(updatedPerson)
                            showingEditPerson = false
                        } catch {
                            dataManager.error = error
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingSettleUpSheet) {
            if let person = person {
                SettleUpSheet(person: person, onSettled: {
                    showingSettleUpSheet = false
                })
            }
        }
        .sheet(isPresented: $showingRecordPaymentSheet) {
            if let person = person {
                RecordPaymentSheet(person: person, onPaymentRecorded: {
                    showingRecordPaymentSheet = false
                })
            }
        }
        .sheet(isPresented: $showingSendReminderSheet) {
            if let person = person {
                SendReminderSheet(person: person, onReminderSent: {
                    showingSendReminderSheet = false
                })
            }
        }
        .alert("Delete Person?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deletePerson()
            }
        } message: {
            if let person = person {
                Text("This will permanently delete '\(person.name)'. They will be removed from all groups.")
            }
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private func headerSection(for person: Person) -> some View {
        VStack(spacing: 16) {
            // Avatar - xxlarge size (80pt)
            AvatarView(person: person, size: .xxlarge, style: .solid)

            // Name - large display font
            Text(person.name)
                .font(.spotifyDisplayMedium)
                .foregroundColor(.wisePrimaryText)

            // Last Activity
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.wiseSecondaryText)

                Text("Last activity: \(person.lastActivityText(transactions: dataManager.transactions))")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
            }

            // Contact Info
            VStack(spacing: 8) {
                if !person.email.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.wiseSecondaryText)
                        Text(person.email)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }

                if !person.phone.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.wiseSecondaryText)
                        Text(person.phone)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Balance Card

    @ViewBuilder
    private func balanceCard(for person: Person) -> some View {
        VStack(spacing: 12) {
            Text("Balance")
                .font(.spotifyLabelLarge)
                .foregroundColor(.wiseSecondaryText)

            Text(String(format: "$%.2f", abs(person.balance)))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(balanceColor(for: person.balance))

            Text(balanceStatusText(for: person.balance))
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
        .padding(.horizontal, 16)
    }

    private func balanceColor(for balance: Double) -> Color {
        if balance > 0 { return .wiseBrightGreen }
        if balance < 0 { return .wiseError }
        return .wisePrimaryText
    }

    private func balanceStatusText(for balance: Double) -> String {
        if balance > 0 { return "owes you" }
        if balance < 0 { return "you owe" }
        return "settled up"
    }

    // MARK: - Quick Actions Section

    @ViewBuilder
    private func quickActionsSection(for person: Person) -> some View {
        VStack(spacing: 16) {
            // Row 1: Primary Actions (Settle Up, Record, Remind)
            HStack(spacing: 0) {
                Spacer()

                // Settle Up (only if balance != 0)
                if person.balance != 0 {
                    PersonQuickActionButton(
                        icon: "checkmark.circle.fill",
                        title: "Settle Up",
                        color: .wiseBrightGreen,
                        action: { showingSettleUpSheet = true }
                    )
                    Spacer()
                }

                // Record
                PersonQuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Record",
                    color: .wiseForestGreen,
                    action: { showingRecordPaymentSheet = true }
                )
                Spacer()

                // Remind
                PersonQuickActionButton(
                    icon: "bell.fill",
                    title: "Remind",
                    color: .wiseBlue,
                    action: { showingSendReminderSheet = true }
                )

                Spacer()
            }

            // Row 2: Contact Actions (Call, Message, WhatsApp, Email)
            HStack(spacing: 0) {
                Spacer()

                if !person.phone.isEmpty {
                    PersonQuickActionButton(
                        icon: "phone.fill",
                        title: "Call",
                        color: .wiseGreen,
                        action: { callPerson(person) }
                    )
                    Spacer()

                    PersonQuickActionButton(
                        icon: "message.fill",
                        title: "Message",
                        color: .wiseBlue,
                        action: { messagePerson(person) }
                    )
                    Spacer()

                    PersonQuickActionButton(
                        icon: "phone.bubble.left.fill",
                        title: "WhatsApp",
                        color: Color(red: 0.0, green: 0.729, blue: 0.322),
                        action: { whatsappPerson(person) }
                    )
                    Spacer()
                }

                if !person.email.isEmpty {
                    PersonQuickActionButton(
                        icon: "envelope.fill",
                        title: "Email",
                        color: .wiseOrange,
                        action: { emailPerson(person) }
                    )
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Shared Groups Section

    @ViewBuilder
    private var sharedGroupsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.wiseBlue)

                Text("Shared Groups")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                Text("\(personGroups.count)")
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.wiseBorder.opacity(0.3))
                    )
            }
            .padding(.horizontal, 16)

            // Group Cards
            VStack(spacing: 12) {
                ForEach(personGroups) { group in
                    NavigationLink(destination: GroupDetailView(groupId: group.id)) {
                        GroupMembershipRow(group: group)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Split Bills Section

    @ViewBuilder
    private var splitBillsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "rectangle.3.group.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.891, green: 0.118, blue: 0.459))

                Text("Split Bills")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                Text("\(personSplitBills.count)")
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wiseSecondaryText)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(personSplitBills) { splitBill in
                        NavigationLink(destination: SplitBillDetailView(splitBillId: splitBill.id)) {
                            SplitBillCard(splitBill: splitBill)
                                .frame(width: 320)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Recent Activity Section

    @ViewBuilder
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.wiseBlue)

                Text("Recent Activity")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                Text("\(personTransactions.count)")
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.wiseBorder.opacity(0.3))
                    )
            }
            .padding(.horizontal, 16)

            // Transaction List
            VStack(spacing: 0) {
                ForEach(Array(personTransactions.prefix(5).enumerated()), id: \.element.id) { index, transaction in
                    NavigationLink(destination: TransactionDetailView(transactionId: transaction.id)) {
                        transactionRow(transaction)
                    }
                    .buttonStyle(PlainButtonStyle())

                    if index < min(4, personTransactions.count - 1) {
                        AlignedDivider()
                    }
                }
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
            .cardShadow()
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Transaction Row

    @ViewBuilder
    private func transactionRow(_ transaction: Transaction) -> some View {
        HStack(spacing: 14) {
            // Initials avatar
            initialsAvatar(for: transaction)

            // Title and description
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                Text(transaction.subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                    .lineLimit(1)
            }

            Spacer()

            // Amount and time
            VStack(alignment: .trailing, spacing: 3) {
                Text(formattedAmount(for: transaction))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(amountColor(for: transaction))

                Text(relativeTime(for: transaction))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func initialsAvatar(for transaction: Transaction) -> some View {
        ZStack {
            Circle()
                .fill(avatarColor(for: transaction))
                .frame(width: 44, height: 44)

            Text(InitialsGenerator.generate(from: transaction.title))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 26/255, green: 26/255, blue: 26/255))
        }
    }

    private func avatarColor(for transaction: Transaction) -> Color {
        transaction.category.pastelAvatarColor
    }

    private func amountColor(for transaction: Transaction) -> Color {
        transaction.isExpense ? AmountColors.negative : AmountColors.positive
    }

    private func formattedAmount(for transaction: Transaction) -> String {
        let sign = transaction.isExpense ? "- " : "+ "
        return "\(sign)\(transaction.formattedAmount)"
    }

    private func relativeTime(for transaction: Transaction) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: transaction.date, relativeTo: Date())
    }

    // MARK: - Delete Button

    private var deletePersonButton: some View {
        Button(action: { showingDeleteAlert = true }) {
            Text("Delete Person")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseError)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }

    // MARK: - Person Not Found View

    private var personNotFoundView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.wiseError)

            Text("Person not found")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Contact Actions

    private func callPerson(_ person: Person) {
        let phoneNumber = person.phone.filter { $0.isNumber }
        if let url = URL(string: "tel://\(phoneNumber)") {
            UIApplication.shared.open(url)
        }
    }

    private func messagePerson(_ person: Person) {
        let phoneNumber = person.phone.filter { $0.isNumber }
        if let url = URL(string: "sms:\(phoneNumber)") {
            UIApplication.shared.open(url)
        }
    }

    private func emailPerson(_ person: Person) {
        if let url = URL(string: "mailto:\(person.email)") {
            UIApplication.shared.open(url)
        }
    }

    private func whatsappPerson(_ person: Person) {
        let phoneNumber = person.phone
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")

        if let url = URL(string: "whatsapp://send?phone=\(phoneNumber)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Fallback to web WhatsApp
                if let webURL = URL(string: "https://wa.me/\(phoneNumber)") {
                    UIApplication.shared.open(webURL)
                }
            }
        }
    }

    // MARK: - Delete Action

    private func deletePerson() {
        guard let person = person else { return }
        do {
            try dataManager.deletePerson(id: person.id)
            dismiss()
        } catch {
            dataManager.error = error
        }
    }
}

// MARK: - Person Quick Action Button

struct PersonQuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.medium)
            action()
        }) {
            VStack(spacing: 8) {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundColor(color)
                    )
                    .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)

                Text(title)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wisePrimaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Group Membership Row

struct GroupMembershipRow: View {
    let group: Group

    var body: some View {
        HStack(spacing: 12) {
            // Group Emoji
            Circle()
                .fill(Color.wiseBlue.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(group.emoji)
                        .font(.system(size: 24))
                )

            // Group Info
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)

                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                    Text("\(group.members.count) members")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)

                    Text("•")
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText)

                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 10))
                    Text("\(group.expenses.count) expenses")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }

            Spacer()

            // Amount
            if group.totalAmount > 0 {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "$%.2f", group.totalAmount))
                        .font(.spotifyNumberSmall)
                        .foregroundColor(.wisePrimaryText)

                    let unsettledCount = group.expenses.filter { !$0.isSettled }.count
                    if unsettledCount > 0 {
                        Text("\(unsettledCount) pending")
                            .font(.spotifyCaptionSmall)
                            .foregroundColor(.wiseError)
                    }
                }
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.wiseSecondaryText.opacity(0.5))
        }
        .padding(12)
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .subtleShadow()
    }
}

// MARK: - Settle Up Sheet

struct SettleUpSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    let person: Person
    let onSettled: () -> Void

    @State private var settlementType: SettlementType = .full
    @State private var partialAmount: String = ""

    enum SettlementType {
        case full
        case partial
    }

    private var totalBalance: Double {
        abs(person.balance)
    }

    private var settlementAmount: Double {
        if settlementType == .full {
            return totalBalance
        } else {
            return min(Double(partialAmount) ?? 0, totalBalance)
        }
    }

    private var isValid: Bool {
        if settlementType == .full {
            return true
        } else {
            return settlementAmount > 0 && settlementAmount <= totalBalance
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Person Info
                    VStack(spacing: 12) {
                        AvatarView(person: person, size: .xlarge, style: .solid)

                        Text(person.name)
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)
                    }
                    .padding(.top, 20)

                    // Settlement Type Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Settlement Type")
                            .font(.spotifyLabelMedium)
                            .foregroundColor(.wiseSecondaryText)

                        Picker("Type", selection: $settlementType) {
                            Text("Full Settlement").tag(SettlementType.full)
                            Text("Partial Settlement").tag(SettlementType.partial)
                        }
                        .pickerStyle(.segmented)
                    }

                    // Amount Display
                    VStack(spacing: 12) {
                        if settlementType == .full {
                            Text(person.balance > 0 ? "\(person.name) owes you" : "You owe \(person.name)")
                                .font(.spotifyHeadingMedium)
                                .foregroundColor(.wisePrimaryText)

                            Text(String(format: "$%.2f", totalBalance))
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundColor(person.balance > 0 ? .wiseBrightGreen : .wiseError)
                        } else {
                            Text("Enter partial amount")
                                .font(.spotifyHeadingMedium)
                                .foregroundColor(.wisePrimaryText)

                            HStack {
                                Text("$")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.wisePrimaryText)

                                TextField("0.00", text: $partialAmount)
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.wisePrimaryText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 16)

                            Text("Total balance: $\(String(format: "%.2f", totalBalance))")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                    .padding(.vertical, 20)

                    // Remaining Balance Info (for partial)
                    if settlementType == .partial && settlementAmount > 0 {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Settling:")
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wiseSecondaryText)
                                Spacer()
                                Text(String(format: "$%.2f", settlementAmount))
                                    .font(.spotifyBodyMedium)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.wisePrimaryText)
                            }

                            HStack {
                                Text("Remaining:")
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wiseSecondaryText)
                                Spacer()
                                Text(String(format: "$%.2f", totalBalance - settlementAmount))
                                    .font(.spotifyBodyMedium)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.wiseError)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.wiseBorder.opacity(0.2))
                        )
                    }

                    Spacer(minLength: 40)

                    // Settle Button
                    Button(action: settleUp) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                            Text(settlementType == .full ? "Mark as Settled" : "Record Partial Payment")
                                .font(.spotifyBodyLarge)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isValid ? Color.wiseBrightGreen : Color.wiseDisabledButton)
                        .cornerRadius(12)
                    }
                    .disabled(!isValid)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 16)
            }
            .background(Color.wiseBackground)
            .navigationTitle("Settle Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.wiseSecondaryText)
                }
            }
        }
    }

    private func settleUp() {
        var updatedPerson = person

        if settlementType == .full {
            updatedPerson.balance = 0.0
        } else {
            // For partial settlement, reduce the balance by the settlement amount
            if person.balance > 0 {
                // Person owes you - reduce what they owe
                updatedPerson.balance -= settlementAmount
            } else {
                // You owe the person - reduce what you owe
                updatedPerson.balance += settlementAmount
            }
        }

        do {
            try dataManager.updatePerson(updatedPerson)

            // Create settlement transaction
            let transaction = Transaction(
                title: settlementType == .full ? "Settlement with \(person.name)" : "Partial payment from \(person.name)",
                subtitle: settlementType == .full ? "Full settlement" : String(format: "$%.2f partial payment", settlementAmount),
                amount: person.balance > 0 ? -settlementAmount : settlementAmount,
                category: .transfer,
                date: Date(),
                isRecurring: false,
                tags: ["settlement"]
            )
            try dataManager.addTransaction(transaction)

            onSettled()
        } catch {
            dataManager.error = error
        }
    }
}

// MARK: - Record Payment Sheet

struct RecordPaymentSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    let person: Person
    let onPaymentRecorded: () -> Void

    @State private var amount = ""
    @State private var paymentDirection: PaymentDirection = .youPaid
    @State private var notes = ""
    @State private var paymentDate = Date()

    enum PaymentDirection: String, CaseIterable {
        case youPaid = "You paid them"
        case theyPaid = "They paid you"
    }

    private var amountValue: Double {
        Double(amount) ?? 0.0
    }

    private var isFormValid: Bool {
        amountValue > 0
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Direction Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Payment Direction")
                            .font(.spotifyLabelMedium)
                            .foregroundColor(.wiseSecondaryText)

                        Picker("Direction", selection: $paymentDirection) {
                            ForEach(PaymentDirection.allCases, id: \.self) { direction in
                                Text(direction.rawValue).tag(direction)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Amount
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Amount *")
                            .font(.spotifyLabelMedium)
                            .foregroundColor(.wiseSecondaryText)

                        HStack {
                            Text("$")
                                .font(.spotifyNumberLarge)
                                .foregroundColor(.wisePrimaryText)

                            TextField("0.00", text: $amount)
                                .font(.spotifyNumberLarge)
                                .foregroundColor(.wisePrimaryText)
                                .keyboardType(.decimalPad)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.wiseBorder.opacity(0.5))
                                .stroke(Color.wiseBorder, lineWidth: 1)
                        )
                    }

                    // Date
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Date")
                            .font(.spotifyLabelMedium)
                            .foregroundColor(.wiseSecondaryText)

                        DatePicker("", selection: $paymentDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes (Optional)")
                            .font(.spotifyLabelMedium)
                            .foregroundColor(.wiseSecondaryText)

                        TextEditor(text: $notes)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                            .frame(height: 100)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.wiseBorder.opacity(0.5))
                                    .stroke(Color.wiseBorder, lineWidth: 1)
                            )
                    }

                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .navigationTitle("Record Payment")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseSecondaryText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Record") {
                        recordPayment()
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(isFormValid ? .white : .wiseSecondaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isFormValid ? Color.wiseForestGreen : Color.wiseBorder)
                    )
                    .disabled(!isFormValid)
                }
            }
        }
    }

    private func recordPayment() {
        var updatedPerson = person

        // Adjust balance based on direction
        let adjustmentAmount = paymentDirection == .youPaid ? amountValue : -amountValue
        updatedPerson.balance += adjustmentAmount

        do {
            try dataManager.updatePerson(updatedPerson)

            // Create a transaction record
            let transaction = Transaction(
                title: paymentDirection == .youPaid ? "Payment to \(person.name)" : "Payment from \(person.name)",
                subtitle: notes.isEmpty ? "Cash payment" : notes,
                amount: amountValue,
                category: .transfer,
                date: paymentDate,
                isRecurring: false,
                tags: []
            )
            try dataManager.addTransaction(transaction)

            onPaymentRecorded()
        } catch {
            dataManager.error = error
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        PersonDetailView(personId: UUID())
            .environmentObject(DataManager.shared)
    }
}
