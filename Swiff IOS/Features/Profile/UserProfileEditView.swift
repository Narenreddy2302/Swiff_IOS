//
//  UserProfileEditView.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Edit user profile information
//

import Combine
import PhotosUI
import SwiftUI

struct UserProfileEditView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var profileManager = UserProfileManager.shared

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var selectedAvatarType: AvatarType = .initials("U", colorIndex: 0)
    @State private var showingAvatarPicker = false
    @State private var showingEmojiPicker = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var hasChanges = false
    @State private var showingDiscardAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar Section
                    VStack(spacing: 16) {
                        AvatarView(
                            avatarType: selectedAvatarType,
                            size: .xxlarge,
                            style: .solid
                        )

                        Button(action: {
                            HapticManager.shared.impact(.medium)
                            showingAvatarPicker = true
                        }) {
                            Text("Change Avatar")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wiseBlue)
                        }
                    }
                    .padding(.top, 20)

                    // Form Fields
                    VStack(spacing: 20) {
                        // Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            TextField("Enter your name", text: $name)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.3))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                                .onChange(of: name) { oldValue, newValue in
                                    hasChanges = true
                                    // Update initials avatar if currently using initials
                                    if case .initials = selectedAvatarType {
                                        updateInitialsAvatar()
                                    }
                                }
                        }

                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            TextField("your.email@example.com", text: $email)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.3))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                                .onChange(of: email) { oldValue, newValue in
                                    hasChanges = true
                                }
                        }

                        // Phone Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            TextField("+1 (234) 567-8900", text: $phone)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .keyboardType(.phonePad)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.3))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                                .onChange(of: phone) { oldValue, newValue in
                                    hasChanges = true
                                }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Save Button
                    SwiffButton(
                        "Save Changes",
                        icon: "checkmark",
                        variant: .primary,
                        size: .large,
                        action: saveProfile
                    )
                    .disabled(!hasChanges)
                    .opacity(hasChanges ? 1.0 : 0.6)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if hasChanges {
                            showingDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(.wiseSecondaryText)
                }
            }
        }
        .onAppear {
            loadProfile()
        }
        .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
            Button("Keep Editing", role: .cancel) {}
            Button("Discard", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
        .sheet(isPresented: $showingAvatarPicker) {
            AvatarTypePickerSheet(
                selectedAvatarType: $selectedAvatarType,
                onAvatarSelected: {
                    hasChanges = true
                    showingAvatarPicker = false
                }
            )
        }
    }

    private func loadProfile() {
        let profile = profileManager.profile
        name = profile.name
        email = profile.email
        phone = profile.phone
        selectedAvatarType = profile.avatarType
    }

    private func saveProfile() {
        var updatedProfile = profileManager.profile
        updatedProfile.name = name
        updatedProfile.email = email
        updatedProfile.phone = phone
        updatedProfile.avatarType = selectedAvatarType

        profileManager.updateProfile(updatedProfile)
        HapticManager.shared.success()
        hasChanges = false
        dismiss()
    }

    private func updateInitialsAvatar() {
        // Extract current color index if using initials
        let currentColorIndex: Int
        if case .initials(_, let colorIndex) = selectedAvatarType {
            currentColorIndex = colorIndex
        } else {
            currentColorIndex = 0
        }

        let components = name.split(separator: " ")
        if components.count >= 2 {
            let first = String(components[0].prefix(1))
            let last = String(components[1].prefix(1))
            selectedAvatarType = .initials(
                "\(first)\(last)".uppercased(), colorIndex: currentColorIndex)
        } else if let first = components.first, !first.isEmpty {
            selectedAvatarType = .initials(
                String(first.prefix(2)).uppercased(), colorIndex: currentColorIndex)
        }
    }
}

// MARK: - Avatar Type Picker Sheet

