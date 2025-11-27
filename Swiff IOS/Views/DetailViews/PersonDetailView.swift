//
//  PersonDetailView.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Detailed view for person with balance and transaction history
//

import SwiftUI
import Combine

struct PersonDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    let personId: UUID
    @State private var showingEditPerson = false
    @State private var showingDeleteAlert = false
    @State private var showingSettleUpSheet = false
    @State private var showingRecordPaymentSheet = false
    @State private var showingSendReminderSheet = false
    @State private var showingExportSheet = false

    var person: Person? {
        dataManager.people.first { $0.id == personId }
    }

    var personTransactions: [Transaction] {
        guard let person = person else { return [] }
        let personName = person.name
        
        // Filter transactions that mention this person
        let filtered = dataManager.transactions.filter { transaction -> Bool in
            let titleContains = transaction.title.contains(personName)
            let subtitleContains = transaction.subtitle.contains(personName)
            let mentionsPerson = titleContains || subtitleContains
            return mentionsPerson
        }
        
        // Sort by date descending
        let sorted = filtered.sorted { firstTransaction, secondTransaction in
            let firstDate = firstTransaction.date
            let secondDate = secondTransaction.date
            return firstDate > secondDate
        }
        
        return sorted
    }

    var personGroups: [Group] {
        guard let person = person else { return [] }
        return dataManager.groups.filter { group in
            group.members.contains(person.id)
        }
    }

    var body: some View {
        ScrollView {
            if let person = person {
                personDetailContent(for: person)
            } else {
                personNotFoundView
            }
        }
        .background(Color.wiseBackground)
        .navigationTitle(person?.name ?? "Person")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                toolbarContent
            }
        }
        .sheet(isPresented: $showingEditPerson) {
            editPersonSheet
        }
        .sheet(isPresented: $showingSettleUpSheet) {
            settleUpSheet
        }
        .sheet(isPresented: $showingRecordPaymentSheet) {
            recordPaymentSheet
        }
        .sheet(isPresented: $showingSendReminderSheet) {
            sendReminderSheet
        }
        .sheet(isPresented: $showingExportSheet) {
            exportSheet
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

    // MARK: - View Components

    @ViewBuilder
    private func personDetailContent(for person: Person) -> some View {
        VStack(spacing: 24) {
            personHeaderSection(for: person)
            balanceCard(for: person)
            quickActionsSection(for: person)
            analyticsSection(for: person)
            groupsSection
            transactionHistorySection(for: person)
            deletePersonButton
        }
    }

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

    @ViewBuilder
    private func personHeaderSection(for person: Person) -> some View {
        VStack(spacing: 16) {
            // Avatar
            AvatarView(person: person, size: .xxlarge, style: .solid)

            // Name
            Text(person.name)
                .font(.spotifyDisplayMedium)
                .foregroundColor(.wisePrimaryText)

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

    @ViewBuilder
    private func balanceCard(for person: Person) -> some View {
        VStack(spacing: 12) {
            Text("Balance")
                .font(.spotifyLabelLarge)
                .foregroundColor(.wiseSecondaryText)

            Text(String(format: "$%.2f", abs(person.balance)))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(person.balance > 0 ? .wiseBrightGreen : person.balance < 0 ? .wiseError : .wisePrimaryText)

            if person.balance != 0 {
                Text(person.balance > 0 ? "owes you" : "you owe")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
            } else {
                Text("settled up")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseBrightGreen)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.wiseCardBackground)
        .cornerRadius(16)
        .cardShadow()
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func quickActionsSection(for person: Person) -> some View {
        VStack(spacing: 12) {
            // Primary Actions
            HStack(spacing: 12) {
                if person.balance != 0 {
                    PersonQuickActionButton(
                        icon: "checkmark.circle.fill",
                        title: "Settle Up",
                        color: .wiseBrightGreen,
                        action: { showingSettleUpSheet = true }
                    )
                }

                PersonQuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Record Payment",
                    color: .wiseForestGreen,
                    action: { showingRecordPaymentSheet = true }
                )

                PersonQuickActionButton(
                    icon: "bell.fill",
                    title: "Send Reminder",
                    color: .wiseBlue,
                    action: { showingSendReminderSheet = true }
                )
            }

            // Contact Actions
            contactActionsRow(for: person)
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func contactActionsRow(for person: Person) -> some View {
        HStack(spacing: 12) {
            if !person.phone.isEmpty {
                PersonQuickActionButton(
                    icon: "phone.fill",
                    title: "Call",
                    color: .wiseGreen,
                    action: { callPerson(person) }
                )

                PersonQuickActionButton(
                    icon: "message.fill",
                    title: "Message",
                    color: .wiseBlue,
                    action: { messagePerson(person) }
                )
            }

            if !person.email.isEmpty {
                PersonQuickActionButton(
                    icon: "envelope.fill",
                    title: "Email",
                    color: .wiseOrange,
                    action: { emailPerson(person) }
                )
            }
        }
    }

    @ViewBuilder
    private func analyticsSection(for person: Person) -> some View {
        if !personTransactions.isEmpty {
            TransactionStatisticsCard(
                person: person,
                transactions: personTransactions
            )
            .padding(.horizontal, 16)
        }

        if !personTransactions.isEmpty && personTransactions.count >= 3 {
            RecurringPatternsCard(
                person: person,
                transactions: personTransactions
            )
            .padding(.horizontal, 16)
        }

        if !personTransactions.isEmpty {
            PaymentHistoryChart(
                person: person,
                transactions: personTransactions
            )
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private var groupsSection: some View {
        if !personGroups.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Groups")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)
                    .padding(.horizontal, 16)

                VStack(spacing: 12) {
                    ForEach(personGroups) { group in
                        GroupMembershipRow(group: group)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    @ViewBuilder
    private func transactionHistorySection(for person: Person) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transaction History")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                Text("\(personTransactions.count) total")
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wiseSecondaryText)
            }
            .padding(.horizontal, 16)

            if personTransactions.isEmpty {
                transactionEmptyState(for: person)
            } else {
                transactionTimeline
            }
        }
    }

    private func transactionEmptyState(for person: Person) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.wiseSecondaryText.opacity(0.5))

            Text("No transactions yet")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)

            Text("Transactions with \(person.name) will appear here")
                .font(.spotifyBodySmall)
                .foregroundColor(.wiseSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var transactionTimeline: some View {
        VStack(spacing: 0) {
            ForEach(Array(personTransactions.enumerated()), id: \.element.id) { index, transaction in
                PersonTransactionTimelineRow(
                    transaction: transaction,
                    isFirst: index == 0,
                    isLast: index == personTransactions.count - 1,
                    showDate: index == 0 || !Calendar.current.isDate(
                        transaction.date,
                        inSameDayAs: personTransactions[index - 1].date
                    )
                )
            }
        }
        .padding(.horizontal, 16)
    }

    private var deletePersonButton: some View {
        Button(action: { showingDeleteAlert = true }) {
            Text("Delete Person")
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseError)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
    }

    @ViewBuilder
    private var toolbarContent: some View {
        HStack(spacing: 16) {
            if !personTransactions.isEmpty {
                Button(action: { showingExportSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(.wiseForestGreen)
                }
            }

            Button(action: { showingEditPerson = true }) {
                Text("Edit")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseForestGreen)
            }
        }
    }

    @ViewBuilder
    private var editPersonSheet: some View {
        if let person = person {
            AddPersonSheet(
                showingAddPersonSheet: $showingEditPerson,
                editingPerson: person,
                onPersonAdded: { updatedPerson in
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

    @ViewBuilder
    private var settleUpSheet: some View {
        if let person = person {
            SettleUpSheet(person: person, onSettled: {
                showingSettleUpSheet = false
            })
        }
    }

    @ViewBuilder
    private var recordPaymentSheet: some View {
        if let person = person {
            RecordPaymentSheet(person: person, onPaymentRecorded: {
                showingRecordPaymentSheet = false
            })
        }
    }

    @ViewBuilder
    private var sendReminderSheet: some View {
        if let person = person {
            SendReminderSheet(person: person, onReminderSent: {
                showingSendReminderSheet = false
            })
        }
    }

    @ViewBuilder
    private var exportSheet: some View {
        if let person = person {
            ExportTransactionsSheet(
                person: person,
                transactions: personTransactions
            )
        }
    }

    // MARK: - Helper Functions

    private func groupTransactionsByDate(_ transactions: [Transaction]) -> [(key: Date, value: [Transaction])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions) { transaction in
            calendar.startOfDay(for: transaction.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Day name
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
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
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundColor(color)
                    )
                
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
            Circle()
                .fill(Color.wiseBlue.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(group.emoji)
                        .font(.system(size: 24))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)

                Text("\(group.members.count) members · \(group.expenses.count) expenses")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

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
        }
        .padding(12)
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .subtleShadow()
    }
}

// MARK: - Person Transaction Row
struct PersonTransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(transaction.category.color.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: transaction.category.icon)
                        .font(.system(size: 20))
                        .foregroundColor(transaction.category.color)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)

                Text(transaction.subtitle)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)

                Text(transaction.date, style: .time)
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            Text(transaction.amountWithSign)
                .font(.spotifyNumberSmall)
                .foregroundColor(transaction.isExpense ? .wiseError : .wiseBrightGreen)
        }
        .padding(12)
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .subtleShadow()
    }
}

// MARK: - Person Transaction Timeline Row
struct PersonTransactionTimelineRow: View {
    let transaction: Transaction
    let isFirst: Bool
    let isLast: Bool
    let showDate: Bool

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Date Header (if needed)
            if showDate {
                Text(dateFormatter.string(from: transaction.date))
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .padding(.bottom, 12)
                    .padding(.top, isFirst ? 0 : 24)
            }

            // Timeline Row
            HStack(alignment: .top, spacing: 12) {
                // Timeline indicator (left side)
                VStack(spacing: 0) {
                    // Top line
                    if !isFirst && !showDate {
                        Rectangle()
                            .fill(Color.wiseBorder)
                            .frame(width: 2, height: 20)
                    } else {
                        Spacer()
                            .frame(height: 20)
                    }

                    // Dot
                    Circle()
                        .fill(transaction.isExpense ? Color.wiseError : Color.wiseBrightGreen)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.wiseCardBackground, lineWidth: 2)
                        )

                    // Bottom line
                    if !isLast {
                        Rectangle()
                            .fill(Color.wiseBorder)
                            .frame(width: 2)
                            .frame(minHeight: 60)
                    }
                }
                .frame(width: 12)

                // Transaction Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        // Category Icon
                        Circle()
                            .fill(transaction.category.color.opacity(0.15))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: transaction.category.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(transaction.category.color)
                            )

                        // Transaction Details
                        VStack(alignment: .leading, spacing: 4) {
                            Text(transaction.title)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)

                            Text(transaction.subtitle)
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseSecondaryText)

                            HStack(spacing: 4) {
                                Text(transaction.date, style: .time)
                                    .font(.spotifyCaptionSmall)
                                    .foregroundColor(.wiseSecondaryText.opacity(0.7))

                                if !transaction.tags.isEmpty {
                                    Text("•")
                                        .font(.spotifyCaptionSmall)
                                        .foregroundColor(.wiseSecondaryText.opacity(0.5))

                                    Text(transaction.tags.first ?? "")
                                        .font(.spotifyCaptionSmall)
                                        .foregroundColor(.wiseSecondaryText.opacity(0.7))
                                }
                            }
                        }

                        Spacer()

                        // Amount
                        Text(transaction.amountWithSign)
                            .font(.spotifyNumberSmall)
                            .fontWeight(.semibold)
                            .foregroundColor(transaction.isExpense ? .wiseError : .wiseBrightGreen)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.wiseCardBackground)
                            .subtleShadow()
                    )
                }
            }
        }
    }
}

