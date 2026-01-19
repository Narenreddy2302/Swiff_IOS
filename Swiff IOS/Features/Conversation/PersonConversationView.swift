//
//  PersonConversationView.swift
//  Swiff IOS
//
//  Professional conversation view for person/group chats
//  Combines messages, transactions, and system updates in a clean timeline
//  Follows Apple Messages design patterns and industry standards
//

import SwiftUI

// MARK: - Person Conversation View

/// Professional conversation view with messages and transactions
/// This is the main view users see when chatting with a person or in a group
struct PersonConversationView: View {
    // Data
    let person: Person?
    let group: Group?
    let members: [Person]
    
    // State
    @State private var messageText: String = ""
    @FocusState private var isMessageFieldFocused: Bool
    @State private var showingTransactionSheet: Bool = false
    
    // Callbacks
    var onBack: (() -> Void)?
    var onInfo: (() -> Void)?
    var onSendMessage: ((String) -> Void)?
    var onAddTransaction: (() -> Void)?
    
    // Mock data for demo
    @State private var conversationItems: [ConversationItem] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            if let person = person {
                CompactPersonHeader(
                    person: person,
                    balance: calculateBalance(),
                    onBack: onBack,
                    onInfo: onInfo
                )
            } else if let group = group {
                CompactGroupHeader(
                    group: group,
                    members: members,
                    balance: calculateBalance(),
                    onBack: onBack,
                    onInfo: onInfo
                )
            }
            
            // Timeline with messages and transactions
            ConversationTimelineView(
                items: conversationItems
            )
            
            // Input bar
            ConversationInputBarWrapper(
                onSendMessage: { text in
                    handleSendMessage(text)
                },
                onAddTransaction: {
                    showingTransactionSheet = true
                    onAddTransaction?()
                },
                onScrollToBottom: {
                    // Scroll to bottom logic
                }
            )
        }
        .background(Color.wiseBackground)
        .navigationBarHidden(true)
        .onAppear {
            loadMockData()
        }
    }
    
    // MARK: - Helpers
    
    private func calculateBalance() -> ConversationBalance? {
        // Mock balance calculation
        return ConversationBalance(amount: 500.0, type: .theyOwe)
    }
    
    private func handleSendMessage(_ text: String) {
        let newMessage = ConversationItem.message(
            id: UUID(),
            text: text,
            timestamp: Date(),
            isFromCurrentUser: true
        )
        conversationItems.append(newMessage)
        onSendMessage?(text)
    }
    
    private func loadMockData() {
        conversationItems = [
            .message(
                id: UUID(),
                text: "Hey! Want to grab lunch this week?",
                timestamp: Date().addingTimeInterval(-86400 * 2),
                isFromCurrentUser: false
            ),
            .message(
                id: UUID(),
                text: "Sure! How about Thursday?",
                timestamp: Date().addingTimeInterval(-86400 * 2 + 300),
                isFromCurrentUser: true
            ),
            .systemMessage(
                id: UUID(),
                message: "You created the transaction",
                icon: "checkmark.circle.fill",
                timestamp: Date().addingTimeInterval(-86400 * 2 + 600)
            ),
            .transaction(
                id: UUID(),
                card: ConversationTransactionCardBuilder.request(
                    from: "Li Wei",
                    amount: "$500.00",
                    totalBill: "$500.00",
                    paidBy: "You",
                    splitMethod: "Equally",
                    participants: "You, Li Wei",
                    creatorName: "You",
                    onTap: {}
                ),
                timestamp: Date().addingTimeInterval(-86400 * 2 + 600)
            ),
            .message(
                id: UUID(),
                text: "Coffee last week",
                timestamp: Date().addingTimeInterval(-86400),
                isFromCurrentUser: true,
                hasAttachment: .payment(amount: "$8.50")
            ),
            .systemMessage(
                id: UUID(),
                message: "You created the transaction",
                icon: "checkmark.circle.fill",
                timestamp: Date()
            ),
            .transaction(
                id: UUID(),
                card: ConversationTransactionCardBuilder.payment(
                    to: "Li Wei",
                    amount: "$250.00",
                    totalBill: "$250.00",
                    paidBy: "You",
                    splitMethod: "Equally",
                    participants: "You, Li Wei",
                    creatorName: "You",
                    onTap: {}
                ),
                timestamp: Date()
            )
        ]
    }
}

// MARK: - Conversation Item

/// Unified item type for conversation timeline
enum ConversationItem: Identifiable {
    case message(id: UUID, text: String, timestamp: Date, isFromCurrentUser: Bool, hasAttachment: MessageAttachment? = nil)
    case transaction(id: UUID, card: ConversationTransactionCard, timestamp: Date)
    case systemMessage(id: UUID, message: String, icon: String?, timestamp: Date)
    
