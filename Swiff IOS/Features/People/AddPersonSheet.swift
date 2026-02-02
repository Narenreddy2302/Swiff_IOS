import Contacts
import ContactsUI
import PhotosUI
import SwiftUI

// MARK: - Smart Input Type Detection
enum PersonInputType {
    case email
    case phone
    case name

    static func detect(_ input: String) -> PersonInputType {
        let trimmed = input.trimmingCharacters(in: .whitespaces)

        // Email detection: contains @
        if trimmed.contains("@") {
            return .email
        }

        // Phone detection: starts with + or is mostly digits
        let digitsOnly = trimmed.filter { $0.isNumber }
        let formattingChars = trimmed.filter {
            $0.isNumber || $0 == " " || $0 == "-" || $0 == "(" || $0 == ")" || $0 == "+"
        }
        if trimmed.hasPrefix("+")
            || (digitsOnly.count >= 7 && formattingChars.count == trimmed.count)
        {
            return .phone
        }

        // Default to name
        return .name
    }
}

// MARK: - Add Person Sheet (Redesigned with Live Preview)
struct AddPersonSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var dataManager: DataManager

    @State private var inputValue = ""
    @State private var avatarScale: CGFloat = 1.0
    @FocusState private var isFocused: Bool

    private var detectedType: PersonInputType {
        PersonInputType.detect(inputValue)
    }

    private var isFormValid: Bool {
        !inputValue.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var generatedName: String {
        let trimmed = inputValue.trimmingCharacters(in: .whitespaces)
        switch detectedType {
        case .email:
            return trimmed.components(separatedBy: "@").first?.replacingOccurrences(
                of: ".", with: " "
            ).capitalized ?? trimmed
        case .phone, .name:
            return trimmed
        }
    }

    private var generatedInitials: String {
        AvatarGenerator.generateInitials(from: generatedName)
    }

    private var colorIndex: Int {
        AvatarColorPalette.colorIndex(for: generatedName)
    }

    private var iconForDetectedType: String {
        switch detectedType {
        case .name: return "person.fill"
        case .email: return "envelope.fill"
        case .phone: return "phone.fill"
        }
    }

    private var colorForDetectedType: Color {
        switch detectedType {
        case .name: return .wiseForestGreen
        case .email: return .wiseBlue
        case .phone: return .wisePurple
        }
    }

    private var labelForDetectedType: String {
        switch detectedType {
        case .name: return "Name"
        case .email: return "Email"
        case .phone: return "Phone"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Live Avatar Preview
            AvatarView(
                avatarType: .initials(
                    generatedInitials.isEmpty ? "?" : generatedInitials,
                    colorIndex: colorIndex
                ),
                size: .xlarge,
                style: .solid
            )
            .scaleEffect(avatarScale)
            .padding(.top, 24)
            .padding(.bottom, 12)

            // Header
            VStack(spacing: 4) {
                Text("New Contact")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Text("Name, email, or phone")
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wiseSecondaryText)
            }
            .padding(.bottom, 24)

            // Smart Input Field with Dynamic Icon
            HStack(spacing: 12) {
                Image(systemName: iconForDetectedType)
                    .font(.system(size: 18))
                    .foregroundColor(colorForDetectedType)
                    .frame(width: 24)
                    .animation(.easeInOut(duration: 0.2), value: detectedType)

                TextField("", text: $inputValue)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
                    .placeholder(when: inputValue.isEmpty) {
                        Text("Enter name, email, or phone")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseSecondaryText.opacity(0.6))
                    }
                    .focused($isFocused)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wiseCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? colorForDetectedType : Color.wiseBorder, lineWidth: 1)
            )
            .padding(.horizontal, 24)

            // Detection Badge
            if !inputValue.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: iconForDetectedType)
                        .font(.system(size: 10))

                    Text("Detected: \(labelForDetectedType)")
                        .font(.spotifyCaptionMedium)
                }
                .foregroundColor(colorForDetectedType)
                .padding(.top, 12)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            Spacer().frame(height: inputValue.isEmpty ? 32 : 20)

            // Add Button
            Button(action: handleAdd) {
                Text("Add Person")
                    .font(.spotifyBodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? .white : .wiseSecondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isFormValid ? Color.wiseForestGreen : Color.wiseBorder)
                    )
            }
            .disabled(!isFormValid)
            .buttonStyle(ScaleButtonStyle(scaleAmount: 0.98))
            .padding(.horizontal, 24)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.wiseGroupedBackground)
        .onAppear { isFocused = true }
        .onChange(of: inputValue) { _, _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                avatarScale = 1.05
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    avatarScale = 1.0
                }
            }
        }
        .onChange(of: detectedType) { _, _ in
            HapticManager.shared.selection()
        }
        .animation(.easeInOut(duration: 0.2), value: inputValue.isEmpty)
    }

    private func handleAdd() {
        HapticManager.shared.impact(.medium)

        let trimmedInput = inputValue.trimmingCharacters(in: .whitespaces)
        guard !trimmedInput.isEmpty else { return }

        var name = ""
        var email = ""
        var phone = ""

        switch detectedType {
        case .email:
            email = trimmedInput
            name =
                trimmedInput.components(separatedBy: "@").first?.replacingOccurrences(
                    of: ".", with: " "
                ).capitalized ?? trimmedInput
        case .phone:
            phone = trimmedInput
            name = trimmedInput
        case .name:
            name = trimmedInput
        }

        // Check for existing person by email, phone, or name
        let existingPerson = dataManager.people.first { person in
            // Check by email
            if !email.isEmpty && person.email.lowercased() == email.lowercased() {
                return true
            }
            // Check by phone (normalized)
            if !phone.isEmpty {
                let normalizedExisting = PhoneNumberNormalizer.normalize(person.phone)
                let normalizedNew = PhoneNumberNormalizer.normalize(phone)
                if !normalizedExisting.isEmpty && normalizedExisting == normalizedNew {
                    return true
                }
            }
            // Check by name (case-insensitive) to prevent duplicate name entries
            if !name.isEmpty && person.name.trimmingCharacters(in: .whitespaces).lowercased() == name.lowercased() {
                return true
            }
            return false
        }

        if let existing = existingPerson {
            HapticManager.shared.warning()
            ToastManager.shared.showInfo("\(existing.name) already exists in People")
            // Don't close sheet - let user see the message and correct input
            return
        }

        let newPerson = Person(
            name: name,
            email: email,
            phone: phone,
            avatarType: .initials(
                AvatarGenerator.generateInitials(from: name),
                colorIndex: AvatarColorPalette.colorIndex(for: name)
            )
        )

        do {
            try dataManager.addPerson(newPerson)
            HapticManager.shared.success()
            ToastManager.shared.showSuccess("Person added!")
            inputValue = ""
            isPresented = false
        } catch {
            dataManager.error = error
        }
    }
}