// MARK: - Settle Up Sheet
struct SettleUpSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    let person: Person
    let onSettled: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                // Amount Display
                VStack(spacing: 12) {
                    Text(person.balance > 0 ? "\(person.name) owes you" : "You owe \(person.name)")
                        .font(.spotifyHeadingMedium)
                        .foregroundColor(.wisePrimaryText)

                    Text(String(format: "$%.2f", abs(person.balance)))
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(person.balance > 0 ? .wiseBrightGreen : .wiseError)
                }

                Spacer()

                // Settle Button
                Button(action: settleUp) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                        Text("Mark as Settled")
                            .font(.spotifyBodyLarge)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.wiseBrightGreen)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
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
        updatedPerson.balance = 0.0

        do {
            try dataManager.updatePerson(updatedPerson)
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
                .padding(.horizontal, 20)
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

// MARK: - Export Transactions Sheet
struct ExportTransactionsSheet: View {
    @Environment(\.dismiss) var dismiss
    let person: Person
    let transactions: [Transaction]

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                // Icon
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.wiseForestGreen)

                // Title
                Text("Export Transactions")
                    .font(.spotifyHeadingLarge)
                    .foregroundColor(.wisePrimaryText)

                // Description
                Text("Export \(transactions.count) transaction\(transactions.count == 1 ? "" : "s") with \(person.name) to CSV format")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                // Export Button
                Button(action: exportTransactions) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 18))
                        Text("Export to CSV")
                            .font(.spotifyBodyLarge)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.wiseForestGreen)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.wiseBackground)
            .navigationTitle("Export")
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

    private func exportTransactions() {
        // Generate CSV content
        let csvService = CSVExportService()
        let csvContent = csvService.generateCSV(
            transactions: transactions,
            person: person
        )

        // Create temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(person.name)_transactions.csv")

        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)

            // Present share sheet
            let activityController = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let viewController = windowScene.windows.first?.rootViewController {
                viewController.present(activityController, animated: true)
            }

            dismiss()
        } catch {
            print("Error exporting transactions: \(error)")
        }
    }
}

