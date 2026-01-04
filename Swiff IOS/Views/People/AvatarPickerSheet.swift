import PhotosUI
import SwiftUI

// MARK: - Avatar Picker Sheet
struct AvatarPickerSheet: View {
    @Binding var selectedAvatarType: AvatarType
    @Binding var isPresented: Bool
    let personName: String  // For generating initials

    @State private var selectedTab = 0
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedEmoji = "👨🏻‍💼"
    @State private var selectedColorIndex = 0
    @State private var isProcessingImage = false
    @State private var selectedMemojiImage: UIImage?

    // Check if Memoji picker is available (iOS 18+)
    private var isMemojiAvailable: Bool {
        if #available(iOS 18.0, *) {
            return true
        }
        return false
    }

    // Tab indices - adjusted based on iOS version
    private var memojiTabIndex: Int { 1 }
    private var emojiTabIndex: Int { isMemojiAvailable ? 2 : 1 }
    private var initialsTabIndex: Int { isMemojiAvailable ? 3 : 2 }

    // Expanded emoji list with diverse options
    private let availableEmojis = [
        "👨🏻‍💼", "👩🏻‍💼", "👨🏼‍💼", "👩🏼‍💼", "👨🏽‍💼", "👩🏽‍💼",
        "👨🏾‍💼", "👩🏾‍💼", "👨🏿‍💼", "👩🏿‍💼", "🧑🏻‍💻", "🧑🏼‍💻",
        "🧑🏽‍💻", "🧑🏾‍💻", "🧑🏿‍💻", "👨🏻‍🎓", "👩🏻‍🎓", "👨🏼‍🎓",
        "👩🏼‍🎓", "👨🏽‍🎓", "👩🏽‍🎓", "👨🏾‍🎓", "👩🏾‍🎓", "👨🏿‍🎓",
        "👩🏿‍🎓", "🧑🏻‍🎨", "🧑🏼‍🎨", "🧑🏽‍🎨", "🧑🏾‍🎨", "🧑🏿‍🎨",
        "👨🏻‍⚕️", "👩🏻‍⚕️", "👨🏼‍⚕️", "👩🏼‍⚕️", "👨🏽‍⚕️", "👩🏽‍⚕️",
        "😊", "😎", "🤓", "😇", "🥳", "🤗", "😍", "🤩", "😺", "🐶",
        "🦊", "🐼", "🦁", "🐯", "🐸", "🐙", "🦋", "🌸", "⭐️", "🔥",
    ]

    private var previewAvatarType: AvatarType {
        if selectedTab == 0 {  // Photo
            if case .photo(let data) = selectedAvatarType, selectedPhotoItem == nil {
                return .photo(data)
            }
            return .initials(AvatarGenerator.generateInitials(from: personName), colorIndex: 0)
        } else if isMemojiAvailable && selectedTab == memojiTabIndex {  // Memoji (iOS 18+)
            if let memojiImage = selectedMemojiImage,
                let processedData = AvatarGenerator.processImage(memojiImage)
            {
                return .photo(processedData)
            }
            return .initials(AvatarGenerator.generateInitials(from: personName), colorIndex: 0)
        } else if selectedTab == emojiTabIndex {  // Emoji
            return .emoji(selectedEmoji)
        } else if selectedTab == initialsTabIndex {  // Initials
            return .initials(
                AvatarGenerator.generateInitials(from: personName), colorIndex: selectedColorIndex)
        } else {
            return .emoji("👤")
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Preview Section
                VStack(spacing: 16) {
                    ZStack {
                        // Preview avatar
                        AvatarView(avatarType: previewAvatarType, size: .xlarge, style: .solid)

                        // Loading overlay
                        if isProcessingImage {
                            Circle()
                                .fill(Color.wiseOverlayColor)
                                .frame(width: 64, height: 64)

                            ProgressView()
                                .tint(.white)
                        }
                    }

                    Text("Choose Your Avatar")
                        .font(.spotifyHeadingMedium)
                        .foregroundColor(.wisePrimaryText)
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
                .background(Color.wiseBorder.opacity(0.3))

                // Tab Selector
                Picker("Avatar Source", selection: $selectedTab) {
                    Label("Photo", systemImage: "photo").tag(0)
                    if isMemojiAvailable {
                        Label("Memoji", systemImage: "face.smiling.inverse").tag(memojiTabIndex)
                    }
                    Label("Emoji", systemImage: "face.smiling").tag(emojiTabIndex)
                    Label("Initials", systemImage: "textformat").tag(initialsTabIndex)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    // Photo Tab
                    photoPickerView.tag(0)

                    // Memoji Tab (iOS 18+ only)
                    if isMemojiAvailable {
                        memojiPickerView.tag(memojiTabIndex)
                    }

                    // Emoji Tab
                    emojiGridView.tag(emojiTabIndex)

                    // Initials Tab
                    initialsBuilderView.tag(initialsTabIndex)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Select Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseSecondaryText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveAvatar()
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.wiseForestGreen)
                    )
                    .disabled(isProcessingImage)
                }
            }
        }
    }

    // MARK: - Photo Picker View
    private var photoPickerView: some View {
        VStack(spacing: 20) {
            Spacer()

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 48))
                        .foregroundColor(.wiseForestGreen)

                    Text("Choose from Photos")
                        .font(.spotifyHeadingSmall)
                        .foregroundColor(.wisePrimaryText)

                    Text("Select any photo or saved Memoji from your library")
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.wiseBrightGreen.opacity(0.1))
                        .stroke(Color.wiseBrightGreen.opacity(0.3), lineWidth: 2)
                        .shadow(color: .wiseBrightGreen.opacity(0.1), radius: 8, x: 0, y: 4)
                )
            }
            .padding(.horizontal, 16)
            .onChange(of: selectedPhotoItem) { oldValue, newValue in
                Task {
                    await loadPhoto(from: newValue)
                }
            }

            Spacer()
        }
    }

    // MARK: - Memoji Picker View (iOS 18+)
    @ViewBuilder
    private var memojiPickerView: some View {
        if #available(iOS 18.0, *) {
            MemojiPickerView(selectedImage: $selectedMemojiImage)
        } else {
            // Fallback for older iOS versions (should not be reached due to isMemojiAvailable check)
            Text("Memoji picker requires iOS 18 or later")
                .foregroundColor(.wiseSecondaryText)
        }
    }

    // MARK: - Emoji Grid View
    private var emojiGridView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(availableEmojis, id: \.self) { emoji in
                    Button(action: { selectedEmoji = emoji }) {
                        Text(emoji)
                            .font(.system(size: 32))
                            .frame(width: 52, height: 52)
                            .background(
                                Circle()
                                    .fill(
                                        selectedEmoji == emoji
                                            ? Color.wiseForestGreen : Color.wiseBorder.opacity(0.3))
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        selectedEmoji == emoji
                                            ? Color.wiseForestGreen : Color.clear,
                                        lineWidth: 3
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
    }

    // MARK: - Initials Builder View
    private var initialsBuilderView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Show generated initials
            VStack(spacing: 12) {
                Text("Your Initials")
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseSecondaryText)

                Text(AvatarGenerator.generateInitials(from: personName))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.wisePrimaryText)
            }

            // Color selection
            VStack(spacing: 12) {
                Text("Choose Color")
                    .font(.spotifyHeadingSmall)
                    .foregroundColor(.wisePrimaryText)

                HStack(spacing: 16) {
                    ForEach(0..<AvatarColorPalette.colors.count, id: \.self) { index in
                        Button(action: { selectedColorIndex = index }) {
                            Circle()
                                .fill(AvatarColorPalette.color(for: index))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            selectedColorIndex == index
                                                ? Color.wisePrimaryText : Color.clear,
                                            lineWidth: 3
                                        )
                                )
                                .shadow(
                                    color: selectedColorIndex == index
                                        ? Color.wiseShadowColor : Color.clear,
                                    radius: 4, x: 0, y: 2
                                )
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Helper Methods
    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        isProcessingImage = true
        defer { isProcessingImage = false }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
                let uiImage = UIImage(data: data),
                let processedData = AvatarGenerator.processImage(uiImage)
            {
                selectedAvatarType = .photo(processedData)
            }
        } catch {
            print("Error loading photo: \(error)")
        }
    }

    private func saveAvatar() {
        if selectedTab == 0 {  // Photo - already set in loadPhoto
            // Photo is already set via loadPhoto()
        } else if isMemojiAvailable && selectedTab == memojiTabIndex {  // Memoji
            if let memojiImage = selectedMemojiImage,
                let processedData = AvatarGenerator.processImage(memojiImage)
            {
                selectedAvatarType = .photo(processedData)
            }
        } else if selectedTab == emojiTabIndex {  // Emoji
            selectedAvatarType = .emoji(selectedEmoji)
        } else if selectedTab == initialsTabIndex {  // Initials
            selectedAvatarType = .initials(
                AvatarGenerator.generateInitials(from: personName),
                colorIndex: selectedColorIndex
            )
        }

        isPresented = false
    }
}
