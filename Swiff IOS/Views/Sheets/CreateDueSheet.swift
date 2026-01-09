//
//  CreateDueSheet.swift
//  Swiff IOS
//
//  Created by Claude Code on 1/8/26.
//  Sheet for creating a simple due/IOU with a contact
//

import SwiftUI

struct CreateDueSheet: View {
    @Binding var isPresented: Bool
    let contact: ContactEntry
    let direction: DueDirection
    let onDueCreated: () -> Void

    @EnvironmentObject var dataManager: DataManager

    // Form fields
    @State private var amountText: String = ""
    @State private var amount: Double = 0.0
    @State private var description: String = ""
    @State private var selectedCategory: TransactionCategory = .other
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var selectedCurrency: Currency = .USD

    // UI State
    @State private var isCreating: Bool = false
    @State private var showCategoryPicker: Bool = false

    // Focus state for keyboard management
    enum FormField: Hashable {
        case amount
        case description
        case notes
    }
    @FocusState private var focusedField: FormField?

    private var isFormValid: Bool {
        !description.trimmingCharacters(in: .whitespaces).isEmpty && amount > 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            sheetHeader

            ScrollView {
                VStack(spacing: 24) {
                    // Contact Info Card
                    contactInfoCard

                    // Direction Badge
                    directionBadge

                    // Amount Input
                    amountInputSection

                    // Description Field
                    descriptionSection

                    // Category Picker
                    categorySection

                    // Date Picker
                    dateSection

                    // Notes Field
                    notesSection

                    // Submit Button
                    submitButton

                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color.wiseBackground)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
                .font(.spotifyBodyMedium)
                .foregroundColor(.wisePrimaryText)
            }
        }
    }

    // MARK: - View Sections

    private var sheetHeader: some View {
        HStack {
            Text("New Due")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            Spacer()

            Button(action: { isPresented = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.wisePrimaryText)
                    .frame(width: 32, height: 32)
                    .background(Color.wiseBorder.opacity(0.3))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.wiseBackground)
    }

    private var contactInfoCard: some View {
        HStack(spacing: 12) {
            // Avatar
            ContactAvatarView(contact: contact, size: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                if let phone = contact.primaryPhone {
                    Text(formatPhoneForDisplay(phone))
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Account status badge
            if contact.hasAppAccount {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                    Text("On Swiff")
                        .font(.spotifyCaptionMedium)
                }
                .foregroundColor(Theme.Colors.success)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wiseCardBackground)
                .stroke(Color.wiseBorder, lineWidth: 1)
        )
    }

    private var directionBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: direction.icon)
                .font(.system(size: 16, weight: .semibold))

            Text(direction.displayText)
                .font(.spotifyBodyMedium)
                .fontWeight(.semibold)
        }
        .foregroundColor(direction.isPositiveBalance ? Theme.Colors.amountPositive : Theme.Colors.amountNegative)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(direction.isPositiveBalance ? Theme.Colors.amountPositive.opacity(0.15) : Theme.Colors.amountNegative.opacity(0.15))
        )
    }

    private var amountInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            HStack(spacing: 12) {
                // Currency picker
                Menu {
                    ForEach(Currency.allCases, id: \.self) { currency in
                        Button(action: {
                            HapticManager.shared.light()
                            focusedField = nil
                            selectedCurrency = currency
                        }) {
                            HStack {
                                Text("\(currency.symbol) \(currency.name)")
                                if selectedCurrency == currency {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedCurrency.symbol)
                            .font(.spotifyBodyLarge)
                            .foregroundColor(.wisePrimaryText)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.wiseSecondaryText)
                    }
                }

                // Amount field
                TextField("0.00", text: $amountText)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amount)
                    .onChange(of: amountText) { _, newValue in
                        // Filter to numbers and single decimal point
                        var filtered = newValue.filter { $0.isNumber || $0 == "." }
                        let decimalCount = filtered.filter { $0 == "." }.count
                        if decimalCount > 1 {
                            if let lastDecimalIndex = filtered.lastIndex(of: ".") {
                                filtered.remove(at: lastDecimalIndex)
                            }
                        }
                        if filtered != newValue {
                            amountText = filtered
                        }
                        amount = Double(filtered) ?? 0
                    }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wiseCardBackground)
                    .stroke(Color.wiseBorder, lineWidth: 1)
            )
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's this for?")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            TextField("e.g., Lunch yesterday, Movie tickets", text: $description)
                .font(.spotifyBodyMedium)
                .foregroundColor(.wisePrimaryText)
                .textInputAutocapitalization(.sentences)
                .focused($focusedField, equals: .description)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.wiseCardBackground)
                        .stroke(Color.wiseBorder, lineWidth: 1)
                )
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            CategoryHorizontalSelector(
                selectedCategory: $selectedCategory,
                onSelect: { focusedField = nil }
            )
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            HStack {
                DatePicker(
                    "",
                    selection: $date,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .onChange(of: date) { _, _ in
                    focusedField = nil
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wiseCardBackground)
                    .stroke(Color.wiseBorder, lineWidth: 1)
            )
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (optional)")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            TextField("Add notes...", text: $notes, axis: .vertical)
                .font(.spotifyBodyMedium)
                .foregroundColor(.wisePrimaryText)
                .lineLimit(3...5)
                .focused($focusedField, equals: .notes)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.wiseCardBackground)
                        .stroke(Color.wiseBorder, lineWidth: 1)
                )
        }
    }

    private var submitButton: some View {
        Button(action: {
            focusedField = nil
            createDue()
        }) {
            HStack(spacing: 8) {
                if isCreating {
                    ProgressView()
                        .tint(.wisePrimaryButtonText)
                        .scaleEffect(0.8)
                }
                Text("Create Due")
                    .font(.spotifyBodyLarge)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isFormValid ? .wisePrimaryButtonText : .wiseSecondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isFormValid ? Color.wisePrimaryButton : Color.wiseDisabledButton)
            .cornerRadius(12)
        }
        .disabled(!isFormValid || isCreating)
    }

    // MARK: - Helper Methods

    private func formatPhoneForDisplay(_ phone: String) -> String {
        guard phone.count >= 10 else { return phone }

        if phone.hasPrefix("+1") && phone.count == 12 {
            let number = String(phone.dropFirst(2))
            let area = number.prefix(3)
            let first = number.dropFirst(3).prefix(3)
            let last = number.suffix(4)
            return "(\(area)) \(first)-\(last)"
        }

        return phone
    }

    private func createDue() {
        guard isFormValid else { return }

        isCreating = true

        do {
            let theyOweMe = direction == .theyOweMe
            _ = try dataManager.createSimpleDue(
                contact: contact,
                amount: amount,
                theyOweMe: theyOweMe,
                description: description,
                category: selectedCategory,
                date: date,
                notes: notes.isEmpty ? nil : notes
            )

            HapticManager.shared.success()
            ToastManager.shared.showSuccess("Due created")
            onDueCreated()
            isPresented = false
        } catch {
            isCreating = false
            HapticManager.shared.error()
            ToastManager.shared.showError("Failed to create due: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

#Preview {
    CreateDueSheet(
        isPresented: .constant(true),
        contact: ContactEntry(
            id: "1",
            name: "John Smith",
            phoneNumbers: ["+12025551234"],
            email: "john@example.com",
            thumbnailImageData: nil,
            hasAppAccount: false
        ),
        direction: .theyOweMe,
        onDueCreated: {}
    )
    .environmentObject(DataManager.shared)
}