// MARK: - Transaction Statistics Card
struct TransactionStatisticsCard: View {
    let person: Person
    let transactions: [Transaction]

    // Calculate statistics
    var totalTransactions: Int {
        transactions.count
    }

    var totalPaidToThem: Double {
        transactions.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) }
    }

    var totalReceivedFromThem: Double {
        transactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
    }

    var averageTransactionAmount: Double {
        guard totalTransactions > 0 else { return 0 }
        let total = transactions.reduce(0) { $0 + abs($1.amount) }
        return total / Double(totalTransactions)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transaction Statistics")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            // Grid of 4 statistics
            VStack(spacing: 12) {
                // Row 1
                HStack(spacing: 12) {
                    StatisticBox(
                        title: "Total Transactions",
                        value: "\(totalTransactions)",
                        icon: "doc.text.fill",
                        color: .wiseBlue
                    )

                    StatisticBox(
                        title: "Avg Amount",
                        value: String(format: "$%.2f", averageTransactionAmount),
                        icon: "chart.bar.fill",
                        color: .wiseGreen
                    )
                }

                // Row 2
                HStack(spacing: 12) {
                    StatisticBox(
                        title: "Paid to Them",
                        value: String(format: "$%.2f", totalPaidToThem),
                        icon: "arrow.up.circle.fill",
                        color: .wiseError
                    )

                    StatisticBox(
                        title: "Received from Them",
                        value: String(format: "$%.2f", totalReceivedFromThem),
                        icon: "arrow.down.circle.fill",
                        color: .wiseBrightGreen
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.wiseCardBackground)
                .cardShadow()
        )
    }
}

