import SwiftUI

// MARK: - People Quick Stats View
struct PeopleQuickStatsView: View {
    let people: [Person]

    var totalOwedToYou: Double {
        people.filter { $0.balance > 0 }.reduce(0) { $0 + $1.balance }
    }

    var totalYouOwe: Double {
        let negativeBalances = people.filter { $0.balance < 0 }
        return abs(negativeBalances.reduce(0) { $0 + $1.balance })
    }

    var owesYouCount: Int {
        people.filter { $0.balance > 0 }.count
    }

    var youOweCount: Int {
        people.filter { $0.balance < 0 }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 1x2 Grid with owed amounts
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                ], spacing: 12
            ) {
                // Owed to You Card
                PeopleStatCard(
                    title: "Owed to You",
                    amount: totalOwedToYou,
                    icon: "arrow.down.circle.fill",
                    color: .wiseBrightGreen,
                    isAmount: true,
                    peopleCount: owesYouCount
                )

                // You Owe Card
                PeopleStatCard(
                    title: "You Owe",
                    amount: totalYouOwe,
                    icon: "arrow.up.circle.fill",
                    color: .wiseError,
                    isAmount: true,
                    peopleCount: youOweCount
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - People Stat Card
struct PeopleStatCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    let isAmount: Bool
    let isCount: Bool
    let peopleCount: Int

    init(
        title: String, amount: Double, icon: String, color: Color, isAmount: Bool = false,
        isCount: Bool = false, peopleCount: Int = 0
    ) {
        self.title = title
        self.amount = amount
        self.icon = icon
        self.color = color
        self.isAmount = isAmount
        self.isCount = isCount
        self.peopleCount = peopleCount
    }

    var formattedAmount: String {
        if isCount {
            return String(Int(amount))
        } else if isAmount {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "$"
            formatter.maximumFractionDigits = amount >= 1000 ? 0 : 2
            return formatter.string(from: NSNumber(value: amount)) ?? "$0"
        }
        return String(format: "%.2f", amount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            Text(title.uppercased())
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .textCase(.uppercase)

            Text(formattedAmount)
                .font(.spotifyNumberLarge)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseCardBackground)
                .cardShadow()
        )
    }
}

// MARK: - Balance Summary Card (Redesigned with 2x2 Grid - Matching Home Screen)
struct BalanceSummaryCard: View {
    let totalOwedToYou: Double
    let totalYouOwe: Double
    let netBalance: Double
    let numberOfPeople: Int

    // Calculate trends (placeholder - in production, compare with previous period)
    private func calculateTrend(for type: String) -> (percentage: Double, isPositive: Bool) {
        switch type {
        case "balance":
            return netBalance >= 0 ? (5.2, true) : (2.1, false)
        case "people":
            return (0.0, true)  // Neutral for count
        case "owed":
            return (3.5, true)
        case "owing":
            return (1.8, false)
        default:
            return (0, true)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 1x2 Grid with only owed amounts
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                ], spacing: 8
            ) {
                // Owed to You Card
                EnhancedFinancialCard(
                    icon: "arrow.down.circle.fill",
                    iconColor: .wiseBrightGreen,
                    title: "OWED TO YOU",
                    amount: formatCurrency(totalOwedToYou),
                    trend: calculateTrend(for: "owed")
                )

                // You Owe Card
                EnhancedFinancialCard(
                    icon: "arrow.up.circle.fill",
                    iconColor: .wiseError,
                    title: "YOU OWE",
                    amount: formatCurrency(totalYouOwe),
                    trend: calculateTrend(for: "owing")
                )
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        String(format: "$%.0f", amount)
    }
}

// MARK: - People Filter Type
enum PeopleFilter: String, CaseIterable {
    case all = "All People"
    case owesYou = "Owes You"
    case youOwe = "You Owe"
    case settled = "Settled"
    case active = "Active"
}

// MARK: - People Filter Pill
struct PeopleFilterPill: View {
    let filter: PeopleFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    private var displayText: String {
        switch filter {
        case .all: return "All"
        case .owesYou: return "Owes You"
        case .youOwe: return "You Owe"
        case .settled: return "Settled"
        case .active: return "Active"
        }
    }

    private var pillColor: Color {
        switch filter {
        case .all: return .wisePrimaryText
        case .owesYou: return .wiseBrightGreen
        case .youOwe: return .wiseError
        case .settled: return .wiseSecondaryText
        case .active: return .wiseBlue
        }
    }

