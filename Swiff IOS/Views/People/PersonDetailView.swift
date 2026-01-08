//
//  PersonDetailView.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Detailed view for person with balance and quick actions
//  Clean, focused design matching the app's visual style
//

import SwiftUI

// MARK: - Person Conversation Tab

enum PersonConversationTab: String, ConversationTabProtocol, CaseIterable {
    case timeline = "Timeline"
    case summary = "Summary"
}

struct PersonDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    public let personId: UUID

    public init(personId: UUID) {
        self.personId = personId
    }

    // Sheet presentation states
    @State private var showingEditPerson = false
    @State private var showingDeleteAlert = false
    @State private var showingSettleUpSheet = false
    @State private var showingRecordPaymentSheet = false
    @State private var showingSendReminderSheet = false
    @State private var showingAddTransactionSheet = false

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
                transaction.title.contains(person.name)
                    || transaction.subtitle.contains(person.name)
            }
            .sorted { $0.date > $1.date }
    }

    // Group transactions by date for timeline
    private var groupedPersonTimelineItems: [(Date, [PersonTimelineItem])] {
        guard let person = person else { return [] }

        // Get transaction-based items
        var items = personTransactions.map { PersonTimelineItem.transaction($0, person) }

        // Add MockData timeline items for this person (for demo/testing)
        items.append(contentsOf: MockData.timelineItems(for: person.id, personName: person.name))

        let grouped = Dictionary(grouping: items) { item in
            Calendar.current.startOfDay(for: item.timestamp)
        }

        return grouped.sorted { $0.key > $1.key }.map {
            ($0.key, $0.value.sorted { $0.timestamp > $1.timestamp })
        }
    }

    // Status banner config
    private var personStatusBanner: StatusBannerConfig? {
        guard let person = person else { return nil }

        // Count pending split requests from timeline items (where youOwe > 0)
        let timelineItems = MockData.timelineItems(for: person.id, personName: person.name)
        var pendingSplitCount = 0
        var pendingSplitTotal: Double = 0

        for item in timelineItems {
            if case .splitRequest(_, _, _, _, _, let youOwe, _) = item, youOwe > 0 {
                pendingSplitCount += 1
                pendingSplitTotal += youOwe
            }
        }

        // Also count pending transactions
        let pendingTransactionCount = personTransactions.filter { $0.paymentStatus != .completed }
            .count

        // Total pending count
        let totalPendingCount = pendingSplitCount + pendingTransactionCount

        // Determine total amount and direction
        let totalAmount: Double
        let isUserOwing: Bool

        if person.balance != 0 {
            totalAmount = abs(person.balance)
            isUserOwing = person.balance < 0
        } else if pendingSplitTotal > 0 {
            totalAmount = pendingSplitTotal
            isUserOwing = true
        } else {
            return nil
        }

        // Only show banner if there are pending items
        guard totalPendingCount > 0 else { return nil }

        return StatusBannerConfig(
            pendingCount: totalPendingCount,
            totalAmount: totalAmount,
            isUserOwing: isUserOwing,
            personName: person.name
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if let person = person {
                // Compact header (no edit button, matches reference)
                PersonConversationHeader(
                    person: person,
                    onBack: { dismiss() }
                )

                // Timeline content directly (no tabs)
                timelineContent(for: person)
            } else {
                personNotFoundView
            }
        }
        .background(Color.wiseBackground)
        .navigationBarHidden(true)
        .hidesTabBar()
        .observeEntityWithRelated(
            personId, type: .person, relatedTypes: [.splitBill, .transaction],
            dataManager: dataManager
        )
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
                SettleUpSheet(
                    person: person,
                    onSettled: {
                        showingSettleUpSheet = false
                    })
            }
        }
        .sheet(isPresented: $showingRecordPaymentSheet) {
            if let person = person {
                RecordPaymentSheet(
                    person: person,
                    onPaymentRecorded: {
                        showingRecordPaymentSheet = false
                    })
            }
        }
        .sheet(isPresented: $showingSendReminderSheet) {
            if let person = person {
                SendReminderSheet(
                    person: person,
                    onReminderSent: {
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
                Text(
                    "This will permanently delete '\(person.name)'. They will be removed from all groups."
                )
            }
        }
        .sheet(isPresented: $showingAddTransactionSheet) {
            if let person = person {
                AddTransactionSheet(
                    showingAddTransactionSheet: $showingAddTransactionSheet,
                    onTransactionAdded: { transaction in
                        do {
                            try dataManager.addTransaction(transaction)
                        } catch {
                            dataManager.error = error
                        }
                    },
                    preselectedParticipant: person
                )
            }
        }
    }

    // MARK: - Timeline Content

    @ViewBuilder
    private func timelineContent(for person: Person) -> some View {
        ZStack(alignment: .bottom) {
            ChatTimelineView(
                groupedItems: groupedPersonTimelineItems,
                emptyStateConfig: TimelineEmptyStateConfig(
                    icon: "tray.fill",
                    title: "No transactions yet",
                    subtitle: "Record a payment to get started"
                )
            ) { item in
                switch item {
                case .transaction(let transaction, _):
                    // Expense (negative amount) = I paid = Outgoing (Right)
                    // Income (positive amount) = They paid = Incoming (Left)
                    ChatBubble(
                        direction: transaction.isExpense ? .outgoing : .incoming,
                        timestamp: transaction.date
                    ) {
                        TransactionBubbleContent(
                            title: transaction.title,
                            subtitle: transaction.subtitle,
                            amount: transaction.amount,
                            isExpense: transaction.isExpense
                        )
                    }

                case .payment(_, let amount, let direction, let description, let date):
                    // Outgoing direction = Right, Incoming = Left
                    ChatBubble(
                        direction: direction == .outgoing ? .outgoing : .incoming,
                        timestamp: date
                    ) {
                        PaymentBubbleContent(amount: amount, note: description)
                    }
                    
                case .message(_, let text, let isFromPerson, let date):
                    ChatBubble(
                        direction: isFromPerson ? .incoming : .outgoing,
                        timestamp: date
                    ) {
                        Text(text)
                            .font(.system(size: 16))
                    }
                    
                case .splitRequest(_, let title, _, let billTotal, _, let youOwe, let date):
                    // If you owe > 0, it's a request FOR you (Incoming)
                    // Otherwise it's a request FROM you (Outgoing)
                    ChatBubble(
                        direction: youOwe > 0 ? .incoming : .outgoing,
                        timestamp: date
                    ) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                Text("Split Bill Request")
                                    .font(.headline)
                            }
                            Text(title)
                            Text("Total: \(String(format: "$%.2f", billTotal))")
                                .font(.caption)
                            if youOwe > 0 {
                                Text("You owe: \(String(format: "$%.2f", youOwe))")
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    
                case .settlement(_, let date):
                    ChatBubble(direction: .center, timestamp: nil) {
                        SystemMessageBubble(text: "Balances settled", icon: "checkmark.circle.fill")
                    }
                    
                case .paidBill(_, let personName, let date):
                    ChatBubble(direction: .center, timestamp: nil) {
                        SystemMessageBubble(text: "\(personName) paid a bill", icon: "checkmark.seal.fill")
                    }
                    
                case .reminder(_, let date):
                    ChatBubble(direction: .outgoing, timestamp: date) {
                        Text("Reminder sent")
                            .italic()
                    }
                }
            }

            TimelineInputArea(
                config: TimelineInputAreaConfig(
                    quickActionTitle: "New split",
                    quickActionIcon: "plus",
                    placeholder: "Send a message...",
                    showMessageField: true
                ),
                onQuickAction: { showingAddTransactionSheet = true },
                onSend: { message in
                    // TODO: Handle sending message
                    print("Message sent: \(message)")
                }
            )
        }
    }

    // MARK: - Tab Content (Legacy - keeping for Summary tab access)

    @ViewBuilder
    private func timelineTabContent(for person: Person) -> some View {
        timelineContent(for: person)
    }

    @ViewBuilder
    private func summaryTabContent(for person: Person) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // 1. Compact Balance Row
                CompactBalanceRow(person: person)
                    .padding(.horizontal, 16)

                // 2. Streamlined Action Buttons (3 only)
                HStack(spacing: 0) {
                    Spacer()
                    CompactActionButton(
                        icon: "plus.circle.fill",
                        title: "Record",
                        color: .wiseForestGreen,
                        action: { showingAddTransactionSheet = true }
                    )
                    Spacer()
                    CompactActionButton(
                        icon: "bell.fill",
                        title: "Remind",
                        color: .wiseBlue,
                        action: { showingSendReminderSheet = true }
                    )
                    Spacer()
                    ContactMenuButton(
                        person: person,
                        onCall: { callPerson(person) },
                        onMessage: { messagePerson(person) },
                        onWhatsApp: { whatsappPerson(person) },
                        onEmail: { emailPerson(person) }
                    )
                    Spacer()
                }
                .padding(.horizontal, 16)

                // 3. Settle Up Button (conditional)
                if person.balance != 0 {
                    Button(action: { showingSettleUpSheet = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                            Text("Settle Up")
                                .font(.spotifyBodyLarge)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.wiseBrightGreen)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                }

                // 4. Shared Groups (keep existing)
                if !personGroups.isEmpty {
                    sharedGroupsSection
                }

                // 5. Split Bills (keep existing)
                if !personSplitBills.isEmpty {
                    splitBillsSection
                }

                // 6. Delete Person (keep existing)
                deletePersonButton
            }
            .padding(.top, 16)
            .padding(.bottom, 40)
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

                Text(
                    "Last activity: \(person.lastActivityText(transactions: dataManager.transactions))"
                )
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
                        NavigationLink(destination: SplitBillDetailView(splitBillId: splitBill.id))
                        {
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
                ForEach(Array(personTransactions.prefix(5).enumerated()), id: \.element.id) {
                    index, transaction in
                    NavigationLink(
                        destination: TransactionDetailView(transactionId: transaction.id)
                    ) {
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
                    .foregroundColor(Color(red: 102 / 255, green: 102 / 255, blue: 102 / 255))
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
                    .foregroundColor(Color(red: 153 / 255, green: 153 / 255, blue: 153 / 255))
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
                .foregroundColor(Color(red: 26 / 255, green: 26 / 255, blue: 26 / 255))
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

// MARK: - Compact Balance Row

struct CompactBalanceRow: View {
    let person: Person

    var body: some View {
        HStack(spacing: 12) {
            // Status icon in circle
            Image(systemName: statusIcon)
                .font(.system(size: 16))
                .foregroundColor(statusColor)
                .frame(width: 32, height: 32)
                .background(statusColor.opacity(0.15))
                .clipShape(Circle())

            // Status text + amount
            HStack(spacing: 4) {
                Text(statusText)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)

                if person.balance != 0 {
                    Text(String(format: "$%.2f", abs(person.balance)))
                        .font(.spotifyNumberMedium)
                        .fontWeight(.bold)
                        .foregroundColor(amountColor)
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.wiseSecondaryText.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .subtleShadow()
    }

    private var statusIcon: String {
        if person.balance > 0 { return "arrow.down.circle.fill" }
        if person.balance < 0 { return "arrow.up.circle.fill" }
        return "checkmark.circle.fill"
    }

    private var statusColor: Color {
        if person.balance > 0 { return AmountColors.positive }
        if person.balance < 0 { return AmountColors.negative }
        return .wiseBrightGreen
    }

    private var statusText: String {
        if person.balance > 0 { return "owes you" }
        if person.balance < 0 { return "you owe" }
        return "Settled up"
    }

    private var amountColor: Color {
        person.balance > 0 ? AmountColors.positive : AmountColors.negative
    }
}

// MARK: - Compact Action Button

struct CompactActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.medium)
            action()
        }) {
            VStack(spacing: 6) {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundColor(color)
                    )

                Text(title)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wisePrimaryText)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Contact Menu Button

struct ContactMenuButton: View {
    let person: Person
    var onCall: () -> Void
    var onMessage: () -> Void
    var onWhatsApp: () -> Void
    var onEmail: () -> Void

    private var hasContactOptions: Bool {
        !person.phone.isEmpty || !person.email.isEmpty
    }

    var body: some View {
        Menu {
            if !person.phone.isEmpty {
                Button(action: onCall) {
                    Label("Call", systemImage: "phone.fill")
                }
                Button(action: onMessage) {
                    Label("Message", systemImage: "message.fill")
                }
                Button(action: onWhatsApp) {
                    Label("WhatsApp", systemImage: "phone.bubble.left.fill")
                }
            }
            if !person.email.isEmpty {
                Button(action: onEmail) {
                    Label("Email", systemImage: "envelope.fill")
                }
            }
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(Color.wiseBrightGreen.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.wiseBrightGreen)
                    )

                Text("Contact")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wisePrimaryText)
            }
        }
        .disabled(!hasContactOptions)
        .opacity(hasContactOptions ? 1.0 : 0.5)
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
                            Text(
                                person.balance > 0
                                    ? "\(person.name) owes you" : "You owe \(person.name)"
                            )
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
                            Text(
                                settlementType == .full
                                    ? "Mark as Settled" : "Record Partial Payment"
                            )
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
                title: settlementType == .full
                    ? "Settlement with \(person.name)" : "Partial payment from \(person.name)",
                subtitle: settlementType == .full
                    ? "Full settlement" : String(format: "$%.2f partial payment", settlementAmount),
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
                title: paymentDirection == .youPaid
                    ? "Payment to \(person.name)" : "Payment from \(person.name)",
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

#Preview("Person Detail - Owed Money") {
    NavigationView {
        PersonDetailView(personId: MockData.personOwedMoney.id)
            .environmentObject(DataManager.shared)
    }
}

#Preview("Person Detail - Owing Money") {
    NavigationView {
        PersonDetailView(personId: MockData.personOwingMoney.id)
            .environmentObject(DataManager.shared)
    }
}

#Preview("Person Detail - Settled") {
    NavigationView {
        PersonDetailView(personId: MockData.personSettled.id)
            .environmentObject(DataManager.shared)
    }
}