// MARK: - Recurring Patterns Card
struct RecurringPatternsCard: View {
    let person: Person
    let transactions: [Transaction]

    // Detect recurring patterns
    var recurringPatterns: [RecurringPattern] {
        detectRecurringPatterns()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "repeat.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.wiseBlue)

                Text("Recurring Patterns")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                if !recurringPatterns.isEmpty {
                    Text("\(recurringPatterns.count) found")
                        .font(.spotifyLabelMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }

            if recurringPatterns.isEmpty {
                // No patterns found
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 32))
                        .foregroundColor(.wiseSecondaryText.opacity(0.5))

                    Text("No recurring patterns detected")
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)

                    Text("Patterns will appear after more transactions")
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Show patterns
                VStack(spacing: 12) {
                    ForEach(recurringPatterns) { pattern in
                        RecurringPatternRow(pattern: pattern)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.wiseCardBackground)
                .cardShadow()
        )
    }

    // Pattern detection algorithm
    private func detectRecurringPatterns() -> [RecurringPattern] {
        guard transactions.count >= 3 else { return [] }

        var patterns: [RecurringPattern] = []

        // Group transactions by amount (similar amounts within 10%)
        let sortedByDate = transactions.sorted { $0.date < $1.date }
        var amountGroups: [Double: [Transaction]] = [:]

        for transaction in sortedByDate {
            let amount = abs(transaction.amount)
            var foundGroup = false

            for (groupAmount, _) in amountGroups {
                let tolerance = groupAmount * 0.1 // 10% tolerance
                if abs(amount - groupAmount) <= tolerance {
                    amountGroups[groupAmount, default: []].append(transaction)
                    foundGroup = true
                    break
                }
            }

            if !foundGroup {
                amountGroups[amount] = [transaction]
            }
        }

        // Analyze each group for recurring patterns
        for (amount, groupTransactions) in amountGroups {
            guard groupTransactions.count >= 3 else { continue }

            // Calculate average interval between transactions
            let intervals = calculateIntervals(groupTransactions)
            guard !intervals.isEmpty else { continue }

            let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
            let intervalVariance = calculateVariance(intervals, mean: avgInterval)

            // If intervals are relatively consistent (low variance), it's a pattern
            if intervalVariance < avgInterval * 0.3 { // 30% variance threshold
                let frequency = determineFrequency(avgInterval)
                let lastTransaction = groupTransactions.last!
                let nextExpectedDate = Calendar.current.date(byAdding: .day, value: Int(avgInterval), to: lastTransaction.date)!

                patterns.append(RecurringPattern(
                    id: UUID(),
                    amount: amount,
                    frequency: frequency,
                    occurrences: groupTransactions.count,
                    lastDate: lastTransaction.date,
                    nextExpectedDate: nextExpectedDate,
                    category: groupTransactions.first?.category ?? .other,
                    isExpense: groupTransactions.first?.isExpense ?? false
                ))
            }
        }

        return patterns.sorted { $0.occurrences > $1.occurrences }
    }

    private func calculateIntervals(_ transactions: [Transaction]) -> [Double] {
        guard transactions.count >= 2 else { return [] }
        let sorted = transactions.sorted { $0.date < $1.date }
        var intervals: [Double] = []

        for i in 1..<sorted.count {
            let interval = sorted[i].date.timeIntervalSince(sorted[i-1].date) / 86400 // Convert to days
            intervals.append(interval)
        }

        return intervals
    }

    private func calculateVariance(_ values: [Double], mean: Double) -> Double {
        guard !values.isEmpty else { return 0 }
        let squaredDiffs = values.map { pow($0 - mean, 2) }
        return squaredDiffs.reduce(0, +) / Double(values.count)
    }

    private func determineFrequency(_ avgDays: Double) -> String {
        if avgDays <= 1.5 {
            return "Daily"
        } else if avgDays <= 8 {
            return "Weekly"
        } else if avgDays <= 16 {
            return "Bi-weekly"
        } else if avgDays <= 35 {
            return "Monthly"
        } else if avgDays <= 95 {
            return "Quarterly"
        } else {
            return "Yearly"
        }
    }
}

