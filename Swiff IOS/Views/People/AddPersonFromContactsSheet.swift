//
//  AddPersonFromContactsSheet.swift
//  Swiff IOS
//
//  Created by Claude Code on 1/8/26.
//  Main sheet for adding people - shows contacts first with manual entry option
//

import SwiftUI

struct AddPersonFromContactsSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var syncManager = ContactSyncManager.shared
    @StateObject private var permissionManager = SystemPermissionManager.shared

    @State private var searchText = ""
    @State private var showingManualEntry = false
    @State private var contactToInvite: ContactEntry?
    @State private var showingInviteSheet = false
    @State private var isRequestingPermission = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar (only show when we have contacts)
                if permissionManager.contactsStatus == .authorized && !syncManager.contacts.isEmpty {
                    searchBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                }

                // Content based on permission status
                switch permissionManager.contactsStatus {
                case .authorized:
                    authorizedContent
                case .denied, .restricted:
                    deniedPermissionContent
                case .notDetermined:
                    notDeterminedContent
                default:
                    notDeterminedContent
                }
            }
            .background(Theme.Colors.background)
            .navigationTitle("Add Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .font(.spotifyLabelMedium)
                    .foregroundColor(Theme.Colors.brandPrimary)
                }
            }
        }
        .onAppear {
            // Check permission status
            _ = permissionManager.checkContactsPermission()

            // Sync contacts if already authorized
            if permissionManager.contactsStatus == .authorized {
                Task {
                    await syncManager.syncContactsIfPermitted()
                }
            }
        }
        .onChange(of: permissionManager.contactsStatus) { oldValue, newValue in
            // When permission becomes authorized, sync contacts
            if newValue == .authorized {
                Task {
                    await syncManager.syncContacts()
                }
            }
        }
        .sheet(isPresented: $showingManualEntry) {
            AddPersonSheet(isPresented: $showingManualEntry)
                .environmentObject(dataManager)
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingInviteSheet) {
            if let contact = contactToInvite {
                InviteSMSSheet(contact: contact, isPresented: $showingInviteSheet)
                    .presentationDetents([.height(300)])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.Colors.textSecondary)
                .font(.system(size: 16))

            TextField("Search contacts...", text: $searchText)
                .font(.spotifyBodyMedium)
                .foregroundColor(Theme.Colors.textPrimary)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.Colors.textTertiary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.Colors.secondaryBackground)
        )
    }

    // MARK: - Authorized Content (Has Permission)

    private var authorizedContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Manual Entry Row (Always at top)
                manualEntryRow

                Divider()
                    .padding(.leading, 16)

                // Loading state
                if syncManager.isSyncing && syncManager.contacts.isEmpty {
                    loadingView
                } else if filteredContacts.isEmpty && searchText.isEmpty {
                    // No contacts on device
                    emptyContactsView
                } else if filteredContacts.isEmpty && !searchText.isEmpty {
                    // No search results
                    noSearchResultsView
                } else {
                    // Contacts sections
                    contactsSections
                }
            }
            .padding(.bottom, 40)
        }
        .refreshable {
            await syncManager.refreshContacts()
        }
    }

    // MARK: - Manual Entry Row

    private var manualEntryRow: some View {
        Button(action: { showingManualEntry = true }) {
            HStack(spacing: 14) {
                // Icon
                Circle()
                    .fill(Theme.Colors.brandPrimary.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Theme.Colors.brandPrimary)
                    )

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enter manually")
                        .font(.spotifyBodyLarge)
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text("Add name, email, or phone")
                        .font(.spotifyBodySmall)
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.textTertiary)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
        .buttonStyle(PlainButtonStyle())
        .background(Theme.Colors.cardBackground)
    }

    // MARK: - Contacts Sections

    private var contactsSections: some View {
        VStack(spacing: 0) {
            // On Swiff Section
            let onSwiffContacts = filteredContacts.filter { $0.hasAppAccount }
            if !onSwiffContacts.isEmpty {
                ContactImportSectionHeader(title: "On Swiff", count: onSwiffContacts.count, color: Theme.Colors.success)

                ForEach(onSwiffContacts) { contact in
                    ContactImportRow(
                        contact: contact,
                        onAdd: { handleContactSelection(contact) },
                        onInvite: nil
                    )

                    if contact.id != onSwiffContacts.last?.id {
                        Divider()
                            .padding(.leading, 76)
                    }
                }
            }

            // Invite to Swiff Section
            let inviteContacts = filteredContacts.filter { !$0.hasAppAccount && $0.hasPhoneNumber }
            if !inviteContacts.isEmpty {
                if !onSwiffContacts.isEmpty {
                    Divider()
                        .padding(.top, 8)
                }

                ContactImportSectionHeader(title: "Invite to Swiff", count: inviteContacts.count, color: Theme.Colors.info)

                ForEach(inviteContacts) { contact in
                    ContactImportRow(
                        contact: contact,
                        onAdd: { handleContactSelection(contact) },
                        onInvite: {
                            contactToInvite = contact
                            showingInviteSheet = true
                        }
                    )

                    if contact.id != inviteContacts.last?.id {
                        Divider()
                            .padding(.leading, 76)
                    }
                }
            }

            // Contacts without phone (can still add but can't invite)
            let noPhoneContacts = filteredContacts.filter { !$0.hasAppAccount && !$0.hasPhoneNumber }
            if !noPhoneContacts.isEmpty {
                Divider()
                    .padding(.top, 8)

                ContactImportSectionHeader(title: "Other Contacts", count: noPhoneContacts.count, color: Theme.Colors.textTertiary)

                ForEach(noPhoneContacts) { contact in
                    ContactImportRow(
                        contact: contact,
                        onAdd: { handleContactSelection(contact) },
                        onInvite: nil
                    )

                    if contact.id != noPhoneContacts.last?.id {
                        Divider()
                            .padding(.leading, 76)
                    }
                }
            }
        }
    }

    // MARK: - Filtered Contacts

    private var filteredContacts: [ContactEntry] {
        if searchText.isEmpty {
            return syncManager.contacts
        }
        return syncManager.contacts.search(searchText)
    }

    // MARK: - Denied Permission Content

    private var deniedPermissionContent: some View {
        VStack(spacing: 0) {
            // Manual entry row always at top
            manualEntryRow

            Divider()
                .padding(.leading, 16)

            // Permission denied message
            VStack(spacing: 20) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Theme.Colors.systemError.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: "person.crop.circle.badge.xmark")
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(Theme.Colors.systemError)
                }

                Text("Contacts Access Denied")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(Theme.Colors.textPrimary)

                Text("Enable contacts access in Settings to see your contacts here, or add people manually above.")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button(action: { permissionManager.openAppSettings() }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Open Settings")
                    }
                    .font(.spotifyLabelMedium)
                    .foregroundColor(Theme.Colors.brandPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Theme.Colors.brandPrimary, lineWidth: 1)
                    )
                }
                .padding(.top, 8)

                Spacer()
            }
        }
    }

    // MARK: - Not Determined Permission Content

    private var notDeterminedContent: some View {
        VStack(spacing: 0) {
            // Manual entry row always at top
            manualEntryRow

            Divider()
                .padding(.leading, 16)

            // Permission request
            VStack(spacing: 20) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Theme.Colors.brandPrimary.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 44, weight: .light))
                        .foregroundColor(Theme.Colors.brandPrimary)
                }

                Text("See Your Contacts")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(Theme.Colors.textPrimary)

                Text("Allow access to see which contacts are on Swiff and easily add them to your people list.")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button(action: requestPermission) {
                    HStack {
                        if isRequestingPermission {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.textOnPrimary))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "person.2.fill")
                            Text("Allow Access")
                        }
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(Theme.Colors.textOnPrimary)
                    .frame(width: 200)
                    .padding(.vertical, 14)
                    .background(Theme.Colors.brandPrimary)
                    .cornerRadius(25)
                }
                .disabled(isRequestingPermission)
                .padding(.top, 8)

                Spacer()
            }
        }
    }

    // MARK: - Empty States

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
        .frame(minHeight: 200)
    }

    private var emptyContactsView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "person.2.slash")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(Theme.Colors.textTertiary)

            Text("No contacts found")
                .font(.spotifyBodyLarge)
                .foregroundColor(Theme.Colors.textSecondary)

            Text("Add contacts to your phone's address book to see them here.")
                .font(.spotifyBodySmall)
                .foregroundColor(Theme.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
        .frame(minHeight: 200)
    }

    private var noSearchResultsView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(Theme.Colors.textTertiary)

            Text("No results for \"\(searchText)\"")
                .font(.spotifyBodyLarge)
                .foregroundColor(Theme.Colors.textSecondary)

            Text("Try a different search or add manually")
                .font(.spotifyBodySmall)
                .foregroundColor(Theme.Colors.textTertiary)

            Button(action: { showingManualEntry = true }) {
                Text("Add manually")
                    .font(.spotifyLabelMedium)
                    .foregroundColor(Theme.Colors.brandPrimary)
            }
            .padding(.top, 4)

            Spacer()
        }
        .frame(minHeight: 200)
    }

    // MARK: - Actions

    private func requestPermission() {
        isRequestingPermission = true
        Task {
            do {
                _ = try await permissionManager.requestContactsPermission()
            } catch {
                // Error handled by permission manager state
            }
            isRequestingPermission = false
        }
    }

    private func handleContactSelection(_ contact: ContactEntry) {
        // Check if contact is already in People (by contactId)
        if let existing = dataManager.people.first(where: { $0.contactId == contact.id }) {
            HapticManager.shared.warning()
            ToastManager.shared.showInfo("\(existing.name) is already in People")
            isPresented = false
            return
        }

        // Check if contact matches an existing person by phone
        let contactPhones = contact.phoneNumbers.map { PhoneNumberNormalizer.normalize($0) }
        if let existing = dataManager.people.first(where: { person in
            let personPhone = PhoneNumberNormalizer.normalize(person.phone)
            return !personPhone.isEmpty && contactPhones.contains(personPhone)
        }) {
            // Link the contact to existing person
            do {
                var updated = existing
                updated.contactId = contact.id
                try dataManager.updatePerson(updated)
                HapticManager.shared.success()
                ToastManager.shared.showSuccess("Linked to \(existing.name)")
                isPresented = false
            } catch {
                dataManager.error = error
            }
            return
        }

        // Import as new person
        do {
            let person = try dataManager.importContact(contact)
            HapticManager.shared.success()
            ToastManager.shared.showSuccess("\(person.name) added!")
            isPresented = false
        } catch {
            HapticManager.shared.error()
            dataManager.error = error
        }
    }
}

