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
    @State private var debouncedSearchText = ""  // FIX 1.2: Debounced search text
    @State private var searchDebounceTask: Task<Void, Never>?  // FIX 1.2: Search debounce task
    @State private var showingManualEntry = false
    @State private var contactToInvite: ContactEntry?
    @State private var showingInviteSheet = false
    @State private var isRequestingPermission = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar (only show when we have contacts)
                if permissionManager.contactsStatus == .authorized && !syncManager.contacts.isEmpty
                {
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
                    .font(Theme.Fonts.labelMedium)
                    .foregroundColor(Theme.Colors.brandPrimary)
                }
            }
        }
        .onAppear {
            // Check permission status
            _ = permissionManager.checkContactsPermission()

            // FIX 1.1: Use debounced sync to avoid redundant syncs
            if permissionManager.contactsStatus == .authorized {
                Task {
                    await syncManager.loadContactsWithCache()  // Changed from syncContactsIfNeeded()
                }
            }
        }
        .onChange(of: permissionManager.contactsStatus) { oldValue, newValue in
            // When permission becomes authorized for the first time, do a full sync
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
        HStack(spacing: Theme.Metrics.paddingSmall) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.Colors.textSecondary)
                .font(.system(size: Theme.Metrics.iconSizeSmall))

            TextField("Search contacts...", text: $searchText)
                .font(Theme.Fonts.bodyLarge)
                .foregroundColor(Theme.Colors.textPrimary)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.Colors.textTertiary)
                        .font(.system(size: Theme.Metrics.iconSizeSmall))
                }
            }
        }
        .padding(.horizontal, Theme.Metrics.paddingMedium)
        .padding(.vertical, Theme.Metrics.paddingSmall)
        .background(
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                .fill(Theme.Colors.secondaryBackground)
        )
    }

    // MARK: - Authorized Content (Has Permission)

    private var authorizedContent: some View {
        List {
            // Manual Entry Row (Always at top)
            Section {
                manualEntryRow
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }

            // iOS 18 Limited Access Button
            if #available(iOS 18.0, *), permissionManager.hasLimitedContactAccess {
                Section {
                    ContactAccessButtonView { identifiers in
                        // When new contacts are selected, refresh triggers automatically via change observer
                        // But we can also force a sync just in case
                        print("User selected \(identifiers.count) more contacts")
                        Task {
                            await syncManager.refreshContacts()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }
            }

            // Loading state
            if syncManager.isSyncing && syncManager.contacts.isEmpty {
                Section {
                    loadingView
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                }
            } else if filteredContacts.isEmpty && debouncedSearchText.isEmpty {
                // No contacts on device
                Section {
                    emptyContactsView
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                }
            } else if filteredContacts.isEmpty && !debouncedSearchText.isEmpty {
                // No search results
                Section {
                    noSearchResultsView
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                }
            } else {
                // Contacts sections
                contactsSections
            }
        }
        .listStyle(.plain)
        .refreshable {
            await syncManager.refreshContacts()
        }
    }

    // MARK: - Manual Entry Row

    private var manualEntryRow: some View {
        Button(action: { showingManualEntry = true }) {
            HStack(spacing: Theme.Metrics.paddingMedium) {
                // Icon
                Circle()
                    .fill(Theme.Colors.brandPrimary.opacity(Theme.Opacity.faint))
                    .frame(width: Theme.Metrics.avatarMedium, height: Theme.Metrics.avatarMedium)
                    .overlay(
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: Theme.Metrics.iconSizeMedium, weight: .medium))
                            .foregroundColor(Theme.Colors.brandPrimary)
                    )

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enter manually")
                        .font(Theme.Fonts.bodyLarge)
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text("Add name, email, or phone")
                        .font(Theme.Fonts.bodySmall)
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.textTertiary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, Theme.Metrics.paddingMedium)
        }
        .buttonStyle(PlainButtonStyle())
        .background(Theme.Colors.cardBackground)
    }

    // MARK: - Contacts Sections

    private var contactsSections: some View {
        SwiftUI.Group {
            // On Swiff Section
            let onSwiffContacts = filteredContacts.filter { $0.hasAppAccount }
            if !onSwiffContacts.isEmpty {
                Section(
                    header: ContactImportSectionHeader(
                        title: "On Swiff", count: onSwiffContacts.count, color: Theme.Colors.success
                    )
                ) {
                    ForEach(onSwiffContacts) { contact in
                        ContactImportRow(
                            contact: contact,
                            isAlreadyAdded: isContactAlreadyAdded(contact),
                            onAdd: { handleContactSelection(contact) },
                            onInvite: nil
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                }
            }

            // Invite to Swiff Section
            let inviteContacts = filteredContacts.filter { !$0.hasAppAccount && $0.hasPhoneNumber }
            if !inviteContacts.isEmpty {
                Section(
                    header: ContactImportSectionHeader(
                        title: "Invite to Swiff", count: inviteContacts.count,
                        color: Theme.Colors.info)
                ) {
                    ForEach(inviteContacts) { contact in
                        ContactImportRow(
                            contact: contact,
                            isAlreadyAdded: isContactAlreadyAdded(contact),
                            onAdd: { handleContactSelection(contact) },
                            onInvite: {
                                contactToInvite = contact
                                showingInviteSheet = true
                            }
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                }
            }

            // Contacts without phone (can still add but can't invite)
            let noPhoneContacts = filteredContacts.filter {
                !$0.hasAppAccount && !$0.hasPhoneNumber
            }
            if !noPhoneContacts.isEmpty {
                Section(
                    header: ContactImportSectionHeader(
                        title: "Other Contacts", count: noPhoneContacts.count,
                        color: Theme.Colors.textTertiary)
                ) {
                    ForEach(noPhoneContacts) { contact in
                        ContactImportRow(
                            contact: contact,
                            isAlreadyAdded: isContactAlreadyAdded(contact),
                            onAdd: { handleContactSelection(contact) },
                            onInvite: nil
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                }
            }
        }
    }

    // MARK: - Filtered Contacts

    /// FIX 1.2: Use debouncedSearchText to avoid filtering on every keystroke
    private var filteredContacts: [ContactEntry] {
        if debouncedSearchText.isEmpty {
            return syncManager.contacts
        }
        return syncManager.contacts.search(debouncedSearchText)
    }

    // MARK: - Duplicate Detection

    /// Check if a contact is already added to the People list
    private func isContactAlreadyAdded(_ contact: ContactEntry) -> Bool {
        // 1. Check by contactId
        if dataManager.people.contains(where: { $0.contactId == contact.id }) {
            return true
        }

        // 2. Check by normalized phone number
        let contactPhones = contact.phoneNumbers.map { PhoneNumberNormalizer.normalize($0) }
        if !contactPhones.isEmpty {
            if dataManager.people.contains(where: { person in
                let personPhone = PhoneNumberNormalizer.normalize(person.phone)
                return !personPhone.isEmpty && contactPhones.contains(personPhone)
            }) {
                return true
            }
        }

        // 3. Check by name (case-insensitive)
        let contactName = contact.name.trimmingCharacters(in: .whitespaces).lowercased()
        if !contactName.isEmpty {
            if dataManager.people.contains(where: {
                $0.name.trimmingCharacters(in: .whitespaces).lowercased() == contactName
            }) {
                return true
            }
        }

        return false
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
                    .font(Theme.Fonts.displayMedium)
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(
                    "Enable contacts access in Settings to see your contacts here, or add people manually above."
                )
                .font(Theme.Fonts.bodyMedium)
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
                    .font(Theme.Fonts.displayMedium)
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(
                    "Allow access to see which contacts are on Swiff and easily add them to your people list."
                )
                .font(Theme.Fonts.bodyMedium)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

                Button(action: requestPermission) {
                    HStack {
                        if isRequestingPermission {
                            ProgressView()
                                .progressViewStyle(
                                    CircularProgressViewStyle(tint: Theme.Colors.textOnPrimary)
                                )
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "person.2.fill")
                            Text("Allow Access")
                        }
                    }
                    .font(Theme.Fonts.labelLarge)
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
                .font(Theme.Fonts.bodyMedium)
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
                .font(Theme.Fonts.bodyLarge)
                .foregroundColor(Theme.Colors.textSecondary)

            Text("Add contacts to your phone's address book to see them here.")
                .font(Theme.Fonts.bodySmall)
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
                .font(Theme.Fonts.bodyLarge)
                .foregroundColor(Theme.Colors.textSecondary)

            Text("Try a different search or add manually")
                .font(Theme.Fonts.bodySmall)
                .foregroundColor(Theme.Colors.textTertiary)

            Button(action: { showingManualEntry = true }) {
                Text("Add manually")
                    .font(Theme.Fonts.labelMedium)
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
                .frame(width: Theme.Metrics.paddingSmall, height: Theme.Metrics.paddingSmall)

            Text(title)
                .font(Theme.Fonts.labelMedium)
                .foregroundColor(Theme.Colors.textSecondary)

            Text("(\(count))")
                .font(Theme.Fonts.captionMedium)
                .foregroundColor(Theme.Colors.textTertiary)

            Spacer()
        }
        .padding(.horizontal, Theme.Metrics.paddingMedium)
        .padding(.vertical, Theme.Metrics.paddingSmall)
        .background(Theme.Colors.background)
    }
}

// MARK: - Contact Import Row

struct ContactImportRow: View {
    let contact: ContactEntry
    var isAlreadyAdded: Bool = false
    let onAdd: () -> Void
    let onInvite: (() -> Void)?

    var body: some View {
        HStack(spacing: Theme.Metrics.paddingMedium) {
            // Avatar
            ContactAvatarView(contact: contact, size: Theme.Metrics.avatarMedium)
                .opacity(isAlreadyAdded ? 0.5 : 1.0)

            // Name and Phone
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(Theme.Fonts.bodyLarge)
                    .foregroundColor(isAlreadyAdded ? Theme.Colors.textTertiary : Theme.Colors.textPrimary)
                    .lineLimit(1)

                if let phone = contact.primaryPhone {
                    Text(formatPhoneForDisplay(phone))
                        .font(Theme.Fonts.bodySmall)
                        .foregroundColor(isAlreadyAdded ? Theme.Colors.textTertiary : Theme.Colors.textSecondary)
                        .lineLimit(1)
                } else if let email = contact.email {
                    Text(email)
                        .font(Theme.Fonts.bodySmall)
                        .foregroundColor(isAlreadyAdded ? Theme.Colors.textTertiary : Theme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if isAlreadyAdded {
                // Already added indicator
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                    Text("Added")
                        .font(Theme.Fonts.captionMedium)
                }
                .foregroundColor(Theme.Colors.success)
            } else {
                // Status Badge (On Swiff)
                if contact.hasAppAccount {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("On Swiff")
                            .font(Theme.Fonts.captionMedium)
                    }
                    .foregroundColor(Theme.Colors.success)
                    .padding(.trailing, 4)
                }

                // Invite Button (for non-Swiff contacts with phone)
                if let onInvite = onInvite, !contact.hasAppAccount && contact.canBeInvited {
                    Button(action: onInvite) {
                        Text("Invite")
                            .font(Theme.Fonts.labelSmall)
                            .foregroundColor(Theme.Colors.info)
                            .padding(.horizontal, Theme.Metrics.paddingMedium)
                            .padding(.vertical, 6)
                            .background(Theme.Colors.info.opacity(Theme.Opacity.faint))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Add Button
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: Theme.Metrics.iconSizeLarge))
                        .foregroundColor(Theme.Colors.brandPrimary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, Theme.Metrics.paddingMedium)
        .background(Theme.Colors.cardBackground)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isAlreadyAdded {
                onAdd()
            }
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