// MARK: - Recurring Pattern Model
struct RecurringPattern: Identifiable {
    let id: UUID
    let amount: Double
    let frequency: String
    let occurrences: Int
    let lastDate: Date
    let nextExpectedDate: Date
    let category: TransactionCategory
    let isExpense: Bool
}

// MARK: - Recurring Pattern Row
struct RecurringPatternRow: View {
    let pattern: RecurringPattern

    private var daysUntilNext: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: pattern.nextExpectedDate).day ?? 0
    }

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Circle()
                .fill(pattern.category.color.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: pattern.category.icon)
                        .font(.system(size: 18))
                        .foregroundColor(pattern.category.color)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(String(format: "$%.2f", pattern.amount))
                        .font(.spotifyBodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.wisePrimaryText)

                    Text("•")
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText)

                    Text(pattern.frequency)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseBlue)
                }

                Text("\(pattern.occurrences) times • Last: \(formatDate(pattern.lastDate))")
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(.wiseSecondaryText)

                if daysUntilNext >= 0 {
                    Text("Next expected in \(daysUntilNext) day\(daysUntilNext == 1 ? "" : "s")")
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseGreen)
                } else {
                    Text("Overdue by \(abs(daysUntilNext)) day\(abs(daysUntilNext) == 1 ? "" : "s")")
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseError)
                }
            }

            Spacer()

            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 16))
                .foregroundColor(.wiseSecondaryText.opacity(0.5))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.wiseBorder.opacity(0.2))
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Payment History Chart
struct PaymentHistoryChart: View {
    let person: Person
    let transactions: [Transaction]

