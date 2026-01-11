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

    public let personId: UUID

    public init(personId: UUID) {
        self.personId = personId
    }

    // Message input state
    @State private var messageText: String = ""

    // Sheet presentation states
    @State private var showingEditPerson = false
    @State private var showingDeleteAlert = false
    @State private var showingSettleUpSheet = false
    @State private var showingRecordPaymentSheet = false
    @State private var showingAddTransactionSheet = false

    // MARK: - Computed Properties

    var person: Person? {
        dataManager.people.first { $0.id == personId }
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
        let items = personTransactions.map { PersonTimelineItem.transaction($0, person) }

        let grouped = Dictionary(grouping: items) { item in
            Calendar.current.startOfDay(for: item.timestamp)
        }

        return grouped.sorted { $0.key > $1.key }.map {
            ($0.key, $0.value.sorted { $0.timestamp > $1.timestamp })
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if let person = person {
                // Compact header with Edit button
                PersonConversationHeader(
                    person: person,
                    onBack: { dismiss() },
                    onEdit: { showingEditPerson = true }
                )

                // Timeline content
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
                    // Use the redesigned bubble card
                    TransactionBubbleCard(
                        transaction: transaction,
                        personName: person.name
                    )
                    .padding(.horizontal, 16)

                case .payment(_, let amount, let direction, let description, let date):
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
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                    }

                case .splitRequest(_, let title, _, let billTotal, _, let youOwe, let date):
                    ChatBubble(
                        direction: youOwe > 0 ? .incoming : .outgoing,
                        timestamp: date
                    ) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 14))
                                Text("Split Bill Request")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            Text(title)
                                .font(.system(size: 16))
                                .padding(.top, 2)
                            
                            Text("Total: \(billTotal.asCurrency)")
                                .font(.system(size: 14))
                                .opacity(0.8)

                            if youOwe > 0 {
                                Text("You owe: \(youOwe.asCurrency)")
                                    .font(.system(size: 16, weight: .bold))
                                    .padding(.top, 2)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                    }

                case .settlement(_, _):
                    ChatBubble(direction: .center, timestamp: nil) {
                        SystemMessageBubble(text: "Balances settled", icon: "checkmark.circle.fill")
                    }

                case .paidBill(_, let personName, _):
                    ChatBubble(direction: .center, timestamp: nil) {
                        SystemMessageBubble(
                            text: "\(personName) paid a bill", icon: "checkmark.seal.fill")
                    }

                case .reminder(_, let date):
                    ChatBubble(direction: .outgoing, timestamp: date) {
                        Text("Reminder sent")
                            .font(.system(size: 16))
                            .italic()
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                    }
                }
            }

            ConversationInputView(
                messageText: $messageText,
                placeholder: "iMessage",
                onSend: { message in
                    sendMessage(message, to: person)
                },
                onAddTransaction: { showingAddTransactionSheet = true },
                additionalActions: []  // No additional action buttons per design spec
            )
        }
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

    // MARK: - Send Message

    private func sendMessage(_ content: String, to person: Person) {
        do {
            try dataManager.sendMessage(
                to: person.id,
                entityType: .person,
                content: content
            )
            HapticManager.shared.impact(.light)
        } catch {
            print("Failed to send message: \(error)")
            ToastManager.shared.showError("Failed to send message")
        }
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

                            Text(totalBalance.asCurrency)
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundColor(person.balance > 0 ? .wiseBrightGreen : .wiseError)
                        } else {
                            Text("Enter partial amount")
                                .font(.spotifyHeadingMedium)
                                .foregroundColor(.wisePrimaryText)

                            HStack {
                                Text(CurrencyFormatter.shared.getCurrencySymbol())
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.wisePrimaryText)

                                TextField("0.00", text: $partialAmount)
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.wisePrimaryText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 16)

                            Text("Total balance: \(totalBalance.asCurrency)")
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
                                Text(settlementAmount.asCurrency)
                                    .font(.spotifyBodyMedium)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.wisePrimaryText)
                            }

                            HStack {
                                Text("Remaining:")
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wiseSecondaryText)
                                Spacer()
                                Text((totalBalance - settlementAmount).asCurrency)
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
                    ? "Full settlement" : "\(settlementAmount.asCurrency) partial payment",
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
                            Text(CurrencyFormatter.shared.getCurrencySymbol())
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