struct AvatarTypePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedAvatarType: AvatarType
    let onAvatarSelected: () -> Void

    @State private var showingEmojiPicker = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var tempAvatarType: AvatarType
    @State private var showingPhotoError = false
    @State private var photoErrorMessage = ""
    @State private var photoErrorRecovery: PhotoLibraryErrorHandler.RecoveryResult?

    private let photoHandler = PhotoLibraryErrorHandler()

    init(selectedAvatarType: Binding<AvatarType>, onAvatarSelected: @escaping () -> Void) {
        self._selectedAvatarType = selectedAvatarType
        self.onAvatarSelected = onAvatarSelected
        self._tempAvatarType = State(initialValue: selectedAvatarType.wrappedValue)
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: {
                        HapticManager.shared.impact(.medium)
                        showingEmojiPicker = true
                    }) {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(Color.wiseBlue.opacity(0.2))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: "face.smiling.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.wiseBlue)
                                )

                            Text("Choose Emoji")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)

                            Spacer()

                            if case .emoji = tempAvatarType {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.wiseForestGreen)
                            }
                        }
                    }

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(Color.wiseForestGreen.opacity(0.2))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.wiseForestGreen)
                                )

                            Text("Choose Photo")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)

                            Spacer()

                            if case .photo = tempAvatarType {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.wiseForestGreen)
                            }
                        }
                    }

                    Button(action: {
                        HapticManager.shared.selection()
                        // Get initials from current name
                        if case .initials(let initials, let colorIndex) = tempAvatarType {
                            tempAvatarType = .initials(initials, colorIndex: colorIndex)
                        } else {
                            // If not already initials, create default
                            tempAvatarType = .initials("AB", colorIndex: 0)
                        }
                        selectedAvatarType = tempAvatarType
                        onAvatarSelected()
                    }) {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(Color.wiseSecondaryText.opacity(0.2))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Text("AB")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.wiseSecondaryText)
                                )

                            Text("Use Initials")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)

                            Spacer()

                            if case .initials = tempAvatarType {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.wiseForestGreen)
                            }
                        }
                    }
                } header: {
                    Text("Avatar Type")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .navigationTitle("Choose Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
        .sheet(isPresented: $showingEmojiPicker) {
            EmojiPickerView(
                selectedEmoji: Binding(
                    get: {
                        if case .emoji(let emoji) = tempAvatarType {
                            return emoji
                        }
                        return "😊"
                    },
                    set: { newEmoji in
                        tempAvatarType = .emoji(newEmoji)
                        selectedAvatarType = tempAvatarType
                        showingEmojiPicker = false
                        onAvatarSelected()
                    }
                ))
        }
        .onChange(of: selectedPhotoItem) { oldValue, newValue in
            Task {
                guard let item = newValue else { return }

                do {
                    // Check photo library access first
                    let hasAccess = await photoHandler.hasPhotoLibraryAccess()
                    if !hasAccess {
                        let status = try await photoHandler.requestAuthorization()
                        guard status == .authorized || status == .limited else {
                            throw PhotoLibraryError.accessDenied
                        }
                    }

                    // Process the photo with comprehensive error handling
                    let result = try await photoHandler.processPhoto(from: item)

                    // Update avatar with processed image data
                    tempAvatarType = .photo(result.imageData)
                    selectedAvatarType = tempAvatarType
                    HapticManager.shared.success()
                    onAvatarSelected()

                } catch let error as PhotoLibraryError {
                    // Handle photo library specific errors
                    HapticManager.shared.error()
                    photoErrorMessage = error.localizedDescription

                    if let suggestion = error.recoverySuggestion {
                        photoErrorMessage += "\n\n\(suggestion)"
                    }

                    photoErrorRecovery = await photoHandler.attemptRecovery(from: error)
                    showingPhotoError = true

                } catch {
                    // Handle other errors
                    HapticManager.shared.error()
                    photoErrorMessage = "Failed to load photo: \(error.localizedDescription)"
                    showingPhotoError = true
                }
            }
        }
        .alert("Photo Error", isPresented: $showingPhotoError) {
            if let recovery = photoErrorRecovery {
                switch recovery {
                case .showSettings:
                    Button("Open Settings") {
                        photoHandler.openAppSettings()
                    }
                    Button("Cancel", role: .cancel) {}

                case .retry:
                    Button("Try Again") {
                        // User can select another photo
                    }
                    Button("Cancel", role: .cancel) {}

                case .suggestCompression, .suggestConversion, .suggestSmallerImage,
                    .suggestDifferentPhoto:
                    Button("OK") {}
                }
            } else {
                Button("OK") {}
            }
        } message: {
            Text(photoErrorMessage)
        }
    }
}

