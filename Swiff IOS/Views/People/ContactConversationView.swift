//
//  ContactConversationView.swift
//  Swiff IOS
//
//  iMessage-style conversation view for contacts
//  Features: Bubble tails, message grouping, swipe timestamps, expanded transaction cards
//

import SwiftUI

struct ContactConversationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    let contact: ContactEntry

    // Message input state
    @State private var messageText: String = ""

    // Sheet presentation states
    @State private var showingCreateDueSheet = false
    @State private var selectedDueDirection: DueDirection = .theyOweMe
    @State private var showingAddTransactionSheet = false
    @State private var showingInviteSheet = false
    @State private var selectedPersonForTransaction: Person?

    // MARK: - Computed Properties

    /// Get the balance for this contact
    private var contactBalance: Double? {
        dataManager.getBalanceForContact(contact)
    }

    /// Get all dues for this contact
    private var contactDues: [SplitBill] {
        dataManager.getDuesForContact(contact)
    }

    /// Get entity ID for messages (using linked person ID if available)
    private var messageEntityId: UUID? {
        dataManager.people.first(where: { $0.contactId == contact.id })?.id
    }

    /// Get messages for this contact
    private var contactMessages: [ConversationMessage] {
        guard let entityId = messageEntityId else { return [] }
        return dataManager.getMessages(for: entityId)
    }

    /// Group dues and messages by date for timeline display
    private var groupedContactTimelineItems: [(Date, [ContactTimelineItem])] {
        // Convert dues to timeline items
        var items: [ContactTimelineItem] = contactDues.map { splitBill in
            // Determine direction: if payer is current user, they owe me
            let currentUserId = UserProfileManager.shared.profile.id
            let isTheyOweMe = splitBill.paidById == currentUserId
            return .due(splitBill, isTheyOweMe: isTheyOweMe)
        }

        // Add messages to timeline items
        let messageItems: [ContactTimelineItem] = contactMessages.map { message in
            .textMessage(message)
        }
        items.append(contentsOf: messageItems)

        // Group by date
        let grouped = Dictionary(grouping: items) { item in
            Calendar.current.startOfDay(for: item.timestamp)
        }

        // Sort by date (newest first for groups, oldest first within each group for timeline flow)
        return grouped.sorted { $0.key > $1.key }.map {
            ($0.key, $0.value.sorted { $0.timestamp < $1.timestamp })
        }
    }

    // MARK: - Helper Methods

    /// Get creator name for a split bill
    private func getCreatorName(for splitBill: SplitBill) -> String {
        let currentUserId = UserProfileManager.shared.profile.id
        if splitBill.paidById == currentUserId {
            return "You"
        }
        return dataManager.people.first { $0.id == splitBill.paidById }?.name ?? contact.name
    }

    /// Check if current user created the split bill
    private func isCurrentUserCreator(_ splitBill: SplitBill) -> Bool {
        let currentUserId = UserProfileManager.shared.profile.id
        return splitBill.paidById == currentUserId
    }

    /// Get bubble direction for timeline item
    private func getDirection(for item: ContactTimelineItem) -> ChatBubbleDirection {
        switch item {
        case .due(_, let isTheyOweMe):
            return isTheyOweMe ? .incoming : .outgoing
        case .settlement:
            return .center
        case .textMessage(let message):
            return message.isSent ? .outgoing : .incoming
        }
    }

    /// Send a message to this contact
    private func sendMessage(_ content: String) {
        // First, ensure contact has a linked person record
        do {
            let person = try dataManager.importContact(contact)
            try dataManager.sendMessage(
                to: person.id,
                entityType: .contact,
                content: content
            )
            HapticManager.shared.impact(.light)
        } catch {
            print("Failed to send message: \(error)")
            ToastManager.shared.showError("Failed to send message")
        }
    }

    /// Format currency amount using user's selected currency
    private func formatCurrency(_ amount: Double) -> String {
        amount.asCurrency
    }

    /// Get your share amount for a split bill
    private func getYourShare(for splitBill: SplitBill) -> Double {
        let currentUserId = UserProfileManager.shared.profile.id
        if let participant = splitBill.participants.first(where: { $0.personId == currentUserId }) {
            return participant.amount
        }
        // If current user is the payer or not found, calculate equal share
        let participantCount = max(splitBill.participants.count, 1)
        return splitBill.totalAmount / Double(participantCount)
    }

    /// Get payer name for a split bill
    private func getPayerName(for splitBill: SplitBill) -> String {
        let currentUserId = UserProfileManager.shared.profile.id
        if splitBill.paidById == currentUserId { return "You" }
        return dataManager.people.first { $0.id == splitBill.paidById }?.name ?? contact.name
    }

    /// Get involved names as comma-separated string
    private func getInvolvedNames(for splitBill: SplitBill) -> String {
        let currentUserId = UserProfileManager.shared.profile.id
        let names = splitBill.participants.compactMap { participant -> String? in
            guard let person = dataManager.people.first(where: { $0.id == participant.personId }) else {
                return nil
            }
            return person.id == currentUserId ? "You" : person.name
        }
        return names.isEmpty ? contact.name : names.joined(separator: ", ")
    }

    /// Get split method display text
    private func getSplitMethodText(for splitBill: SplitBill) -> String {
        switch splitBill.splitType {
        case .equally: return "Equally"
        case .exactAmounts: return "Exact Amounts"
        case .percentages: return "By Percentage"
        case .shares: return "By Shares"
        case .adjustments: return "With Adjustments"
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            ContactConversationHeader(
                contact: contact,
                balance: contactBalance,
                onBack: { dismiss() }
            )

            // Timeline content
            ChatTimelineView(
                groupedItems: groupedContactTimelineItems,
                emptyStateConfig: TimelineEmptyStateConfig(
                    icon: "bubble.left.and.bubble.right",
                    title: "No dues yet",
                    subtitle: "Create a due to start tracking what you owe or are owed"
                ),
                getItemDirection: getDirection
            ) { item, groupInfo in
                timelineItemView(item: item, groupInfo: groupInfo)
            }

            // Input area with messaging + transaction actions
            ConversationInputView(
                messageText: $messageText,
                placeholder: "iMessage",
                onSend: sendMessage,
                onAddTransaction: {
                    selectedDueDirection = .theyOweMe
                    showingCreateDueSheet = true
                },
                additionalActions: []  // No additional action buttons per design spec
            )
        }
        .background(Color.wiseBackground)
        .navigationBarHidden(true)
        .hidesTabBar()
        .sheet(isPresented: $showingCreateDueSheet) {
            CreateDueSheet(
                isPresented: $showingCreateDueSheet,
                contact: contact,
                direction: selectedDueDirection,
                onDueCreated: {
                    // Refresh happens automatically via dataManager
                }
            )
        }
        .sheet(isPresented: $showingAddTransactionSheet) {
            AddTransactionSheet(
                showingAddTransactionSheet: $showingAddTransactionSheet,
                onTransactionAdded: { transaction in
                    do {
                        try dataManager.addTransaction(transaction)
                        HapticManager.shared.success()
                        ToastManager.shared.showSuccess("Transaction added")
                    } catch {
                        dataManager.error = error
                    }
                },
                preselectedParticipant: selectedPersonForTransaction
            )
        }
        .sheet(isPresented: $showingInviteSheet) {
            InviteSMSSheet(contact: contact, isPresented: $showingInviteSheet)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Timeline Item View

    @ViewBuilder
    private func timelineItemView(item: ContactTimelineItem, groupInfo: MessageGroupInfo) -> some View {
        switch item {
        case .due(let splitBill, let isTheyOweMe):
            let bubbleDirection: iMessageBubbleDirection = isTheyOweMe ? .incoming : .outgoing

            // Professional rectangular transaction card
            ConversationTransactionCardBuilder.split(
                description: splitBill.title,
                amount: formatCurrency(getYourShare(for: splitBill)),
                totalBill: formatCurrency(splitBill.totalAmount),
                paidBy: getPayerName(for: splitBill),
                splitMethod: getSplitMethodText(for: splitBill),
                participants: getInvolvedNames(for: splitBill),
                creatorName: getCreatorName(for: splitBill),
                isUserPayer: isTheyOweMe,  // If they owe me, I was the payer (green), otherwise I owe (orange)
                onTap: {
                    // Handle tap - could navigate to detail view
                    HapticManager.shared.impact(.light)
                }
            )
            .padding(.horizontal, 12)
            .swipeToRevealTimestamp(splitBill.date, direction: bubbleDirection)

        case .settlement:
            // Settlement system messages removed per design spec
            // Chat should only contain text bubbles, transaction bubbles, and date separators
            EmptyView()

        case .textMessage(let message):
            // Text message bubble
            MessageBubbleView(
                message: message,
                showTail: groupInfo.isLastInGroup
            )
            .swipeToRevealTimestamp(
                message.timestamp,
                direction: message.isSent ? .outgoing : .incoming
            )
        }
    }
}

// MARK: - Preview

#Preview("Contact Conversation - With Dues") {
    ContactConversationView(
        contact: ContactEntry(
            id: "1",
            name: "John Smith",
            phoneNumbers: ["+12025551234"],
            email: "john@example.com",
            thumbnailImageData: nil,
            hasAppAccount: false
        )
    )
    .environmentObject(DataManager.shared)
}

#Preview("Contact Conversation - On Swiff") {
    ContactConversationView(
        contact: ContactEntry(
            id: "2",
            name: "Jane Doe",
            phoneNumbers: ["+12025555678"],
            email: nil,
            thumbnailImageData: nil,
            hasAppAccount: true
        )
    )
    .environmentObject(DataManager.shared)
}
