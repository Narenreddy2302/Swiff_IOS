//
//  AddTransactionSheet.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 1/2/26.
//  Redesigned Add Transaction Sheet
//

import SwiftUI

struct AddTransactionSheet: View {
    @Binding var showingAddTransactionSheet: Bool
    let onTransactionAdded: (Transaction) -> Void
    var preselectedParticipant: Person? = nil

    @EnvironmentObject var dataManager: DataManager

    // Basic transaction fields
    @State private var title = ""
    @State private var amount = 0.0  // Changed to Double for ValidatedAmountField
    @State private var selectedCategory: TransactionCategory = .food
    @State private var transactionType: TransactionType = .expense
    @State private var notes = ""
    @State private var selectedCurrency: Currency = UserSettings.shared.selectedCurrency

    // Split transaction fields
    @State private var selectedPayer: Person?
    @State private var selectedParticipants: Set<UUID> = []
    @State private var splitType: SplitType = .equally
    @State private var participantAmounts: [UUID: Double] = [:]
    @State private var participantPercentages: [UUID: Double] = [:]
    @State private var participantShares: [UUID: Int] = [:]

    // Validation
    @State private var validationMessage: String?
    @State private var validationType: ValidationBanner.BannerType = .info

    // UI state
    @State private var showingPaidByPicker = false
    @State private var showingParticipantPicker = false
    @State private var amountText: String = ""  // String-based for better UX

    // Focus state for keyboard management
    enum FormField: Hashable {
        case amount
        case transactionName
        case notes
        case participantAmount(UUID)
        case participantPercentage(UUID)
    }
    @FocusState private var focusedField: FormField?

    enum TransactionType: String, CaseIterable {
        case expense = "Expense"
        case income = "Income"

        var color: Color {
            switch self {
            case .expense: return .wiseError
            case .income: return .wiseBrightGreen
            }
        }

        var icon: String {
            switch self {
            case .expense: return "arrow.down.circle.fill"
            case .income: return "arrow.up.circle.fill"
            }
        }
    }

