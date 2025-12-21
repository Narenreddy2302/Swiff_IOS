//
//  AddGroupExpenseSheet.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Form to add expenses to groups with split logic
//

import SwiftUI
import Combine

struct AddGroupExpenseSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    let group: Group
    let onExpenseAdded: () -> Void

    @State private var title = ""
    @State private var amount = ""
    @State private var selectedCategory: TransactionCategory = .food
    @State private var selectedPayer: Person?
    @State private var selectedSplitMembers: Set<UUID> = []
    @State private var notes = ""
    @State private var expenseDate = Date()
    @State private var showingCategoryPicker = false

    private var groupMembers: [Person] {
        group.members.compactMap { memberId in
            dataManager.people.first { $0.id == memberId }
        }
    }

    private var amountValue: Double {
        Double(amount) ?? 0.0
    }

    private var amountPerPerson: Double {
        guard !selectedSplitMembers.isEmpty, amountValue > 0 else { return 0 }
        return amountValue / Double(selectedSplitMembers.count)
    }

    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        amountValue > 0 &&
        selectedPayer != nil &&
        !selectedSplitMembers.isEmpty
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Expense Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Expense Details")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        // Title
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Title *")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            TextField("e.g., Dinner at Restaurant", text: $title)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
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

                        // Category
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Category *")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            Button(action: { showingCategoryPicker = true }) {
                                HStack {
                                    Image(systemName: selectedCategory.icon)
                                        .foregroundColor(selectedCategory.color)

                                    Text(selectedCategory.rawValue)
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wisePrimaryText)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.wiseSecondaryText)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                            }
                        }

                        // Date
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Date")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            DatePicker("", selection: $expenseDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                    }

                    // Who Paid Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Who Paid? *")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        ForEach(groupMembers) { member in
                            Button(action: { selectedPayer = member }) {
                                HStack(spacing: 12) {
                                    AvatarView(person: member, size: .medium, style: .solid)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(member.name)
                                            .font(.spotifyBodyMedium)
                                            .foregroundColor(.wisePrimaryText)

                                        Text(member.email)
                                            .font(.spotifyBodySmall)
                                            .foregroundColor(.wiseSecondaryText)
                                    }

                                    Spacer()

                                    Image(systemName: selectedPayer?.id == member.id ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 20))
                                        .foregroundColor(selectedPayer?.id == member.id ? .wiseBrightGreen : .wiseSecondaryText)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedPayer?.id == member.id ? Color.wiseBrightGreen.opacity(0.1) : Color.wiseBorder.opacity(0.3))
                                        .stroke(selectedPayer?.id == member.id ? Color.wiseBrightGreen : Color.wiseBorder, lineWidth: 1)
                                )
                            }
                        }
                    }

                    // Split Between Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Split Between *")
                                .font(.spotifyHeadingMedium)
                                .foregroundColor(.wisePrimaryText)

                            Spacer()

                            if amountValue > 0 && !selectedSplitMembers.isEmpty {
                                Text(String(format: "$%.2f each", amountPerPerson))
                                    .font(.spotifyLabelLarge)
                                    .foregroundColor(.wiseForestGreen)
                            }
                        }

                        ForEach(groupMembers) { member in
                            Button(action: {
                                if selectedSplitMembers.contains(member.id) {
                                    selectedSplitMembers.remove(member.id)
                                } else {
                                    selectedSplitMembers.insert(member.id)
                                }
                            }) {
                                HStack(spacing: 12) {
                                    AvatarView(person: member, size: .medium, style: .solid)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(member.name)
                                            .font(.spotifyBodyMedium)
                                            .foregroundColor(.wisePrimaryText)

                                        if amountValue > 0 && selectedSplitMembers.contains(member.id) {
                                            Text(String(format: "Owes $%.2f", amountPerPerson))
                                                .font(.spotifyBodySmall)
                                                .foregroundColor(.wiseForestGreen)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: selectedSplitMembers.contains(member.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 20))
                                        .foregroundColor(selectedSplitMembers.contains(member.id) ? .wiseBrightGreen : .wiseSecondaryText)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedSplitMembers.contains(member.id) ? Color.wiseBrightGreen.opacity(0.1) : Color.wiseBorder.opacity(0.3))
                                        .stroke(selectedSplitMembers.contains(member.id) ? Color.wiseBrightGreen : Color.wiseBorder, lineWidth: 1)
                                )
                            }
                        }
                    }

                    // Notes Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Notes (Optional)")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

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
            .navigationTitle("Add Expense")
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
                    Button("Add") {
                        addExpense()
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
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerSheet(selectedCategory: $selectedCategory, isPresented: $showingCategoryPicker)
        }
        .onAppear {
            // Auto-select all members by default
            selectedSplitMembers = Set(groupMembers.map { $0.id })
            // Auto-select first member as payer
            selectedPayer = groupMembers.first
        }
    }

    private func addExpense() {
        guard let payer = selectedPayer else { return }

        let expense = GroupExpense(
            title: title.trimmingCharacters(in: .whitespaces),
            amount: amountValue,
            paidBy: payer.id,
            splitBetween: Array(selectedSplitMembers),
            category: selectedCategory,
            notes: notes.trimmingCharacters(in: .whitespaces)
        )

        // Update group with new expense
        var updatedGroup = group
        updatedGroup.expenses.append(expense)
        updatedGroup.totalAmount += expense.amount

        do {
            try dataManager.updateGroup(updatedGroup)
            onExpenseAdded()
            dismiss()
        } catch {
            dataManager.error = error
        }
    }
}

#Preview("Add Group Expense Sheet") {
    AddGroupExpenseSheet(
        group: MockData.groupWithExpenses,
        onExpenseAdded: {}
    )
    .environmentObject(DataManager.shared)
}
