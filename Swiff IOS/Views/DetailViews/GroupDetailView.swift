//
//  GroupDetailView.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Detailed view for group expense management
//  Enhanced with comprehensive features for expense tracking and settlement
//

import SwiftUI
import Combine
import Charts

struct GroupDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    let groupId: UUID
    @State private var showingAddExpense = false
    @State private var showingEditGroup = false
    @State private var showingDeleteAlert = false
    @State private var showingSettleAllAlert = false
    @State private var showingMemberManagement = false
    @State private var showingExportSheet = false
    @State private var selectedTab: DetailTab = .overview

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

    var totalPendingAmount: Double {
        unsettledExpenses.reduce(0) { $0 + $1.amount }
    }

    var settlementProgress: Double {
        guard totalGroupExpenses > 0 else { return 0 }
        return totalSettledAmount / totalGroupExpenses
    }

    var groupSplitBills: [SplitBill] {
        guard let group = group else { return [] }
        return dataManager.getSplitBillsForGroup(groupId: group.id)
    }

    var totalSplitBillAmount: Double {
        groupSplitBills.reduce(0) { $0 + $1.totalAmount }
    }

    var settledSplitBillAmount: Double {
        groupSplitBills.reduce(0) { $0 + $1.totalSettled }
    }

    var pendingSplitBillAmount: Double {
        groupSplitBills.reduce(0) { $0 + $1.totalPending }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            if let group = group {
                VStack(spacing: 24) {
                    // TASK 2.1: Enhanced Header
                    headerSection(group: group)

                    // TASK 2.2: Horizontal Scrolling Member Avatars
                    membersScrollSection

                    // TASK 2.3: Settle All Button
                    if !unsettledExpenses.isEmpty {
                        settleAllButton
                    }

                    // TASK 2.4: Balance Summary Card
                    if totalGroupExpenses > 0 {
                        balanceSummaryCard(group: group)
                    }

                    // TASK 2.5: Per-Member Balance Breakdown
                    if !members.isEmpty && totalGroupExpenses > 0 {
                        memberBalanceSection(group: group)
                    }

                    // TASK 2.7: Category Distribution Pie Chart
                    if !group.expenses.isEmpty {
                        categoryDistributionSection(group: group)
                    }

                    // TASK 2.8: Expense Timeline (grouped by date)
                    expenseTimelineSection(group: group)

                    // Split Bills Section
                    if !groupSplitBills.isEmpty {
                        splitBillsSection
                    }

                    // TASK 2.12: Group Activity Summary
                    if !group.expenses.isEmpty {
                        activitySummarySection(group: group)
                    }

                    // Quick Actions
                    quickActionsSection

                    // TASK 2.11: Member Management Button
                    memberManagementButton

                    // TASK 2.10: Export Button
                    exportButton

                    // Delete Group Button
                    deleteGroupButton
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
        .observeEntityWithRelated(groupId, type: .group, relatedTypes: [.splitBill, .person], dataManager: dataManager)
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
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
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

    // MARK: - TASK 2.1: Enhanced Header Section

    @ViewBuilder
    private func headerSection(group: Group) -> some View {
        VStack(spacing: 16) {
            // Large Emoji (80pt)
            UnifiedEmojiCircle(
                emoji: group.emoji,
                backgroundColor: .wiseBlue,
                size: 80
            )

            // Group Name
            Text(group.name)
                .font(.spotifyDisplayMedium)
                .foregroundColor(.wisePrimaryText)

            // Description
            if !group.description.isEmpty {
                Text(group.description)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Member Count Badge
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
    }

    // MARK: - TASK 2.2: Horizontal Scrolling Members Section

    @ViewBuilder
    private var membersScrollSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Members")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(members) { member in
                        NavigationLink(destination: PersonDetailView(personId: member.id)) {
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
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - TASK 2.3: Settle All Button

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

    // MARK: - TASK 2.4: Balance Summary Card

    @ViewBuilder
    private func balanceSummaryCard(group: Group) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Total Spending
            HStack(spacing: 12) {
                StatisticsCardComponent(
                    icon: "dollarsign.circle.fill",
                    title: "Total Spending",
                    value: String(format: "$%.2f", totalGroupExpenses),
                    iconColor: .wiseForestGreen,
                    showIcon: true
                )

                StatisticsCardComponent(
                    icon: "chart.pie.fill",
                    title: "Per Person",
                    value: String(format: "$%.2f", members.isEmpty ? 0 : totalGroupExpenses / Double(members.count)),
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

    // MARK: - TASK 2.5: Per-Member Balance Breakdown

    @ViewBuilder
    private func memberBalanceSection(group: Group) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Member Balances")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)
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
            value: String(format: "$%.2f", memberStats.amount),
            valueColor: memberStats.color,
            valueLabel: memberStats.label
        ) {
            AvatarView(person: member, size: .medium, style: .solid)
        }
    }

    private func calculateMemberStats(member: Person, in group: Group) -> (subtitle: String, amount: Double, color: Color, label: String) {
        let paidExpenses = group.expenses.filter { $0.paidBy == member.id }
        let totalPaid = paidExpenses.reduce(0) { $0 + $1.amount }

        let expensesInvolved = group.expenses.filter { $0.splitBetween.contains(member.id) }
        let totalOwes = expensesInvolved.reduce(0) { $0 + $1.amountPerPerson }

        let netBalance = totalPaid - totalOwes

        if netBalance > 0 {
            return ("Paid \(String(format: "$%.2f", totalPaid))", netBalance, .wiseBrightGreen, "owed to them")
        } else if netBalance < 0 {
            return ("Owes \(String(format: "$%.2f", abs(netBalance)))", abs(netBalance), .wiseError, "they owe")
        } else {
            return ("All settled up", 0, .wiseMidGray, "balanced")
        }
    }

    // MARK: - TASK 2.7: Category Distribution Pie Chart

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
              let latest = expenses.map({ $0.date }).max() else {
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

    // MARK: - TASK 2.8: Expense Timeline (grouped by date)

    @ViewBuilder
    private func expenseTimelineSection(group: Group) -> some View {
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
                emptyStateView
            } else {
                // TASK 2.6: Expense list with swipe-to-settle
                expenseListByDate(group: group)
            }
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
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
    }

    @ViewBuilder
    private func expenseListByDate(group: Group) -> some View {
        let groupedExpenses = Dictionary(grouping: group.expenses.sorted(by: { $0.date > $1.date })) { expense in
            Calendar.current.startOfDay(for: expense.date)
        }

        let sortedDates = groupedExpenses.keys.sorted(by: >)

        VStack(spacing: 16) {
            ForEach(sortedDates, id: \.self) { date in
                VStack(alignment: .leading, spacing: 8) {
                    // Date Header
                    Text(formatDateHeader(date))
                        .font(.spotifyLabelMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .padding(.horizontal, 16)

                    // Expenses for this date
                    VStack(spacing: 0) {
                        ForEach(Array(groupedExpenses[date]?.enumerated() ?? [].enumerated()), id: \.element.id) { index, expense in
                            ExpenseRowView(
                                expense: expense,
                                members: members,
                                onSettle: { settleExpense(expense) }
                            )

                            if index < (groupedExpenses[date]?.count ?? 0) - 1 {
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
        }
    }

    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d, yyyy"
            return formatter.string(from: date)
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

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(groupSplitBills.count)")
                        .font(.spotifyLabelMedium)
                        .foregroundColor(.wisePrimaryText)

                    if pendingSplitBillAmount > 0 {
                        Text(String(format: "$%.2f pending", pendingSplitBillAmount))
                            .font(.spotifyCaptionSmall)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(groupSplitBills) { splitBill in
                        NavigationLink(destination: SplitBillDetailView(splitBillId: splitBill.id)) {
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

    // MARK: - TASK 2.12: Activity Summary

    @ViewBuilder
    private func activitySummarySection(group: Group) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)
                .padding(.horizontal, 16)

            VStack(spacing: 8) {
                // Most active member
                if let mostActiveMember = getMostActiveMember(in: group) {
                    activityRowItem(
                        icon: "star.fill",
                        title: "Most Active",
                        subtitle: mostActiveMember.name,
                        color: .wiseOrange
                    )
                }

                // Recent expense
                if let recentExpense = group.expenses.sorted(by: { $0.date > $1.date }).first,
                   let payer = members.first(where: { $0.id == recentExpense.paidBy }) {
                    activityRowItem(
                        icon: "clock.fill",
                        title: "Latest Expense",
                        subtitle: "\(recentExpense.title) by \(payer.name)",
                        color: .wiseBlue
                    )
                }

                // Largest expense
                if let largestExpense = group.expenses.max(by: { $0.amount < $1.amount }),
                   let _ = members.first(where: { $0.id == largestExpense.paidBy }) {
                    activityRowItem(
                        icon: "chart.bar.fill",
                        title: "Largest Expense",
                        subtitle: "\(String(format: "$%.2f", largestExpense.amount)) - \(largestExpense.title)",
                        color: .wiseForestGreen
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func activityRowItem(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.spotifyLabelMedium)
                    .foregroundColor(.wiseSecondaryText)

                Text(subtitle)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .subtleShadow()
    }

    private func getMostActiveMember(in group: Group) -> Person? {
        var memberExpenseCount: [UUID: Int] = [:]

        for expense in group.expenses {
            memberExpenseCount[expense.paidBy, default: 0] += 1
        }

        guard let mostActiveMemberId = memberExpenseCount.max(by: { $0.value < $1.value })?.key else {
            return nil
        }

        return members.first { $0.id == mostActiveMemberId }
    }

    // MARK: - Quick Actions Section (TASK 2.9: Add Expense)

    @ViewBuilder
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
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
        }
        .padding(.horizontal, 16)
    }

    // MARK: - TASK 2.11: Member Management Button

    @ViewBuilder
    private var memberManagementButton: some View {
        Button(action: { showingMemberManagement = true }) {
            HStack {
                Image(systemName: "person.2.badge.gearshape.fill")
                    .font(.system(size: 18))
                Text("Manage Members")
                    .font(.spotifyBodyMedium)
            }
            .foregroundColor(.wiseForestGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.wiseBorder, lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
    }

    // MARK: - TASK 2.10: Export Button

    @ViewBuilder
    private var exportButton: some View {
        Button(action: { showingExportSheet = true }) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18))
                Text("Export Group Expenses")
                    .font(.spotifyBodyMedium)
            }
            .foregroundColor(.wiseBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.wiseBorder, lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Delete Group Button

    @ViewBuilder
    private var deleteGroupButton: some View {
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

    // MARK: - Helper Functions

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

// MARK: - Supporting Types

enum DetailTab: String, CaseIterable {
    case overview = "Overview"
    case expenses = "Expenses"
    case members = "Members"
}

// MARK: - TASK 2.6: Expense Row View with Swipe-to-Settle

struct ExpenseRowView: View {
    let expense: GroupExpense
    let members: [Person]
    let onSettle: () -> Void

    private var paidByPerson: Person? {
        members.first { $0.id == expense.paidBy }
    }

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: expense.date, relativeTo: Date())
    }

    private var initials: String {
        InitialsGenerator.generate(from: expense.title)
    }

    private var avatarColor: Color {
        expense.category.pastelAvatarColor
    }

    private var statusText: String {
        expense.isSettled ? "Settled" : "Pending"
    }

    var body: some View {
        HStack(spacing: 14) {
            // Initials avatar (44x44, no status badge)
            initialsAvatar

            // Title and Status
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                Text(statusText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                    .lineLimit(1)
            }

            Spacer()

            // Amount and Time
            VStack(alignment: .trailing, spacing: 3) {
                Text("-\(String(format: "$%.2f", expense.amount))")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AmountColors.negative)

                Text(relativeTime)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
            }
        }
        .padding(.vertical, 14)
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

    private var initialsAvatar: some View {
        ZStack {
            Circle()
                .fill(avatarColor)
                .frame(width: 44, height: 44)

            Text(initials)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 26/255, green: 26/255, blue: 26/255))
        }
    }
}

// MARK: - TASK 2.11: Member Management Sheet

struct MemberManagementSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    let group: Group
    @State private var selectedPeople: Set<UUID> = []
    @State private var showingAddMemberPicker = false

    private var currentMembers: [Person] {
        group.members.compactMap { memberId in
            dataManager.people.first { $0.id == memberId }
        }
    }

    private var availablePeople: [Person] {
        dataManager.people.filter { !group.members.contains($0.id) }
    }

    init(group: Group) {
        self.group = group
        _selectedPeople = State(initialValue: Set(group.members))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Members Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Members")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)
                            .padding(.horizontal, 16)

                        if currentMembers.isEmpty {
                            Text("No members yet")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wiseSecondaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(currentMembers) { member in
                                    memberRow(member: member, canRemove: currentMembers.count > 1)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    // Add Member Button
                    if !availablePeople.isEmpty {
                        Button(action: { showingAddMemberPicker = true }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 18))
                                Text("Add Member")
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
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color.wiseBackground)
            .navigationTitle("Manage Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddMemberPicker) {
                AddMemberPickerSheet(group: group, availablePeople: availablePeople)
            }
        }
    }

    @ViewBuilder
    private func memberRow(member: Person, canRemove: Bool) -> some View {
        HStack(spacing: 12) {
            AvatarView(person: member, size: .medium, style: .solid)

            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)

                Text(member.email)
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
            }

            Spacer()

            if canRemove {
                Button(action: { removeMember(member) }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.wiseError)
                }
            }
        }
        .padding(12)
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .subtleShadow()
    }

    private func removeMember(_ member: Person) {
        var updatedGroup = group
        updatedGroup.members.removeAll { $0 == member.id }

        do {
            try dataManager.updateGroup(updatedGroup)
        } catch {
            dataManager.error = error
        }
    }
}

// MARK: - Add Member Picker Sheet

struct AddMemberPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    let group: Group
    let availablePeople: [Person]
    @State private var selectedPerson: Person?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(availablePeople) { person in
                        Button(action: { addMember(person) }) {
                            HStack(spacing: 12) {
                                AvatarView(person: person, size: .medium, style: .solid)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(person.name)
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wisePrimaryText)

                                    Text(person.email)
                                        .font(.spotifyCaptionMedium)
                                        .foregroundColor(.wiseSecondaryText)
                                }

                                Spacer()

                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.wiseForestGreen)
                            }
                            .padding(12)
                            .background(Color.wiseCardBackground)
                            .cornerRadius(12)
                            .subtleShadow()
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.wiseBackground)
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addMember(_ person: Person) {
        var updatedGroup = group
        updatedGroup.members.append(person.id)

        do {
            try dataManager.updateGroup(updatedGroup)
            dismiss()
        } catch {
            dataManager.error = error
        }
    }
}

// MARK: - TASK 2.10: Export Group Sheet

struct ExportGroupSheet: View {
    @Environment(\.dismiss) var dismiss
    let group: Group
    let members: [Person]

    @State private var exportFormat: ExportFormat = .csv
    @State private var includeSettled = true
    @State private var includePending = true
    @State private var showingShareSheet = false
    @State private var exportedText = ""

    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case text = "Text"
        case summary = "Summary"
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Format Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Export Format")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Button(action: { exportFormat = format }) {
                                HStack {
                                    Image(systemName: exportFormat == format ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(exportFormat == format ? .wiseForestGreen : .wiseMidGray)

                                    Text(format.rawValue)
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wisePrimaryText)

                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.wiseCardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(exportFormat == format ? Color.wiseForestGreen : Color.clear, lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Include")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        Toggle("Settled Expenses", isOn: $includeSettled)
                            .font(.spotifyBodyMedium)

                        Toggle("Pending Expenses", isOn: $includePending)
                            .font(.spotifyBodyMedium)
                    }
                    .padding(.horizontal, 16)

                    // Export Button
                    Button(action: { generateExport() }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18))
                            Text("Export")
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
                }
                .padding(.vertical, 20)
            }
            .background(Color.wiseBackground)
            .navigationTitle("Export Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [exportedText])
            }
        }
    }

    private func generateExport() {
        var expenses = group.expenses

        // Filter based on options
        if !includeSettled {
            expenses = expenses.filter { !$0.isSettled }
        }
        if !includePending {
            expenses = expenses.filter { $0.isSettled }
        }

        switch exportFormat {
        case .csv:
            exportedText = generateCSV(expenses: expenses)
        case .text:
            exportedText = generateText(expenses: expenses)
        case .summary:
            exportedText = generateSummary(expenses: expenses)
        }

        showingShareSheet = true
    }

    private func generateCSV(expenses: [GroupExpense]) -> String {
        var csv = "Date,Title,Amount,Paid By,Split Between,Category,Status,Notes\n"

        for expense in expenses {
            let payer = members.first { $0.id == expense.paidBy }?.name ?? "Unknown"
            let splitNames = expense.splitBetween.compactMap { id in
                members.first { $0.id == id }?.name
            }.joined(separator: "; ")

            let date = DateFormatter.localizedString(from: expense.date, dateStyle: .short, timeStyle: .none)
            let status = expense.isSettled ? "Settled" : "Pending"

            csv += "\(date),\(expense.title),\(expense.amount),\(payer),\"\(splitNames)\",\(expense.category.rawValue),\(status),\"\(expense.notes)\"\n"
        }

        return csv
    }

    private func generateText(expenses: [GroupExpense]) -> String {
        var text = "Group: \(group.name)\n"
        text += "Generated: \(Date().formatted())\n"
        text += "=================================\n\n"

        for expense in expenses {
            let payer = members.first { $0.id == expense.paidBy }?.name ?? "Unknown"
            text += "Date: \(expense.date.formatted(date: .abbreviated, time: .omitted))\n"
            text += "Title: \(expense.title)\n"
            text += "Amount: $\(String(format: "%.2f", expense.amount))\n"
            text += "Paid by: \(payer)\n"
            text += "Status: \(expense.isSettled ? "Settled" : "Pending")\n"
            if !expense.notes.isEmpty {
                text += "Notes: \(expense.notes)\n"
            }
            text += "\n"
        }

        return text
    }

    private func generateSummary(expenses: [GroupExpense]) -> String {
        let total = expenses.reduce(0) { $0 + $1.amount }
        let settled = expenses.filter { $0.isSettled }.count
        let pending = expenses.count - settled

        var summary = "GROUP SUMMARY: \(group.name)\n"
        summary += "=================================\n\n"
        summary += "Total Expenses: \(expenses.count)\n"
        summary += "Total Amount: $\(String(format: "%.2f", total))\n"
        summary += "Settled: \(settled)\n"
        summary += "Pending: \(pending)\n"
        summary += "Members: \(members.count)\n"
        summary += "Average per person: $\(String(format: "%.2f", members.isEmpty ? 0 : total / Double(members.count)))\n"

        return summary
    }
}

// Note: ShareSheet is defined in SettingsView.swift
// Note: TransactionCategory.pastelAvatarColor is defined in TransactionCard.swift

// MARK: - Preview

#Preview {
    NavigationView {
        GroupDetailView(groupId: UUID())
            .environmentObject(DataManager.shared)
    }
}
