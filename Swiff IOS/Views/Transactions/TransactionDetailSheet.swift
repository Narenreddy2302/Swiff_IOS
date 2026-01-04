//
//  TransactionDetailSheet.swift
//  Swiff IOS
//
//  Bottom sheet popup for transaction details
//  Replaces full-page navigation with compact card-based layout
//

import SwiftUI

// MARK: - Entity Type for Sheet Display

/// Determines how the transaction is displayed in the detail sheet
enum SheetEntityType: String, CaseIterable {
    case contact = "Contact"
    case group = "Group"
    case subscription = "Subscription"

    var icon: String {
        switch self {
        case .contact: return "person.fill"
        case .group: return "person.3.fill"
        case .subscription: return "arrow.triangle.2.circlepath"
        }
    }

    func label(isIncome: Bool) -> String {
        switch self {
        case .contact: return isIncome ? "Received From" : "Payment To"
        case .group: return "Group Expense"
        case .subscription: return "Subscription"
        }
    }

    var badgeText: String {
        rawValue.uppercased()
    }

    var badgeColors: (bg: Color, text: Color) {
        switch self {
        case .contact:
            return (Color(red: 0.859, green: 0.914, blue: 1.0),
                    Color(red: 0.114, green: 0.306, blue: 0.851))
        case .group:
            return (Color(red: 0.953, green: 0.910, blue: 1.0),
                    Color(red: 0.576, green: 0.200, blue: 0.918))
        case .subscription:
            return (Color(red: 0.996, green: 0.953, blue: 0.780),
                    Color(red: 0.702, green: 0.263, blue: 0.035))
        }
    }
}

// MARK: - Transaction Detail Sheet

struct TransactionDetailSheet: View {
    let transaction: Transaction
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var showToast = false
    @State private var toastMessage = ""

    // MARK: - Computed Properties

    private var entityType: SheetEntityType {
        if transaction.linkedSubscriptionId != nil {
            return .subscription
        } else if transaction.splitBillId != nil {
            return .group
        }
        return .contact
    }

    private var entityName: String {
        // Subscription
        if let subscriptionId = transaction.linkedSubscriptionId,
           let subscription = dataManager.subscriptions.first(where: { $0.id == subscriptionId }) {
            return subscription.name
        }

        // Group/Split Bill
        if let splitBillId = transaction.splitBillId {
            if let splitBill = dataManager.splitBills.first(where: { $0.id == splitBillId }) {
                if let group = dataManager.groups.first(where: { $0.expenses.contains(where: { $0.id == splitBillId }) }) {
                    return group.name
                }
                return splitBill.title
            }
        }

        // Contact - check if it matches a person
        if let person = dataManager.people.first(where: { $0.name.lowercased() == transaction.title.lowercased() }) {
            return person.name
        }

        // Fallback
        return transaction.merchant ?? transaction.title
    }

    private var splitBill: SplitBill? {
        guard let splitBillId = transaction.splitBillId else { return nil }
        return dataManager.splitBills.first(where: { $0.id == splitBillId })
    }

    private var subscription: Subscription? {
        guard let subscriptionId = transaction.linkedSubscriptionId else { return nil }
        return dataManager.subscriptions.first(where: { $0.id == subscriptionId })
    }

    private var avatarColor: FeedAvatarColor {
        FeedAvatarColor.forName(transaction.displayName)
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let formatted = formatter.string(from: NSNumber(value: abs(transaction.amount))) ?? String(format: "%.2f", abs(transaction.amount))
        let prefix = transaction.isExpense ? "-$" : "+$"
        return "\(prefix)\(formatted)"
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Drag Indicator
                RoundedRectangle(cornerRadius: 100)
                    .fill(Color(red: 0.886, green: 0.906, blue: 0.925))
                    .frame(width: 36, height: 4)
                    .padding(.top, 10)

                // Header
                HStack {
                    Text("Transaction Details")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Theme.Colors.feedPrimaryText)

                    Spacer()

                    Button(action: { dismiss() }) {
                        Circle()
                            .fill(Color(red: 0.945, green: 0.957, blue: 0.965))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Theme.Colors.feedPrimaryText)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)

                // Summary Card
                SheetSummaryCard(
                    transaction: transaction,
                    entityName: entityName,
                    avatarColor: avatarColor,
                    formattedAmount: formattedAmount
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // Info Card
                SheetInfoCard(
                    transaction: transaction,
                    entityType: entityType,
                    entityName: entityName,
                    splitBill: splitBill,
                    subscription: subscription
                )
                .environmentObject(dataManager)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // Details Grid
                SheetDetailsGrid(transaction: transaction)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                // Action Buttons
                HStack(spacing: 10) {
                    // Share Button
                    Button(action: {
                        toastMessage = "Link copied!"
                        showToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showToast = false
                        }
                    }) {
                        Text("Share")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.Colors.feedPrimaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(red: 0.945, green: 0.957, blue: 0.965))
                            .cornerRadius(12)
                    }

