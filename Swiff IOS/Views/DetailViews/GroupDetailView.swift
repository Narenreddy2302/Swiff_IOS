//
//  GroupDetailView.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Detailed view for group expense management
//

import SwiftUI
import Combine

struct GroupDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    let groupId: UUID
    @State private var showingAddExpense = false
    @State private var showingEditGroup = false
    @State private var showingDeleteAlert = false
    @State private var showingSettleAllAlert = false

    var group: Group? {
        dataManager.groups.first { $0.id == groupId }
    }

    var members: [Person] {
        guard let group = group else { return [] }
        return group.members.compactMap { memberId in
            dataManager.people.first { $0.id == memberId }
        }
    }

    var unsettledExpenses: [GroupExpense] {
        group?.expenses.filter { !$0.isSettled } ?? []
    }

    var totalGroupExpenses: Double {
        group?.expenses.reduce(0) { $0 + $1.amount } ?? 0
    }

    var body: some View {
        ScrollView {
            if let group = group {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 16) {
                        // Large Emoji
                        Text(group.emoji)
                            .font(.system(size: 80))

                        Text(group.name)
                            .font(.spotifyDisplayMedium)
                            .foregroundColor(.wisePrimaryText)

                        if !group.description.isEmpty {
                            Text(group.description)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wiseSecondaryText)
                                .multilineTextAlignment(.center)
                        }

                        // Member count badge
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 12))
                            Text("\(members.count) members")
                                .font(.spotifyLabelMedium)
                        }
                        .foregroundColor(.wiseSecondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.wiseBorder.opacity(0.5))
                        .cornerRadius(20)
                    }
                    .padding(.top, 20)

                    // Members Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Members")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)
                            .padding(.horizontal, 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(members) { member in
                                    VStack(spacing: 8) {
                                        AvatarView(person: member, size: .xlarge, style: .solid)

                                        Text(member.name.components(separatedBy: " ").first ?? member.name)
                                            .font(.spotifyLabelSmall)
                                            .foregroundColor(.wisePrimaryText)
                                            .lineLimit(1)
                                    }
                                    .frame(width: 80)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    // Settle All Button (if unsettled expenses exist)
                    if !unsettledExpenses.isEmpty {
                        Button(action: { showingSettleAllAlert = true }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                Text("Settle All (\(unsettledExpenses.count))")
                                    .font(.spotifyBodyLarge)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.wiseBrightGreen)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)
                    }

                    // Balance Summary Card
                    if totalGroupExpenses > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Total Group Spending")
                                .font(.spotifyLabelLarge)
                                .foregroundColor(.wiseSecondaryText)

                            Text(String(format: "$%.2f", totalGroupExpenses))
                                .font(.spotifyDisplayMedium)
                                .foregroundColor(.wisePrimaryText)

                            Divider()

                            // Expense breakdown
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Settled")
                                        .font(.spotifyLabelSmall)
                                        .foregroundColor(.wiseSecondaryText)
                                    Text("\(group.expenses.filter { $0.isSettled }.count)")
                                        .font(.spotifyNumberSmall)
                                        .foregroundColor(.wiseBrightGreen)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Pending")
                                        .font(.spotifyLabelSmall)
                                        .foregroundColor(.wiseSecondaryText)
                                    Text("\(unsettledExpenses.count)")
                                        .font(.spotifyNumberSmall)
                                        .foregroundColor(.wiseError)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.wiseCardBackground)
                        .cornerRadius(16)
                        .cardShadow()
                        .padding(.horizontal, 16)
                    }

                    // Expenses List
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Expenses")
                                .font(.spotifyHeadingMedium)
                                .foregroundColor(.wisePrimaryText)

                            Spacer()

                            Text("\(group.expenses.count) total")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }
                        .padding(.horizontal, 16)

                        if group.expenses.isEmpty {
                            // Empty state
                            VStack(spacing: 16) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 48))
                                    .foregroundColor(.wiseSecondaryText.opacity(0.5))

                                Text("No expenses yet")
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wiseSecondaryText)

                                Text("Add your first expense to start tracking")
                                    .font(.spotifyBodySmall)
                                    .foregroundColor(.wiseSecondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(group.expenses.sorted(by: { $0.date > $1.date })) { expense in
                                    ExpenseRowView(
                                        expense: expense,
                                        members: members,
                                        onSettle: { settleExpense(expense) }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    // Add Expense Button
                    Button(action: { showingAddExpense = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            Text("Add Expense")
                                .font(.spotifyBodyLarge)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.wiseForestGreen)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)

                    // Delete Group Button
                    Button(action: { showingDeleteAlert = true }) {
                        Text("Delete Group")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseError)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            } else {
                // Group not found
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.wiseError)

                    Text("Group not found")
                        .font(.spotifyHeadingMedium)
                        .foregroundColor(.wisePrimaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.wiseBackground)
        .navigationTitle(group?.name ?? "Group")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingEditGroup = true }) {
                    Text("Edit")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseForestGreen)
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            if let group = group {
                AddGroupExpenseSheet(group: group, onExpenseAdded: {})
            }
        }
        .sheet(isPresented: $showingEditGroup) {
            if let group = group {
                AddGroupSheet(
                    showingAddGroupSheet: $showingEditGroup,
                    editingGroup: group,
                    people: dataManager.people,
                    onGroupAdded: { updatedGroup in
                        do {
                            try dataManager.updateGroup(updatedGroup)
                        } catch {
                            dataManager.error = error
                        }
                    }
                )
            }
        }
        .alert("Delete Group?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteGroup()
            }
        } message: {
            if let group = group {
                Text("This will permanently delete '\(group.name)' and all \(group.expenses.count) expenses.")
            }
        }
        .alert("Settle All Expenses?", isPresented: $showingSettleAllAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Settle All") {
                settleAllExpenses()
            }
        } message: {
            Text("This will mark all \(unsettledExpenses.count) unsettled expenses as paid.")
        }
    }

    private func settleExpense(_ expense: GroupExpense) {
        guard let group = group else { return }
        do {
            try dataManager.settleExpense(id: expense.id, inGroup: group.id)
        } catch {
            dataManager.error = error
        }
    }

    private func settleAllExpenses() {
        guard let group = group else { return }
        for expense in unsettledExpenses {
            try? dataManager.settleExpense(id: expense.id, inGroup: group.id)
        }
    }

    private func deleteGroup() {
        guard let group = group else { return }
        do {
            try dataManager.deleteGroup(id: group.id)
            dismiss()
        } catch {
            dataManager.error = error
        }
    }
}