// MARK: - Contact Import Section Header

struct ContactImportSectionHeader: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.spotifyLabelMedium)
                .foregroundColor(Theme.Colors.textSecondary)

            Text("(\(count))")
                .font(.spotifyCaptionMedium)
                .foregroundColor(Theme.Colors.textTertiary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.Colors.background)
    }
}

// MARK: - Contact Import Row

struct ContactImportRow: View {
    let contact: ContactEntry
    let onAdd: () -> Void
    let onInvite: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ContactAvatarView(contact: contact, size: 48)

            // Name and Phone
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)

                if let phone = contact.primaryPhone {
                    Text(formatPhoneForDisplay(phone))
                        .font(.spotifyBodySmall)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(1)
                } else if let email = contact.email {
                    Text(email)
                        .font(.spotifyBodySmall)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Status Badge (On Swiff)
            if contact.hasAppAccount {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                    Text("On Swiff")
                        .font(.spotifyCaptionMedium)
                }
                .foregroundColor(Theme.Colors.success)
                .padding(.trailing, 4)
            }

            // Invite Button (for non-Swiff contacts with phone)
            if let onInvite = onInvite, !contact.hasAppAccount && contact.canBeInvited {
                Button(action: onInvite) {
                    Text("Invite")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(Theme.Colors.info)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.Colors.info.opacity(0.1))
                        .cornerRadius(14)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Add Button
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Theme.Colors.brandPrimary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Theme.Colors.cardBackground)
        .contentShape(Rectangle())
        .onTapGesture {
            onAdd()
        }
    }

    private func formatPhoneForDisplay(_ phone: String) -> String {
        guard phone.count >= 10 else { return phone }

        // Format US phone numbers
        if phone.hasPrefix("+1") && phone.count == 12 {
            let number = String(phone.dropFirst(2))
            let area = number.prefix(3)
            let first = number.dropFirst(3).prefix(3)
            let last = number.suffix(4)
            return "(\(area)) \(first)-\(last)"
        }

        return phone
    }
}

// MARK: - Preview

#Preview {
    AddPersonFromContactsSheet(isPresented: .constant(true))
        .environmentObject(DataManager.shared)
}
