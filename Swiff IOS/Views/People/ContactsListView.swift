//
//  ContactsListView.swift
//  Swiff IOS
//
//  Created by Claude Code on 1/8/26.
//  Main contacts list view with sections
//

import SwiftUI

struct ContactsListView: View {
    @StateObject private var syncManager = ContactSyncManager.shared
    @StateObject private var permissionManager = SystemPermissionManager.shared
    @EnvironmentObject var dataManager: DataManager
    @Binding var searchText: String
    @State private var debouncedSearchText = ""  // FIX 1.2: Debounced search text
    @State private var searchDebounceTask: Task<Void, Never>?  // FIX 1.2: Search debounce task
    @State private var selectedFilter: ContactsFilter = .all
    @State private var contactToInvite: ContactEntry?
    @State private var showingInviteSheet = false
    @State private var showingAddTransactionSheet = false
    @State private var selectedPersonForTransaction: Person?

    // Contact Conversation Navigation
    @State private var selectedContactForNavigation: ContactEntry?

    var body: some View {
        SwiftUI.Group {
            // Check permission status
            if permissionManager.contactsStatus == .authorized {
                contactsContent
            } else {
                ContactsPermissionView()
            }
        }
        .onAppear {
            // Check and update permission status
            _ = permissionManager.checkContactsPermission()

            // FIX 1.1: Use debounced sync to avoid redundant syncs
            if permissionManager.contactsStatus == .authorized {
                Task {
                    await syncManager.syncContactsIfNeeded()
                }
            }
        }
        .onChange(of: permissionManager.contactsStatus) { oldValue, newValue in
            // When permission changes to authorized for the first time, do a full sync
            if newValue == .authorized && oldValue != .authorized {
                Task {
                    await syncManager.syncContacts()
                }
            }
        }
        // FIX 1.2: Debounce search input to avoid filtering on every keystroke
        .onChange(of: searchText) { oldValue, newValue in
            // Cancel any pending debounce task
            searchDebounceTask?.cancel()

            // Debounce for 300ms before filtering
            searchDebounceTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000)  // 300ms
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    debouncedSearchText = newValue
                }
            }
        }
        .onDisappear {
            // Clean up debounce task
            searchDebounceTask?.cancel()
        }
        .sheet(isPresented: $showingInviteSheet) {
            if let contact = contactToInvite {
                InviteSMSSheet(contact: contact, isPresented: $showingInviteSheet)
                    .presentationDetents([.height(300)])
                    .presentationDragIndicator(.visible)
            }
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
        // Navigation to Contact Conversation View
        .navigationDestination(item: $selectedContactForNavigation) { contact in
            ContactConversationView(contact: contact)
        }
    }

    // MARK: - Contacts Content

    private var contactsContent: some View {
        VStack(spacing: 0) {
            // Filter Pills
            ContactsFilterPillsView(selectedFilter: $selectedFilter, contacts: syncManager.contacts)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            // Content
            if let error = syncManager.syncError {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.Colors.systemError)
                    Text("Failed to load contacts")
                        .font(.spotifyHeadingMedium)
                        .foregroundColor(Theme.Colors.textPrimary)
                    Text(error.localizedDescription)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Try Again") {
                        Task {
                            await syncManager.refreshContacts()
                        }
                    }
                    .padding(.top, 8)
                    Spacer()
                }
            } else if syncManager.isSyncing && syncManager.contacts.isEmpty {
                loadingView
            } else if filteredContacts.isEmpty {
                emptyStateView
            } else {
                contactsList
            }
        }
    }

    // MARK: - Filtered Contacts

    /// FIX 1.2: Use debouncedSearchText to avoid filtering on every keystroke
    private var filteredContacts: [ContactEntry] {
        var result = syncManager.contacts

        // Apply search filter using debounced text
        if !debouncedSearchText.isEmpty {
            result = result.search(debouncedSearchText)
        }

        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .withDues:
            // Filter to only contacts with non-zero balance
            result = result.filter { dataManager.getBalanceForContact($0) != nil }
        case .onSwiff:
            result = result.onSwiff
        case .toInvite:
            result = result.invitable
        }

        return result
    }

    /// Get contacts with pending dues (for the "With Dues" section)
    private var contactsWithDues: [ContactEntry] {
        syncManager.contacts.filter { dataManager.getBalanceForContact($0) != nil }
    }

    // MARK: - Contacts List

    private var contactsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // With Dues Section (shown at top when filter is .all or .withDues)
                if selectedFilter == .all || selectedFilter == .withDues {
                    let withDues = selectedFilter == .withDues ? filteredContacts : contactsWithDues
                    if !withDues.isEmpty {
                        ContactsSectionHeader(title: "With Pending Dues", count: withDues.count)
                        ForEach(withDues) { contact in
                            ContactRowView(
                                contact: contact,
                                onInvite: {
                                    contactToInvite = contact
                                    showingInviteSheet = true
                                },
                                onSelect: {
                                    selectedContactForNavigation = contact
                                },
                                pendingBalance: dataManager.getBalanceForContact(contact)
                            )
                            if contact.id != withDues.last?.id {
                                Divider()
                                    .padding(.leading, 76)
                            }
                        }

                        if selectedFilter == .all {
                            Divider()
                                .padding(.top, 8)
                        }
                    }
                }

                // On Swiff Section (exclude those with dues to avoid duplicates when filter is .all)
                if selectedFilter == .all || selectedFilter == .onSwiff {
                    // Calculate onSwiff using ternary to avoid ViewBuilder issues
                    let dueContactIds = Set(contactsWithDues.map { $0.id })
                    let onSwiff = selectedFilter == .onSwiff
                        ? filteredContacts
                        : filteredContacts.onSwiff.filter { !dueContactIds.contains($0.id) }

                    if !onSwiff.isEmpty {
                        ContactsSectionHeader(title: "On Swiff", count: onSwiff.count)
                        ForEach(onSwiff) { contact in
                            ContactRowView(
                                contact: contact,
                                onInvite: {
                                    // On Swiff contacts don't need invite
                                },
                                onSelect: {
                                    selectedContactForNavigation = contact
                                },
                                pendingBalance: dataManager.getBalanceForContact(contact)
                            )
                            if contact.id != onSwiff.last?.id {
                                Divider()
                                    .padding(.leading, 76)
                            }
                        }
                    }
                }

                // To Invite Section (exclude those with dues to avoid duplicates when filter is .all)
                if selectedFilter == .all || selectedFilter == .toInvite {
                    // Calculate toInvite using ternary to avoid ViewBuilder issues
                    let dueContactIdsForInvite = Set(contactsWithDues.map { $0.id })
                    let toInvite = selectedFilter == .toInvite
                        ? filteredContacts
                        : filteredContacts.invitable.filter { !dueContactIdsForInvite.contains($0.id) }

                    if !toInvite.isEmpty {
                        if selectedFilter == .all {
                            Divider()
                                .padding(.top, 8)
                        }
                        ContactsSectionHeader(title: "Invite to Swiff", count: toInvite.count)
                        ForEach(toInvite) { contact in
                            ContactRowView(
                                contact: contact,
                                onInvite: {
                                    contactToInvite = contact
                                    showingInviteSheet = true
                                },
                                onSelect: {
                                    selectedContactForNavigation = contact
                                },
                                pendingBalance: dataManager.getBalanceForContact(contact)
                            )
                            if contact.id != toInvite.last?.id {
                                Divider()
                                    .padding(.leading, 76)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 100)  // Safe area for tab bar
        }
        .refreshable {
            await syncManager.refreshContacts()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading contacts...")
                .font(.spotifyBodyMedium)
                .foregroundColor(Theme.Colors.textSecondary)
            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            if debouncedSearchText.isEmpty && syncManager.totalContactsCount == 0 {
                // No contacts on device case
                Image(systemName: "person.2.slash.fill")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(Theme.Colors.textTertiary)

                Text("No contacts found on device")
                    .font(.spotifyBodyLarge)
                    .foregroundColor(Theme.Colors.textSecondary)

                Text("Add contacts to your phone's address book to see them here.")
                    .font(.spotifyBodySmall)
                    .foregroundColor(Theme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            } else {
                // Search/Filter empty case - show the actual typed text for feedback
                Image(
                    systemName: debouncedSearchText.isEmpty
                        ? "person.crop.circle.badge.questionmark" : "magnifyingglass"
                )
                .font(.system(size: 50, weight: .light))
                .foregroundColor(Theme.Colors.textTertiary)

                Text(debouncedSearchText.isEmpty ? "No contacts found" : "No results for \"\(searchText)\"")
                    .font(.spotifyBodyLarge)
                    .foregroundColor(Theme.Colors.textSecondary)

                if !debouncedSearchText.isEmpty {
                    Text("Try a different search term")
                        .font(.spotifyBodySmall)
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }

            Spacer()
        }
    }

}

// MARK: - Contacts Filter

enum ContactsFilter: String, CaseIterable {
    case all = "All"
    case withDues = "With Dues"
    case onSwiff = "On Swiff"
    case toInvite = "To Invite"
}

// MARK: - Filter Pills View

struct ContactsFilterPillsView: View {
    @Binding var selectedFilter: ContactsFilter
    let contacts: [ContactEntry]
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ContactsFilter.allCases, id: \.self) { filter in
                    ContactsFilterPill(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        count: countForFilter(filter)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
        }
    }

    private func countForFilter(_ filter: ContactsFilter) -> Int {
        switch filter {
        case .all: return contacts.count
        case .withDues: return dataManager.contactsWithDuesCount
        case .onSwiff: return contacts.onSwiff.count
        case .toInvite: return contacts.invitable.count
        }
    }
}

// MARK: - Filter Pill

struct ContactsFilterPill: View {
    let filter: ContactsFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    private var pillColor: Color {
        switch filter {
        case .all: return Theme.Colors.brandPrimary
        case .withDues: return Theme.Colors.warning
        case .onSwiff: return Theme.Colors.success
        case .toInvite: return Theme.Colors.info
        }
    }

    private var textColor: Color {
        if isSelected {
            switch filter {
            case .all: return Theme.Colors.textOnPrimary
            case .withDues: return .white
            case .onSwiff: return .white
            case .toInvite: return .white
            }
        } else {
            return Theme.Colors.textPrimary
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(filter.rawValue)
                if count > 0 {
                    Text("(\(count))")
                        .opacity(0.8)
                }
            }
            .font(.spotifyLabelMedium)
            .foregroundColor(textColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? pillColor : Theme.Colors.border)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Section Header

struct ContactsSectionHeader: View {
    let title: String
    let count: Int

    var body: some View {
        HStack {
            Text(title)
                .font(.spotifyLabelMedium)
                .foregroundColor(Theme.Colors.textSecondary)

            Text("(\(count))")
                .font(.spotifyCaptionMedium)
                .foregroundColor(Theme.Colors.textTertiary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Theme.Colors.background)
    }
}

// MARK: - Preview

#Preview {
    ContactsListView(searchText: .constant(""))
}