    private var isFormValid: Bool {
        // Basic validation
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty,
            amount > 0
        else {
            return false
        }

        // Payer validation - required for all transactions
        guard selectedPayer != nil else { return false }

        // Split validation - only validate if participants are selected
        if !selectedParticipants.isEmpty {
            if let validation = validateSplitConfiguration() {
                guard validation.isValid else { return false }
            }
        }

        return true
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            sheetHeader

            ScrollView {
                VStack(spacing: 24) {  // Increased spacing for cleaner look
                    // Amount Input (Large and central)
                    amountInputSection

                    // Main Form Fields
                    VStack(spacing: 20) {
                        // Transaction Name with focus support
                        transactionNameSection

                        // Category Selection
                        categorySection

                        // Paid By
                        paidBySection

                        // Split With
                        splitWithSection

                        // Split Method
                        splitMethodSection

                        // Notes
                        notesSection
                    }

                    // Validation Banner
                    if let message = validationMessage {
                        ValidationBanner(type: validationType, message: message)
                    }

                    // Submit Button
                    submitButton

                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .scrollDismissesKeyboard(.interactively)  // Dismiss keyboard on scroll
        }
        .background(Color.wiseBackground)
        // Keyboard toolbar with Done button
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
        .onChange(of: selectedCategory) { _, newCategory in
            focusedField = nil  // Dismiss keyboard on category change
            transactionType = (newCategory == .income) ? .income : .expense
        }
        .onChange(of: amount) { _, _ in
            updateValidationMessage()
        }
        .onChange(of: selectedParticipants) { _, _ in
            updateValidationMessage()
        }
        .onChange(of: splitType) { _, newType in
            focusedField = nil  // Dismiss keyboard on split type change
            resetSplitInputs()
            initializeSplitDefaults(for: newType)
            updateValidationMessage()
        }
        .onAppear {
            selectedParticipants.removeAll()
            if let person = preselectedParticipant {
                selectedParticipants.insert(person.id)
                initializeSplitDefaults(for: splitType)
            }
        }
    }

    // MARK: - View Sections

    private var sheetHeader: some View {
        HStack {
            Text("New Transaction")
                .font(.spotifyHeadingMedium)
                .foregroundColor(.wisePrimaryText)

            Spacer()

            Button(action: { showingAddTransactionSheet = false }) {
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
        .background(Color.wiseBackground)  // Ensure header has background
    }

    private var amountInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            HStack(spacing: 12) {
                // Currency picker (tappable) - dismisses keyboard
                Menu {
                    ForEach(Currency.allCases, id: \.self) { currency in
                        Button(action: {
                            HapticManager.shared.light()
                            focusedField = nil  // Dismiss keyboard
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

                // String-based amount field for seamless typing
                TextField("0.00", text: $amountText)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amount)
                    .onChange(of: amountText) { _, newValue in
                        // Filter to numbers and single decimal point
                        var filtered = newValue.filter { $0.isNumber || $0 == "." }
                        // Ensure only one decimal point
                        let decimalCount = filtered.filter { $0 == "." }.count
                        if decimalCount > 1 {
                            if let lastDecimalIndex = filtered.lastIndex(of: ".") {
                                filtered.remove(at: lastDecimalIndex)
                            }
                        }
                        if filtered != newValue {
                            amountText = filtered
                        }
                        // Sync with Double amount
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

    private var transactionNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transaction Name")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            TextField("e.g., Dinner at Mario's", text: $title)
                .font(.spotifyBodyMedium)
                .foregroundColor(.wisePrimaryText)
                .textInputAutocapitalization(.words)
                .focused($focusedField, equals: .transactionName)
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
            FormSectionHeader(title: "Category", isRequired: false)
            CategoryHorizontalSelector(
                selectedCategory: $selectedCategory,
                onSelect: { focusedField = nil }  // Dismiss keyboard on category select
            )
        }
    }

    private var paidBySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            FormSectionHeader(title: "Paid By", isRequired: true)

            VStack(spacing: 12) {
                // Select Payer Button
                Menu {
                    ForEach(Array(dataManager.people), id: \.id) { (person: Person) in
                        Button(action: {
                            HapticManager.shared.light()
                            focusedField = nil  // Dismiss keyboard
                            selectedPayer = person
                        }) {
                            HStack {
                                Text(person.avatarType.displayValue)
                                Text(person.name)
                                if selectedPayer?.id == person.id {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedPayer == nil ? "Select payer" : "Change payer")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseSecondaryText)
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.wisePrimaryText)
                    }
                    .padding(16)
                    .background(Color.wiseCardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.wiseBorder, lineWidth: 1)
                    )
                }

                // Selected Payer Display
                if let payer = selectedPayer {
                    HStack(spacing: 12) {
                        AvatarView(avatarType: payer.avatarType, size: .small, style: .solid)
                            .frame(width: 32, height: 32)

                        Text(payer.name)
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)

                        Spacer()

                        Button(action: {
                            HapticManager.shared.light()
                            selectedPayer = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                    .padding(12)
                    .background(Color.wiseCardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.wiseBorder, lineWidth: 1)
                    )
                }
            }
        }
    }

    private var splitWithSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            FormSectionHeader(title: "Split With (Optional)", isRequired: false)

            VStack(spacing: 12) {
                // Add Participants Button
                Menu {
                    ForEach(Array(dataManager.people), id: \.id) { (person: Person) in
                        Button(action: { toggleParticipant(person.id) }) {
                            HStack {
                                Text(person.avatarType.displayValue)
                                Text(person.name)
                                if selectedParticipants.contains(person.id) {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text("Add people to split with")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseSecondaryText)
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.wisePrimaryText)
                    }
                    .padding(16)
                    .background(Color.wiseCardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.wiseBorder, lineWidth: 1)
                    )
                }

                // Selected Participants List
                if !selectedParticipants.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(Array(selectedParticipants), id: \.self) { personId in
                            if let person = dataManager.people.first(where: { $0.id == personId }) {
                                participantChipView(person: person)
                            }
                        }
                    }
                }
            }
        }
    }

