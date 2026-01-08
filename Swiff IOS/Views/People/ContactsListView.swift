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
    @State private var selectedFilter: ContactsFilter = .all
    @State private var contactToInvite: ContactEntry?
    @State private var showingInviteSheet = false
    @State private var showingAddTransactionSheet = false
    @State private var selectedPersonForTransaction: Person?

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

            // Sync contacts if permitted
            if permissionManager.contactsStatus == .authorized {
                Task {
                    await syncManager.syncContactsIfPermitted()
                }
            }
        }
        .onChange(of: permissionManager.contactsStatus) { oldValue, newValue in
            // When permission changes to authorized, sync contacts
            if newValue == .authorized {
                Task {
                    await syncManager.syncContacts()
                }
            }
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

    private var filteredContacts: [ContactEntry] {
        var result = syncManager.contacts

        // Apply search filter
        if !searchText.isEmpty {
            result = result.search(searchText)
        }

        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .onSwiff:
            result = result.onSwiff
        case .toInvite:
            result = result.invitable
        }

        return result
    }

    // MARK: - Contacts List

    private var contactsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // On Swiff Section
                if selectedFilter == .all || selectedFilter == .onSwiff {
                    let onSwiff =
                        selectedFilter == .onSwiff ? filteredContacts : filteredContacts.onSwiff
                    if !onSwiff.isEmpty {
                        ContactsSectionHeader(title: "On Swiff", count: onSwiff.count)
                        ForEach(onSwiff) { contact in
                            ContactRowView(
                                contact: contact,
                                onInvite: {
                                    // On Swiff contacts don't need invite
                                },
                                onSelect: {
                                    importAndTransact(contact: contact)
                                }
                            )
                            if contact.id != onSwiff.last?.id {
                                Divider()
                                    .padding(.leading, 76)
                            }
                        }
                    }
                }

                // To Invite Section
                if selectedFilter == .all || selectedFilter == .toInvite {
                    let toInvite =
                        selectedFilter == .toInvite ? filteredContacts : filteredContacts.invitable
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
                                    importAndTransact(contact: contact)
                                }
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

            if searchText.isEmpty && syncManager.totalContactsCount == 0 {
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
                // Search/Filter empty case
                Image(
                    systemName: searchText.isEmpty
                        ? "person.crop.circle.badge.questionmark" : "magnifyingglass"
                )
                .font(.system(size: 50, weight: .light))
                .foregroundColor(Theme.Colors.textTertiary)

                Text(searchText.isEmpty ? "No contacts found" : "No results for \"\(searchText)\"")
                    .font(.spotifyBodyLarge)
                    .foregroundColor(Theme.Colors.textSecondary)

                if !searchText.isEmpty {
                    Text("Try a different search term")
                        .font(.spotifyBodySmall)
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }

            Spacer()
        }
    }

    // MARK: - Helper Methods

    private func importAndTransact(contact: ContactEntry) {
        do {
            let person = try dataManager.importContact(contact)
            selectedPersonForTransaction = person
            showingAddTransactionSheet = true
        } catch {
            dataManager.error = error
        }
    }
}

// MARK: - Contacts Filter

enum ContactsFilter: String, CaseIterable {
    case all = "All"
    case onSwiff = "On Swiff"
    case toInvite = "To Invite"
}

// MARK: - Filter Pills View

struct ContactsFilterPillsView: View {
    @Binding var selectedFilter: ContactsFilter
    let contacts: [ContactEntry]

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
        case .onSwiff: return Theme.Colors.success
        case .toInvite: return Theme.Colors.info
        }
    }

    private var textColor: Color {
        if isSelected {
            switch filter {
            case .all: return Theme.Colors.textOnPrimary
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