// MARK: - Emoji Picker View

struct EmojiPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedEmoji: String

    let emojis = [
        // People
        "😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂", "🙂", "🙃", "😉", "😊", "😇",
        "🥰", "😍", "🤩", "😘", "😗", "😚", "😙", "🥲", "😋", "😛", "😜", "🤪", "😝",
        "🤑", "🤗", "🤭", "🤫", "🤔", "🤐", "🤨", "😐", "😑", "😶", "😏", "😒", "🙄",
        "😬", "🤥", "😌", "😔", "😪", "🤤", "😴", "😷", "🤒", "🤕", "🤢", "🤮", "🤧",
        "🥵", "🥶", "🥴", "😵", "🤯", "🤠", "🥳", "🥸", "😎", "🤓", "🧐", "😕", "😟",
        "🙁", "😮", "😯", "😲", "😳", "🥺", "😦", "😧", "😨", "😰", "😥", "😢", "😭",
        "😱", "😖", "😣", "😞", "😓", "😩", "😫", "🥱", "😤", "😡", "😠", "🤬", "👿",
        // Animals
        "🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯", "🦁", "🐮", "🐷",
        "🐸", "🐵", "🐔", "🐧", "🐦", "🐤", "🦆", "🦅", "🦉", "🦇", "🐺", "🐗", "🐴",
        "🦄", "🐝", "🐛", "🦋", "🐌", "🐞", "🐜", "🦟", "🦗", "🕷", "🦂", "🐢", "🐍",
        // Food
        "🍎", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🫐", "🍈", "🍒", "🍑", "🥭", "🍍",
        "🥥", "🥝", "🍅", "🥑", "🍆", "🥔", "🥕", "🌽", "🥒", "🥬", "🥦", "🧄", "🧅",
        "🍄", "🥜", "🌰", "🍞", "🥐", "🥖", "🥨", "🥯", "🥞", "🧇", "🧀", "🍖", "🍗",
        "🥩", "🥓", "🍔", "🍟", "🍕", "🌭", "🥪", "🌮", "🌯", "🥙", "🧆", "🥚", "🍳",
        // Activities & Objects
        "⚽️", "🏀", "🏈", "⚾️", "🎾", "🏐", "🏉", "🎱", "🏓", "🏸", "🏒", "🏑", "🥍",
        "🏏", "🥅", "⛳️", "🏹", "🎣", "🥊", "🥋", "🎽", "⛸", "🥌", "🛷", "🎿", "⛷",
        "🏂", "🏋️", "🤺", "🤸", "🤼", "🤽", "🤾", "🤹", "🧘", "🎭", "🎨", "🎬", "🎤",
        "🎧", "🎼", "🎹", "🥁", "🎷", "🎺", "🎸", "🪕", "🎻", "🎲", "♟", "🎯", "🎳",
        // Travel & Places
        "🚗", "🚕", "🚙", "🚌", "🚎", "🏎", "🚓", "🚑", "🚒", "🚐", "🚚", "🚛", "🚜",
        "🛴", "🚲", "🛵", "🏍", "🛺", "🚨", "🚔", "🚍", "🚘", "🚖", "🚡", "🚠", "🚟",
        "🚃", "🚋", "🚞", "🚝", "🚄", "🚅", "🚈", "🚂", "🚆", "🚇", "🚊", "🚉", "✈️",
        "🛫", "🛬", "🛩", "💺", "🚁", "🚟", "🚠", "🚡", "🛰", "🚀", "🛸", "🚢", "⛵️",
    ]

    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 7)

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button(action: {
                            HapticManager.shared.selection()
                            selectedEmoji = emoji
                            dismiss()
                        }) {
                            Text(emoji)
                                .font(.system(size: 36))
                                .frame(width: 48, height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            selectedEmoji == emoji
                                                ? Color.wiseForestGreen.opacity(0.2) : Color.clear)
                                )
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Choose Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }
}

#Preview("User Profile Edit View") {
    UserProfileEditView()
}
