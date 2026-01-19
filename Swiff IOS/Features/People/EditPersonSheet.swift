import Contacts
import ContactsUI
import PhotosUI
import SwiftUI

// MARK: - Edit Person Sheet (Full Featured)
struct EditPersonSheet: View {
    @Binding var showingEditPersonSheet: Bool
    let editingPerson: Person
    let onPersonUpdated: (Person) -> Void

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var selectedAvatarType: AvatarType = .initials("", colorIndex: 0)
    @State private var showingAvatarPicker = false
    @State private var showingContactPicker = false

    // Initialize with existing person data
    init(
        showingEditPersonSheet: Binding<Bool>, editingPerson: Person,
        onPersonUpdated: @escaping (Person) -> Void
    ) {
        self._showingEditPersonSheet = showingEditPersonSheet
        self.editingPerson = editingPerson
        self.onPersonUpdated = onPersonUpdated

        _name = State(initialValue: editingPerson.name)
        _email = State(initialValue: editingPerson.email)
        _phone = State(initialValue: editingPerson.phone)
        _selectedAvatarType = State(initialValue: editingPerson.avatarType)
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // Auto-update initials when name changes
    private var currentInitials: String {
        AvatarGenerator.generateInitials(from: name)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Profile Avatar")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        Button(action: { showingAvatarPicker = true }) {
                            HStack(spacing: 16) {
                                // Show current avatar or default initials
                                if case .initials = selectedAvatarType, !currentInitials.isEmpty {
                                    AvatarView(
                                        avatarType: .initials(
                                            currentInitials,
                                            colorIndex: AvatarColorPalette.colorIndex(for: name)),
                                        size: .large,
                                        style: .solid
                                    )
                                } else {
                                    AvatarView(
                                        avatarType: selectedAvatarType, size: .large, style: .solid)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Choose Avatar")
                                        .font(.spotifyHeadingSmall)
                                        .foregroundColor(.wisePrimaryText)

                                    Text("Select photo, emoji, or use initials")
                                        .font(.spotifyBodySmall)
                                        .foregroundColor(.wiseSecondaryText)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.wiseSecondaryText)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.wiseBorder.opacity(0.3))
                            )
                        }
                    }

                    // Basic Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Information")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        // Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Name *")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            TextField("e.g., John Smith", text: $name)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                                .onChange(of: name) { oldValue, newValue in
                                    // Auto-generate initials avatar as default
                                    if case .initials = selectedAvatarType, !newValue.isEmpty {
                                        selectedAvatarType = .initials(
                                            AvatarGenerator.generateInitials(from: newValue),
                                            colorIndex: AvatarColorPalette.colorIndex(for: newValue)
                                        )
                                    } else if case .initials = selectedAvatarType {
                                        selectedAvatarType = .initials("", colorIndex: 0)
                                    }
                                }
                        }

                        // Email
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            TextField("e.g., john@example.com", text: $email)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }

                        // Phone
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Phone")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            TextField("e.g., +1 234 567 8900", text: $phone)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .keyboardType(.phonePad)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }
                    }

                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .navigationTitle("Edit Person")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingEditPersonSheet = false
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseSecondaryText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePerson()
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
            .sheet(isPresented: $showingAvatarPicker) {
                AvatarPickerSheet(
                    selectedAvatarType: $selectedAvatarType,
                    isPresented: $showingAvatarPicker,
                    personName: name.isEmpty ? "User" : name
                )
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView(
                    name: $name,
                    email: $email,
                    phone: $phone,
                    isPresented: $showingContactPicker
                )
            }
        }
        .onAppear {
            // Initialize with initials avatar if needed
            if case .initials = selectedAvatarType, !name.isEmpty {
                selectedAvatarType = .initials(
                    AvatarGenerator.generateInitials(from: name),
                    colorIndex: AvatarColorPalette.colorIndex(for: name)
                )
            }
        }
    }

    private func savePerson() {
        // Ensure we have the latest initials if still using initials avatar
        var finalAvatarType = selectedAvatarType
        if case .initials = selectedAvatarType {
            finalAvatarType = .initials(
                AvatarGenerator.generateInitials(from: name),
                colorIndex: AvatarColorPalette.colorIndex(for: name)
            )
        }

        var updatedPerson = editingPerson
        updatedPerson.name = name.trimmingCharacters(in: .whitespaces)
        updatedPerson.email = email.trimmingCharacters(in: .whitespaces)
        updatedPerson.phone = phone.trimmingCharacters(in: .whitespaces)
        updatedPerson.avatarType = finalAvatarType

        onPersonUpdated(updatedPerson)
        showingEditPersonSheet = false
    }
}
