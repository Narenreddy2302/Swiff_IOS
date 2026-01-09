//
//  ContactConversationView.swift
//  Swiff IOS
//
//  Created by Claude Code on 1/8/26.
//  Full-screen conversation view for contacts (WhatsApp-style)
//  Shows dues history and actions for creating/managing dues
//

import SwiftUI

struct ContactConversationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    let contact: ContactEntry

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

    /// Group dues by date for timeline display
    private var groupedContactTimelineItems: [(Date, [ContactTimelineItem])] {
        // Convert dues to timeline items
        let items: [ContactTimelineItem] = contactDues.map { splitBill in
            // Determine direction: if payer is current user, they owe me
            let currentUserId = UserProfileManager.shared.profile.id
            let isTheyOweMe = splitBill.paidById == currentUserId
            return .due(splitBill, isTheyOweMe: isTheyOweMe)
        }

        // Group by date
        let grouped = Dictionary(grouping: items) { item in
            Calendar.current.startOfDay(for: item.timestamp)
        }

        // Sort by date (newest first)
        return grouped.sorted { $0.key > $1.key }.map {
            ($0.key, $0.value.sorted { $0.timestamp > $1.timestamp })
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
            ZStack(alignment: .bottom) {
                ChatTimelineView(
                    groupedItems: groupedContactTimelineItems,
                    emptyStateConfig: TimelineEmptyStateConfig(
                        icon: "bubble.left.and.bubble.right",
                        title: "No dues yet",
                        subtitle: "Create a due to start tracking what you owe or are owed"
                    )
                ) { item in
                    switch item {
                    case .due(let splitBill, let isTheyOweMe):
                        ChatBubble(
                            direction: isTheyOweMe ? .incoming : .outgoing,
                            timestamp: splitBill.date
                        ) {
                            DueBubbleContent(
                                splitBill: splitBill,
                                isTheyOweMe: isTheyOweMe
                            )
                        }

                    case .settlement(_, let amount, let date):
                        ChatBubble(direction: .center, timestamp: nil) {
                            SystemMessageBubble(
                                text: "Payment of \(String(format: "$%.2f", amount)) received",
                                icon: "checkmark.circle.fill"
                            )
                        }
                    }
                }

                // Action bar
                ContactActionBar(
                    contact: contact,
                    onTheyOweMe: {
                        selectedDueDirection = .theyOweMe
                        showingCreateDueSheet = true
                    },
                    onIOwe: {
                        selectedDueDirection = .iOweThem
                        showingCreateDueSheet = true
                    },
                    onSplitBill: {
                        // Import contact and open add transaction sheet
                        do {
                            let person = try dataManager.importContact(contact)
                            selectedPersonForTransaction = person
                            showingAddTransactionSheet = true
                        } catch {
                            dataManager.error = error
                        }
                    },
                    onInvite: contact.hasAppAccount ? nil : {
                        showingInviteSheet = true
                    }
                )
            }
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