// MARK: - Expense Row View
struct ExpenseRowView: View {
    let expense: GroupExpense
    let members: [Person]
    let onSettle: () -> Void

    private var paidByPerson: Person? {
        members.first { $0.id == expense.paidBy }
    }

    private var splitMembers: [Person] {
        expense.splitBetween.compactMap { memberId in
            members.first { $0.id == memberId }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Category icon
                Circle()
                    .fill(expense.category.color.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: expense.category.icon)
                            .font(.system(size: 20))
                            .foregroundColor(expense.category.color)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.title)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)

                    if let payer = paidByPerson {
                        Text("Paid by \(payer.name)")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }

                    Text("Split between \(expense.splitBetween.count) people")
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "$%.2f", expense.amount))
                        .font(.spotifyNumberMedium)
                        .foregroundColor(.wisePrimaryText)

                    // Settlement status badge
                    if expense.isSettled {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                            Text("Settled")
                                .font(.spotifyCaptionSmall)
                        }
                        .foregroundColor(.wiseBrightGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.wiseBrightGreen.opacity(0.1))
                        .cornerRadius(12)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                            Text("Pending")
                                .font(.spotifyCaptionSmall)
                        }
                        .foregroundColor(.wiseError)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.wiseError.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }

            // Amount per person
            if !expense.splitBetween.isEmpty {
                Text(String(format: "$%.2f per person", expense.amountPerPerson))
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseForestGreen)
                    .padding(.leading, 56)
            }

            // Notes if present
            if !expense.notes.isEmpty {
                Text(expense.notes)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .padding(.leading, 56)
            }

            // Date
            Text(expense.date, style: .date)
                .font(.spotifyCaptionSmall)
                .foregroundColor(.wiseSecondaryText)
                .padding(.leading, 56)
        }
        .padding(16)
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .subtleShadow()
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if !expense.isSettled {
                Button {
                    onSettle()
                } label: {
                    Label("Settle", systemImage: "checkmark.circle")
                }
                .tint(.green)
            }
        }
    }
}

#Preview {
    NavigationView {
        GroupDetailView(groupId: UUID())
            .environmentObject(DataManager.shared)
    }
}