    private func participantChipView(person: Person) -> some View {
        HStack(spacing: 12) {
            AvatarView(avatarType: person.avatarType, size: .small, style: .solid)
                .frame(width: 32, height: 32)

            Text(person.name)
                .font(.spotifyBodyMedium)
                .foregroundColor(.wisePrimaryText)

            Spacer()

            participantInputField(for: person)

            Button(action: { toggleParticipant(person.id) }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.wiseSecondaryText)
            }
        }
        .padding(12)
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.wiseBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func participantInputField(for person: Person) -> some View {
        switch splitType {
        case .equally:
            let amount = calculateEqualAmount()
            Text(amount.asCurrency)
                .font(.spotifyBodyMedium)
                .foregroundColor(.wisePrimaryText)

        case .percentages:
            HStack(spacing: 4) {
                TextField(
                    "0",
                    value: Binding(
                        get: { participantPercentages[person.id] ?? 0 },
                        set: { participantPercentages[person.id] = $0 }
                    ), format: .number
                )
                .keyboardType(.decimalPad)
                .frame(width: 50)
                .multilineTextAlignment(.trailing)
                .font(.spotifyBodyMedium)
                .focused($focusedField, equals: .participantPercentage(person.id))

                Text("%")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
            }

        case .shares:
            HStack(spacing: 4) {
                Stepper(
                    value: Binding(
                        get: { participantShares[person.id] ?? 1 },
                        set: { participantShares[person.id] = max(1, $0) }
                    ),
                    in: 1...10
                ) {
                    Text("\(participantShares[person.id] ?? 1)×")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                }
            }

        case .exactAmounts, .adjustments:
            HStack(spacing: 4) {
                Text(UserSettings.shared.selectedCurrency.symbol)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)

                TextField(
                    "0.00",
                    value: Binding(
                        get: { participantAmounts[person.id] ?? 0 },
                        set: { participantAmounts[person.id] = $0 }
                    ), format: .number
                )
                .keyboardType(.decimalPad)
                .frame(width: 60)
                .multilineTextAlignment(.trailing)
                .font(.spotifyBodyMedium)
                .focused($focusedField, equals: .participantAmount(person.id))
            }
        }
    }

    private var splitMethodSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            FormSectionHeader(title: "Split Method", isRequired: false)
            SplitMethodSelector(
                selectedType: $splitType,
                onSelect: { focusedField = nil }  // Dismiss keyboard on split method select
            )
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            FormSectionHeader(title: "Notes (Optional)", isRequired: false)

            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("Add details...")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .padding(16)
                }

                TextEditor(text: $notes)
                    .font(.spotifyBodyMedium)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .focused($focusedField, equals: .notes)
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.wiseBorder, lineWidth: 1)
            )
        }
    }

    private var submitButton: some View {
        Button(action: {
            focusedField = nil  // Dismiss keyboard first
            addTransaction()
        }) {
            Text("Add Transaction")
                .font(.spotifyBodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(isFormValid ? .wisePrimaryButtonText : .wiseSecondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isFormValid ? Color.wisePrimaryButton : Color.wiseDisabledButton)
                .cornerRadius(12)
        }
        .disabled(!isFormValid)
    }

    // MARK: - Helper Methods

    private func calculateEqualAmount() -> Double {
        guard !selectedParticipants.isEmpty,
            amount > 0
        else { return 0 }
        return amount / Double(selectedParticipants.count)
    }

    private func calculateAmount(for personId: UUID) -> Double {
        guard amount > 0 else { return 0 }

        switch splitType {
        case .equally:
            return calculateEqualAmount()

        case .percentages:
            let percentage = participantPercentages[personId] ?? 0
            return amount * (percentage / 100)

        case .shares:
            let shares = participantShares[personId] ?? 1
            let totalShares = participantShares.values.reduce(0, +)
            return totalShares > 0 ? amount * Double(shares) / Double(totalShares) : 0

        case .exactAmounts, .adjustments:
            return participantAmounts[personId] ?? 0
        }
    }

    private func validateSplitConfiguration() -> (isValid: Bool, message: String)? {
        guard amount > 0 else { return nil }

        switch splitType {
        case .equally:
            return (true, "Split equally among \(selectedParticipants.count) people")

        case .percentages:
            let total = participantPercentages.values.reduce(0, +)
            if abs(total - 100) < 0.1 {
                return (true, "Percentages add up to 100%")
            } else {
                return (
                    false,
                    "Percentages must add up to 100% (currently \(String(format: "%.1f", total))%)"
                )
            }

        case .exactAmounts, .adjustments:
            let total = participantAmounts.values.reduce(0, +)
            if abs(total - amount) < 0.01 {
                return (true, "Amounts match total")
            } else {
                return (
                    false,
                    "Amounts must add up to \(amount.asCurrency) (currently \(total.asCurrency))"
                )
            }

        case .shares:
            return (true, "Split by shares")
        }
    }

    private func initializeSplitDefaults(for splitType: SplitType) {
        let count = Double(selectedParticipants.count)

        switch splitType {
        case .equally:
            break

        case .percentages:
            let equalPercentage = count > 0 ? 100.0 / count : 0
            for personId in selectedParticipants {
                participantPercentages[personId] = equalPercentage
            }

        case .shares:
            for personId in selectedParticipants {
                participantShares[personId] = 1
            }

        case .exactAmounts, .adjustments:
            let equalAmount = count > 0 ? amount / count : 0
            for personId in selectedParticipants {
                participantAmounts[personId] = equalAmount
            }
        }
    }

    private func resetSplitInputs() {
        participantAmounts.removeAll()
        participantPercentages.removeAll()
        participantShares.removeAll()
    }

    private func toggleParticipant(_ personId: UUID) {
        HapticManager.shared.light()
        focusedField = nil  // Dismiss keyboard when selecting participants
        if selectedParticipants.contains(personId) {
            selectedParticipants.remove(personId)
            participantAmounts.removeValue(forKey: personId)
            participantPercentages.removeValue(forKey: personId)
            participantShares.removeValue(forKey: personId)
        } else {
            selectedParticipants.insert(personId)
            initializeSplitDefaults(for: splitType)
        }
    }

    private func updateValidationMessage() {
        if let validation = validateSplitConfiguration() {
            validationMessage = validation.message
            validationType = validation.isValid ? .success : .warning
        } else {
            validationMessage = nil
        }
    }

    private func addTransaction() {
        guard let payer = selectedPayer else { return }
        let finalAmount = transactionType == .expense ? -abs(amount) : abs(amount)

        var splitBillId: UUID? = nil

        // Only create split bill if participants are selected
        if !selectedParticipants.isEmpty {
            let payerId = payer.id
            let participants = selectedParticipants.map { personId -> SplitParticipant in
                let participantAmount = calculateAmount(for: personId)
                return SplitParticipant(
                    personId: personId,
                    amount: participantAmount,
                    hasPaid: personId == payerId,
                    percentage: participantPercentages[personId],
                    shares: participantShares[personId]
                )
            }

            let splitBill = SplitBill(
                title: title.trimmingCharacters(in: .whitespaces),
                totalAmount: abs(amount),
                paidById: payerId,
                splitType: splitType,
                participants: participants,
                notes: notes,
                category: selectedCategory,
                date: Date()
            )

            do {
                try dataManager.addSplitBill(splitBill)
                splitBillId = splitBill.id

                // Update balances for participants
                for participant in participants where participant.personId != payer.id {
                    if var person = dataManager.people.first(where: { $0.id == participant.personId }) {
                        person.balance -= participant.amount
                        try dataManager.updatePerson(person)
                    }
                }

                if var payerPerson = dataManager.people.first(where: { $0.id == payer.id }) {
                    let totalOwed =
                        participants
                        .filter { $0.personId != payer.id }
                        .reduce(0) { $0 + $1.amount }
                    payerPerson.balance += totalOwed
                    try dataManager.updatePerson(payerPerson)
                }
            } catch {
                print("Error creating split bill: \(error)")
                return
            }
        }

        let subtitle = selectedParticipants.isEmpty ? transactionType.rawValue : "Split Transaction"
        let newTransaction = Transaction(
            title: title.trimmingCharacters(in: .whitespaces),
            subtitle: subtitle,
            amount: finalAmount,
            category: selectedCategory,
            date: Date(),
            isRecurring: false,
            tags: [],
            notes: notes,
            splitBillId: splitBillId
        )

        onTransactionAdded(newTransaction)
        HapticManager.shared.success()
        showingAddTransactionSheet = false
    }
}