    // Group transactions by month
    var monthlyData: [MonthlyData] {
        groupTransactionsByMonth()
    }

    var maxAmount: Double {
        monthlyData.map { max(abs($0.totalPaid), abs($0.totalReceived)) }.max() ?? 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.wiseGreen)

                Text("Payment History")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                Text("Last 6 months")
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wiseSecondaryText)
            }

            if monthlyData.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 32))
                        .foregroundColor(.wiseSecondaryText.opacity(0.5))

                    Text("No payment history")
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Chart
                VStack(spacing: 8) {
                    // Bar chart
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(monthlyData) { data in
                            VStack(spacing: 4) {
                                // Bars
                                HStack(spacing: 2) {
                                    // Paid bar (red)
                                    if data.totalPaid > 0 {
                                        VStack {
                                            Spacer()
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.wiseError.opacity(0.8))
                                                .frame(width: 20, height: CGFloat(data.totalPaid / maxAmount) * 100)
                                        }
                                    }

                                    // Received bar (green)
                                    if data.totalReceived > 0 {
                                        VStack {
                                            Spacer()
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.wiseBrightGreen.opacity(0.8))
                                                .frame(width: 20, height: CGFloat(data.totalReceived / maxAmount) * 100)
                                        }
                                    }

                                    if data.totalPaid == 0 && data.totalReceived == 0 {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.wiseBorder.opacity(0.3))
                                            .frame(width: 20, height: 4)
                                    }
                                }
                                .frame(height: 120)

                                // Month label
                                Text(data.monthLabel)
                                    .font(.spotifyCaptionSmall)
                                    .foregroundColor(.wiseSecondaryText)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 140)

                    // Legend
                    HStack(spacing: 20) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.wiseError.opacity(0.8))
                                .frame(width: 8, height: 8)

                            Text("Paid to them")
                                .font(.spotifyCaptionSmall)
                                .foregroundColor(.wiseSecondaryText)
                        }

                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.wiseBrightGreen.opacity(0.8))
                                .frame(width: 8, height: 8)

                            Text("Received from them")
                                .font(.spotifyCaptionSmall)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.wiseCardBackground)
                .cardShadow()
        )
    }

    private func groupTransactionsByMonth() -> [MonthlyData] {
        let calendar = Calendar.current
        let today = Date()
        var monthlyDataDict: [String: (paid: Double, received: Double)] = [:]

        // Get last 6 months
        var months: [Date] = []
        for i in (0..<6).reversed() {
            if let monthDate = calendar.date(byAdding: .month, value: -i, to: today) {
                months.append(monthDate)
            }
        }

        // Initialize all months with zero
        for month in months {
            let monthKey = formatMonthKey(month)
            monthlyDataDict[monthKey] = (0, 0)
        }

        // Aggregate transactions by month
        for transaction in transactions {
            let monthKey = formatMonthKey(transaction.date)

            if let existing = monthlyDataDict[monthKey] {
                if transaction.isExpense {
                    monthlyDataDict[monthKey] = (existing.paid + abs(transaction.amount), existing.received)
                } else {
                    monthlyDataDict[monthKey] = (existing.paid, existing.received + abs(transaction.amount))
                }
            }
        }

        // Convert to array and sort by date
        return months.map { month in
            let monthKey = formatMonthKey(month)
            let data = monthlyDataDict[monthKey] ?? (0, 0)
            return MonthlyData(
                id: UUID(),
                month: month,
                monthLabel: formatMonthLabel(month),
                totalPaid: data.paid,
                totalReceived: data.received
            )
        }
    }

    private func formatMonthKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    private func formatMonthLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
}

// MARK: - Monthly Data Model
// Note: MonthlyData is defined in AnalyticsModels.swift

// MARK: - Statistic Box Component
struct StatisticBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)

                Text(title)
                    .font(.spotifyLabelSmall)
                    .foregroundColor(.wiseSecondaryText)
            }

            Text(value)
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseBorder.opacity(0.2))
        )
    }
}

#Preview {
    NavigationView {
        PersonDetailView(personId: UUID())
            .environmentObject(DataManager.shared)
    }
}