    var id: UUID {
        switch self {
        case .message(let id, _, _, _, _): return id
        case .transaction(let id, _, _): return id
        case .systemMessage(let id, _, _, _): return id
        }
    }
    
    var timestamp: Date {
        switch self {
        case .message(_, _, let timestamp, _, _): return timestamp
        case .transaction(_, _, let timestamp): return timestamp
        case .systemMessage(_, _, _, let timestamp): return timestamp
        }
    }
}

enum MessageAttachment {
    case payment(amount: String)
    case request(amount: String)
    case photo
}

// MARK: - Conversation Timeline View

/// Timeline view that displays all conversation items
struct ConversationTimelineView: View {
    let items: [ConversationItem]
    
    // Group items by date
    private var groupedItems: [(Date, [ConversationItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: items) { item in
            calendar.startOfDay(for: item.timestamp)
        }
        return grouped.sorted { $0.key < $1.key }
            .map { ($0.key, $0.value.sorted { $0.timestamp < $1.timestamp }) }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(groupedItems, id: \.0) { date, dateItems in
                        VStack(spacing: 0) {
                            // Date header
                            ChatDateHeader(date: date)
                                .padding(.vertical, 24)
                            
                            // Items for this date
                            ForEach(Array(dateItems.enumerated()), id: \.element.id) { index, item in
                                conversationItemView(for: item)
                                    .id(item.id)
                                    .padding(.top, index == 0 ? 0 : itemSpacing(
                                        previous: index > 0 ? dateItems[index - 1] : nil,
                                        current: item
                                    ))
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    @ViewBuilder
    private func conversationItemView(for item: ConversationItem) -> some View {
        switch item {
        case .message(_, let text, let timestamp, let isFromCurrentUser, let attachment):
            ChatBubble(
                direction: isFromCurrentUser ? .outgoing : .incoming,
                timestamp: timestamp
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(text)
                        .font(.system(size: 16))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                    
                    if let attachment = attachment {
                        attachmentView(for: attachment)
                    }
                }
            }
            
        case .transaction(_, let card, _):
            // Transaction card with proper horizontal padding
            card
                .padding(.horizontal, 12)
            
        case .systemMessage(_, let message, let icon, _):
            SystemMessageView(message: message, icon: icon)
                .padding(.vertical, 4)
        }
    }
    
    @ViewBuilder
    private func attachmentView(for attachment: MessageAttachment) -> some View {
        switch attachment {
        case .payment(let amount):
            HStack(spacing: 8) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 14))
                Text("Payment")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text(amount)
                    .font(.system(size: 16, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
            
        case .request(let amount):
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 14))
                Text("Request")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text(amount)
                    .font(.system(size: 16, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
            
        case .photo:
            EmptyView()
        }
    }
    
    private func itemSpacing(previous: ConversationItem?, current: ConversationItem) -> CGFloat {
        guard let previous = previous else { return 0 }
        
        // Tighter spacing for messages from same sender
        if case .message(_, _, _, let prevIsFromUser, _) = previous,
           case .message(_, _, _, let currIsFromUser, _) = current,
           prevIsFromUser == currIsFromUser {
            return 2
        }
        
        // Wider spacing for different senders or types
        return 16
    }
}

// MARK: - Compact Person Header (Placeholder)

/// Placeholder for person header - similar to group header
struct CompactPersonHeader: View {
    let person: Person
    let balance: ConversationBalance?
    var onBack: (() -> Void)?
    var onInfo: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            BaseConversationHeader(
                onBack: onBack,
                leading: {
                    Circle()
                        .fill(Color.wiseBrightGreen.opacity(0.2))
                        .frame(width: Theme.Metrics.avatarCompact, height: Theme.Metrics.avatarCompact)
                        .overlay(
                            Text(person.initials)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.wiseBrightGreen)
                        )
                },
                title: {
                    HeaderTitleView(
                        title: person.name,
                        subtitle: balance?.formattedBalance ?? "No balance"
                    )
                },
                trailing: {
                    if let onInfo = onInfo {
                        Button(action: onInfo) {
                            Image(systemName: "info.circle")
                                .iconActionButtonStyle(color: .wiseForestGreen)
                        }
                        .accessibilityLabel("Person info")
                    }
                }
            )
            
            if let balance = balance {
                ConversationBalanceBanner(balance: balance)
            }
        }
    }
}

// NOTE: Person.initials is defined in Models/Domain/Person.swift - do not duplicate here
