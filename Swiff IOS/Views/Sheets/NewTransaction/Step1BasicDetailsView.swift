//
//  Step1BasicDetailsView.swift
//  Swiff IOS
//
//  Step 1: Basic Info - Transaction name, amount, currency, category
//  Enhanced with robust validation, keyboard management, and smooth interactions
//

import SwiftUI

struct Step1BasicDetailsView: View {
    @ObservedObject var viewModel: NewTransactionViewModel
    @EnvironmentObject var dataManager: DataManager
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case name
        case amount
    }

    // Track if user has attempted to proceed (for showing validation)
    @State private var hasAttemptedProceed: Bool = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Metrics.paddingLarge) {
                    // Divider below header
                    Divider()
                        .padding(.horizontal, -20)

                    // Section title
                    Text("Basic Info")
                        .font(.spotifyDisplayMedium)
                        .foregroundColor(.wisePrimaryText)

                    // Transaction Name Field
                    transactionNameField
                        .id("nameField")

                    // Amount and Currency Row
                    amountCurrencyRow
                        .id("amountField")

                    // Category Section
                    categorySection

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, Theme.Metrics.paddingMedium + 4)
                .padding(.top, Theme.Metrics.paddingSmall)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                // Next Step Button with validation
                nextStepButton
                    .padding(.horizontal, Theme.Metrics.paddingMedium + 4)
                    .padding(.bottom, Theme.Metrics.paddingMedium + 4)
                    .background(
                        Color.wiseGroupedBackground
                            .ignoresSafeArea()
                    )
            }
            .onChange(of: focusedField) { _, newValue in
                // Scroll to focused field
                withAnimation(.smooth) {
                    if newValue == .name {
                        proxy.scrollTo("nameField", anchor: .top)
                    } else if newValue == .amount {
                        proxy.scrollTo("amountField", anchor: .center)
                    }
                }
            }
        }
        .onTapGesture {
            // Dismiss keyboard on tap outside
            dismissKeyboard()
        }
    }

    // MARK: - Transaction Name Field

    private var transactionNameField: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.paddingSmall) {
            Text("Transaction Name")
                .font(.spotifyLabelLarge)
                .foregroundColor(.wisePrimaryText)

            TextField("e.g., Dinner at Nobu", text: $viewModel.transactionName)
                .font(.spotifyBodyLarge)
                .padding(.horizontal, Theme.Metrics.paddingMedium)
                .padding(.vertical, Theme.Metrics.paddingMedium)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                        .fill(Color.wiseCardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                        .stroke(borderColor(for: .name), lineWidth: borderWidth(for: .name))
                )
                .focused($focusedField, equals: .name)
                .submitLabel(.next)
                .onSubmit {
                    // Move to amount field on submit
                    focusedField = .amount
                }

            // Validation message
            if hasAttemptedProceed && viewModel.transactionName.trimmingCharacters(in: .whitespaces).isEmpty {
                validationMessage("Enter a transaction name")
            }
        }
    }

    // MARK: - Amount and Currency Row

    private var amountCurrencyRow: some View {
        HStack(alignment: .top, spacing: Theme.Metrics.paddingMedium) {
            // Amount Field
            VStack(alignment: .leading, spacing: Theme.Metrics.paddingSmall) {
                Text("Amount")
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wisePrimaryText)

                HStack(spacing: Theme.Metrics.paddingSmall) {
                    Text(viewModel.selectedCurrency.symbol)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wiseSecondaryText)

                    TextField("0.00", text: $viewModel.amountString)
                        .font(.spotifyBodyLarge)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .amount)
                        .onChange(of: viewModel.amountString) { _, newValue in
                            filterAmountInput(newValue)
                        }
                }
                .padding(.horizontal, Theme.Metrics.paddingMedium)
                .padding(.vertical, Theme.Metrics.paddingMedium)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                        .fill(Color.wiseCardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                        .stroke(borderColor(for: .amount), lineWidth: borderWidth(for: .amount))
                )

                // Validation message
                if hasAttemptedProceed && viewModel.amount <= 0 {
                    validationMessage("Enter an amount greater than 0")
                }
            }
            .frame(maxWidth: .infinity)

            // Currency Picker
            VStack(alignment: .leading, spacing: Theme.Metrics.paddingSmall) {
                Text("Currency")
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wisePrimaryText)

                Menu {
                    ForEach(Currency.allCases, id: \.self) { currency in
                        Button(action: {
                            HapticManager.shared.selection()
                            viewModel.selectedCurrency = currency
                        }) {
                            HStack {
                                Text("\(currency.flag) \(currency.rawValue)")
                                if currency == viewModel.selectedCurrency {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedCurrency.rawValue)
                            .font(.spotifyBodyLarge)
                            .foregroundColor(.wisePrimaryText)

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(.wiseSecondaryText)
                    }
                    .padding(.horizontal, Theme.Metrics.paddingMedium)
                    .padding(.vertical, Theme.Metrics.paddingMedium)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                            .fill(Color.wiseCardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium)
                            .stroke(Color.wiseBorder, lineWidth: 1)
                    )
                }
            }
            .frame(width: 120)
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.paddingSmall + 4) {
            Text("Category")
                .font(.spotifyLabelLarge)
                .foregroundColor(.wisePrimaryText)

            // Horizontal scrollable category chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(TransactionCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            category: category,
                            isSelected: viewModel.selectedCategory == category,
                            action: {
                                HapticManager.shared.selection()
                                withAnimation(.smooth(duration: 0.2)) {
                                    viewModel.selectedCategory = category
                                }
                                // Dismiss keyboard when selecting category
                                dismissKeyboard()
                            }
                        )
                    }
                }
                .padding(.vertical, 2)  // Prevent shadow clipping
            }
        }
    }

    // MARK: - Next Step Button

    private var nextStepButton: some View {
        VStack(spacing: Theme.Metrics.paddingSmall) {
            Button {
                dismissKeyboard()

                if viewModel.canProceedStep1 {
                    viewModel.goToNextStep()
                } else {
                    // Show validation errors
                    withAnimation(.smooth) {
                        hasAttemptedProceed = true
                    }
                    HapticManager.shared.warning()
                }
            } label: {
                HStack(spacing: Theme.Metrics.paddingSmall) {
                    Text("Next Step")
                        .font(.spotifyBodyLarge)
                        .fontWeight(.semibold)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium + 2)
                        .fill(Color.wiseForestGreen)
                        .opacity(viewModel.canProceedStep1 ? 1 : 0.5)
                )
            }
            .cardShadow()
        }
    }

    // MARK: - Helper Views

    private func validationMessage(_ message: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 12))

            Text(message)
                .font(.spotifyLabelSmall)
        }
        .foregroundColor(.wiseError)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Helper Functions

    private func borderColor(for field: Field) -> Color {
        if focusedField == field {
            return Color.wiseForestGreen
        }

        // Show error border if validation failed
        if hasAttemptedProceed {
            switch field {
            case .name:
                if viewModel.transactionName.trimmingCharacters(in: .whitespaces).isEmpty {
                    return Color.wiseError
                }
            case .amount:
                if viewModel.amount <= 0 {
                    return Color.wiseError
                }
            }
        }

        return Color.wiseBorder
    }

    private func borderWidth(for field: Field) -> CGFloat {
        if focusedField == field {
            return 2
        }

        // Thicker border for error state
        if hasAttemptedProceed {
            switch field {
            case .name:
                if viewModel.transactionName.trimmingCharacters(in: .whitespaces).isEmpty {
                    return 2
                }
            case .amount:
                if viewModel.amount <= 0 {
                    return 2
                }
            }
        }

        return 1
    }

    private func filterAmountInput(_ newValue: String) {
        var filtered = newValue.filter { $0.isNumber || $0 == "." }

        // Prevent leading zeros (except for "0.")
        if filtered.hasPrefix("00") {
            filtered = String(filtered.dropFirst())
        }

        // Add leading zero for decimal starting with "."
        if filtered.hasPrefix(".") {
            filtered = "0" + filtered
        }

        // Prevent multiple decimals
        let decimalCount = filtered.filter { $0 == "." }.count
        if decimalCount > 1 {
            if let lastDecimalIndex = filtered.lastIndex(of: ".") {
                filtered.remove(at: lastDecimalIndex)
            }
        }

        // Limit decimal places to 2
        if let decimalIndex = filtered.firstIndex(of: ".") {
            let decimalPart = filtered[filtered.index(after: decimalIndex)...]
            if decimalPart.count > 2 {
                let endIndex = filtered.index(decimalIndex, offsetBy: 3)
                filtered = String(filtered[..<endIndex])
            }
        }

        // Only update if changed
        if filtered != newValue {
            viewModel.amountString = filtered
        }
    }

    private func dismissKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Category Chip Component

struct CategoryChip: View {
    let category: TransactionCategory
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Metrics.paddingSmall) {
                Image(systemName: category.icon)
                    .font(.system(size: 22))

                Text(category.rawValue)
                    .font(.spotifyLabelMedium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(isSelected ? .white : .wisePrimaryText)
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium + 2)
                    .fill(isSelected ? Color.wiseForestGreen : Color.wiseCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadiusMedium + 2)
                    .stroke(isSelected ? Color.clear : Color.wiseBorder, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .cardShadow()
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Preview

#Preview("Step 1 - Basic Details") {
    Step1BasicDetailsView(viewModel: NewTransactionViewModel())
        .environmentObject(DataManager.shared)
        .background(Color.wiseGroupedBackground)
}