    var body: some View {
        Button(action: action) {
            Text(displayText)
                .font(.spotifyLabelMedium)
                .foregroundColor(isSelected ? .white : .wisePrimaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? pillColor : Color.wiseBorder.opacity(0.3))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - People List View
struct PeopleListView: View {
    @EnvironmentObject var dataManager: DataManager
    let people: [Person]
    @Binding var searchText: String
    @State private var editingPerson: Person?
    @State private var showingEditSheet = false
    @State private var personToDelete: Person?
    @State private var showingDeleteAlert = false
    @State private var selectedFilter: PeopleFilter = .all
    @State private var personToSettle: Person?
    @State private var showingSettleSheet = false
    @State private var showingSettleAllSheet = false
    @State private var isSelectionMode = false
    @State private var selectedPeople: Set<UUID> = []
    @State private var showingBulkReminderSheet = false

    var filteredPeople: [Person] {
        var result = people

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { person in
                person.name.localizedCaseInsensitiveContains(searchText)
                    || person.email.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply balance filter
        switch selectedFilter {
        case .all:
            break
        case .owesYou:
            result = result.filter { $0.balance > 0 }
        case .youOwe:
            result = result.filter { $0.balance < 0 }
        case .settled:
            result = result.filter { $0.balance == 0 }
        case .active:
            result = result.filter { $0.balance != 0 }
        }

        // Sort by most recent transaction date (recent activity)
        result.sort { person1, person2 in
            let trans1 = dataManager.transactions.filter { trans in
                trans.title.contains(person1.name) || trans.subtitle.contains(person1.name)
            }
            let trans2 = dataManager.transactions.filter { trans in
                trans.title.contains(person2.name) || trans.subtitle.contains(person2.name)
            }
            let date1 = trans1.sorted { $0.date > $1.date }.first?.date ?? Date.distantPast
            let date2 = trans2.sorted { $0.date > $1.date }.first?.date ?? Date.distantPast
            return date1 > date2
        }

        return result
    }

    // Balance calculations
    var totalOwedToYou: Double {
        let positiveBalances = people.filter { $0.balance > 0 }
        return positiveBalances.reduce(0) { $0 + $1.balance }
    }

    var totalYouOwe: Double {
        let negativeBalances = people.filter { $0.balance < 0 }
        let total = negativeBalances.reduce(0) { $0 + $1.balance }
        return abs(total)
    }

    var netBalance: Double {
        let owedToYou = totalOwedToYou
        let youOwe = totalYouOwe
        return owedToYou - youOwe
    }

    var numberOfPeople: Int {
        people.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PeopleFilter.allCases, id: \.self) { filter in
                        PeopleFilterPill(
                            filter: filter,
                            isSelected: selectedFilter == filter,
                            count: 0,  // Placeholder
                            action: {
                                HapticManager.shared.selection()
                                withAnimation {
                                    selectedFilter = filter
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 12)

            // People List
            if dataManager.isLoading && people.isEmpty {
                SkeletonListView(rowCount: 5, rowType: .person)
            } else if filteredPeople.isEmpty {
                // Empty State with better design
                VStack(spacing: 16) {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.wiseSecondaryText.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "person.2.slash")
                            .font(.system(size: 32))
                            .foregroundColor(.wiseSecondaryText)
                    }

                    Text("No people found")
                        .font(.spotifyHeadingSmall)
                        .foregroundColor(.wisePrimaryText)

                    Text("Try adjusting your filters or search")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(filteredPeople.enumerated()), id: \.element.id) {
                            index, person in
                            NavigationLink(destination: PersonDetailView(personId: person.id)) {
                                FeedPersonRow(
                                    person: person,
                                    transactions: dataManager.transactions
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 16)
                            .contextMenu {
                                Button {
                                    editingPerson = person
                                    showingEditSheet = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }

                                if person.balance != 0 {
                                    Button {
                                        personToSettle = person
                                        showingSettleSheet = true
                                    } label: {
                                        Label("Settle Up", systemImage: "checkmark.circle")
                                    }
                                }

                                Divider()

                                Button(role: .destructive) {
                                    personToDelete = person
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }

                            // Divider (aligned with text, matching feed style)
                            if index < filteredPeople.count - 1 {
                                FeedRowDivider()
                            }
                        }

                        // Bottom padding for tab bar
                        Color.clear.frame(height: 100)
                    }
                    .padding(.bottom, 20)
                }
                .background(Color.white)
                .scrollDismissesKeyboard(.interactively)
                .refreshable {
                    HapticManager.shared.pullToRefresh()
                    dataManager.loadAllData()
                    ToastManager.shared.showSuccess("Refreshed")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let person = editingPerson {
                EditPersonSheet(
                    showingEditPersonSheet: $showingEditSheet,
                    editingPerson: person,
                    onPersonUpdated: { updatedPerson in
                        do {
                            try dataManager.updatePerson(updatedPerson)
                        } catch {
                            dataManager.error = error
                        }
                    }
                )
            }
        }
        .alert(
            "Delete \(personToDelete?.name ?? "Person")?", isPresented: $showingDeleteAlert,
            presenting: personToDelete
        ) { person in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                do {
                    try dataManager.deletePerson(id: person.id)
                } catch {
                    dataManager.error = error
                }
            }
        } message: { person in
            if person.balance != 0 {
                Text(
                    "You cannot delete a person with a non-zero balance. Please settle up first."
                )
            } else {
                Text(
                    "This will permanently delete '\(person.name)' and all associated history. This action cannot be undone."
                )
            }
        }
    }
}

// MARK: - Groups List View
struct GroupsListView: View {
    @EnvironmentObject var dataManager: DataManager
    let groups: [Group]
    let people: [Person]
    @Binding var searchText: String
    @State private var editingGroup: Group?
    @State private var showingEditSheet = false
    @State private var groupToDelete: Group?
    @State private var showingDeleteAlert = false
    @State private var selectedFilter: GroupFilter = .all

    var filteredGroups: [Group] {
        var result = groups

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { group in
                group.name.localizedCaseInsensitiveContains(searchText)
                    || group.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .active:
            result = result.filter { $0.hasUnsettledExpenses }
        case .settled:
            result = result.filter { !$0.hasUnsettledExpenses && !$0.expenses.isEmpty }
        }

        // Sort by most recent expense (recent activity)
        result.sort { group1, group2 in
            let date1 = group1.expenses.sorted { $0.date > $1.date }.first?.date ?? group1.createdDate
            let date2 = group2.expenses.sorted { $0.date > $1.date }.first?.date ?? group2.createdDate
            return date1 > date2
        }

        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(GroupFilter.allCases, id: \.self) { filter in
                        GroupFilterPill(
                            filter: filter,
                            isSelected: selectedFilter == filter,
                            action: {
                                HapticManager.shared.selection()
                                withAnimation {
                                    selectedFilter = filter
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 12)

            // Groups List
            if dataManager.isLoading && groups.isEmpty {
                // Loading State
                SkeletonListView(rowCount: 5, rowType: .group)
            } else if filteredGroups.isEmpty {
                // Empty State
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        Spacer()

                        VStack(spacing: 24) {
                            // Icon - Properly sized and centered
                            ZStack {
                                // Background circle for visual weight
                                Circle()
                                    .fill(Color.wiseSecondaryText.opacity(0.08))
                                    .frame(width: 120, height: 120)

                                Image(systemName: "person.3")
                                    .font(.system(size: 56, weight: .light))
                                    .foregroundColor(.wiseSecondaryText.opacity(0.5))
                            }

                            // Text Content - Professional spacing and sizing
                            VStack(spacing: 12) {
                                Text("No Groups Yet")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.wisePrimaryText)

                                Text("Create your first group to track\nshared expenses")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(.wiseSecondaryText)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 48)
                        }
                        .frame(maxWidth: .infinity)

                        Spacer()
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(filteredGroups.enumerated()), id: \.element.id) {
                            index, group in
                            NavigationLink(destination: GroupDetailView(groupId: group.id)) {
                                FeedGroupRow(group: group)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 16)
                            .contextMenu {
                                Button {
                                    editingGroup = group
                                    showingEditSheet = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }

                                Divider()

                                Button(role: .destructive) {
                                    groupToDelete = group
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }

                            // Divider (aligned with text, matching feed style)
                            if index < filteredGroups.count - 1 {
                                FeedRowDivider()
                            }
                        }

                        // Bottom padding for tab bar
                        Color.clear.frame(height: 100)
                    }
                    .padding(.bottom, 20)
                }
                .background(Color.white)
                .scrollDismissesKeyboard(.interactively)
                .refreshable {
                    HapticManager.shared.pullToRefresh()
                    dataManager.loadAllData()
                    ToastManager.shared.showSuccess("Refreshed")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let group = editingGroup {
                AddGroupSheet(
                    showingAddGroupSheet: $showingEditSheet,
                    editingGroup: group,
                    people: people,
                    onGroupAdded: { updatedGroup in
                        do {
                            try dataManager.updateGroup(updatedGroup)
                        } catch {
                            dataManager.error = error
                        }
                    }
                )
                .environmentObject(dataManager)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .alert(
            "Delete \(groupToDelete?.name ?? "Group")?", isPresented: $showingDeleteAlert,
            presenting: groupToDelete
        ) { group in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                do {
                    try dataManager.deleteGroup(id: group.id)
                } catch {
                    dataManager.error = error
                }
            }
        } message: { group in
            Text("This will delete the group and all \(group.expenses.count) expenses.")
        }
    }
}

// MARK: - Group Row View (Unified Design)
@available(*, deprecated, message: "Use UnifiedListRowV2 with emoji icon instead")
struct GroupRowView: View {
    let group: Group
    let people: [Person]

    private var memberCountText: String {
        return "\(group.members.count) member\(group.members.count == 1 ? "" : "s")"
    }

    private var expenseCountText: String {
        return "\(group.expenses.count) expense\(group.expenses.count == 1 ? "" : "s")"
    }

    private var displaySubtitle: String {
        // Format: {memberCount} members • {expenseCount} expenses
        return "\(memberCountText) • \(expenseCountText)"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Unified Emoji Circle (48x48)
            UnifiedEmojiCircle(
                emoji: group.emoji,
                backgroundColor: .wiseBlue
            )

            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                Text(displaySubtitle)
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
                    .lineLimit(1)
            }

            Spacer()

            // Value Area - Single amount, right-aligned
            Text(formatCurrency(group.totalAmount))
                .font(.spotifyNumberMedium)
                .foregroundColor(.wisePrimaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Feed Group Row

/// Group row for People list with 8-color avatar system (matching FeedPersonRow)
/// Layout: 48x48 emoji avatar | Name (15pt) + Last expense (13pt) | Amount (15pt) + Status (13pt)
struct FeedGroupRow: View {
    let group: Group
    var onTap: (() -> Void)? = nil

    private let avatarSize: CGFloat = 48

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 14) {
                // Emoji avatar
                emojiAvatar

                // Left side - Name and last expense
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.Colors.feedPrimaryText)
                        .lineLimit(1)

                    Text(group.lastExpenseDetails())
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Theme.Colors.feedSecondaryText)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                // Right side - Amount and status
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formattedAmount)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.Colors.feedPrimaryText)

                    Text(group.settlementStatus)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(statusColor)
                }
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(group.name), \(formattedAmount), \(group.settlementStatus)")
    }

    // MARK: - Computed Properties

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let formatted = formatter.string(from: NSNumber(value: group.totalAmount)) ?? String(format: "%.2f", group.totalAmount)
        return "$\(formatted)"
    }

    private var statusColor: Color {
        switch group.settlementStatus {
        case "Active":
            return Theme.Colors.feedPositiveAmount  // Green for active
        case "Settled":
            return Theme.Colors.feedSecondaryText  // Gray for settled
        default:
            return Theme.Colors.feedSecondaryText
        }
    }

    // MARK: - Emoji Avatar

    private var avatarColor: FeedAvatarColor {
        FeedAvatarColor.forName(group.name)
    }

    private var emojiAvatar: some View {
        Circle()
            .fill(avatarColor.background)
            .frame(width: avatarSize, height: avatarSize)
            .overlay(
                Text(group.emoji)
                    .font(.system(size: 20))
            )
            .accessibilityHidden(true)
    }
}

// MARK: - Group Filter Type
enum GroupFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case settled = "Settled"
}