                    // Repeat Button
                    Button(action: { repeatTransaction() }) {
                        Text("Repeat")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(red: 0.020, green: 0.588, blue: 0.412))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.016, green: 0.502, blue: 0.353), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Color.white)

            // Toast
            if showToast {
                SheetToast(message: toastMessage)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 20)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showToast)
        .presentationDetents([.height(580)])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Actions

    private func repeatTransaction() {
        let duplicate = Transaction(
            title: transaction.title,
            subtitle: transaction.subtitle,
            amount: transaction.amount,
            category: transaction.category,
            date: Date(),
            isRecurring: false,
            tags: transaction.tags,
            merchant: transaction.merchant,
            paymentStatus: .completed,
            linkedSubscriptionId: transaction.linkedSubscriptionId,
            merchantCategory: transaction.merchantCategory,
            paymentMethod: transaction.paymentMethod,
            location: transaction.location,
            notes: transaction.notes
        )

        do {
            try dataManager.addTransaction(duplicate)
            toastMessage = "Repeated!"
            showToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showToast = false
                dismiss()
            }
        } catch {
            toastMessage = "Failed to repeat"
            showToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showToast = false
            }
        }
    }
}

// MARK: - Summary Card

private struct SheetSummaryCard: View {
    let transaction: Transaction
    let entityName: String
    let avatarColor: FeedAvatarColor
    let formattedAmount: String

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            Circle()
                .fill(avatarColor.background)
                .frame(width: 52, height: 52)
                .overlay(
                    Text(InitialsGenerator.generate(from: transaction.displayName))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(avatarColor.foreground)
                )

            // Name and Entity
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.Colors.feedPrimaryText)

                Text(entityName)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.feedSecondaryText)
            }

            Spacer()

            // Amount
            Text(formattedAmount)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(transaction.isExpense ? Theme.Colors.feedPrimaryText : Color(red: 0.020, green: 0.588, blue: 0.412))
        }
        .padding(14)
        .background(Color(red: 0.973, green: 0.980, blue: 0.988))
        .cornerRadius(14)
    }
}

// MARK: - Info Card

private struct SheetInfoCard: View {
    let transaction: Transaction
    let entityType: SheetEntityType
    let entityName: String
    let splitBill: SplitBill?
    let subscription: Subscription?
    @EnvironmentObject var dataManager: DataManager

    private var badgeColors: (bg: Color, text: Color) {
        entityType.badgeColors
    }

