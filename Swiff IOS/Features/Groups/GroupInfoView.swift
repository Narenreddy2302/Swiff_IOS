//
//  GroupInfoView.swift
//  Swiff IOS
//
//  Detailed view for group information
//  Moved from GroupDetailView (tab content)
//

import Charts
import SwiftUI

struct GroupInfoView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    let groupId: UUID
    @Binding var showingEditGroup: Bool  // Passed from parent if needed, or local

    // Local state for alerts
    @State private var showingDeleteAlert = false
    @State private var showingSettleAllAlert = false
    @State private var showingMemberManagement = false
    @State private var showingExportSheet = false

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

    var settledExpenses: [GroupExpense] {
        group?.expenses.filter { $0.isSettled } ?? []
    }

    var totalGroupExpenses: Double {
        group?.expenses.reduce(0) { $0 + $1.amount } ?? 0
    }

    var totalSettledAmount: Double {
        settledExpenses.reduce(0) { $0 + $1.amount }
    }

    var settlementProgress: Double {
        guard totalGroupExpenses > 0 else { return 0 }
        return totalSettledAmount / totalGroupExpenses
    }

    var groupSplitBills: [SplitBill] {
        guard let group = group else { return [] }
        return dataManager.getSplitBillsForGroup(groupId: group.id)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let group = group {
                    ScrollView {
                        VStack(spacing: 24) {
                            // 1. Large Header
                            GroupConversationHeader(
                                group: group,
                                members: members,
                                backgroundColor: .clear
                            )

                            // 2. Balance Summary
                            if totalGroupExpenses > 0 {
                                balanceSummaryCard(group: group)
                            }

                            // 3. Settle All Button
                            if !unsettledExpenses.isEmpty {
                                settleAllButton
                            }

                            // 4. Member Balances
                            if !members.isEmpty {
                                memberBalanceSection(group: group)
                            }

                            // 5. Category Distribution
                            if !group.expenses.isEmpty {
                                categoryDistributionSection(group: group)
                            }

                            // 6. Split Bills
                            if !groupSplitBills.isEmpty {
                                splitBillsSection
                            }

                            // 7. Actions
                            VStack(spacing: 12) {
                                Button(action: { showingExportSheet = true }) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Export Group Data")
                                    }
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wiseBlue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.wiseCardBackground)
                                    .cornerRadius(12)
                                }

                                Button(action: { showingDeleteAlert = true }) {
                                    Text("Delete Group")
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wiseError)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 40)
                        }
                        .padding(.top, 16)
                    }
                } else {
                    Text("Group not found")
                }
            }
            .background(Color.wiseBackground)
            .navigationTitle("Group Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                        showingEditGroup = true
                    }) {
                        Text("Edit")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseForestGreen)
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.wisePrimaryText)
                }
            }
            .sheet(isPresented: $showingMemberManagement) {
                if let group = group {
                    MemberManagementSheet(group: group)
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                if let group = group {
                    ExportGroupSheet(group: group, members: members)
                }
            }
            .alert("Delete Group?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteGroup()
                }
            } message: {
                if let group = group {
                    Text(
                        "This will permanently delete '\(group.name)' and all \(group.expenses.count) expenses."
                    )
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
    }

    // MARK: - Components (Copied/Adapted from GroupDetailView)

    @ViewBuilder
    private var settleAllButton: some View {
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

    @ViewBuilder
    private func balanceSummaryCard(group: Group) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Total Spending
            HStack(spacing: 12) {
                StatisticsCardComponent(
                    icon: "dollarsign.circle.fill",
                    title: "Total Spending",
                    value: totalGroupExpenses.asCurrency,
                    iconColor: .wiseForestGreen,
                    showIcon: true
                )

                StatisticsCardComponent(
                    icon: "chart.pie.fill",
                    title: "Per Person",
                    value: (members.isEmpty ? 0 : totalGroupExpenses / Double(members.count)).asCurrency,
                    iconColor: .wiseBlue,
                    showIcon: true
                )
            }

            // Settled vs Pending Count Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.wiseBrightGreen)
                                .frame(width: 8, height: 8)
                            Text("Settled")
                                .font(.spotifyLabelSmall)
                                .foregroundColor(.wiseSecondaryText)
                        }
                        Text("\(settledExpenses.count)")
                            .font(.spotifyNumberSmall)
                            .foregroundColor(.wiseBrightGreen)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Pending")
                                .font(.spotifyLabelSmall)
                                .foregroundColor(.wiseSecondaryText)
                            Circle()
                                .fill(Color.wiseError)
                                .frame(width: 8, height: 8)
                        }
                        Text("\(unsettledExpenses.count)")
                            .font(.spotifyNumberSmall)
                            .foregroundColor(.wiseError)
                    }
                }

                // Settlement Progress Bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Settlement Progress")
                            .font(.spotifyLabelSmall)
                            .foregroundColor(.wiseSecondaryText)
                        Spacer()
                        Text(String(format: "%.0f%%", settlementProgress * 100))
                            .font(.spotifyLabelSmall)
                            .foregroundColor(.wisePrimaryText)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.wiseBorder.opacity(0.3))
                                .frame(height: 8)

                            // Progress
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.wiseBrightGreen)
                                .frame(width: geometry.size.width * settlementProgress, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
            .padding(16)
            .background(Color.wiseCardBackground)
            .cornerRadius(16)
            .cardShadow()
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func memberBalanceSection(group: Group) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Member Balances")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                Button(action: { showingMemberManagement = true }) {
                    Text("Manage")
                        .font(.spotifyLabelMedium)
                        .foregroundColor(.wiseBlue)
                }
            }
            .padding(.horizontal, 16)

            VStack(spacing: 8) {
                ForEach(members) { member in
                    memberBalanceRow(member: member, in: group)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func memberBalanceRow(member: Person, in group: Group) -> some View {
        let memberStats = calculateMemberStats(member: member, in: group)

        UnifiedListRow(
            title: member.name,
            subtitle: memberStats.subtitle,
            value: memberStats.amount.asCurrency,
            valueColor: memberStats.color,
            valueLabel: memberStats.label
        ) {
            AvatarView(person: member, size: .medium, style: .solid)
        }
    }

    @ViewBuilder
    private func categoryDistributionSection(group: Group) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending by Category")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)
                .padding(.horizontal, 16)

            let categoryData = generateCategoryData(from: group.expenses)

            CategoryPieChart(
                data: categoryData,
                total: totalGroupExpenses,
                isIncome: false,
                dateRange: dateRangeText(from: group.expenses)
            )
            .padding(.horizontal, 16)
        }
    }

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
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(groupSplitBills) { splitBill in
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

    // MARK: - Helper Methods

    private func calculateMemberStats(member: Person, in group: Group) -> (
        subtitle: String, amount: Double, color: Color, label: String
    ) {
        let paidExpenses = group.expenses.filter { $0.paidBy == member.id }
        let totalPaid = paidExpenses.reduce(0) { $0 + $1.amount }

        let expensesInvolved = group.expenses.filter { $0.splitBetween.contains(member.id) }
        let totalOwes = expensesInvolved.reduce(0) { $0 + $1.amountPerPerson }

        let netBalance = totalPaid - totalOwes

        if netBalance > 0 {
            return (
                "Paid \(totalPaid.asCurrency)", netBalance, .wiseBrightGreen,
                "owed to them"
            )
        } else if netBalance < 0 {
            return (
                "Owes \(abs(netBalance).asCurrency)", abs(netBalance), .wiseError,
                "they owe"
            )
        } else {
            return ("All settled up", 0, .wiseMidGray, "balanced")
        }
    }

    private func generateCategoryData(from expenses: [GroupExpense]) -> [ChartDataItem] {
        var categoryTotals: [TransactionCategory: Double] = [:]

        for expense in expenses {
            categoryTotals[expense.category, default: 0] += expense.amount
        }

        return categoryTotals.map { category, amount in
            ChartDataItem(
                category: category.rawValue,
                amount: amount,
                color: category.color,
                icon: category.icon,
                percentage: totalGroupExpenses > 0 ? (amount / totalGroupExpenses) * 100 : 0
            )
        }.sorted { $0.amount > $1.amount }
    }

    private func dateRangeText(from expenses: [GroupExpense]) -> String {
        guard let earliest = expenses.map({ $0.date }).min(),
            let latest = expenses.map({ $0.date }).max()
        else {
            return "No expenses"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        if Calendar.current.isDate(earliest, inSameDayAs: latest) {
            return formatter.string(from: latest)
        } else {
            return "\(formatter.string(from: earliest)) - \(formatter.string(from: latest))"
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

    private func settleAllExpenses() {
        guard let group = group else { return }
        for expense in unsettledExpenses {
            var updatedExpense = expense
            updatedExpense.isSettled = true

            do {
                try dataManager.updateGroupExpense(updatedExpense, inGroup: group.id)
            } catch {
                print("Error settling expense: \(error)")
            }
        }
    }
}