// MARK: - Group Filter Pill
struct GroupFilterPill: View {
    let filter: GroupFilter
    let isSelected: Bool
    let action: () -> Void

    private var pillColor: Color {
        switch filter {
        case .all: return .wisePrimaryText
        case .active: return .wiseBrightGreen
        case .settled: return .wiseSecondaryText
        }
    }

    var body: some View {
        Button(action: action) {
            Text(filter.rawValue)
                .font(.spotifyLabelMedium)
                .foregroundColor(isSelected ? .white : .wisePrimaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? pillColor : Color.wiseBorder.opacity(0.3))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Legacy Member Avatar Button (kept for backward compatibility)
struct MemberAvatarButton: View {
    let person: Person
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .bottomTrailing) {
                    AvatarView(person: person, size: .large, style: .solid)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? Color.wiseForestGreen : Color.clear, lineWidth: 2)
                        )

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.wiseForestGreen)
                            .background(Circle().fill(Color.white).frame(width: 14, height: 14))
                            .offset(x: 2, y: 2)
                    }
                }

                Text(person.name.components(separatedBy: " ").first ?? person.name)
                    .font(.spotifyCaptionSmall)
                    .foregroundColor(isSelected ? .wisePrimaryText : .wiseSecondaryText)
                    .lineLimit(1)
            }
            .frame(width: 60)
        }
    }
}

// MARK: - Add Person Row
struct AddPersonRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Dashed circle
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                    .foregroundColor(.wiseBorder)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.wiseSecondaryText)
                    )

                Text("Add new person")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