    // Get participants for group display
    private var groupMembers: [(id: UUID, name: String)] {
        guard let splitBill = splitBill else { return [] }
        return splitBill.participants.compactMap { participant in
            if let person = dataManager.people.first(where: { $0.id == participant.personId }) {
                return (id: participant.personId, name: person.name)
            }
            return nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header Row
            HStack {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(badgeColors.bg)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: entityType.icon)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(badgeColors.text)
                        )

                    Text(entityType.label(isIncome: !transaction.isExpense))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.feedPrimaryText)
                }

                Spacer()

                Text(entityType.badgeText)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(badgeColors.text)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badgeColors.bg)
                    .cornerRadius(100)
            }
            .padding(.bottom, 12)

            Rectangle()
                .fill(Color(red: 0.886, green: 0.906, blue: 0.925))
                .frame(height: 1)
                .padding(.bottom, 12)

            // Payment Flow Row
            paymentFlowRow
                .padding(.bottom, 8)

            // Info Rows based on entity type
            infoRows

            // Group Members (if applicable)
            if entityType == .group && !groupMembers.isEmpty {
                Rectangle()
                    .fill(Color(red: 0.886, green: 0.906, blue: 0.925))
                    .frame(height: 1)
                    .padding(.top, 10)
                    .padding(.bottom, 10)

                groupMembersRow
            }
        }
        .padding(14)
        .background(Color(red: 0.973, green: 0.980, blue: 0.988))
        .cornerRadius(14)
    }

    // MARK: - Payment Flow Row

    private var paymentFlowRow: some View {
        HStack {
            // From side
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(red: 0.820, green: 0.980, blue: 0.902))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(transaction.isExpense ? "You" : InitialsGenerator.generate(from: entityName).prefix(2))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(red: 0.016, green: 0.471, blue: 0.341))
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text(transaction.isExpense ? "You" : entityName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.feedPrimaryText)
                        .lineLimit(1)

                    Text(transaction.isExpense ? "Paid by You" : "Sender")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.Colors.feedTertiaryText)
                }
            }

            Spacer()

            // Arrow with Amount
            VStack(spacing: 2) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.feedTertiaryText)

                Text("$\(String(format: "%.2f", abs(transaction.amount)))")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Theme.Colors.feedSecondaryText)
            }

            Spacer()

            // To side
            HStack(spacing: 8) {
                VStack(alignment: .trailing, spacing: 1) {
                    Text(transaction.isExpense ? entityName : "You")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.feedPrimaryText)
                        .lineLimit(1)

                    Text("Recipient")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.Colors.feedTertiaryText)
                }

                Circle()
                    .fill(Color(red: 0.878, green: 0.949, blue: 0.992))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(transaction.isExpense ? String(InitialsGenerator.generate(from: entityName).prefix(1)) : "You")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(red: 0.008, green: 0.518, blue: 0.780))
                    )
            }
        }
    }

    // MARK: - Info Rows

    @ViewBuilder
    private var infoRows: some View {
        VStack(spacing: 8) {
            Rectangle()
                .fill(Color(red: 0.886, green: 0.906, blue: 0.925))
                .frame(height: 1)
                .padding(.top, 4)

            switch entityType {
            case .contact:
                InfoRow(label: transaction.isExpense ? "To" : "From", value: entityName)
                InfoRow(label: "Initiated By", value: "You")

            case .group:
                if splitBill != nil {
                    InfoRow(label: "Created By", value: "You")
                    InfoRow(label: "Split Type", value: "You Paid")
                    InfoRow(label: "Your Share", value: "$\(String(format: "%.2f", abs(transaction.amount)))")
                }

            case .subscription:
                if let subscription = subscription {
                    InfoRow(label: "Billing", value: subscription.billingCycle.displayName)
                    InfoRow(label: "Next Billing", value: subscription.nextBillingDate.formatted(date: .abbreviated, time: .omitted))
                }
            }
        }
    }

    // MARK: - Group Members Row

    private var groupMembersRow: some View {
        HStack(spacing: 8) {
            HStack(spacing: -6) {
                ForEach(Array(groupMembers.prefix(4).enumerated()), id: \.element.id) { index, member in
                    let color = FeedAvatarColor.forName(member.name)
                    Circle()
                        .fill(color.background)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text(InitialsGenerator.generate(from: member.name).prefix(2))
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(color.foreground)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color(red: 0.973, green: 0.980, blue: 0.988), lineWidth: 2)
                        )
                        .zIndex(Double(4 - index))
                }
            }

            Text("\(groupMembers.count) members")
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.feedSecondaryText)

            Spacer()
        }
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Theme.Colors.feedSecondaryText)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.Colors.feedPrimaryText)
        }
    }
}

// MARK: - Details Grid

private struct SheetDetailsGrid: View {
    let transaction: Transaction

    private var dateString: String {
        transaction.date.formatted(date: .abbreviated, time: .omitted)
    }

    private var timeString: String {
        transaction.formattedTime
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
            SheetDetailItem(label: "Date", value: dateString)
            SheetDetailItem(label: "Time", value: timeString)
            SheetDetailItem(label: "Category", value: transaction.category.rawValue)
            SheetDetailItem(label: "Status", value: transaction.paymentStatus.displayText, isSuccess: transaction.paymentStatus == .completed)
        }
    }
}

// MARK: - Detail Item

private struct SheetDetailItem: View {
    let label: String
    let value: String
    var isSuccess: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Theme.Colors.feedTertiaryText)

            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSuccess ? Color(red: 0.020, green: 0.588, blue: 0.412) : Theme.Colors.feedPrimaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(red: 0.973, green: 0.980, blue: 0.988))
        .cornerRadius(10)
    }
}

// MARK: - Toast

private struct SheetToast: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Theme.Colors.feedPrimaryText)
            .cornerRadius(10)
    }
}

// MARK: - Preview

#Preview("Transaction Detail Sheet - Group") {
    Text("Tap to show sheet")
        .sheet(isPresented: .constant(true)) {
            TransactionDetailSheet(
                transaction: Transaction(
                    title: "Dinner",
                    subtitle: "Family dinner",
                    amount: -85.00,
                    category: .food,
                    date: Date(),
                    isRecurring: false,
                    tags: [],
                    paymentStatus: .completed
                )
            )
            .environmentObject(DataManager.shared)
        }
}

#Preview("Transaction Detail Sheet - Contact Income") {
    Text("Tap to show sheet")
        .sheet(isPresented: .constant(true)) {
            TransactionDetailSheet(
                transaction: Transaction(
                    title: "Payment from James",
                    subtitle: "Rent payment",
                    amount: 500.00,
                    category: .income,
                    date: Date(),
                    isRecurring: false,
                    tags: []
                )
            )
            .environmentObject(DataManager.shared)
        }
}
